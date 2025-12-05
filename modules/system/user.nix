{
  pkgs,
  frostflakeUser,
  ...
}: let
  user = frostflakeUser;
  shellPackage = user.shellPackage pkgs;
  groups = user.extraGroups or [];
  description = user.description or user.fullName or user.username;
  homeDir = user.linuxHome or "/home/${user.username}";
in {
  users.users.${user.username} = {
    isNormalUser = true;
    inherit description;
    home = homeDir;
    shell = shellPackage;
    extraGroups = groups;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
