{
  config,
  frostflakeRoot,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    optionalAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkDefault
    types
    optionals
    ;
  frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};
  cfg = config.frostflake.base;
  defaultCliPackages = frostflakePackages.system.cli;
  defaultDesktopPackages = frostflakePackages.system.desktop;
  defaultPipewire = {
    sampleRate = 48000;
    allowedRates = [
      48000
      96000
    ];
    latency = "64/48000";
    resampleQuality = 10;
  };
  mkPipewireConfig = settings: {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig = {
      pipewire."context.properties" = {
        default = {
          clock = {
            rate = settings.sampleRate;
            allowed-rates = settings.allowedRates;
            quantum = 256;
            min-quantum = 32;
            max-quantum = 2048;
          };
        };
        resample.quality = settings.resampleQuality;
      };
      "pipewire-pulse"."context.properties"."resample.quality" = settings.resampleQuality;
      "pipewire-pulse"."stream.properties" = {
        "node.latency" = settings.latency;
        "resample.quality" = settings.resampleQuality;
      };
    };
  };
in {
  options.frostflake.base = {
    enable =
      mkEnableOption "Frostflake base profile"
      // {
        default = true;
      };

    audio = {
      enable =
        mkEnableOption "PipeWire + rtkit tuning"
        // {
          default = true;
        };
      pipewire = {
        sampleRate = mkOption {
          type = types.int;
          default = defaultPipewire.sampleRate;
        };
        allowedRates = mkOption {
          type = types.listOf types.int;
          default = defaultPipewire.allowedRates;
        };
        latency = mkOption {
          type = types.str;
          default = defaultPipewire.latency;
        };
        resampleQuality = mkOption {
          type = types.int;
          default = defaultPipewire.resampleQuality;
        };
      };
    };

    peripherals = {
      enable =
        mkEnableOption "Common udev rules (PD400X + MCU serial)"
        // {
          default = true;
        };
      extraRules = mkOption {
        type = types.lines;
        default = ''
          ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="352f", ATTRS{idProduct}=="0100", ATTRS{product}=="PD400X Podcast Microphone", SYMLINK+="snd/by-id/PD400X"
          KERNEL=="ttyACM[0-9]*", MODE:="0660", GROUP:="dialout"
          KERNEL=="ttyUSB[0-9]*", MODE:="0660", GROUP:="dialout"
        '';
      };
    };

    tooling = {
      cli = {
        enable =
          mkEnableOption "CLI + embedded tooling"
          // {
            default = true;
          };
        packages = mkOption {
          type = types.listOf types.package;
          default = defaultCliPackages;
        };
      };
      desktopApps = {
        enable =
          mkEnableOption "Desktop GUI apps for x86_64 hosts"
          // {
            default = pkgs.stdenv.hostPlatform.isx86_64;
          };
        packages = mkOption {
          type = types.listOf types.package;
          default = defaultDesktopPackages;
        };
      };
      nh = {
        enable =
          mkEnableOption "NH helper CLI + garbage collection timer"
          // {
            default = false;
          };
        flake = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Default flake reference for NH (sets NH_FLAKE when provided).";
        };
        clean = {
          enable =
            mkEnableOption "Run nh clean on a schedule"
            // {
              default = true;
            };
          dates = mkOption {
            type = types.singleLineStr;
            default = "weekly";
            description = "systemd timer expression for nh clean";
          };
          extraArgs = mkOption {
            type = types.singleLineStr;
            default = "--keep-since 7d --keep 5";
            description = "Additional arguments passed to nh clean all";
          };
        };
      };
    };

    virtualization = {
      docker = {
        enable =
          mkEnableOption "Enable opinionated Docker manager"
          // {
            default = true;
          };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      time = {
        timeZone = mkDefault "Etc/UTC";
        hardwareClockInLocalTime = mkDefault false;
      };
      i18n.defaultLocale = mkDefault "en_US.UTF-8";
      console.keyMap = mkDefault "us";

      networking.networkmanager.enable = true;

      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = mkDefault pkgs.stdenv.hostPlatform.isx86_64;

      services = {
        fwupd.enable = true;
        openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            X11Forwarding = false;
            AllowAgentForwarding = false;
            AllowTcpForwarding = false;
            LoginGraceTime = "30s";
            ClientAliveInterval = 300;
            ClientAliveCountMax = 2;
            MaxAuthTries = 3;
          };
        };
      };

      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.hack
      ];

      environment.variables = {
        XCURSOR_THEME = mkDefault "Adwaita";
        XCURSOR_SIZE = mkDefault "24";
      };
    }

    (mkIf cfg.audio.enable {
      security.rtkit.enable = true;
      services.pipewire = mkPipewireConfig cfg.audio.pipewire;
    })

    (mkIf cfg.peripherals.enable {
      services.udev.extraRules = cfg.peripherals.extraRules;
    })

    (mkIf cfg.tooling.cli.enable {
      programs.zsh.enable = true;
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })

    (
      let
        cliPackages = optionals cfg.tooling.cli.enable cfg.tooling.cli.packages;
        desktopPackages = optionals cfg.tooling.desktopApps.enable cfg.tooling.desktopApps.packages;
        combined = cliPackages ++ desktopPackages;
      in
        mkIf (combined != []) {
          environment.systemPackages = combined;
        }
    )

    (mkIf cfg.tooling.nh.enable {
      programs.nh =
        {
          enable = true;
          clean = let
            cleanCfg = cfg.tooling.nh.clean;
          in {
            inherit (cleanCfg) enable dates extraArgs;
          };
        }
        // optionalAttrs (cfg.tooling.nh.flake != null) {
          inherit (cfg.tooling.nh) flake;
        };
    })

    (mkIf cfg.virtualization.docker.enable {
      services.dockerManager.enable = true;
    })
  ]);
}
