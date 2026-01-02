{...}: {
  imports = [];

  # Placeholder hardware configuration. Replace with output from
  # `nixos-generate-config --show-hardware-config` for Aurora's disks.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [];

  # Keep declarative networking/time defaults elsewhere; nothing hardware-specific here yet.
}
