let
  whitelodge = ""; # TODO: SSH host key.

  setKeys = keys: secrets:
    builtins.listToAttrs (builtins.map (secret: {
      name = secret;
      value.publicKeys = keys;
    }) secrets);
in setKeys [ whitelodge ] [
  "users-tomas-password"
  "wg-server-pk"
  "wg-home-psk"
  "wg-tomas-laptop-psk"
  "wg-tomas-phone-psk"
  "wg-martin-windows-psk"
  "wg-tomas-home-psk"
]
