{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../../modules/system/linux-base.nix
    ../../modules/system/user-jager.nix
    ../../modules/system/docker.nix
    ../../modules/hardware/gpu.nix
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "hailstone";

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

  services.ollama.acceleration = lib.mkDefault false;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/linux/default.nix;
  };

  system.stateVersion = "25.11";
}
