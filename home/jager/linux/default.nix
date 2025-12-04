{lib, ...}: {
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
  };

  xdg.mime.enable = lib.mkDefault true;
}
