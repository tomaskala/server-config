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

    secrets = builtins.map makeSecret [ "users-tomas-password" ];

    systemdNetworkReadableSecrets =
      builtins.map makeSystemdNetworkReadableSecret [
        "wg-server-pk"
        "wg-home-psk"
        "wg-tomas-phone-psk"
        "wg-martin-windows-psk"
        "wg-tomas-home-psk"
      ];
  in builtins.listToAttrs (secrets ++ systemdNetworkReadableSecrets);
}
