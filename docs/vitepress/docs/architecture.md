
---
title: Architecture
description: Visual and text-based architecture diagram for the Frostflake Nix flake project.
lastUpdated: true
---

# Architecture

![Frostflake Architecture](./architecture.svg)

---

```mermaid
flowchart TD
  subgraph Hosts
    Avalanche
    Aurora
    Iceberg
    Glacier
    Hailstone
  end
  subgraph Modules
    System[system]
    Hardware[hardware]
    Security[security]
    User[user]
    VMs[vms]
    Desktop[desktop]
    Docker[docker]
    VPN[vpn]
    AI[ai]
    Secrets[secrets]
    Webauthn[webauthn]
  end
  subgraph HomeProfiles
    Common[common]
    Linux[linux]
    Darwin[darwin]
  end
  subgraph Lib
    MkLinuxHost[mk-linux-host]
    Packages[packages]
    LibUser[user]
  end
  subgraph Secrets
    Sops[.sops.yaml]
    Overlays[overlays]
    HostSecrets[hosts/*.yaml]
    SharedSecrets[shared.yaml]
  end
  subgraph Deployment
    NixOS
    NixDarwin[nix-darwin]
    HomeManager[Home Manager]
  end

  Hosts --> Modules
  Modules --> Secrets
  Hosts --> HomeProfiles
  Modules --> Lib
  Lib --> Deployment
  HomeProfiles --> Deployment
  Secrets --> Deployment
```

---

This diagram shows how Frostflake’s hosts, modules, user profiles, lib, secrets, and deployment interact. Each box represents a major part of the repo, and arrows show the flow of configuration and data.

- **Hosts**: Each machine (Avalanche, Aurora, etc.) has its own config and imports modules.
- **Modules**: Reusable building blocks for system, hardware, security, user, VMs, desktop, docker, VPN, AI, secrets, and webauthn.
- **Home Profiles**: User environment overlays for common, Linux, and Darwin.
- **Lib**: Helper functions and shared logic (mk-linux-host, packages, user).
- **Secrets**: Managed via overlays, .sops.yaml, and per-host/shared YAML files.
- **Deployment**: NixOS, nix-darwin, and Home Manager handle system and user environment builds.

> For a visual version, see the SVG above. For a text/diagram version, see the Mermaid chart.
