{
  jagerPublicKey,
  frostflakeUser,
}: {lib, ...}: let
  vmName = "frostflake-builder";
  vmUser = frostflakeUser.username;
  storeShare = {
    source = "/nix/store";
    mountPoint = "/nix/.ro-store";
    tag = "ro-store";
    proto = "virtiofs";
    readOnly = true;
  };
in {
  microvm = {
    host.enable = true;
    autostart = [vmName];
    vms = {
      ${vmName} = {
        autostart = true;
        config = {
          networking.hostName = "builder-microvm";
          system.stateVersion = lib.mkDefault "25.11";

          services.openssh = {
            enable = true;
            permitRootLogin = "prohibit-password";
            passwordAuthentication = false;
          };

          users.users.${vmUser} = {
            isNormalUser = true;
            extraGroups = ["wheel"];
            openssh.authorizedKeys.keys = [jagerPublicKey];
          };

          microvm = {
            mem = 3072;
            vcpu = 2;
            interfaces = [
              {
                id = "fmb-user";
                type = "user";
                mac = "02:00:00:00:aa:01";
              }
            ];
            forwardPorts = [
              {
                from = "host";
                host.port = 3022;
                guest.port = 22;
              }
            ];
            shares = [storeShare];
          };
        };
      };
    };
  };
}
