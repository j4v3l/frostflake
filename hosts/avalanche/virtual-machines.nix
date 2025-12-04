_: {
  services.vmManager = {
    enable = true;
    virtualMachines = {
      # Example Windows VM: flip `enable = true;` once the disk paths exist.
      win11-dev = {
        enable = false;
        description = "Windows 11 sandbox for CUDA tooling tests";
        memoryMiB = 12288;
        vcpus = 8;
        autostart = false;
        disks = [
          {
            path = "/var/lib/libvirt/images/win11.qcow2";
            format = "qcow2";
            bootOrder = 1;
            # Create with: `sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 150G`
            # 150G leaves headroom for Visual Studio + CUDA SDKs; adjust if you need less.
          }
          {
            path = "/var/lib/libvirt/iso/Win11_24H2.iso";
            device = "cdrom";
            format = "raw";
            bootOrder = 2;
            # Drop the ISO under /var/lib/libvirt/iso (usually a bind mount to your downloads).
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
}
