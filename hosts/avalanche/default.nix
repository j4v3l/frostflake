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
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "avalanche";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.nvidia-container-toolkit.enable = true;
  hardware.gpu.profile = "nvidia";
  services.ollama.acceleration = lib.mkDefault "cuda";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/linux/default.nix;
  };

  system.stateVersion = "25.11";

  services.vmManager = {
    enable = true;
    virtualMachines = {
      # Example Windows VM: flip `enable = true;` once the disk paths exist.
      win11-dev = {
        enable = false;
        description = "Windows 11 sandbox for CUDA tooling tests";
        memoryMiB = 12288;
        vcpus = 8;
        autostart = false; # keep manual control; use `virsh autostart win11-dev` if desired
        disks = [
          {
            path = "/var/lib/libvirt/images/win11.qcow2";
            format = "qcow2";
            # Create with: `sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 150G`
            # 150G leaves headroom for Visual Studio + CUDA SDKs; adjust if you need less.
            bootOrder = 1;
          }
          {
            path = "/var/lib/libvirt/iso/Win11_24H2.iso";
            device = "cdrom";
            format = "raw";
            # Drop the ISO under /var/lib/libvirt/iso (usually a bind mount to your downloads).
            bootOrder = 2; # drop this entry once the install finishes
          }
        ];
        networks = [
          {
            source = "default"; # attaches to libvirt NAT; swap to a bridge if you need LAN access
          }
        ];
      };
    };
  };

  virtualisation.oci-containers.containers.gpu-hot = {
    autoStart = true;
    image = "ghcr.io/psalias2006/gpu-hot:latest";
    ports = ["1312:1312"];
    environment = {
      NODE_NAME = "Avalanche";
    };
    extraOptions = [
      "--gpus=all"
      "--init"
      "--pid=host"
    ];
  };
}
