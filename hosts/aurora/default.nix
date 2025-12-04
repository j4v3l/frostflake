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

  networking.hostName = "aurora";

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

  security.pam = {
    services = {
      sudo.fprintAuth = true;
      login.fprintAuth = lib.mkForce true;
      "gdm-password".fprintAuth = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/linux/default.nix;
  };

  system.stateVersion = "25.11";
}
