{
  pkgs,
  lib,
  frostflakeUser,
  frostflakeRoot,
  inputs,
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
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

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
      // lib.optionalAttrs (flakePath != null) {
        FLAKE = flakePath;
        NH_FLAKE = flakePath;
        NH_OS_FLAKE = flakePath;
        NH_HOME_FLAKE = flakePath;
        NH_DARWIN_FLAKE = flakePath;
      };
    stateVersion = "24.11";
  };

  home.file.".vscode/extensions/.keep".text = "";

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
    nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      globals.mapleader = " ";
      opts = {
        number = true;
        relativenumber = true;
        cursorline = true;
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        smartindent = true;
        wrap = false;
        scrolloff = 8;
        sidescrolloff = 8;
        termguicolors = true;
        signcolumn = "yes";
        splitbelow = true;
        splitright = true;
        ignorecase = true;
        smartcase = true;
        timeoutlen = 400;
        updatetime = 250;
      };
      colorschemes.catppuccin = {
        enable = true;
        flavour = "macchiato";
        integrations = {
          cmp = true;
          gitsigns = true;
          telescope = true;
          treesitter = true;
          which_key = true;
          indent_blankline = true;
          nvimtree = true;
          native_lsp = {
            enabled = true;
          };
        };
      };
      keymaps = [
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<cr>";
          options = {
            desc = "Find files";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>fg";
          action = "<cmd>Telescope live_grep<cr>";
          options = {
            desc = "Live grep";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>fb";
          action = "<cmd>Telescope buffers<cr>";
          options.desc = "List buffers";
        }
        {
          mode = "n";
          key = "<leader>fh";
          action = "<cmd>Telescope help_tags<cr>";
          options.desc = "Help tags";
        }
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>NvimTreeToggle<cr>";
          options.desc = "Toggle file explorer";
        }
        {
          mode = "n";
          key = "<C-n>";
          action = "<cmd>NvimTreeToggle<cr>";
          options.desc = "Toggle file explorer";
        }
        {
          mode = "n";
          key = "<leader>bd";
          action = "<cmd>bdelete<cr>";
          options.desc = "Delete buffer";
        }
        {
          mode = "n";
          key = "<leader>qq";
          action = "<cmd>qa<cr>";
          options.desc = "Quit all";
        }
        {
          mode = "n";
          key = "gd";
          action = "<cmd>lua vim.lsp.buf.definition()<cr>";
          options.desc = "LSP definition";
        }
        {
          mode = "n";
          key = "gr";
          action = "<cmd>lua vim.lsp.buf.references()<cr>";
          options.desc = "LSP references";
        }
        {
          mode = "n";
          key = "K";
          action = "<cmd>lua vim.lsp.buf.hover()<cr>";
          options.desc = "LSP hover";
        }
        {
          mode = "n";
          key = "<leader>rn";
          action = "<cmd>lua vim.lsp.buf.rename()<cr>";
          options.desc = "LSP rename";
        }
        {
          mode = "n";
          key = "<leader>ca";
          action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
          options.desc = "LSP code action";
        }
        {
          mode = "n";
          key = "[d";
          action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
          options.desc = "Prev diagnostic";
        }
        {
          mode = "n";
          key = "]d";
          action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
          options.desc = "Next diagnostic";
        }
      ];
      plugins = {
        lualine = {
          enable = true;
          settings = {
            options = {
              theme = "auto";
              globalstatus = true;
              component_separators = {
                left = "|";
                right = "|";
              };
              section_separators = {
                left = "";
                right = "";
              };
            };
          };
        };
        bufferline = {
          enable = true;
          settings = {
            options = {
              diagnostics = "nvim_lsp";
              separatorStyle = "slant";
              showCloseIcon = false;
              showBufferCloseIcons = false;
            };
          };
        };
        telescope = {
          enable = true;
          extensions."fzf-native".enable = true;
        };
        treesitter = {
          enable = true;
          indent = true;
          ensureInstalled = [
            "bash"
            "c"
            "cpp"
            "fish"
            "json"
            "lua"
            "markdown"
            "markdown_inline"
            "nix"
            "python"
            "regex"
            "rust"
            "toml"
            "tsx"
            "typescript"
            "vim"
            "vimdoc"
            "yaml"
          ];
        };
        "nvim-tree" = {
          enable = true;
          view.width = 32;
          renderer = {
            highlightGit = true;
            indentMarkers.enable = true;
          };
          git.enable = true;
          diagnostics.enable = true;
          filters.custom = [".git"];
          actions.openFile.resizeWindow = true;
        };
        gitsigns.enable = true;
        comment.enable = true;
        "which-key".enable = true;
        "indent-blankline" = {
          enable = true;
          settings = {
            indent.char = "|";
            scope.enabled = true;
          };
        };
        "nvim-autopairs".enable = true;
        alpha = {
          enable = true;
          theme = "dashboard";
        };
        cmp = {
          enable = true;
          autoEnableSources = true;
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "path";}
            {name = "buffer";}
          ];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<Tab>" = "cmp.mapping.select_next_item()";
            "<S-Tab>" = "cmp.mapping.select_prev_item()";
          };
        };
        luasnip.enable = true;
        lsp = {
          enable = true;
          servers = {
            lua_ls.enable = true;
            nixd.enable = true;
            rust_analyzer.enable = true;
            pyright.enable = true;
          };
        };
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
          nhclean = "nh clean all --keep-since 7d --keep 5";
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
          ts-up = "sudo tailscale up";
          ts-down = "sudo tailscale down";
          ts-status = "tailscale status";
          wg-up = "iface=\"$WG_IFACE\"; [ -n \"$iface\" ] || iface=wg0; sudo wg-quick up \"$iface\"";
          wg-down = "iface=\"$WG_IFACE\"; [ -n \"$iface\" ] || iface=wg0; sudo wg-quick down \"$iface\"";
          nvpn = "nordvpn";
          nvpn-status = "nordvpn status";
          nvpn-connect = "if [ -n \"$NORD_REGION\" ]; then nordvpn connect \"$NORD_REGION\"; else nordvpn connect; fi";
          nvpn-disconnect = "nordvpn disconnect";
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
      mutableExtensionsDir = true;
      profiles.default = let
        nixExtensionPack =
          if pkgs.vscode-extensions ? pinage404
          then pkgs.vscode-extensions.pinage404."nix-extension-pack" or null
          else null;
      in {
        extensions =
          (with pkgs.vscode-extensions; [
            github.github-vscode-theme
            jnoortheen.nix-ide
            ms-python.python
            ms-python.vscode-pylance
            mkhl.direnv
            charliermarsh.ruff
            rust-lang.rust-analyzer
            pkief.material-icon-theme
          ])
          ++ lib.optional (nixExtensionPack != null) nixExtensionPack;
        userSettings = {
          "editor.formatOnSave" = true;
          "editor.fontFamily" = "JetBrainsMono Nerd Font, Menlo, Monaco, 'Courier New', monospace";
          "editor.fontLigatures" = true;
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "workbench.colorTheme" = "GitHub Dark Default";
          "workbench.iconTheme" = "material-icon-theme";

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
              "options" = let
                flakePath = toString frostflakeRoot;
              in {
                # NixOS host options (env override NIXOS_HOST, else first host)
                "nixos" = {
                  "expr" = ''
                    let
                      flake = builtins.getFlake "${flakePath}";
                      envHost = builtins.getEnv "NIXOS_HOST";
                      host =
                        if envHost != "" && flake.nixosConfigurations ? envHost
                        then envHost
                        else builtins.head (builtins.attrNames flake.nixosConfigurations);
                    in (builtins.getAttr host flake.nixosConfigurations).options
                  '';
                };
                # Home Manager options for the configured user
                "home-manager" = {
                  "expr" = ''(builtins.getFlake "${flakePath}").homeConfigurations.${frostflakeUser.username}.options'';
                };
                # nix-darwin options (env override NIX_DARWIN_HOST, else first)
                "nix-darwin" = {
                  "expr" = ''
                    let
                      flake = builtins.getFlake "${flakePath}";
                      envHost = builtins.getEnv "NIX_DARWIN_HOST";
                      host =
                        if envHost != "" && flake.darwinConfigurations ? envHost
                        then envHost
                        else builtins.head (builtins.attrNames flake.darwinConfigurations);
                    in (builtins.getAttr host flake.darwinConfigurations).options
                  '';
                };
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

          "direnv.path" = "direnv";
          "direnv.restart.automatic" = true;
        };
      };
    };
  };

  fonts.fontconfig.enable = lib.mkDefault (!isDarwin);
  xdg = {
    enable = lib.mkDefault (!isDarwin);
    configFile = {
      "starship.toml".source = ./starship.toml;

      "kitty/kitty.conf".source = ./kitty/kitty.conf;
      "kitty/theme.conf".source = ./kitty/theme.conf;
      "kitty/themes/frostflake-dark.conf".source = ./kitty/themes/frostflake-dark.conf;
      "kitty/themes/frostflake-light.conf".source = ./kitty/themes/frostflake-light.conf;

      "ghostty/config".source = ./ghostty/config;
      "ghostty/config.light".source = ./ghostty/config.light;
      "ghostty/themes/frostflake-dark".source = ./ghostty/themes/frostflake-dark;
      "ghostty/themes/frostflake-light".source = ./ghostty/themes/frostflake-light;
    };
  };
}
