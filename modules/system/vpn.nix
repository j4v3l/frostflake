{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalString
    types
    ;

  cfg = config.frostflake.vpn;
  secretsCfg = config.frostflake.secrets;
  hostSops = secretsCfg.hostFile;
  nordvpnPackage = pkgs.nordvpn or null;

  mkSecret = {
    name,
    sopsFile ? hostSops,
    key,
    path,
    owner ? "root",
    group ? "root",
    mode ? "0400",
  }: {
    ${name} = {
      sopsFile = builtins.path {path = sopsFile;};
      inherit
        key
        path
        owner
        group
        mode
        ;
    };
  };
in {
  options.frostflake.vpn = {
    enable =
      mkEnableOption "Frostflake VPN module (tailscale, wireguard, nordvpn)"
      // {
        default = true;
      };

    tailscale = {
      enable = mkEnableOption "Enable tailscale service";
      authKeySopsFile = mkOption {
        type = types.str;
        default = hostSops;
        description = "SOPS file that stores the tailscale auth key.";
      };
      authKeyKey = mkOption {
        type = types.str;
        default = "tailscale_authkey";
        description = "YAML key in the SOPS file with the tailscale auth key.";
      };
      authKeyPath = mkOption {
        type = types.str;
        default = "/run/secrets/tailscale/authkey";
        description = "Path for the rendered auth key.";
      };
      useRoutingFeatures = mkOption {
        type = types.nullOr (
          types.enum [
            "client"
            "server"
          ]
        );
        default = null;
        description = "Expose Tailscale subnet/exit-node routing features.";
      };
      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra flags passed to tailscaled.";
      };
    };

    nordvpn = {
      enable = mkEnableOption "Enable nordvpn service with token-based login";
      tokenSopsFile = mkOption {
        type = types.str;
        default = hostSops;
        description = "SOPS file containing the NordVPN token.";
      };
      tokenKey = mkOption {
        type = types.str;
        default = "nordvpn_token";
        description = "YAML key in the SOPS file with the NordVPN login token.";
      };
      tokenPath = mkOption {
        type = types.str;
        default = "/run/secrets/nordvpn/token";
        description = "Path where the NordVPN token will be rendered.";
      };
      autoconnect = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If set, auto-connect to this country/city/group (e.g., \"us\" or \"United States\").";
      };
      technology = mkOption {
        type = types.enum [
          "nordlynx"
          "openvpn"
        ];
        default = "nordlynx";
        description = "Transport to use for NordVPN.";
      };
      killSwitch = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NordVPN killswitch after login.";
      };
      package = mkOption {
        type = types.nullOr types.package;
        default = nordvpnPackage;
        description = "NordVPN package; set null on platforms where nordvpn is unavailable.";
      };
    };

    wireguard = {
      enable = mkEnableOption "Enable wg-quick interface";
      interfaceName = mkOption {
        type = types.str;
        default = "wg0";
        description = "WireGuard interface name.";
      };
      addresses = mkOption {
        type = types.listOf types.str;
        default = ["10.7.0.2/32"];
        description = "Local interface addresses.";
      };
      listenPort = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Optional UDP listen port.";
      };
      privateKeySopsFile = mkOption {
        type = types.str;
        default = hostSops;
        description = "SOPS file holding the WireGuard private key.";
      };
      privateKeyKey = mkOption {
        type = types.str;
        default = "wireguard_private_key";
        description = "YAML key name for the WireGuard private key.";
      };
      privateKeyPath = mkOption {
        type = types.str;
        default = "/run/secrets/wireguard/privatekey";
        description = "Path for the rendered WireGuard private key.";
      };
      peers = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              publicKey = mkOption {
                type = types.str;
                description = "Peer public key.";
              };
              allowedIPs = mkOption {
                type = types.listOf types.str;
                description = "Allowed IPs for the peer.";
              };
              endpoint = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Peer endpoint (host:port).";
              };
              persistentKeepalive = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Persistent keepalive in seconds.";
              };
            };
          }
        );
        default = [];
        description = "Peer definitions for WireGuard.";
        example = literalExpression ''
          [
            {
              publicKey = "BASE64PUBKEY";
              allowedIPs = ["10.7.0.1/32"];
              endpoint = "vpn.example.com:51820";
              persistentKeepalive = 25;
            }
          ]
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Secrets rendered via SOPS
    {
      frostflake.secrets.extraSecrets = mkMerge [
        (mkIf cfg.tailscale.enable (mkSecret {
          name = "tailscale_authkey";
          sopsFile = cfg.tailscale.authKeySopsFile;
          key = cfg.tailscale.authKeyKey;
          path = cfg.tailscale.authKeyPath;
        }))

        (mkIf cfg.nordvpn.enable (mkSecret {
          name = "nordvpn_token";
          sopsFile = cfg.nordvpn.tokenSopsFile;
          key = cfg.nordvpn.tokenKey;
          path = cfg.nordvpn.tokenPath;
        }))

        (mkIf cfg.wireguard.enable (mkSecret {
          name = "wireguard_private_key";
          sopsFile = cfg.wireguard.privateKeySopsFile;
          key = cfg.wireguard.privateKeyKey;
          path = cfg.wireguard.privateKeyPath;
        }))
      ];
    }

    # Services and networking
    (mkIf cfg.tailscale.enable {
      services.tailscale = {
        enable = true;
        inherit (cfg.tailscale) useRoutingFeatures;
        authKeyFile = cfg.tailscale.authKeyPath;
        extraSetFlags = cfg.tailscale.extraFlags;
        package = pkgs.tailscale;
      };
      environment.systemPackages = [pkgs.tailscale];
    })

    (mkIf (cfg.nordvpn.enable && cfg.nordvpn.package != null) {
      systemd.services.nordvpnd = {
        description = "NordVPN daemon";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${cfg.nordvpn.package}/bin/nordvpnd";
          Restart = "on-failure";
          RestartSec = 5;
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW";
          NoNewPrivileges = true;
        };
        wantedBy = ["multi-user.target"];
      };

      # Perform token-based login and optional autoconnect on boot
      systemd.services.nordvpn-login = {
        description = "NordVPN login via SOPS token";
        after = [
          "network-online.target"
          "nordvpnd.service"
        ];
        wants = [
          "network-online.target"
          "nordvpnd.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          Environment = "PATH=${
            lib.makeBinPath [
              cfg.nordvpn.package
              pkgs.coreutils
              pkgs.gnused
              pkgs.gnugrep
            ]
          }";
          ExecStart = pkgs.writeShellScript "nordvpn-login" ''
            set -euo pipefail
            token_file="${cfg.nordvpn.tokenPath}"
            if [ ! -s "$token_file" ]; then
              echo "nordvpn-login: missing token at $token_file" >&2
              exit 1
            fi

            token="$(cat "$token_file")"
            if ! nordvpn account >/dev/null 2>&1; then
              nordvpn login --token "$token"
            fi

            nordvpn set technology ${cfg.nordvpn.technology}
            ${optionalString cfg.nordvpn.killSwitch "nordvpn set killswitch on"}
            ${optionalString (cfg.nordvpn.autoconnect != null) ''nordvpn connect "${cfg.nordvpn.autoconnect}"''}
          '';
        };
        wantedBy = ["multi-user.target"];
      };

      environment.systemPackages = [cfg.nordvpn.package];
    })

    (mkIf cfg.wireguard.enable {
      networking.wg-quick.interfaces.${cfg.wireguard.interfaceName} = {
        address = cfg.wireguard.addresses;
        privateKeyFile = cfg.wireguard.privateKeyPath;
        inherit (cfg.wireguard) listenPort;
        peers =
          map (
            peer:
              {
                inherit (peer) publicKey allowedIPs;
              }
              // (mkIf (peer.endpoint != null) {inherit (peer) endpoint;})
              // (mkIf (peer.persistentKeepalive != null) {inherit (peer) persistentKeepalive;})
          )
          cfg.wireguard.peers;
      };

      networking.firewall.allowedUDPPorts =
        optional (
          cfg.wireguard.listenPort != null
        )
        cfg.wireguard.listenPort;

      environment.systemPackages = [pkgs.wireguard-tools];
    })

    # Helper warnings when secrets are missing
    {
      warnings =
        optional (cfg.tailscale.enable && !(builtins.pathExists cfg.tailscale.authKeySopsFile)) ''
          frostflake.vpn.tailscale.enable is true, but ${cfg.tailscale.authKeySopsFile} was not found. Add it with `make secret-host HOST=${config.networking.hostName}` then add key ${cfg.tailscale.authKeyKey}.
        ''
        ++ optional (cfg.nordvpn.enable && !(builtins.pathExists cfg.nordvpn.tokenSopsFile)) ''
          frostflake.vpn.nordvpn.enable is true, but ${cfg.nordvpn.tokenSopsFile} was not found. Add it and set key ${cfg.nordvpn.tokenKey}.
        ''
        ++ optional (cfg.nordvpn.enable && cfg.nordvpn.package == null) ''
          frostflake.vpn.nordvpn.enable is true, but no nordvpn package is available for platform ${pkgs.stdenv.hostPlatform.system}. Set frostflake.vpn.nordvpn.package to a valid package or disable nordvpn.
        ''
        ++ optional (cfg.wireguard.enable && !(builtins.pathExists cfg.wireguard.privateKeySopsFile)) ''
          frostflake.vpn.wireguard.enable is true, but ${cfg.wireguard.privateKeySopsFile} was not found. Add it and set key ${cfg.wireguard.privateKeyKey}.
        '';
    }
  ]);
}
