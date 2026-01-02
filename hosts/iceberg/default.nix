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
      ./hardware-configuration.nix
    ];
    extraConfig = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      hardware.gpu.profile = "vm";
      services = {
        qemuGuest.enable = true;
        spice-vdagentd.enable = true;
      };

      frostflake.ai = {
        enable = false;
        packages.enable = false;
        ollama.enable = false;
      };

      frostflake.base.tooling.nh = {
        enable = true;
        flake = "/etc/nixos";
      };

      system.stateVersion = "25.11";
    };
  }
