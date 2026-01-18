{lib, ...}: let
  frostflakeProfileDark = "c2c8a1f6-7b7f-42d0-8464-55b91dd6276a";
  frostflakeProfileLight = "7c7a7c31-6f2d-46b7-aef8-4a84c9e7d807";
  frostflakeProfileDarkKey = "org/gnome/terminal/legacy/profiles:/:${frostflakeProfileDark}";
  frostflakeProfileLightKey = "org/gnome/terminal/legacy/profiles:/:${frostflakeProfileLight}";

  frostflakePaletteDark = [
    "#232f44"
    "#eb4d28"
    "#6fbf8f"
    "#e3c27a"
    "#769ff0"
    "#c79df4"
    "#66c2d6"
    "#f2f2f2"
    "#2f5783"
    "#f06b4a"
    "#8fd7a8"
    "#f2d49b"
    "#a4c4ff"
    "#e1c2ff"
    "#8ad7e7"
    "#ffffff"
  ];

  frostflakePaletteLight = [
    "#1d2230"
    "#d14a2a"
    "#3d8f6a"
    "#b8842a"
    "#2f5783"
    "#7e4f9f"
    "#2e8aa7"
    "#f2f2f2"
    "#3b6aa1"
    "#eb4d28"
    "#51b485"
    "#d1a23f"
    "#769ff0"
    "#a576d6"
    "#5fbcd6"
    "#ffffff"
  ];

  frostflakeDark = {
    background = "#1d2230";
    foreground = "#f2f2f2";
    cursorBg = "#769ff0";
    cursorFg = "#1d2230";
    bold = "#f06b4a";
  };

  frostflakeLight = {
    background = "#f7f9fc";
    foreground = "#1d2230";
    cursorBg = "#2f5783";
    cursorFg = "#f7f9fc";
    bold = "#d14a2a";
  };

  hidpiFontDpi = 144;
  xfceXftDpi = hidpiFontDpi * 1024;
  gnomeTextScale = 1.5;
in {
  imports = [../common/default.nix];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-format = "12h";
      show-battery-percentage = true;
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      cursor-size = 24;
      text-scaling-factor = gnomeTextScale;
    };
    "org/gnome/mutter" = {
      experimental-features = ["scale-monitor-framebuffer"];
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/terminal/legacy/profiles:" = {
      default = frostflakeProfileDark;
      list = [
        frostflakeProfileDark
        frostflakeProfileLight
      ];
    };
    ${frostflakeProfileDarkKey} = {
      visible-name = "Frostflake Dark";
      palette = frostflakePaletteDark;
      background-color = frostflakeDark.background;
      foreground-color = frostflakeDark.foreground;
      bold-color = frostflakeDark.bold;
      bold-color-same-as-fg = false;
      use-theme-colors = false;
      use-system-font = false;
      font = "JetBrainsMono Nerd Font 12";
      cursor-colors-set = true;
      cursor-background-color = frostflakeDark.cursorBg;
      cursor-foreground-color = frostflakeDark.cursorFg;
      cursor-blink-mode = "on";
      cursor-shape = "underline";
      use-custom-command = false;
      scrollbar-policy = "never";
      audible-bell = false;
      allow-bold = true;
      default-size-columns = 110;
      default-size-rows = 30;
    };

    ${frostflakeProfileLightKey} = {
      visible-name = "Frostflake Light";
      palette = frostflakePaletteLight;
      background-color = frostflakeLight.background;
      foreground-color = frostflakeLight.foreground;
      bold-color = frostflakeLight.bold;
      bold-color-same-as-fg = false;
      use-theme-colors = false;
      use-system-font = false;
      font = "JetBrainsMono Nerd Font 12";
      cursor-colors-set = true;
      cursor-background-color = frostflakeLight.cursorBg;
      cursor-foreground-color = frostflakeLight.cursorFg;
      cursor-blink-mode = "on";
      cursor-shape = "underline";
      use-custom-command = false;
      scrollbar-policy = "never";
      audible-bell = false;
      allow-bold = true;
      default-size-columns = 110;
      default-size-rows = 30;
    };
  };

  xdg.configFile = {
    "kcmfonts".text = ''
      [General]
      forceFontDPI=${toString hidpiFontDpi}
    '';
    "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Xft" type="empty">
          <property name="Antialias" type="int" value="1"/>
          <property name="Hinting" type="int" value="1"/>
          <property name="HintStyle" type="string" value="hintslight"/>
          <property name="RGBA" type="string" value="rgb"/>
          <property name="DPI" type="int" value="${toString xfceXftDpi}"/>
        </property>
      </channel>
    '';
  };

  xdg.mime.enable = lib.mkDefault true;
}
