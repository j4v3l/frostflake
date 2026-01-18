{
  inputs,
  lib,
  pkgs,
  frostflakeRoot,
  frostflakeUser,
  ...
}: let
  mkLinuxHost = import (frostflakeRoot + "/lib/frostflake/mk-linux-host.nix") {inherit lib;};
  desktopProfile = "gnome";
in
  mkLinuxHost {
    inherit inputs frostflakeRoot frostflakeUser;
    hostName = "aurora";
    inherit desktopProfile;
    homeModule = import ../../home/jager/linux/default.nix;
    extraModules = [
      ../../modules/system/docker.nix
      ../../modules/system/vms.nix
      ../../modules/hardware/gpu.nix
      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-pc-ssd
      inputs.nixos-hardware.nixosModules.common-gpu-intel
      ./hardware-configuration.nix
      ./hibernate.nix
      ./containers.nix
      ./virtual-machines.nix
    ];
    extraConfig = {
      boot = {
        loader = {
          systemd-boot.enable = false;
          grub = {
            enable = true;
            efiSupport = true;
            device = "nodev";
            gfxmodeEfi = "2560x1440";
          };
          efi.canTouchEfiVariables = true;
        };
      };

      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
      hardware = {
        gpu.profile = "intel";
        enableRedistributableFirmware = true;
        sensor.iio.enable = true;
      };
      services = {
        tlp.enable = true;
        tlp.settings = {
          # Yubico vendor ID (FIDO keys) - keep out of USB autosuspend.
          USB_BLACKLIST = "1050:*";
        };
        power-profiles-daemon.enable = false;
        fprintd.enable = true;
        colord.enable = true;
      };

      environment.systemPackages = [
        pkgs.fprintd
      ];

      # Allow plain password auth during initial bring-up; keep WebAuthn tooling installed without PAM enforcement.
      security.pam.services = lib.mkMerge [
        {
          login.u2fAuth = lib.mkForce false;
          # Enable fingerprint auth for login, sudo, and polkit.
          login.fprintAuth = lib.mkForce true;
          sudo.fprintAuth = true;
          "polkit-1".fprintAuth = true;
        }
        (lib.mkIf (desktopProfile == "gnome") {
          "gdm-password".fprintAuth = true;
        })
        (lib.mkIf (desktopProfile == "kde") {
          sddm.u2fAuth = lib.mkForce false;
          sddm.fprintAuth = true;
          "sddm-autologin".u2fAuth = lib.mkForce false;
          "sddm-autologin".fprintAuth = lib.mkForce false;
        })
        (lib.mkIf (desktopProfile == "xfce") {
          lightdm.fprintAuth = true;
        })
        (lib.mkIf (desktopProfile == "cosmic") {
          "cosmic-greeter".fprintAuth = true;
        })
      ];

      frostflake = {
        security.webauthn = {
          enable = false;
        };
        ai = {
          enable = false;
          packages.enable = false;
          ollama.enable = false;
        };
        base.audio.pipewire = {
          sampleRate = 96000;
          allowedRates = [96000 48000];
          latency = "128/96000";
          resampleQuality = 10;
        };
        base.tooling.nh = {
          enable = true;
          flake = "/etc/nixos";
        };
      };

      # Container and VM definitions now live in ./containers.nix and ./virtual-machines.nix

      system.stateVersion = "25.11";
    };
  }
