{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    genAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionals
    types
    ;
  cfg = config.frostflake.security.webauthn;
  hardwareAlgorithmsDefault = [
    "sk-ssh-ed25519@openssh.com"
    "sk-ssh-ecdsa-sha2-nistp256@openssh.com"
  ];
in {
  options.frostflake.security.webauthn = mkOption {
    type = types.submodule (_: {
      options = {
        enable = mkEnableOption "Global WebAuthn / YubiKey policy" // {default = true;};

        mappingFile = mkOption {
          type = types.str;
          default = "/etc/security/u2f-mappings";
          example = "/run/secrets/u2f-mappings";
          description = "Absolute path to the pam_u2f mapping file.";
        };

        mappingFileSource = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = ./secrets/u2f-mappings;
          description = "Optional source for the mapping file (useful when injecting secrets via flakes).";
        };

        pamServices = mkOption {
          type = types.listOf types.str;
          default = ["login" "sudo" "sshd" "polkit-1"];
          description = "PAM stacks that must require pam_u2f.";
        };

        enforcePam = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to add pam_u2f to the configured PAM services.";
        };

        allowUserOptOut = mkOption {
          type = types.bool;
          default = true;
          description = "If true, users in the exempt group skip pam_u2f checks.";
        };

        exemptGroup = mkOption {
          type = types.str;
          default = "frostflake-webauthn-exempt";
          description = "Group name used to bypass FIDO2 enforcement.";
        };

        ssh = {
          hardwareOnly = mkOption {
            type = types.bool;
            default = true;
            description = "Restrict sshd to hardware-backed public keys.";
          };

          allowedAlgorithms = mkOption {
            type = types.listOf types.str;
            default = hardwareAlgorithmsDefault;
            description = "Algorithms accepted when hardwareOnly is enabled.";
          };

          authenticationMethods = mkOption {
            type = types.str;
            default = "publickey";
            description = "Value for sshd_config AuthenticationMethods when hardwareOnly is enabled.";
          };
        };
      };
    });
    default = {};
    description = "Global WebAuthn / YubiKey policy applied across Frostflake systems.";
  };
  config = mkIf cfg.enable (let
    pamServicesConfig = mkIf cfg.enforcePam {
      security.pam.services = genAttrs cfg.pamServices (_: {
        u2fAuth = true;
        rules.auth = mkIf cfg.allowUserOptOut {
          "frostflake-webauthn-exempt" = {
            enable = true;
            order = 5000;
            control = "[success=done default=ignore]";
            modulePath = "${pkgs.pam}/lib/security/pam_succeed_if.so";
            args = ["user" "ingroup" cfg.exemptGroup];
          };
        };
      });
    };
    managedMappingFile = mkIf (cfg.mappingFileSource != null) {
      environment.etc."security/u2f-mappings" = {
        source = cfg.mappingFileSource;
        mode = "0400";
      };
    };
    sshAlgorithmsValue = lib.concatStringsSep "," cfg.ssh.allowedAlgorithms;
    pcscPackages = [
      pkgs.libfido2
      pkgs.opensc
      pkgs.yubico-pam
      pkgs.yubikey-manager
      pkgs.yubikey-personalization
    ];
  in
    mkMerge [
      {
        services.pcscd.enable = true;
        services.udev.packages = optionals (pkgs ? yubikey-personalization) [pkgs.yubikey-personalization];
        environment.systemPackages = pcscPackages;

        security.pam.u2f = {
          enable = true;
          control = "required";
          settings = {
            authfile = cfg.mappingFile;
            cue = true;
            interactive = true;
          };
        };
      }

      managedMappingFile

      pamServicesConfig

      (mkIf cfg.ssh.hardwareOnly {
        services.openssh.settings = {
          # Restrict user public keys to hardware-backed algorithms only.
          PubkeyAcceptedAlgorithms = sshAlgorithmsValue;
          AuthenticationMethods = cfg.ssh.authenticationMethods;
        };
      })
    ]);
}
