
---
title: Developer Workflow
description: Modern Nix development workflow for Frostflake contributors.
lastUpdated: true
---

# Developer Workflow

Frostflake uses a modern Nix development workflow:

## 1. Allow direnv

```sh
direnv allow
```

## 2. Enter the Dev Shell

```sh
nix develop
```

## 3. Install Pre-commit Hooks

```sh
pre-commit install
```

## 4. Lint and Format

```sh
nix fmt
nix flake check   # also runs via pre-commit
```

The dev shell provides tools like `alejandra`, `statix`, `deadnix`, `direnv`, `nix-direnv`, `git`, and `pre-commit`. Hooks enforce formatting/linting and fail the commit if anything is out of date.
