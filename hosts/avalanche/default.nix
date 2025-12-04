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
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "avalanche";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.gpu.profile = "nvidia";
  services.ollama.acceleration = lib.mkDefault "cuda";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/linux/default.nix;
  };

  system.stateVersion = "25.11";
}
