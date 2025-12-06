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
    desktopProfile = "gnome";
    homeModule = import ../../home/jager/linux/default.nix;
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
      services.ollama.acceleration = lib.mkDefault "cuda";

      system.stateVersion = "25.11";

      # Container and VM definitions now live in ./containers.nix and ./virtual-machines.nix
    };
  }
