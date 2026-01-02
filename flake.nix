{
  description = "Frostflake: multi-host NixOS 25.11 + home-manager + nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      pre-commit-hooks,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      frostflakeRoot = ./.;
      frostflakeUser = import ./lib/frostflake/user.nix;
      frostflakeOverlay = import (frostflakeRoot + "/pkgs/overlay.nix");
      overlays = [ frostflakeOverlay ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        fn:
        lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
            };
            frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") { inherit pkgs lib; };
            nvfetcherUpdate = pkgs.writeShellApplication {
              name = "nvfetcher-update";
              runtimeInputs = [
                pkgs.nvfetcher
                pkgs.git
              ];
              text = ''
                set -euo pipefail
                repo_root="''${NVF_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
                cd "$repo_root/pkgs"
                nvfetcher --config ./sources.toml --build-dir ./_sources "$@"
              '';
            };
          in
          fn {
            inherit
              system
              pkgs
              frostflakePackages
              nvfetcherUpdate
              ;
          }
        );
    in
    {
      formatter = forAllSystems ({ pkgs, ... }: pkgs.alejandra);

      overlays = {
        default = frostflakeOverlay;
      };

      devShells = forAllSystems (
        {
          pkgs,
          system,
          frostflakePackages,
          ...
        }:
        {
          default = pkgs.mkShell {
            name = "frostflake";
            packages = frostflakePackages.devShell;
            shellHook = ''
              export NIX_CONFIG="experimental-features = nix-command flakes"
              echo "Loaded frostflake dev shell (${system}) for $USER"
            '';
          };
        }
      );

      packages = forAllSystems (
        {
          pkgs,
          nvfetcherUpdate,
          ...
        }:
        {
          nvfetcher-update = nvfetcherUpdate;
        }
      );

      apps = forAllSystems (
        {
          nvfetcherUpdate,
          ...
        }:
        {
          nvfetcher-update = {
            type = "app";
            program = "${nvfetcherUpdate}/bin/nvfetcher-update";
          };
        }
      );

      checks = forAllSystems (
        { system, ... }:
        {
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };
        }
      );

      nixosConfigurations = {
        Avalanche = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs frostflakeUser frostflakeRoot; };
          modules = [ ./hosts/avalanche/default.nix ];
        };

        Aurora = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs frostflakeUser frostflakeRoot; };
          modules = [ ./hosts/aurora/default.nix ];
        };

        Iceberg = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs frostflakeUser frostflakeRoot; };
          modules = [ ./hosts/iceberg/default.nix ];
        };

        Hailstone = lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs frostflakeUser frostflakeRoot; };
          modules = [ ./hosts/hailstone/default.nix ];
        };
      };

      darwinConfigurations = {
        Glacier = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs frostflakeUser frostflakeRoot; };
          modules = [ ./hosts/glacier/default.nix ];
        };
      };
    };
}
