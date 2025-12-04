{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  homeDir =
    if isDarwin
    then "/Users/jager"
    else "/home/jager";
  envFlakePath = builtins.getEnv "FLAKE_PATH";
  candidateFlakePaths =
    lib.optional (envFlakePath != "") envFlakePath
    ++ map (rel: "${homeDir}/${rel}") [
      "Documents/Codes/frostflake"
      "Documents/frostflake"
      "Codes/frostflake"
      "dev/frostflake"
      "frostflake"
    ];
  flakePath =
    lib.findFirst (p: builtins.pathExists p)
    (lib.head candidateFlakePaths)
    candidateFlakePaths;
  treeAlias = "eza --tree --icons=always";
  fastfetchModules = [
    "title"
    "separator"
    {
      type = "os";
      key = "Distro";
    }
    {
      type = "host";
      key = "Machine";
    }
    {
      type = "kernel";
      key = "Kernel";
    }
    {
      type = "uptime";
      key = "Uptime";
    }
    {
      type = "packages";
      key = "Packages";
    }
    {
      type = "shell";
      key = "Shell";
    }
    "break"
    {
      type = "cpu";
      key = "CPU";
    }
    {
      type = "gpu";
      key = "GPU";
    }
    {
      type = "memory";
      key = "Memory";
    }
    {
      type = "swap";
      key = "Swap";
    }
    {
      type = "disk";
      key = "Disk";
    }
    "break"
    {
      type = "localip";
      key = "LAN";
    }
    {
      type = "battery";
      key = "Battery";
    }
    {
      type = "locale";
      key = "Locale";
    }
    "colors"
  ];
in {
  home = {
    username = "jager";
    homeDirectory = homeDir;
    packages = with pkgs;
      [
        alejandra
        bat
        deadnix
        direnv
        eza
        fd
        glances
        neovim
        ripgrep
        starship
        statix
        tree
      ]
      ++ lib.optionals (!isDarwin) [
        brave
        code-cursor
        gnome-terminal
        lmstudio
        ollama
        vscode
      ];
    sessionVariables = {
      FLAKE = flakePath;
      EDITOR = "nvim";
      LESS = "-FRSX";
    };
    stateVersion = "24.11";
  };

  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      settings = {
        user.name = "j4v3l";
        user.email = "jj4v3l@gmail.com";
        init.defaultBranch = "master";
        pull.ff = "only";
        push.autoSetupRemote = true;
      };
    };
    starship.enable = true;
    fastfetch = {
      enable = true;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";
        logo = {
          type = "small";
          source = "nixos";
          padding = {
            top = 1;
            bottom = 1;
            right = 2;
          };
        };
        display = {
          separator = " :: ";
          color = "cyan";
        };
        modules = fastfetchModules;
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 50000;
      history.path = "${homeDir}/.zsh_history";
      initContent = ''
        eval "$(direnv hook zsh)"
      '';
      shellAliases = lib.mkMerge [
        {
          ll = "eza -lh --icons=always";
          la = "eza -lha --icons=always";
          lt = treeAlias;
          tree = "${treeAlias} -L 3";
          gs = "git status -sb";
          ga = "git add";
          gp = "git push";
          gl = "git pull";
          nclean = "sudo nix-collect-garbage -d && nix store optimise";
          nfu = "nix flake update";
          nfmt = "alejandra .";
          ncheck = "statix check . && deadnix";
        }
        (lib.mkIf (!isDarwin) {
          nixup = "sudo nixos-rebuild switch --flake ${flakePath}#\$(hostname)";
          nixboot = "sudo nixos-rebuild boot --flake ${flakePath}#\$(hostname)";
          nixdry = "nixos-rebuild dry-activate --flake ${flakePath}#\$(hostname)";
          vmls = "virsh list --all";
          vmstart = "virsh start";
          vmstop = "virsh shutdown";
          vmforce = "virsh destroy";
          vmconsole = "virsh console";
          vmautostart = "virsh autostart";
        })
      ];
    };
  };

  fonts.fontconfig.enable = lib.mkDefault (!isDarwin);
  xdg = {
    enable = lib.mkDefault (!isDarwin);
    configFile."starship.toml".source = ./starship.toml;
  };
}
