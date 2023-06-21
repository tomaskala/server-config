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

    secrets = builtins.map makeSecret [
      "users-tomas-password-whitelodge"
      "miniflux-admin-credentials"
    ];

    systemdNetworkReadableSecrets =
      builtins.map makeSystemdNetworkReadableSecret [
        "wg-whitelodge-pk"
        "wg-bob2whitelodge-psk"
        "wg-tomas-phone2whitelodge-psk"
        "wg-martin-windows2whitelodge-psk"
        "wg-blacklodge2whitelodge-psk"
      ];
  in builtins.listToAttrs (secrets ++ systemdNetworkReadableSecrets);
}
