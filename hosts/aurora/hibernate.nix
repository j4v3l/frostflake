{
  config,
  lib,
  ...
}: let
  swapDevices = config.swapDevices or [];
  firstSwap =
    if swapDevices != []
    then builtins.head swapDevices
    else null;
  swapDevice =
    if firstSwap != null && firstSwap ? device
    then toString firstSwap.device
    else null;
  resumeDevice =
    if swapDevice != null && lib.hasPrefix "/dev/" swapDevice
    then swapDevice
    else null;
in {
  config = lib.mkIf (resumeDevice != null) {
    # Auto-wire resume for swap partitions; swapfiles need a resume_offset.
    boot.resumeDevice = lib.mkDefault resumeDevice;
  };
}
