{
  inputs,
  lib,
  frostflakeRoot,
  frostflakeUser,
  ...
}: let
  mkLinuxHost = import (frostflakeRoot + "/lib/frostflake/mk-linux-host.nix") {inherit lib;};
in
  mkLinuxHost {
    inherit inputs frostflakeRoot frostflakeUser;
    hostName = "avalanche";
    desktopProfile = "hyprland";
    homeModule = import ../../home/jager/linux/hyprland.nix;
    extraModules = [
      ../../modules/system/docker.nix
      ../../modules/system/vms.nix
      ../../modules/hardware/gpu.nix
      ./hardware-configuration.nix
      ./containers.nix
      ./virtual-machines.nix
    ];
    extraConfig = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.nvidia-container-toolkit.enable = true;
      hardware.gpu.profile = "nvidia";
      frostflake.ai = {
        enable = true;
        packages.enable = true;
        ollama = {
          enable = lib.mkDefault true;
          acceleration = lib.mkDefault "cuda";
        };
      };

      system.stateVersion = "25.11";

      home-manager.backupFileExtension = "hm-bak";

      # Container and VM definitions now live in ./containers.nix and ./virtual-machines.nix
    };
  }
