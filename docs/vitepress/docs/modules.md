
---
title: Modules Reference
description: Documentation for all reusable modules in the Frostflake project.
lastUpdated: true
---

# Modules Reference

Frostflake uses reusable modules for hardware, system, and user configuration.

## Example: GPU Module

```nix
# modules/hardware/gpu.nix
{
  options.hardware.gpu.profile = mkOption {
    type = types.enum ["nvidia" "intel" "vm" "none"];
    default = "none";
    description = "GPU profile selector so hosts can switch drivers without touching module internals.";
  };

  config = mkMerge [
    (mkIf isNvidia {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        package = nvidiaPkg;
        open = false;
        powerManagement.enable = mkDefault true;
      };
      hardware.graphics.extraPackages = with pkgs; [nvidia-vaapi-driver];
    })
    # ...other profiles...
  ];
}
```

## Other Modules

- `modules/system/linux-base.nix`: Base system settings for Linux hosts.
- `modules/system/gnome.nix`: GNOME desktop configuration.
- `modules/system/user-jager.nix`: User account and sudo settings.
