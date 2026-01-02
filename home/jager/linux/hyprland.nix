{
  pkgs,
  lib,
  frostflakeRoot,
  ...
}: let
  frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};
  wallpaper = pkgs.nixos-artwork.wallpapers.simple-dark.gnomeFile;
in {
  imports = [../common/default.nix];

  home.packages = frostflakePackages.home.hyprland;

  services.mako = {
    enable = true;
    font = "JetBrainsMono Nerd Font 11";
    backgroundColor = "#1d2230";
    textColor = "#f2f2f2";
    borderColor = "#769ff0";
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 600;
        command = "hyprlock";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "hyprlock";
      }
    ];
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    theme = "gruvbox-dark";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
    };
  };

  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 28;
      modules-left = ["hyprland/workspaces" "clock"];
      modules-center = [];
      modules-right = ["pulseaudio" "network" "battery" "tray"];
      clock = {
        format = "{:%a %b %d, %I:%M %p}";
        tooltip = false;
      };
      network = {
        format-wifi = "  {essid}";
        format-ethernet = "󰈀  {ipaddr}";
        format-disconnected = "󰤭";
        tooltip = false;
      };
      battery = {
        format = "{capacity}%";
        format-charging = " {capacity}%";
        format-plugged = " {capacity}%";
      };
      pulseaudio = {
        format = "  {volume}%";
        format-muted = "";
        tooltip = false;
      };
      tray = {
        spacing = 6;
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 12px;
        color: #f2f2f2;
      }
      window {
        background: rgba(29,34,48,0.90);
      }
      #workspaces button.focused {
        background: #769ff0;
        color: #1d2230;
      }
      #tray,
      #battery,
      #network,
      #pulseaudio,
      #clock {
        padding: 0 8px;
      }
    '';
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = true;
    settings = {
      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Adwaita"
        "NIXOS_OZONE_WL,1"
        "QT_QPA_PLATFORM,wayland"
        "GDK_BACKEND,wayland,x11"
        "MOZ_ENABLE_WAYLAND,1"
      ];

      monitor = [",preferred,auto,1"];

      "$mod" = "SUPER";

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          scroll_factor = 0.9;
        };
      };

      general = {
        gaps_in = 8;
        gaps_out = 16;
        border_size = 2;
        "col.active_border" = "0xff769ff0";
        "col.inactive_border" = "0x77232f44";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
      };

      dwindle = {
        preserve_split = true;
        smart_resizing = false;
      };

      misc = {
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
      };

      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Q, killactive"
        "$mod SHIFT, Q, exit"
        "$mod, F, fullscreen"
        "$mod, D, exec, rofi -show drun"
        "$mod, E, exec, rofi -show window"
        "$mod, V, togglefloating"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        "$mod, mouse_down, workspace, e-1"
        "$mod, mouse_up, workspace, e+1"
        "$mod, SPACE, togglefloating"
        "CTRL ALT, L, exec, hyprlock"
        "CTRL ALT, P, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod, R, exec, hyprctl reload"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      exec-once = [
        "waybar"
        "mako"
        "nm-applet --indicator"
        "blueman-applet"
      ];

      windowrulev2 = [
        "suppressevent maximize, class:^(.*)$"
      ];
    };
  };

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    # Replace HDMI-A-1 with your monitor identifier.
    preload = ${wallpaper}
    wallpaper = HDMI-A-1,${wallpaper}
  '';
}
