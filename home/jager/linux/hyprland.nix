{
  pkgs,
  lib,
  frostflakeRoot,
  ...
}: let
  frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};

  # Catppuccin-inspired palette
  theme = let
    colors = {
      rosewater = "F5E0DC";
      flamingo = "F2CDCD";
      pink = "F5C2E7";
      mauve = "DDB6F2";
      red = "F28FAD";
      maroon = "E8A2AF";
      peach = "F8BD96";
      yellow = "FAE3B0";
      green = "ABE9B3";
      teal = "B5E8E0";
      blue = "96CDFB";
      sky = "89DCEB";
      lavender = "C9CBFF";
      black0 = "0D1416";
      black1 = "111719";
      black2 = "131A1C";
      black3 = "192022";
      black4 = "202729";
      gray0 = "363D3E";
      gray1 = "4A5051";
      gray2 = "5C6262";
      white = "C5C8C9";
    };
  in {
    inherit colors;
    xcolors = lib.mapAttrsRecursive (_: c: "#${c}") colors;
    wallpaper = pkgs.nixos-artwork.wallpapers.simple-dark.gnomeFile;
    font = {
      family = "GeistMono Nerd Font";
      size = 12;
    };
    icon = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtkTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-gtk-theme;
    };
    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };
in {
  imports = [../common/default.nix];

  # Core packages for the session (adds fonts/themes/cursors on top of the shared Hyprland set).
  home.packages =
    frostflakePackages.home.hyprland
    ++ [
      theme.icon.package
      theme.gtkTheme.package
      theme.cursor.package
      pkgs.colloid-kde
      pkgs.geist-font
      pkgs.hyprlandPlugins.hyprexpo
    ];

  # Appearance
  home.pointerCursor = {
    inherit (theme.cursor) name size package;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    font = {
      package = pkgs.geist-font;
      name = theme.font.family;
      inherit (theme.font) size;
    };
    iconTheme = theme.icon;
    theme = theme.gtkTheme;
    gtk3.bookmarks = [];
    gtk4.bookmarks = [];
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig".text = lib.generators.toINI {} {
    General.theme = "ColloidDark";
  };

  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      theme = null; # keep default theme to avoid missing assets
      extraConfig = {
        modi = "drun,run,window";
        show-icons = true;
      };
    };

    waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          gtk-layer-shell = true;
          fixed-center = true;
          height = 32;
          spacing = 8;
          modules-left = ["image" "hyprland/workspaces" "idle_inhibitor" "hyprland/window"];
          modules-right = [
            "group/network"
            "group/audio"
            "group/backlight"
            "group/battery"
            "tray"
            "clock"
            "group/power"
          ];

          image = {
            path = "${theme.wallpaper}";
            size = 24;
            tooltip = false;
          };

          "group/network".modules = ["network"];
          network = {
            format = "󰤨  {essid}";
            format-ethernet = "󰈀  {ifname}";
            format-disconnected = "󰤭";
            tooltip-format = "{ifname} {ipaddr}";
          };

          "group/audio".modules = ["wireplumber#icon" "wireplumber#volume"];
          "wireplumber#icon" = {
            format = "{icon}";
            format-muted = "󰖁";
            format-icons = ["󰕿" "󰖀" "󰕾"];
            on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+";
            on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%-";
          };
          "wireplumber#volume" = {
            format = "{volume}%";
          };

          "group/backlight".modules = ["backlight#icon" "backlight#percent"];
          "backlight#icon" = {
            format = "{icon}";
            format-icons = ["󰃞" "󰃟" "󰃠"];
            on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 1%+";
            on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";
          };
          "backlight#percent".format = "{percent}%";

          "group/battery".modules = ["battery#capacity" "battery#state"];
          "battery#capacity" = {
            format = "{capacity}%";
            tooltip-format = "{timeTo}, {capacity}%";
          };
          "battery#state" = {
            format = "{icon}";
            format-charging = "󰂄";
            format-plugged = "󰂄";
            format-icons = ["󰁺" "󰁼" "󰂁" "󰁹" "󰂂" "󰁿" "󰁾"];
          };

          tray = {
            icon-size = 20;
            spacing = 8;
            show-passive-items = true;
          };

          clock.format = "{:%a %b %d  %I:%M %p}";

          "group/power".modules = [
            "custom/lock"
            "custom/exit"
            "custom/reboot"
            "custom/power"
          ];
          "custom/lock" = {
            format = "󰌾";
            on-click = "${pkgs.systemd}/bin/loginctl lock-session";
            tooltip = false;
          };
          "custom/exit" = {
            format = "󰍃";
            on-click = "${pkgs.systemd}/bin/loginctl terminate-user $USER";
            tooltip = false;
          };
          "custom/reboot" = {
            format = "󰜉";
            on-click = "${pkgs.systemd}/bin/systemctl reboot";
            tooltip = false;
          };
          "custom/power" = {
            format = "󰐥";
            on-click = "${pkgs.systemd}/bin/systemctl poweroff";
            tooltip = false;
          };
        }
      ];

      style = let
        x = theme.xcolors;
      in ''
        * {
          all: unset;
          font-family: "${theme.font.family}", sans-serif;
          font-size: ${toString theme.font.size}pt;
        }

        window {
          background: ${x.black0};
          color: ${x.white};
          border-radius: 12px;
        }

        #workspaces button {
          padding: 4px 10px;
          color: ${x.white};
        }

        #workspaces button.active {
          background: ${x.blue};
          color: ${x.black0};
        }

        #tray, #clock, #network, #backlight, #battery, #wireplumber, #custom-lock, #custom-exit, #custom-reboot, #custom-power {
          padding: 0 10px;
        }

        #tray > .needs-attention { background: ${x.red}; }
      '';
    };

    hyprlock = {
      enable = true;
      settings = let
        x = theme.xcolors;
      in {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
        };

        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 2;
            blur_size = 2;
            ignore_opacity = false;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "320, 56";
            outline_thickness = 2;
            outer_color = x.gray0;
            inner_color = x.black0;
            font_color = x.white;
            check_color = x.blue;
            fail_color = x.red;
            placeholder_text = "<i>Enter Password</i>";
            dots_spacing = 0.2;
            dots_center = true;
            position = "0, 120";
            valign = "center";
            halign = "center";
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_family = "${theme.font.family} Bold";
            font_size = 96;
            color = x.white;
            position = "0, -120";
            valign = "center";
            halign = "center";
          }
          {
            monitor = "";
            text = "$USER";
            font_family = "${theme.font.family}";
            font_size = 18;
            color = x.gray1;
            position = "0, 80";
            valign = "center";
            halign = "center";
          }
        ];
      };
    };
  };

  services = {
    hyprpaper = {
      enable = true;
      settings = {
        preload = ["${theme.wallpaper}"];
        wallpaper = [", ${theme.wallpaper}"];
      };
    };

    hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = lib.getExe pkgs.hyprlock;
          before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
          }
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 600;
            on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
      };
    };

    dunst = {
      enable = true;
      iconTheme = theme.icon;
      settings = let
        x = theme.xcolors;
      in {
        global = {
          font = "${theme.font.family} ${toString theme.font.size}";
          frame_color = x.gray0;
          frame_width = 2;
          separator_height = 2;
          corner_radius = 12;
          padding = 12;
          horizontal_padding = 16;
          gap_size = 5;
          markup = "full";
          format = "<b>%a</b>\n<i>%s</i>\n%b";
          transparency = 0;
          width = 320;
          alignment = "left";
          follow = "mouse";
        };
        urgency_low = {
          background = x.black1;
          foreground = x.white;
          frame_color = x.gray0;
        };
        urgency_normal = {
          background = x.black2;
          foreground = x.white;
          frame_color = x.blue;
        };
        urgency_critical = {
          background = x.black2;
          foreground = x.red;
          frame_color = x.red;
        };
      };
    };

    cliphist = {
      enable = true;
      allowImages = true;
      systemdTarget = "graphical-session.target";
    };
  };

  # Polkit agent as a user service (Wayland safe).
  systemd.user.services.polkit-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    plugins = with pkgs.hyprlandPlugins; [hyprexpo];
    systemd = {
      enable = true;
      variables = ["--all"];
    };

    settings = let
      pointer = theme.cursor;
      defaultApp = type: "${pkgs.gtk3}/bin/gtk-launch $(${pkgs.xdg-utils}/bin/xdg-mime query default ${type})";
      browser = defaultApp "x-scheme-handler/https";
      editor = defaultApp "text/plain";
      fileManager = defaultApp "inode/directory";
    in {
      env = [
        "CLUTTER_BACKEND,wayland"
        "GDK_BACKEND,wayland,x11,*"
        "SDL_VIDEODRIVER,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_STYLE_OVERRIDE,kvantum"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "GTK_THEME,${theme.gtkTheme.name}"
        "XCURSOR_THEME,${pointer.name}"
        "XCURSOR_SIZE,${toString pointer.size}"
        "NIXOS_OZONE_WL,1"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd --all"
        "hyprpaper"
        "waybar"
      ];

      monitor = [",preferred,auto,1"];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        "col.active_border" = "rgb(${theme.colors.blue})";
        "col.inactive_border" = "rgb(${theme.colors.gray0})";
        resize_on_border = true;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        fullscreen_opacity = 1.0;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        first_launch_animation = true;
        bezier = ["easeOutQuart, 0.25, 1, 0.5, 1"];
        animation = [
          "windows, 1, 3, easeOutQuart, slide"
          "layers, 1, 3, easeOutQuart, fade"
          "fade, 1, 3, easeOutQuart"
          "border, 1, 5, easeOutQuart"
          "workspaces, 1, 5, easeOutQuart, slide"
          "specialWorkspace, 1, 5, easeOutQuart, slidevert"
        ];
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        accel_profile = "flat";
        touchpad = {
          disable_while_typing = true;
          natural_scroll = true;
          tap-to-click = true;
          tap-and-drag = true;
          scroll_factor = 0.5;
        };
      };

      gestures = {
        workspace_swipe = true;
        workspace_swipe_forever = true;
      };

      misc = {
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        disable_autoreload = true;
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
        vfr = true;
        vrr = 1;
      };

      binds = {
        allow_workspace_cycles = true;
      };

      xwayland = {
        enabled = true;
        force_zero_scaling = true;
      };

      plugin.hyprexpo = {
        columns = 3;
        gap_size = 4;
        bg_col = "rgb(${theme.colors.black0})";
        enable_gesture = true;
        gesture_fingers = 3;
        gesture_distance = 300;
        gesture_positive = false;
      };

      bind =
        [
          # Compositor controls
          "SUPER, P, pseudo"
          "SUPER, S, togglesplit"
          "SUPER, Space, togglefloating"
          "SUPER, Q, killactive"
          "SUPER, F, fullscreen"
          "SUPER, C, centerwindow"
          "SUPER_SHIFT, P, pin"

          # Focus
          "SUPER, left, movefocus, l"
          "SUPER, H, movefocus, l"
          "SUPER, right, movefocus, r"
          "SUPER, L, movefocus, r"
          "SUPER, up, movefocus, u"
          "SUPER, K, movefocus, u"
          "SUPER, down, movefocus, d"
          "SUPER, J, movefocus, d"

          # Move windows
          "SUPER_SHIFT, left, movewindow, l"
          "SUPER_SHIFT, H, movewindow, l"
          "SUPER_SHIFT, right, movewindow, r"
          "SUPER_SHIFT, L, movewindow, r"
          "SUPER_SHIFT, up, movewindow, u"
          "SUPER_SHIFT, K, movewindow, u"
          "SUPER_SHIFT, down, movewindow, d"
          "SUPER_SHIFT, J, movewindow, d"

          # Cycle workspaces
          "SUPER, bracketleft, workspace, m-1"
          "SUPER, bracketright, workspace, m+1"

          # Cycle monitors
          "SUPER_SHIFT, bracketleft, focusmonitor, l"
          "SUPER_SHIFT, bracketright, focusmonitor, r"

          # Send workspace to monitor
          "SUPER_SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
          "SUPER_SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"

          # App shortcuts
          "SUPER, Return, exec, kitty"
          "SUPER, B, exec, ${browser}"
          "SUPER, E, exec, ${editor}"
          "SUPER, N, exec, ${fileManager}"
          "CTRL_ALT, L, exec, pgrep hyprlock || hyprlock"

          # Screenshots
          ", Print, exec, grimblast --notify copysave area"
          "CTRL, Print, exec, grimblast --notify --cursor copysave output"
          "ALT, Print, exec, grimblast --notify --cursor copysave screen"
        ]
        ++ lib.concatLists (lib.genList (
            x: let
              ws = let c = (x + 1) / 10; in lib.toString (x + 1 - (c * 10));
            in [
              "SUPER, ${ws}, workspace, ${lib.toString (x + 1)}"
              "SUPER_SHIFT, ${ws}, movetoworkspace, ${lib.toString (x + 1)}"
              "ALT_SHIFT, ${ws}, movetoworkspacesilent, ${lib.toString (x + 1)}"
            ]
          )
          10)
        ++ [
          # Resize
          "SUPER_CTRL, left, resizeactive, -20 0"
          "SUPER_CTRL, H, resizeactive, -20 0"
          "SUPER_CTRL, right, resizeactive,  20 0"
          "SUPER_CTRL, L, resizeactive,  20 0"
          "SUPER_CTRL, up, resizeactive,  0 -20"
          "SUPER_CTRL, K, resizeactive,  0 -20"
          "SUPER_CTRL, down, resizeactive,  0 20"
          "SUPER_CTRL, J, resizeactive,  0 20"

          # Move by pixels
          "SUPER_ALT, left, moveactive, -20 0"
          "SUPER_ALT, H, moveactive, -20 0"
          "SUPER_ALT, right, moveactive,  20 0"
          "SUPER_ALT, L, moveactive,  20 0"
          "SUPER_ALT, up, moveactive,  0 -20"
          "SUPER_ALT, K, moveactive,  0 -20"
          "SUPER_ALT, down, moveactive,  0 20"
          "SUPER_ALT, J, moveactive,  0 20"
        ];

      bindr = [
        # Launcher
        "SUPER, SUPER_L, exec, pkill rofi || rofi -show drun"
      ];

      bindl = [
        # Media keys
        ",XF86AudioMute, exec, volumectl toggle-mute"
        ",XF86AudioMicMute, exec, volumectl toggle-mic-mute"
        ",XF86RFKill, exec, networkctl toggle-network"
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, volumectl up 5"
        ",XF86AudioLowerVolume, exec, volumectl down 5"
        ",XF86MonBrightnessUp, exec, lightctl up 5"
        ",XF86MonBrightnessDown, exec, lightctl down 5"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
        "SUPER ALT, mouse:272, resizewindow"
      ];

      windowrulev2 = [
        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(com.saivert.pwvucontrol)$"
        "float, class:^(io.bassi.Amberol)$"
        "float, class:^(io.github.celluloid_player.Celluloid)$"
        "float, class:^(mpv)$"
        "float, class:^(nm-applet)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, class:^(org.gnome.Loupe)$"
        "float, class:^(thunar)$"
        "float, class:^(xdg-desktop-portal-gtk)$"
        "float, title:^(File Upload)(.*)$"
        "float, title:^(Library)(.*)$"
        "float, title:^(Open File)(.*)$"
        "float, title:^(Open Folder)(.*)$"
        "float, title:^(Save As)(.*)$"
        "float, title:^(Select a File)(.*)$"
        "float, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
        "pin, title:^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$"
        "idleinhibit fullscreen, class:^(.*)$"
        "idleinhibit fullscreen, title:^(.*)$"
        "idleinhibit fullscreen, fullscreen:1"
        "suppressevent maximize, class:.*"
      ];

      workspace = [
        "w[tv1], gapsout:0, gapsin:0"
        "f[1], gapsout:0, gapsin:0"
      ];
    };
  };
}
