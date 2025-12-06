SHELL := /bin/sh
SOPS_AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt
FLAKE ?= .
HOST ?=
FILE ?=
EDITOR ?= nvim

.PHONY: age-key secret-host secret-edit secrets-verify fmt check switch build darwin devshell repl clean hooks lint

age-key:
	@mkdir -p "$(dir $(SOPS_AGE_KEY_FILE))"
	@if [ ! -f "$(SOPS_AGE_KEY_FILE)" ]; then \
		age-keygen -o "$(SOPS_AGE_KEY_FILE)"; \
		chmod 600 "$(SOPS_AGE_KEY_FILE)"; \
	fi
	@echo "Age identity stored at $(SOPS_AGE_KEY_FILE)"
	@printf "Public key: "
	@grep '^# public key:' "$(SOPS_AGE_KEY_FILE)" | tail -n1 | cut -d' ' -f4

secret-host:
	@test -n "$(HOST)" || { echo "Usage: make secret-host HOST=<hostname>" >&2; exit 1; }
	@mkdir -p secrets/hosts
	@EDITOR="$(EDITOR)" sops "secrets/hosts/$(HOST).yaml"

secret-edit:
	@test -n "$(FILE)" || { echo "Usage: make secret-edit FILE=<relative path under secrets/>" >&2; exit 1; }
	@EDITOR="$(EDITOR)" sops "secrets/$(FILE)"

secrets-verify:
	@find secrets -name '*.yaml' -print0 | xargs -0 -r sops --verify

hooks:
	pre-commit install --install-hooks --hook-type commit-msg

lint:
	pre-commit run --all-files

fmt:
	nix fmt .

check:
	nix flake check --impure

switch:
	@test -n "$(HOST)" || { echo "Usage: make switch HOST=<flake output>" >&2; exit 1; }
	sudo nixos-rebuild switch --flake "$(FLAKE)#$(HOST)"

build:
	@test -n "$(HOST)" || { echo "Usage: make build HOST=<flake output>" >&2; exit 1; }
	sudo nixos-rebuild build --flake "$(FLAKE)#$(HOST)"

repl:
	nix repl "$(FLAKE)"

devshell:
	nix develop "$(FLAKE)"

darwin:
	@test -n "$(HOST)" || { echo "Usage: make darwin HOST=Glacier" >&2; exit 1; }
	darwin-rebuild switch --flake "$(FLAKE)#$(HOST)"

clean:
	rm -f result
