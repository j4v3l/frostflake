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
  nvidiaPkg = config.boot.kernelPackages.nvidiaPackages.latest;
  nvidiaToolkitCfg = config.hardware.nvidia-container-toolkit;
  nvidiaToolkitPackage = nvidiaToolkitCfg.package or pkgs.nvidia-container-toolkit;
  nvidiaRuntimePackage = nvidiaToolkitPackage.tools or nvidiaToolkitPackage;
  intelPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    intel-compute-runtime
    libvdpau-va-gl
  ];
  vmDrivers = ["qxl" "vmware"];
  inherit (lib) mkIf mkOption types mkDefault mkMerge optional;
in {
  options.hardware.gpu.profile = mkOption {
    type = types.enum ["nvidia" "intel" "vm" "none"];
    default = "none";
    description = "GPU profile selector so hosts can switch drivers without touching module internals.";
  };

  config = mkMerge [
    (mkIf isNvidia {
      services.xserver.videoDrivers = ["nvidia"];
      hardware = {
        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          package = nvidiaPkg;
          open = mkDefault true;
          powerManagement.enable = mkDefault true;
        };
        graphics.extraPackages = with pkgs; [nvidia-vaapi-driver];
        nvidia-container-toolkit.enable = mkDefault true;
      };
      environment.systemPackages =
        [nvidiaToolkitPackage]
        ++ optional (nvidiaRuntimePackage != nvidiaToolkitPackage) nvidiaRuntimePackage;
    })

    (mkIf isIntel {
      services.xserver.videoDrivers = ["intel" "modesetting"];
      hardware = {
        graphics.extraPackages = intelPackages;
      };
    })

    (mkIf isVm {
      services.xserver.videoDrivers = vmDrivers;
    })
  ];
}
