{
  jagerPublicKey,
  frostflakeUser,
}: {lib, ...}: let
  vmName = "frostflake-builder-aurora";
  vmUser = frostflakeUser.username;
  hostName = "builder-aurora";
  forwardPort = 3122;
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
          networking.hostName = hostName;
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
                id = "fma-user";
                type = "user";
                mac = "02:00:00:00:ab:01";
              }
            ];
            forwardPorts = [
              {
                from = "host";
                host.port = forwardPort;
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
