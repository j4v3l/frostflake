{lib, ...}: {
  # TODO: Replace this with the output of `nixos-generate-config` after flashing the SD card.
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  swapDevices = [];
}
