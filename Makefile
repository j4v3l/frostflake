SHELL := /bin/sh

# Paths and tool defaults
SOPS_AGE_KEY_FILE ?= $(HOME)/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE
SOPS ?= sops
AGE_KEYGEN ?= age-keygen
FLAKE ?= .
NIX_FLAGS ?= --extra-experimental-features "nix-command flakes"
NIX ?= nix $(NIX_FLAGS)
HOST ?=
FILE ?=hosts/avalanche.yaml
EDITOR ?= nvim
YUBI_CONFIG_DIR ?= $(HOME)/.config/Yubico
U2F_KEYS_FILE ?= $(YUBI_CONFIG_DIR)/u2f_keys
U2F_MAPPING_OUT ?= /tmp/u2f_mapping_$(USER)

.PHONY: help age-key secret-host secret-edit secret-encrypt secret-decrypt secret-encrypt-all secret-decrypt-all regen-hardware switch-hw secrets-verify fmt check switch build darwin dev devshell repl clean hooks lint yubi-pam-enroll yubi-ssh-key

help:
	@echo "Useful targets:"
	@echo "  make age-key                     # generate Age keypair (for sops-nix)"
	@echo "  make secret-host HOST=...        # edit per-host secret file via sops"
	@echo "  make secret-edit FILE=...        # edit secrets/<FILE> via sops"
	@echo "  make secret-encrypt [FILE=...]   # encrypt secrets/<FILE> or all *.yaml under secrets/"
	@echo "  make secret-decrypt [FILE=...]   # decrypt secrets/<FILE> or all *.yaml under secrets/"
	@echo "  make secret-encrypt-all          # encrypt every *.yaml under secrets/"
	@echo "  make secret-decrypt-all          # decrypt every *.yaml under secrets/"
	@echo "  make regen-hardware HOST=...     # regenerate hosts/<HOST>/hardware-configuration.nix"
	@echo "  make switch-hw HOST=...          # regen hardware config, then nixos-rebuild switch"
	@echo "  make secrets-verify              # verify all *.yaml secrets with sops"
	@echo "  make yubi-pam-enroll             # enroll YubiKey for pam_u2f; writes $(U2F_MAPPING_OUT)"
	@echo "  make yubi-ssh-key                # generate hardware-backed ssh key (ed25519-sk)"
	@echo "  make switch HOST=...             # nixos-rebuild switch --flake"
	@echo "  make darwin HOST=...             # darwin-rebuild switch --flake"
	@echo "  make fmt / check / lint          # formatting, flake check, pre-commit (with nix-command + flakes)"
	@echo "  make repl                        # nix repl with this flake"
	@echo "  make dev                         # enter dev shell (nix-command + flakes enabled)"

age-key:
	@mkdir -p "$(dir $(SOPS_AGE_KEY_FILE))"
	@if [ ! -f "$(SOPS_AGE_KEY_FILE)" ]; then \
		$(AGE_KEYGEN) -o "$(SOPS_AGE_KEY_FILE)"; \
		chmod 600 "$(SOPS_AGE_KEY_FILE)"; \
	fi
	@echo "Age identity stored at $(SOPS_AGE_KEY_FILE)"
	@printf "Public key: "
	@grep '^# public key:' "$(SOPS_AGE_KEY_FILE)" | tail -n1 | cut -d' ' -f4

secret-host:
	@test -n "$(HOST)" || { echo "Usage: make secret-host HOST=<hostname>" >&2; exit 1; }
	@mkdir -p secrets/hosts
	@EDITOR="$(EDITOR)" $(SOPS) "secrets/hosts/$(HOST).yaml"

secret-edit:
	@test -n "$(FILE)" || { echo "Usage: make secret-edit FILE=<relative path under secrets/>" >&2; exit 1; }
	@EDITOR="$(EDITOR)" $(SOPS) "secrets/$(FILE)"

secret-encrypt:
	@FILES=$${FILE:+secrets/$$FILE}; \
	 if [ -z "$$FILES" ]; then FILES=$$(find secrets -type f -name '*.yaml'); fi; \
	 echo "[encrypt] files: $$FILES"; \
	 for f in $$FILES; do $(SOPS) --encrypt --in-place "$$f"; done

secret-encrypt-all:
	@FILES=$$(find secrets -type f -name '*.yaml'); \
	 if [ -z "$$FILES" ]; then echo "[encrypt] no secrets found"; exit 0; fi; \
	 echo "[encrypt] files: $$FILES"; \
	 for f in $$FILES; do $(SOPS) --encrypt --in-place "$$f"; done

secret-decrypt:
	@FILES=$${FILE:+secrets/$$FILE}; \
	 if [ -z "$$FILES" ]; then FILES=$$(find secrets -type f -name '*.yaml'); fi; \
	 echo "[decrypt] files: $$FILES"; \
	 for f in $$FILES; do $(SOPS) --decrypt --in-place "$$f"; done

secret-decrypt-all:
	@FILES=$$(find secrets -type f -name '*.yaml'); \
	 if [ -z "$$FILES" ]; then echo "[decrypt] no secrets found"; exit 0; fi; \
	 echo "[decrypt] files: $$FILES"; \
	 for f in $$FILES; do $(SOPS) --decrypt --in-place "$$f"; done

regen-hardware:
	@test -n "$(HOST)" || { echo "Usage: make regen-hardware HOST=<host>" >&2; exit 1; }
	@nixos-generate-config --show-hardware-config > "hosts/$(HOST)/hardware-configuration.nix"

switch-hw: regen-hardware
	@test -n "$(HOST)" || { echo "Usage: make switch-hw HOST=<flake output>" >&2; exit 1; }
	sudo nixos-rebuild switch --flake "$(FLAKE)#$(HOST)"

secrets-verify:
	@find secrets -name '*.yaml' -print0 | while IFS= read -r -d '' f; do \
		status=$$($(SOPS) filestatus "$$f"); \
		echo "$$status" | rg -q '"encrypted":[[:space:]]*true' || { \
			echo "secrets-verify: $$f is not encrypted"; \
			exit 1; \
		}; \
	done

yubi-pam-enroll:
	@mkdir -p "$(YUBI_CONFIG_DIR)"
	@echo "Touch the YubiKey when it blinks to create pam_u2f mapping..."
	@$(NIX) shell nixpkgs#pam_u2f -c pamu2fcfg -u "$(USER)" > "$(U2F_MAPPING_OUT)"
	@echo "pam_u2f mapping written to $(U2F_MAPPING_OUT)"
	@echo "Append this line into secrets/shared.yaml (pam_u2f_mappings) and re-encrypt with 'make secret-encrypt FILE=shared.yaml'."

yubi-ssh-key:
	@if [ -f "$(HOME)/.ssh/id_ed25519_sk" ]; then \
		echo "~/.ssh/id_ed25519_sk already exists; skipping"; \
		exit 0; \
	fi
	@ssh-keygen -t ed25519-sk -O resident -O verify-required -C "$(USER) hardware key" -f "$(HOME)/.ssh/id_ed25519_sk"
	@echo "Add ~/.ssh/id_ed25519_sk.pub to your user hardwareKeys in Nix."
	@echo "To restore the stub on a new client with the YubiKey present: ssh-keygen -K -f ~/.ssh/id_ed25519_sk"

hooks:
	pre-commit install --install-hooks
	pre-commit install --hook-type commit-msg
	pre-commit install --hook-type pre-push

lint:
	$(NIX) develop "$(FLAKE)" -c pre-commit run --all-files

fmt:
	$(NIX) fmt

check:
	$(NIX) flake check

switch:
	@test -n "$(HOST)" || { echo "Usage: make switch HOST=<flake output>" >&2; exit 1; }
	sudo nixos-rebuild switch --flake "$(FLAKE)#$(HOST)"

build:
	@test -n "$(HOST)" || { echo "Usage: make build HOST=<flake output>" >&2; exit 1; }
	sudo nixos-rebuild build --flake "$(FLAKE)#$(HOST)"

repl:
	$(NIX) repl "$(FLAKE)"

devshell:
	$(NIX) develop "$(FLAKE)"

dev: devshell

darwin:
	@test -n "$(HOST)" || { echo "Usage: make darwin HOST=Glacier" >&2; exit 1; }
	darwin-rebuild switch --flake "$(FLAKE)#$(HOST)"

clean:
	rm -f result
