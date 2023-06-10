let
  whitelodge = ""; # TODO: SSH host key.

  setKeys = keys: secrets:
    builtins.listToAttrs (builtins.map (secret: {
      name = secret;
      value.publicKeys = keys;
    }) secrets);
in setKeys [ whitelodge ] [
  "whitelodge-users-tomas-password"
  "whitelodge-wg-server-pk"
  "whitelodge-wg-home-psk"
  "whitelodge-wg-tomas-laptop-psk"
  "whitelodge-wg-tomas-phone-psk"
  "whitelodge-wg-martin-windows-psk"
  "whitelodge-wg-tomas-home-psk"
]
