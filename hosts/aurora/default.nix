{
  inputs,
  lib,
  ...
}: {
  imports = [
    ../../modules/system/linux-base.nix
    ../../modules/system/user-jager.nix
    ../../modules/system/gnome.nix
    ../../modules/system/docker.nix
    ../../modules/system/vms.nix
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

  services.vmManager = {
    enable = true;
    virtualMachines = {
      # Sample lightweight NixOS VM for on-the-road testing.
      nixos-dev = {
        enable = false; # toggle to true after seeding the disk image below
        description = "Ephemeral lab VM for cross-checking flakes";
        memoryMiB = 4096;
        vcpus = 4;
        disks = [
          {
            path = "/var/lib/libvirt/images/nixos-dev.qcow2";
            format = "qcow2";
            # Create with: `sudo qemu-img create -f qcow2 /var/lib/libvirt/images/nixos-dev.qcow2 40G`
            # 40G is plenty for quick NixOS builds; bump it if you plan to cache derivations inside.
            bootOrder = 1;
          }
          {
            path = "/var/lib/libvirt/iso/nixos-25.11.iso";
            device = "cdrom";
            format = "raw";
            # Copy the installer ISO into /var/lib/libvirt/iso before enabling this VM definition.
            bootOrder = 2;
          }
        ];
        networks = [
          {
            source = "default";
            model = "virtio"; # change to e1000 if a legacy OS is installed
          }
        ];
        spice.enable = true; # keep SPICE graphics for laptop-friendly remote console
      };
    };
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
