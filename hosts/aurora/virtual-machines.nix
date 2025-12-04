_: {
  services.vmManager = {
    enable = true;
    virtualMachines = {
      # Sample lightweight NixOS VM for on-the-road testing.
      nixos-dev = {
        enable = false;
        description = "Ephemeral lab VM for cross-checking flakes";
        memoryMiB = 4096;
        vcpus = 4;
        disks = [
          {
            path = "/var/lib/libvirt/images/nixos-dev.qcow2";
            format = "qcow2";
            bootOrder = 1;
            # Create with: `sudo qemu-img create -f qcow2 /var/lib/libvirt/images/nixos-dev.qcow2 40G`
            # 40G is plenty for quick NixOS builds; bump it if you plan to cache derivations inside.
          }
          {
            path = "/var/lib/libvirt/iso/nixos-25.11.iso";
            device = "cdrom";
            format = "raw";
            bootOrder = 2;
            # Copy the installer ISO into /var/lib/libvirt/iso before enabling this VM definition.
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
}
