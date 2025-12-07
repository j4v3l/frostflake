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
    hostName = "iceberg";
    desktopProfile = "xfce";
    homeModule = import ../../home/jager/linux/default.nix;
    extraModules = [
      ../../modules/system/docker.nix
      ../../modules/hardware/gpu.nix
    ];
    extraConfig = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      fileSystems."/" = lib.mkDefault {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      }; # adjust device for Iceberg VM

      hardware.gpu.profile = "vm";
      services = {
        qemuGuest.enable = true;
        spice-vdagentd.enable = true;
      };

      frostflake.ai.ollama.acceleration = lib.mkDefault false;

      system.stateVersion = "25.11";
    };
  }
