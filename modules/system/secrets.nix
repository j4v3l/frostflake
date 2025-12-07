{
  config,
  lib,
  frostflakeRoot,
  ...
}: let
  inherit
    (lib)
    hasInfix
    literalExpression
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;
  cfg = config.frostflake.secrets;
  secretsDir = frostflakeRoot + "/secrets";
  secretsDirString = toString secretsDir;
  defaultHostFile = "${secretsDirString}/hosts/${config.networking.hostName}.yaml";
  pamTargetPath =
    if cfg.pamU2F.targetPath != null
    then cfg.pamU2F.targetPath
    else config.frostflake.security.webauthn.mappingFile;
  hasExtraSecrets = cfg.extraSecrets != {};
  hostSecretAvailable = builtins.pathExists cfg.hostFile;
  pamSecretAvailable = builtins.pathExists cfg.sharedFile;
  hostSecretReady = hostSecretAvailable && hasInfix "sops:" (builtins.readFile cfg.hostFile);
  pamSecretReady = pamSecretAvailable && hasInfix "sops:" (builtins.readFile cfg.sharedFile);
in {
  options.frostflake.secrets = {
    enable = mkEnableOption "SOPS-Nix managed secrets" // {default = true;};

    hostFile = mkOption {
      type = types.str;
      default = defaultHostFile;
      description = "Default SOPS file that stores host-specific secrets.";
    };

    sharedFile = mkOption {
      type = types.str;
      default = "${secretsDirString}/shared.yaml";
      description = "Shared SOPS file for secrets consumed by multiple hosts.";
    };

    ageKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Location on the target host where the Age private key lives.";
    };

    pamU2F = {
      enable = mkEnableOption "Provision the pam_u2f mapping via SOPS" // {default = true;};
      key = mkOption {
        type = types.str;
        default = "pam_u2f_mappings";
        description = "YAML key name that stores the pam_u2f mapping blob.";
      };
      targetPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override path for the pam_u2f mapping file (defaults to frostflake.security.webauthn.mappingFile).";
      };
    };

    extraSecrets = mkOption {
      type = types.attrsOf types.attrs;
      default = {};
      example = literalExpression ''
        {
          "docker_config" = {
            sopsFile = frostflakeRoot + "/secrets/hosts/${config.networking.hostName}.yaml";
            key = "docker_config";
            path = "/var/lib/docker/config.json";
            mode = "0400";
          };
        }
      '';
      description = "Additional attrsets merged into sops.secrets for host-specific needs.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.age.keyFile = cfg.ageKeyFile;
    }

    (mkIf hostSecretReady {
      sops.defaultSopsFile = builtins.path {path = cfg.hostFile;};
    })

    (mkIf (cfg.pamU2F.enable && pamSecretReady) {
      sops.secrets = {
        pam_u2f_mappings = {
          sopsFile = builtins.path {path = cfg.sharedFile;};
          inherit (cfg.pamU2F) key;
          path = pamTargetPath;
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };
    })

    (mkIf hasExtraSecrets {
      sops.secrets = cfg.extraSecrets;
    })
    {
      warnings =
        optional (cfg.pamU2F.enable && !pamSecretAvailable) ''
          frostflake.secrets.pamU2F is enabled but ${cfg.sharedFile} does not exist yet.
          Run `make secret-edit FILE=shared.yaml` to create and encrypt the mapping file before deployment.
        ''
        ++ optional (cfg.pamU2F.enable && pamSecretAvailable && !pamSecretReady) ''
          frostflake.secrets.pamU2F detected ${cfg.sharedFile}, but it is still plaintext.
          Encrypt it with `sops` (see docs/secrets.md) so the mapping stays secret at rest.
        ''
        ++ optional (hostSecretAvailable && !hostSecretReady) ''
          ${cfg.hostFile} exists but is not encrypted yet. Run `make secret-host HOST=${config.networking.hostName}` to convert it with sops.
        '';
    }
  ]);
}
