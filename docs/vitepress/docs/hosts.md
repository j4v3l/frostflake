
---
title: Host Matrix
description: Overview of all hosts and their configuration in the Frostflake project.
lastUpdated: true
---

# Host Matrix

Frostflake supports multiple hosts, each with its own configuration. Here’s a summary:

| Host      | Platform       | GPU profile | Notes                                                                   |
| --------- | -------------- | ----------- | ----------------------------------------------------------------------- |
| Avalanche | x86_64 desktop | `nvidia`    | RTX 5070 Ti + CUDA acceleration for Ollama.                             |
| Aurora    | x86_64 laptop  | `intel`     | Laptop power tweaks (`tlp`, disabled `power-profiles-daemon`).          |
| Iceberg   | x86_64 VM      | `vm`        | Guest additions (`qemuGuest`, `spice-vdagentd`).                        |
| Glacier   | aarch64-darwin | —           | nix-darwin + Homebrew apps (Brave, Cursor, LM Studio, Ollama, VS Code). |

## Host Configuration Files

- Linux hosts: `hosts/<host>/default.nix`
- macOS host: `hosts/glacier/default.nix`

Each host imports shared modules and sets its own options. For example:

```nix
# hosts/avalanche/default.nix
{
  imports = [
    ../../modules/system/linux-base.nix
    ../../modules/system/user-jager.nix
    ../../modules/system/gnome.nix
    ../../modules/hardware/gpu.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  networking.hostName = "avalanche";
  hardware.gpu.profile = "nvidia";
  services.ollama.acceleration = lib.mkDefault "cuda";
  # ...other options...
}
```
