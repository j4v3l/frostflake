{
  config,
  frostflakeRoot,
  frostflakeUser,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    types
    ;
  frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};
  cfg = config.frostflake.ai;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  aiSystemPkgs = frostflakePackages.ai.system;
  aiHomePkgs = frostflakePackages.ai.home;
  aiDarwinCasks = frostflakePackages.ai.darwinCasks;
  hasUser = frostflakeUser ? username;
in {
  options.frostflake.ai = {
    enable =
      mkEnableOption "AI tooling (Ollama + desktop apps)"
      // {
        default = pkgs.stdenv.hostPlatform.isx86_64 || isDarwin;
      };

    packages = {
      enable =
        mkEnableOption "Install AI desktop applications"
        // {
          default = true;
        };

      system = mkOption {
        type = types.listOf types.package;
        default = aiSystemPkgs;
        description = "System-wide AI applications (Nix packages).";
      };

      home = mkOption {
        type = types.listOf types.package;
        default = aiHomePkgs;
        description = "User-scoped AI applications (home-manager packages).";
      };

      darwinCasks = mkOption {
        type = types.listOf types.str;
        default = aiDarwinCasks;
        description = "Homebrew casks for macOS AI applications.";
      };
    };

    ollama = {
      enable =
        mkEnableOption "Enable Ollama service"
        // {
          default = pkgs.stdenv.hostPlatform.isx86_64;
        };

      acceleration = mkOption {
        type = types.nullOr (types.either types.bool types.str);
        default = null;
        description = ''Acceleration backend (e.g., "cuda", "rocm", or false for CPU-only).'';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.packages.enable && cfg.packages.system != []) {
      environment.systemPackages = cfg.packages.system;
    })

    (mkIf (cfg.packages.enable && hasUser && cfg.packages.home != []) {
      home-manager.users.${frostflakeUser.username}.home.packages = cfg.packages.home;
    })

    (mkIf (cfg.ollama.enable && !isDarwin) {
      services.ollama =
        {
          enable = mkDefault true;
        }
        // optionalAttrs (cfg.ollama.acceleration != null) {
          acceleration = mkDefault cfg.ollama.acceleration;
        };
    })
  ]);
}
