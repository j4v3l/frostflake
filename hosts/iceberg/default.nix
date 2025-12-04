{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../../modules/system/linux-base.nix
    ../../modules/system/user-jager.nix
    ../../modules/system/gnome.nix
    ../../modules/hardware/gpu.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "iceberg";

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
    ollama.acceleration = lib.mkDefault false;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/linux/default.nix;
  };

  system.stateVersion = "25.11";
}
