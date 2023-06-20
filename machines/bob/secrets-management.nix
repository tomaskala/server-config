{ config, lib, ... }:

{
  config.age.secrets = let
    makeSecret = name: {
      inherit name;
      value.file = "/root/secrets/${name}.age";
    };

    makeSystemdNetworkReadableSecret = name:
      lib.recursiveUpdate (makeSecret name) {
        value = {
          mode = "0640";
          owner = "root";
          group = "systemd-network";
        };
      };

    secrets = builtins.map makeSecret
      [ "users-tomas-password-${config.networking.hostName}" ];

    systemdNetworkReadableSecrets =
      builtins.map makeSystemdNetworkReadableSecret [
        "wg-${config.networking.hostName}-pk"
        "wg-${config.networking.hostName}2whitelodge-psk"
      ];
  in builtins.listToAttrs (secrets ++ systemdNetworkReadableSecrets);
}
