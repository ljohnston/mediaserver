SHELL = /bin/bash

.DEFAULT_GOAL := targets

-include script_development.mk

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

DEV_INSTANCE_IP    := $(shell terraform/tf.sh dev -chdir=terraform output -raw instance_private_ip)
SSH_BASTION_TARGET := $(shell terraform/tf.sh dev -chdir=terraform output -raw bastion_ssh_target)

SSH_KEY  := ~/.ssh/id_ed25519
# SSH_OPTS := -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR
SSH_OPTS := -o IPQoS=throughput -o LogLevel=ERROR 

define open_tunnel
	# Pick a port beteen 20000 and 25000.
	export TUNNEL_PORT=$$(( ($$RANDOM % 5001) + 20000 )); \
	while nc -z localhost $$TUNNEL_PORT >/dev/null 2>&1; do \
		TUNNEL_PORT=$$(( ($$RANDOM % 5001) + 20000 )); \
	done; \
	\
	echo "Opening tunnel to $(DEV_INSTANCE_IP):$(1) on local port $$TUNNEL_PORT..."; \
	ssh -i $(SSH_KEY) -4 -N -L $$TUNNEL_PORT:$(DEV_INSTANCE_IP):$(1) -p 22 $(SSH_BASTION_TARGET) >/dev/null 2>&1 & \
	ssh_pid=$$!; \
	\
	cleanup() { \
		echo "Shutting down SSH tunnel on port $$TUNNEL_PORT..."; \
		kill $$ssh_pid 2>/dev/null; \
		wait $$ssh_pid 2>/dev/null; \
	}; \
	trap cleanup EXIT; \
	\
	timeout=40; \
	until nc -z localhost $$TUNNEL_PORT >/dev/null 2>&1; do \
		((timeout--)); \
		if [ $$timeout -eq 0 ]; then \
			echo "❌ ERROR: Timed out waiting for SSH tunnel."; \
			exit 1; \
		fi; \
		sleep 0.2; \
	done;
endef

.PHONY: ansible-tags
ansible-tags:
	@ansible-playbook --list-tags playbook.yml 2>&1 \
		|grep -v '^[WARNING]' \
		|grep "TASK TAGS" \
		|cut -d ":" -f 2- \
		|tr -d '[]' \
		|tr ',' '\n' \
		|sed 's/^[ \t]*//'
	

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
	@$(call open_tunnel,22) \
	ansible-playbook playbook.yml \
	--extra-vars "ansible_port=$$TUNNEL_PORT" \
	--inventory inventory/hosts.yml \
	--private-key ~/.ssh/id_ed25519 \
	--vault-id ~/.ansible/.vault_pass \
	--limit dev \
	$(ANSIBLE_ARGS)


.PHONY: dev-test
dev-test: 
	@$(call open_tunnel,22) \
	ANSIBLE_REMOTE_PORT=$$TUNNEL_PORT \
	pytest \
	--hosts=ansible://dev \
	--ansible-inventory=inventory/hosts.yml \
	--connection=ansible \
	--sudo \
	tests/test.py 


.PHONY: dev-ssh
dev-ssh:
	@$(call open_tunnel,22) \
	ssh -q $(SSH_OPTS) \
	-p $$TUNNEL_PORT ubuntu@localhost

.PHONY: dev
dev: dev-infra dev-config dev-test

.PHONY: dev-destroy
dev-destroy:
	@terraform/tf.sh dev -chdir=terraform destroy


.PHONY: dev-plex-tunnel
dev-plex-tunnel:
	@$$(terraform/tf.sh dev \
		-chdir=terraform output \
		-raw bastion_plex_forward_command)

dev-scripts:
ifndef SCRIPT_DEVELOPMENT_USER
	$(error SCRIPT_DEVELOMENT_USER is not defined!)
endif	
	@ssh -i $(SCRIPT_DEVELOPMENT_SSH_KEY) \
		$(SSH_OPTS) \
		-J $(SSH_BASTION_TARGET) \
		-R $(SCRIPT_DEVELOPMENT_REVERSE_PORT):localhost:22 -t \
		$(SCRIPT_DEVELOPMENT_USER)@$(DEV_INSTANCE_IP) \
		"sshfs -p $(SCRIPT_DEVELOPMENT_REVERSE_PORT) \
			$(SCRIPT_DEVELOPMENT_USER)@localhost:$(SCRIPT_DEVELOPMENT_LOCAL_DIR) \
			$(SCRIPT_DEVELOPMENT_REMOTE_DIR) \
			-o reconnect -o compression=yes; \
		trap 'echo \"Cleaning up remote mount...\"; \
			if mountpoint -q $(SCRIPT_DEVELOPMENT_REMOTE_DIR); then fusermount -u $(SCRIPT_DEVELOPMENT_REMOTE_DIR); fi' \
		 	EXIT INT TERM; \
			bash"

dev-scripts-unmount:
ifndef SCRIPT_DEVELOPMENT_USER
	$(error SCRIPT_DEVELOPMENT_USER is not defined!)
endif
	@echo "Checking remote mount status for $(MOUNT_POINT)..."
	@ssh -i ~/.ssh/id_rsa \
		$(SSH_OPTS) \
		-J $(SSH_BASTION_TARGET) \
		$(SCRIPT_DEVELOPMENT_USER)@$(INSTANCE_IP) \
		"if mountpoint -q $(SCRIPT_DEVELOPMENT_REMOTE_DIR); then \
			echo 'Active mount found. Unmounting...'; \
			fusermount -u $(SCRIPT_DEVELOPMENT_REMOTE_DIR); \
		 else \
			echo 'Directory is not mounted. Skipping cleanup.'; \
		 fi"

.PHONY: prd-config
prd-config:
	@ansible-playbook playbook.yml \
	--ask-become-pass \
	--inventory inventory/hosts.yml \
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
