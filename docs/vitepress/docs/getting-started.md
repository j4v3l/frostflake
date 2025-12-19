
---
title: Getting Started
description: Step-by-step guide to setting up and understanding Frostflake.
lastUpdated: true
---

# Getting Started

Welcome to Frostflake! This guide will help you set up and understand the basics of this multi-host Nix flake.

## What is Frostflake?

Frostflake is a Nix flake that manages configuration for multiple hosts (Linux desktops, laptops, VMs, and macOS) using NixOS, Home Manager, and nix-darwin. It makes it easy to share modules, customize environments, and deploy reproducible systems.

## Prerequisites

- Basic familiarity with Nix and NixOS (no worries, we explain everything!)
- Nix installed on your system ([Nix installation guide](https://nixos.org/download.html))
- Git

## Clone the Repository

```sh
git clone https://github.com/j4v3l/frostflake.git
cd frostflake
```

## Enable direnv (optional but recommended)

```sh
direnv allow
```

This lets your shell automatically load the Nix development environment.

## Enter the Dev Shell

```sh
nix develop
```

## Install Pre-commit Hooks

```sh
pre-commit install
```

## Next Steps

- [Host Matrix](./hosts.md)
- [Developer Workflow](./dev-workflow.md)
- [Deploying Hosts](./deploying.md)
