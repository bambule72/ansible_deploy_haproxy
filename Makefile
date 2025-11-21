.PHONY: help lint test clean install

help:
	@echo "Makefile commands for ansible_deploy_haproxy"
	@echo ""
	@echo "Usage:"
	@echo "  make lint           Run yamllint and ansible-lint"
	@echo "  make test           Run molecule tests"
	@echo "  make test-create    Create test instances"
	@echo "  make test-converge  Run converge on test instances"
	@echo "  make test-verify    Run verification tests"
	@echo "  make test-destroy   Destroy test instances"
	@echo "  make clean          Clean up test artifacts"
	@echo "  make install        Install development dependencies"

lint:
	@echo "Running yamllint..."
	yamllint .
	@echo "Running ansible-lint..."
	ansible-lint

test:
	@echo "Running full Molecule test suite..."
	molecule test

test-create:
	@echo "Creating test instances..."
	molecule create

test-converge:
	@echo "Running converge on test instances..."
	molecule converge

test-verify:
	@echo "Running verification tests..."
	molecule verify

test-destroy:
	@echo "Destroying test instances..."
	molecule destroy

clean:
	@echo "Cleaning up test artifacts..."
	rm -rf .molecule
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete

install:
	@echo "Installing development dependencies..."
	pip install "molecule[podman]" molecule-plugins[podman] ansible-lint yamllint
	@echo "Installing required Ansible collections..."
	ansible-galaxy collection install containers.podman ansible.posix
