
---
title: Deploying Hosts
description: How to deploy and rebuild hosts with Frostflake (NixOS, macOS).
lastUpdated: true
---

# Deploying Hosts

## Linux Machines

```sh
sudo nixos-rebuild switch --flake .#Avalanche
sudo nixos-rebuild switch --flake .#Aurora
sudo nixos-rebuild switch --flake .#Iceberg
```

## macOS

```sh
darwin-rebuild switch --flake .#Glacier
```

For Glacier, nix-darwin handles CLI tooling, while GUI apps (Brave, Cursor, LM Studio, Ollama, VS Code) are installed via Homebrew casks declared in `hosts/common/darwin.nix`.
