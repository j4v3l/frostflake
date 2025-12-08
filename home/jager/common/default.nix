{
  pkgs,
  lib,
  frostflakeUser,
  frostflakeRoot,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  user = frostflakeUser;
  homeDir =
    if isDarwin
    then user.darwinHome
    else user.linuxHome;
  frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};
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
  flakePath = lib.findFirst (p: builtins.pathExists p) null candidateFlakePaths;
  defaultFlakeRef =
    if flakePath != null
    then "\${FLAKE:-${flakePath}}"
    else "\${FLAKE:?Set FLAKE to your frostflake checkout}";
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
  pythonWithPsutil = pkgs.python3.withPackages (ps: [ps.psutil]);
  tmuxMetricsScript = pkgs.writeShellScriptBin "tmux-frostflake-stats" ''
        exec ${pythonWithPsutil}/bin/python3 - <<'PY'
    import shutil
    import subprocess
    import psutil


    def cpu_usage():
        return round(psutil.cpu_percent(interval=0.15))


    def memory_usage():
        return round(psutil.virtual_memory().percent)


    def battery_status():
        data = psutil.sensors_battery()
        if data is None:
            return "--"
        plug = "+" if data.power_plugged else ""
        return f"{int(data.percent)}%{plug}"


    def gpu_usage():
        nvidia = shutil.which("nvidia-smi")
        if not nvidia:
            return "--"
        try:
            lines = (
                subprocess.check_output(
                    [
                        nvidia,
                        "--query-gpu=utilization.gpu",
                        "--format=csv,noheader,nounits",
                    ],
                    text=True,
                    timeout=0.4,
                )
                .strip()
                .splitlines()
            )
            if lines:
                value = lines[0].strip()
                if value:
                    return f"{value}%"
        except Exception:
            pass
        return "--"


    stats = "CPU {cpu}% · MEM {mem}% · BAT {bat} · GPU {gpu}".format(
        cpu=cpu_usage(),
        mem=memory_usage(),
        bat=battery_status(),
        gpu=gpu_usage(),
    )
    print(stats, end="")
    PY
  '';
in {
  home = {
    inherit (user) username;
    homeDirectory = homeDir;
    packages =
      frostflakePackages.home.common
      ++ lib.optionals (!isDarwin) frostflakePackages.home.linuxDesktop
      ++ lib.optionals isDarwin frostflakePackages.home.darwinExtra
      ++ [tmuxMetricsScript];
    sessionVariables =
      {
        EDITOR = "nvim";
        LESS = "-FRSX";
      }
      // lib.optionalAttrs (flakePath != null) {FLAKE = flakePath;};
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
        user.name = user.git.name;
        user.email = user.git.email;
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
        if [ -z "''${TMUX_THEME:-}" ]; then
          if command -v defaults >/dev/null 2>&1; then
            if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi "Dark"; then
              export TMUX_THEME="dark"
            else
              export TMUX_THEME="light"
            fi
          elif command -v gsettings >/dev/null 2>&1; then
            if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -qi "dark"; then
              export TMUX_THEME="dark"
            else
              export TMUX_THEME="light"
            fi
          elif [ -n "''${COLORFGBG:-}" ]; then
            bg_colour="''${COLORFGBG##*;}"
            case "$bg_colour" in
              0|1|2|3|4|5|6|7) export TMUX_THEME="dark" ;;
              *) export TMUX_THEME="light" ;;
            esac
          else
            export TMUX_THEME="dark"
          fi
        fi
        if command -v tmux >/dev/null 2>&1; then
          if [ -z "$TMUX" ] && [ -t 0 ]; then
            export TMUX_AUTO=1
            tmux attach -t frostflake || tmux new -s frostflake
            unset TMUX_AUTO
          fi
        fi
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
          pkgupdate = "nix flake update";
          nfmt = "alejandra .";
          ncheck = "statix check . && deadnix";
          yubi-pam-enroll = "make -C ${defaultFlakeRef} yubi-pam-enroll";
          yubi-ssh-key = "make -C ${defaultFlakeRef} yubi-ssh-key";
          yk-info = "ykman info";
          yk-oath-list = "ykman oath accounts list";
          tmls = "tmux list-sessions";
          tma = "tmux attach -t";
          tmn = "tmux new -s";
          tmk = "tmux kill-session -t";
          tmf = "tmux attach -t frostflake || tmux new -s frostflake";
        }
        (lib.mkIf (!isDarwin) {
          nixup = "sudo nixos-rebuild switch --flake ${defaultFlakeRef}#\$(hostname)";
          pkgupgrade = "sudo nixos-rebuild switch --flake ${defaultFlakeRef}#\$(hostname)";
          nixboot = "sudo nixos-rebuild boot --flake ${defaultFlakeRef}#\$(hostname)";
          nixdry = "nixos-rebuild dry-activate --flake ${defaultFlakeRef}#\$(hostname)";
          vmls = "virsh list --all";
          vmstart = "virsh start";
          vmstop = "virsh shutdown";
          vmforce = "virsh destroy";
          vmconsole = "virsh console";
          vmautostart = "virsh autostart";
        })
        (lib.mkIf isDarwin {
          pkgupgrade = "darwin-rebuild switch --flake ${defaultFlakeRef}#Glacier";
        })
      ];
    };

    tmux = let
      palette = {
        bg = "default";
        fg = "#{?#{==:#{environ:TMUX_THEME},light},colour0,colour15}";
        accent = "colour4";
        muted = "colour8";
        warn = "colour1";
      };
      statsCommand = "${tmuxMetricsScript}/bin/tmux-frostflake-stats";
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
        set -g status-style "bg=${palette.bg} fg=${palette.fg}"
        set -g message-style "bg=${palette.accent} fg=${palette.bg}"
        set -g message-command-style "bg=${palette.accent} fg=${palette.bg}"
        set -g pane-border-style "fg=${palette.muted}"
        set -g pane-active-border-style "fg=${palette.accent}"
        set -g display-panes-colour ${palette.muted}
        set -g display-panes-active-colour ${palette.accent}
        set -g status-interval 1
        set -g status-justify centre
        set -g status-left-length 40
        set -g status-right-length 100
        setw -g window-status-format " #[fg=${palette.muted}]#I #[fg=${palette.fg}]#W "
        setw -g window-status-current-format " #[fg=${palette.accent}]#I #[fg=${palette.fg},bold]#W "
        set -g status-left "#[fg=${palette.accent},bold] #[fg=${palette.fg}]#S #[fg=${palette.muted}]#H"
        set -g status-right "#[fg=${palette.warn}]#{?client_prefix,⌘ ,} #[fg=${palette.fg}]#(${statsCommand}) #[fg=${palette.muted}]· #[fg=${palette.fg}]%Y-%m-%d %H:%M"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Frostflake tmux reloaded"
      '';
    };

    vscode = {
      enable = true;
      package = pkgs.vscode;
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-python.python
        ms-python.vscode-pylance
        charliermarsh.ruff
        rust-lang.rust-analyzer
      ];
      userSettings = {
        "editor.formatOnSave" = true;
        "editor.fontFamily" = "JetBrainsMono Nerd Font, Menlo, Monaco, 'Courier New', monospace";

        "[nix]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "alejandra";
        "nix.serverSettings" = {
          "nixd" = {
            "formatting" = {
              "command" = ["alejandra"];
            };
          };
        };

        "[python]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "charliermarsh.ruff";
        };
        "python.defaultInterpreterPath" = "python3";
        "python.analysis.typeCheckingMode" = "basic";
        "python.formatting.provider" = "none";

        "[rust]" = {
          "editor.formatOnSave" = true;
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        };
        "rust-analyzer.check.command" = "clippy";
        "rust-analyzer.cargo.allFeatures" = true;
        "rust-analyzer.procMacro.enable" = true;
      };
    };
  };

  fonts.fontconfig.enable = lib.mkDefault (!isDarwin);
  xdg = {
    enable = lib.mkDefault (!isDarwin);
    configFile."starship.toml".source = ./starship.toml;
  };
}
