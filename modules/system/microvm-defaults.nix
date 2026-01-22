{lib, ...}:
with lib; {
  config.microvm.host.enable = mkDefault false;
}
