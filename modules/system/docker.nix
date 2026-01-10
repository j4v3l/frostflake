{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.dockerManager;
  nvidiaToolkit = config.hardware.nvidia-container-toolkit;
  nvidiaToolkitPackage = nvidiaToolkit.package or pkgs.nvidia-container-toolkit;
  nvidiaRuntimePackage = nvidiaToolkitPackage.tools or nvidiaToolkitPackage;
  dockerPackages = with pkgs; [
    docker
    docker-compose
    lazydocker
  ];
  usersCfg = config.users.users;
  defaultUsers = builtins.attrNames (filterAttrs (_: user: user.isNormalUser or false) usersCfg);
  targetUsers =
    if cfg.autoAddNormalUsers
    then defaultUsers ++ cfg.extraUsers
    else cfg.extraUsers;
in {
  options.services.dockerManager = {
    enable = mkEnableOption "opinionated Docker setup";

    autoAddNormalUsers = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically add all normal users to the docker group.";
    };

    rootless = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Docker rootless mode when supported.";
    };

    extraUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional usernames to add to the docker group.";
    };

    daemonSettings = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      example = literalExpression "{ data-root = \"/var/lib/docker\"; }";
      description = "Extra JSON settings merged into /etc/docker/daemon.json.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = dockerPackages;
      example = literalExpression "with pkgs; [ docker docker-compose swayimg ]";
      description = "Packages installed alongside Docker for host-side tooling.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        enableOnBoot = true;
        rootless = mkIf cfg.rootless {
          enable = true;
          setSocketVariable = true;
        };
        daemon.settings = mkMerge [
          (mkIf nvidiaToolkit.enable {
            "default-runtime" = mkDefault "nvidia";
            runtimes.nvidia.path = lib.getExe' nvidiaRuntimePackage "nvidia-container-runtime";
          })
          cfg.daemonSettings
        ];
      };
      "oci-containers".backend = mkDefault "docker";
    };

    environment.systemPackages = cfg.packages;

    # Ensure NVIDIA toolkit binaries (e.g., nvidia-ctk) are available at predictable paths
    # for docker/nvidia-container-runtime hooks.
    environment.etc."usr/bin/nvidia-ctk" = mkIf nvidiaToolkit.enable {
      source = lib.getExe nvidiaToolkitPackage;
    };

    systemd.services.docker = {
      environment = mkIf nvidiaToolkit.enable {
        NVIDIA_CTK_PATH = lib.getExe nvidiaToolkitPackage;
      };
      after = ["network-online.target"];
      wants = ["network-online.target"];
    };

    users.groups.docker.members = mkAfter targetUsers;
  };
}
