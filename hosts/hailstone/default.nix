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
    hostName = "hailstone";
    desktopEnable = false;
    homeModule = import ../../home/jager/linux/default.nix;
    extraModules = [
      ../../modules/system/docker.nix
      ../../modules/hardware/gpu.nix
      ./hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ];
    extraConfig = {
      # Raspberry Pi boots via firmware on the SD card, so GRUB/systemd-boot should stay disabled.
      boot = {
        loader = {
          systemd-boot.enable = lib.mkForce false;
          efi.canTouchEfiVariables = lib.mkForce false;
          generic-extlinux-compatible.enable = true;
        };
      };

      hardware = {
        gpu.profile = "none";
        enableRedistributableFirmware = true;
      };

      frostflake.ai = {
        enable = false;
        packages.enable = false;
        ollama.enable = false;
      };

      system.stateVersion = "25.11";
    };
  }
