{pkgs, ...}: {
  users.users.jager = {
    isNormalUser = true;
    description = "jager";
    home = "/home/jager";
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "video" "audio" "docker"];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
