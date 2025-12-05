{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  isX86Linux = (!isDarwin) && pkgs.stdenv.hostPlatform.isx86_64;
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
      ++ lib.optionals isX86Linux [
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

    tmux = let
      palette = {
        bg1 = "#336699";
        bg2 = "#2f5783";
        bg3 = "#294262";
        bg4 = "#232f44";
        bg5 = "#1d2230";
        blue = "#769ff0";
        gray = "#999999";
        red = "#eb4d28";
        white = "#f2f2f2";
      };
    in {
      enable = true;
      extraConfig = ''
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
        set -g base-index 1
        setw -g pane-base-index 1
        set -g history-limit 20000
        set -g repeat-time 250
        set -g escape-time 25
        set -g default-terminal "tmux-256color"
        set -ga terminal-overrides ",xterm-256color:RGB"
        setw -g mode-keys vi
        set -g mouse on
        set -g renumber-windows on
        set -g status-interval 1
        set -g status-justify centre
        set -g message-style "bg=${palette.bg1} fg=${palette.white}"
        set -g message-command-style "bg=${palette.bg2} fg=${palette.white}"
        setw -g clock-mode-colour ${palette.blue}
        set -g pane-border-style "fg=${palette.bg3}"
        set -g pane-active-border-style "fg=${palette.blue}"
        set -g display-panes-colour ${palette.bg3}
        set -g display-panes-active-colour ${palette.blue}
        set -g status-style "bg=${palette.bg5} fg=${palette.gray}"
        set -g status-left-length 80
        set -g status-right-length 120
        set -g window-status-separator ""
        setw -g window-status-format "#[fg=${palette.gray}]#[fg=${palette.white},bg=${palette.bg4}] #I:#W #[fg=${palette.bg4},bg=${palette.bg5}]"
        setw -g window-status-current-format "#[fg=${palette.bg3}]#[fg=${palette.white},bg=${palette.bg3}] #I:#W #[fg=${palette.bg3},bg=${palette.bg5}]"
        set -g status-left "#[fg=${palette.bg1},bg=${palette.bg5}]#[fg=${palette.white},bg=${palette.bg1}] #S #[fg=${palette.bg1},bg=${palette.bg2}]#[fg=${palette.white},bg=${palette.bg2}] #H #[fg=${palette.bg2},bg=${palette.bg3}]#[fg=${palette.white},bg=${palette.bg3}] #I:#W #[fg=${palette.bg3},bg=${palette.bg5}]"
        set -g status-right "#[fg=${palette.bg4},bg=${palette.bg5}]#[fg=${palette.white},bg=${palette.bg4}] #{?client_prefix,⏱ ,}#[fg=${palette.bg4},bg=${palette.bg5}]#[fg=${palette.gray},bg=${palette.bg5}] %Y-%m-%d %I:%M %p #[fg=${palette.bg5},bg=default]"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Frostflake tmux reloaded"
      '';
    };
  };

  fonts.fontconfig.enable = lib.mkDefault (!isDarwin);
  xdg = {
    enable = lib.mkDefault (!isDarwin);
    configFile."starship.toml".source = ./starship.toml;
  };
}
