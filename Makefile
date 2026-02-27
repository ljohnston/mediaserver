SHELL = /bin/bash

.DEFAULT_GOAL := targets

# 
# Targets.
#

.PHONY: targets
targets:
	@echo Available targets:
	@make -qp \
	    |awk -F':' '/^[a-zA-Z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' \
	    |grep -Ev ^\(Makefile\|targets\)$$ \
	    |sort -u \
	    |awk '{ print "- " $$0 }'

TUNNEL_COMMAND := \
	while : ; do \
		tunnel_port=$$((RANDOM%63000 + 2000)); \
		if ! nc -z localhost $$tunnel_port >/dev/null 2>&1; then \
			break; \
		fi; \
	done; \
	ssh_cmd="$$(terraform/tf.sh dev \
			-chdir=terraform output \
			-raw bastion_ssh_forward_command \
		    |sed -E "s/-L [0-9]{4,}:/-L $$tunnel_port:/")"; \
	echo "Starting SSH tunnel on port $$tunnel_port..."; \
	sh -c "$$ssh_cmd" >/dev/null 2>&1 & \
	ssh_pid=$$!; \
	trap 'echo "Shutting down SSH tunnel on port $$tunnel_port..."; \
              kill $$ssh_pid 2>/dev/null; \
	      wait $$ssh_pid 2>/dev/null' \
	      EXIT; \
	max_attempts=40; \
	for i in $$(seq 1 $$max_attempts); do \
		if nc -z localhost $$tunnel_port >/dev/null 2>&1; then \
			break; \
		fi; \
		if ! kill -0 $$ssh_pid 2>/dev/null; then \
			echo "ERROR: SSH tunnel process exited prematurely."; \
			exit 1; \
		fi; \
		sleep 0.2; \
		if [ $$i -eq $$max_attempts ]; then \
			echo "ERROR: Timed out waiting for SSH tunnel."; \
			exit 1; \
		fi; \
	done;
	
.PHONY: dev-plan
dev-plan:
	@terraform/tf.sh dev -chdir=terraform plan

.PHONY: dev-infra
dev-infra:
	@terraform/tf.sh dev -chdir=terraform plan -detailed-exitcode -out=tfplan.out >/dev/null; \
	exit_code=$$?; \
	if [ "$$exit_code" = "2" ]; then \
		terraform -chdir=terraform apply tfplan.out; \
	elif [ "$$exit_code" = "0" ]; then \
		echo "Terraform config up to date."; \
	fi

.PHONY: dev-config
dev-config: 
	@$(TUNNEL_COMMAND) \
	ansible-playbook playbook.yml \
	--extra-vars "ansible_port=$$tunnel_port" \
	--inventory inventory/hosts.yml \
	--private-key ~/.ssh/id_ed25519 \
	--vault-id ~/.ansible/.vault_pass \
	--limit dev \
	$(ANSIBLE_ARGS)

.PHONY: dev-test
dev-test: 
	@$(TUNNEL_COMMAND) \
	ANSIBLE_REMOTE_PORT=$$tunnel_port \
	pytest \
	--hosts=ansible://dev \
	--ansible-inventory=inventory/hosts.yml \
	--connection=ansible \
	--sudo \
	tests/test.py 

.PHONY: dev-ssh
dev-ssh:
	@$(TUNNEL_COMMAND) \
	ssh -p $$tunnel_port ubuntu@localhost

.PHONY: dev
dev: dev-infra dev-config dev-test

.PHONY: dev-destroy
dev-destroy:
	@terraform/tf.sh dev -chdir=terraform destroy

.PHONY: prd-config
	@ansible-playbook playbook.yml \
	--inventory inventory/hosts.yml \
	--private-key ~/.ssh/id_ed25519 \
	--vault-id ~/.ansible/.vault_pass \
	--limit prd \
	$(ANSIBLE_ARGS)

.PHONY: prd-test
prd-test: 
	pytest tests/test.py \
	--hosts=ansible://prd \
	--ansible-inventory=inventory/hosts.yml \
	--connection=ansible \
	--sudo

.PHONY: prd
prd: prd-config prd-test

# '--ask-become-pass' here as log file creation requires root.
.PHONY: macbook-config
macbook-config: 
	@ansible-playbook playbook.yml \
	--inventory inventory/hosts.yml \
	--vault-id ~/.ansible/.vault_pass \
	--ask-become-pass \
	--limit macbook \
	$(ANSIBLE_ARGS)

