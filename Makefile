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
	ssh_cmd=$$(terraform/tf.sh dev -chdir=terraform output -raw bastion_ssh_forward_command |sed 's/-N -L/-f -N -L/') && \
	echo "Starting SSH tunnel..."; echo; \
	eval "$${ssh_cmd} -- tag=bastion_ssh_forward" < /dev/null > /dev/null 2>&1; \
	trap 'echo "Shutting down SSH tunnel..."; pkill -f "tag=bastion_ssh_forward" 2>/dev/null' EXIT; \
	while ! nc -z localhost $$(terraform/tf.sh dev -chdir=terraform output -raw bastion_ssh_forward_port) >/dev/null 2>&1; do \
		sleep 0.1; \
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
		--inventory inventory/hosts.yml \
		--private-key ~/.ssh/id_ed25519 \
		--vault-id ~/.ansible/.vault_pass \
		--limit dev \
		$(ANSIBLE_ARGS)

.PHONY: dev-test
dev-test: 
	@$(TUNNEL_COMMAND) \
		pytest tests/test.py \
		--hosts=ansible://dev \
		--ansible-inventory=inventory/hosts.yml \
		--connection=ansible \
		--sudo

.PHONY: dev-ssh
dev-ssh:
	@$(TUNNEL_COMMAND) \
	ssh -p 9022 ubuntu@localhost

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
	@$(TUNNEL_COMMAND) \
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

