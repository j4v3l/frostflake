{
  username = "jager";
  fullName = "jager";
  description = "jager";
  email = "jj4v3l@gmail.com";
  linuxHome = "/home/jager";
  darwinHome = "/Users/jager";
  shellPackage = pkgs: pkgs.zsh;
  extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "docker"
    "libvirtd"
    "dialout"
    "uucp"
    "plugdev"
  ];
  git = {
    name = "j4v3l";
    email = "jj4v3l@gmail.com";
  };

  security = {
    requireWebauthn = true;
    ssh = {
      hardwareKeys = [];
      softFallbackKeys = [];
      allowSoftFallback = false;
    };
  };
}
