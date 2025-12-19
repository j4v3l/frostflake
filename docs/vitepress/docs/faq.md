
---
title: FAQ
description: Frequently asked questions about Frostflake and NixOS.
lastUpdated: true
---

# FAQ

## What is a Nix flake?
A flake is a new way to package and distribute Nix projects, making them more reproducible and composable.

## How do I add a new host?
Create a new folder in `hosts/`, copy an existing `default.nix`, and adjust the options for your machine.

## How do I update packages?
Edit the relevant module or Home Manager profile, then rebuild your system.

## Where are secrets stored?
Secrets are managed via overlays and not committed to the repo. See the `secrets/` folder for examples.

## Where can I learn more about NixOS?
- [NixOS Manual](https://nixos.org/manual/)
- [Nix Pills](https://nixos.org/guides/nix-pills.html)
- [NixOS Wiki](https://wiki.nixos.org/)
