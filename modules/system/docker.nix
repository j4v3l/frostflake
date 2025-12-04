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
  dockerPackages = with pkgs; [docker docker-compose lazydocker];
  usersCfg = config.users.users;
  defaultUsers = builtins.attrNames (filterAttrs (_: user: user.isNormalUser or false) usersCfg);
  targetUsers =
    if cfg.extraUsers == []
    then defaultUsers
    else cfg.extraUsers;
in {
  options.services.dockerManager = {
    enable = mkEnableOption "opinionated Docker setup";

    rootless = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Docker rootless mode when supported.";
    };

    extraUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional usernames to add to the docker group. Defaults to all normal users.";
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

    users.groups.docker.members = mkAfter targetUsers;

    systemd.services.docker.after = ["network-online.target"];
    systemd.services.docker.wants = ["network-online.target"];
  };
}
