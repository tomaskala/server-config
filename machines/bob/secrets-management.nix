{ config, ... }:

{
  config.age.secrets = let
    makeSecret = name: {
      inherit name;
      value.file = "/root/secrets/${name}.age";
    };

    secrets = builtins.map makeSecret
      [ "users-tomas-password-${config.networking.hostName}" ];
  in builtins.listToAttrs secrets;
}
