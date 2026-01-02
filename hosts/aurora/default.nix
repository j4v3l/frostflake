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
    desktopProfile = "kde";
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

      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
      hardware.gpu.profile = "intel";
      services = {
        tlp.enable = true;
        power-profiles-daemon.enable = false;
        fprintd.enable = true;
      };

      # Allow plain password auth during initial bring-up; disable WebAuthn/PAM U2F on this host.
      security.pam.services = {
        login.u2fAuth = lib.mkForce false;
        sddm.u2fAuth = lib.mkForce false;
        "sddm-autologin".u2fAuth = lib.mkForce false;
        # Enable fingerprint auth for login, sudo, and SDDM.
        login.fprintAuth = true;
        sudo.fprintAuth = true;
        sddm.fprintAuth = true;
        "sddm-autologin".fprintAuth = lib.mkForce false;
      };

      frostflake = {
        security.webauthn.enable = false;
        ai = {
          enable = false;
          packages.enable = false;
          ollama.enable = false;
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
