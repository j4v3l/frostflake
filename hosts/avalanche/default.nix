{
  inputs,
  lib,
  pkgs,
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
      # Force cgroup v1 for NVIDIA Docker compatibility and nest all boot options
      boot = {
        kernelParams = [
          "systemd.unified_cgroup_hierarchy=0"
          "usbcore.autosuspend=-1"
        ];
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };
      # Enable Docker and NVIDIA runtime support
      hardware.nvidia-container-toolkit.enable = true;
      hardware.gpu.profile = "nvidia";
      frostflake = {
        ai = {
          enable = true;
          packages.enable = true;
          ollama = {
            enable = lib.mkDefault true;
            acceleration = lib.mkDefault "cuda";
          };
        };

        base.tooling.nh = {
          enable = true;
          flake = "/etc/nixos";
          clean.extraArgs = "--keep-since 7d --keep 7";
        };

        security.webauthn.allowUserOptOut = false;
      };

      system.stateVersion = "25.11";

      home-manager.backupFileExtension = "hm-bak";

      services = {
        displayManager.autoLogin.enable = false;
        colord.enable = true;
        udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
        '';
        # Ensure Docker/NVIDIA runtime config is merged
        dockerManager.enable = true;
      };

      # Container and VM definitions now live in ./containers.nix and ./virtual-machines.nix

      users = {
        groups.plugdev.members = ["jager"];
        users.jager.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCsQ4NNDuuAj/NLrC9yXVoGRNU5DRTEqC2ybN+Y9Qjf jager@Javels-MacBook-Pro.local"
        ];
      };

      environment.systemPackages = [
        pkgs.nvidia-container-toolkit
      ];
    };
  }
