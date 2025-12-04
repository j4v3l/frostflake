{
  pkgs,
  lib,
  ...
}: {
  services = {
    xserver = {
      enable = true;
      videoDrivers = lib.mkDefault ["modesetting"];
      xkb.layout = "us";
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      autoLogin.enable = false;
    };
    desktopManager.gnome.enable = true;
    gnome.gnome-keyring.enable = true;
    flatpak.enable = true;
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };
}
