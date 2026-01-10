{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    genAttrs
    hasPrefix
    mkAfter
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionals
    removePrefix
    types
    ;
  cfg = config.frostflake.security.webauthn;
  # OpenSSH expects the FIDO2 key algorithms in the sk-*@openssh.com form.
  hardwareAlgorithmsDefault = [
    "sk-ssh-ed25519@openssh.com"
    "sk-ecdsa-sha2-nistp256@openssh.com"
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
          default = [
            "login"
            "sudo"
            "sshd"
            "polkit-1"
            "gdm-password"
            "sddm"
            "lightdm"
            "cosmic-greeter"
          ];
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
            default = false;
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
    mappingFileEtc =
      if hasPrefix "/etc/" cfg.mappingFile
      then removePrefix "/etc/" cfg.mappingFile
      else null;
    managedMappingFile = mkIf (cfg.mappingFileSource != null) (mkMerge [
      (mkIf (mappingFileEtc != null) {
        environment.etc.${mappingFileEtc} = {
          source = cfg.mappingFileSource;
          mode = "0400";
        };
      })
      (mkIf (mappingFileEtc == null) {
        systemd.tmpfiles.rules = [
          "C ${cfg.mappingFile} 0400 root root - ${cfg.mappingFileSource}"
        ];
      })
    ]);
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
        services = {
          pcscd.enable = true;
          udev.packages =
            optionals (pkgs ? yubikey-personalization) [pkgs.yubikey-personalization]
            ++ optionals (pkgs ? libfido2) [pkgs.libfido2];
          udev.extraRules = mkAfter ''
            # Allow members of plugdev (including the primary user) to access YubiKey HID devices.
            KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0660", GROUP="plugdev", TAG+="uaccess"
          '';
        };
        environment.systemPackages = pcscPackages;

        # Ensure the opt-out group exists so pam_succeed_if rules can succeed.
        users.groups.${cfg.exemptGroup} = {};

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
        services.openssh = {
          # `settings` wraps string values in single quotes which sshd treats as part of
          # the value; use extraConfig so algorithm names stay verbatim.
          extraConfig = ''
            PubkeyAcceptedAlgorithms ${sshAlgorithmsValue}
          '';
          settings.AuthenticationMethods = cfg.ssh.authenticationMethods;
        };
      })
    ]);
}
