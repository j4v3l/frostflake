{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.hardware.gpu;
  isNvidia = cfg.profile == "nvidia";
  isIntel = cfg.profile == "intel";
  isVm = cfg.profile == "vm";
  isNone = cfg.profile == "none";
  nvidiaPkg = config.boot.kernelPackages.nvidiaPackages.latest;
  intelPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    intel-compute-runtime
    libvdpau-va-gl
  ];
  vmDrivers = ["qxl" "vmware"];
  inherit (lib) mkIf mkOption types mkDefault mkMerge;
in {
  options.hardware.gpu.profile = mkOption {
    type = types.enum ["nvidia" "intel" "vm" "none"];
    default = "none";
    description = "GPU profile selector so hosts can switch drivers without touching module internals.";
  };

  config = mkMerge [
    (mkIf isNvidia {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        nvidiaSettings = true;
        package = nvidiaPkg;
        open = mkDefault true;
        powerManagement.enable = mkDefault true;
      };
      hardware.graphics.extraPackages = with pkgs; [nvidia-vaapi-driver];
    })

    (mkIf isIntel {
      services.xserver.videoDrivers = ["intel" "modesetting"];
      hardware.graphics.extraPackages = intelPackages;
    })

    (mkIf isVm {
      services.xserver.videoDrivers = vmDrivers;
    })

    (mkIf (!isNone) {
      hardware.graphics.extraPackages32 = config.hardware.graphics.extraPackages or [];
    })
  ];
}
