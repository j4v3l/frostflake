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
    hostName = "aurora";
    desktopProfile = "deepin";
    homeModule = import ../../home/jager/linux/default.nix;
    extraModules = [
      ../../modules/system/docker.nix
      ../../modules/system/vms.nix
      ../../modules/hardware/gpu.nix
      ./containers.nix
      ./virtual-machines.nix
    ];
    extraConfig = {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      fileSystems."/" = lib.mkDefault {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      }; # adjust device for Aurora

      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
      hardware.gpu.profile = "intel";
      services = {
        ollama.acceleration = lib.mkDefault false;
        tlp.enable = true;
        power-profiles-daemon.enable = false;
        fprintd.enable = true;
      };

      # Container and VM definitions now live in ./containers.nix and ./virtual-machines.nix

      security.pam = {
        services = {
          sudo.fprintAuth = true;
          login.fprintAuth = lib.mkForce true;
          "gdm-password".fprintAuth = true;
        };
      };

      system.stateVersion = "25.11";
    };
  }
