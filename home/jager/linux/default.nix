{lib, ...}: let
  frostflakeProfile = "c2c8a1f6-7b7f-42d0-8464-55b91dd6276a";
  frostflakeProfileKey = "org/gnome/terminal/legacy/profiles:/:${frostflakeProfile}";
  catppuccinPalette = [
    "#1E1E2E"
    "#F38BA8"
    "#A6E3A1"
    "#F9E2AF"
    "#89B4FA"
    "#CBA6F7"
    "#94E2D5"
    "#BAC2DE"
    "#45475A"
    "#F38BA8"
    "#A6E3A1"
    "#F9E2AF"
    "#89B4FA"
    "#CBA6F7"
    "#94E2D5"
    "#A6ADC8"
  ];
in {
  imports = [../common/default.nix];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-format = "12h";
      show-battery-percentage = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
    "org/gnome/terminal/legacy/profiles:/" = {
      default = frostflakeProfile;
      list = [frostflakeProfile];
    };
    ${frostflakeProfileKey} = {
      visible-name = "Frostflake";
      palette = catppuccinPalette;
      background-color = "#11111B";
      foreground-color = "#CDD6F4";
      bold-color = "#F38BA8";
      bold-color-same-as-fg = false;
      use-theme-colors = false;
      use-system-font = false;
      font = "JetBrainsMono Nerd Font 12";
      cursor-colors-set = true;
      cursor-background-color = "#CBA6F7";
      cursor-foreground-color = "#1E1E2E";
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

  xdg.mime.enable = lib.mkDefault true;
}
