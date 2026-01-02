{...}: {
  imports = [];

  # Placeholder hardware configuration for the Iceberg VM. Update if the VM
  # disk layout changes.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [];
}
