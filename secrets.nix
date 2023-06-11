let
  whitelodge = ""; # TODO: SSH host key.

  setKeys = keys: secrets:
    builtins.listToAttrs (builtins.map (secret: {
      name = secret;
      value.publicKeys = keys;
    }) secrets);
in setKeys [ whitelodge ] [
  # tomas@whitelodge password
  "users-tomas-password-whitelodge"
  # whitelodge WireGuard private key
  "wg-whitelodge-pk"
  # bob2whitelodge WireGuard preshared key
  "wg-bob2whitelodge-psk"
  # tomas-phone2whitelodge WireGuard preshared key
  "wg-tomas-phone2whitelodge-psk"
  # martin-windows2whitelodge WireGuard preshared key
  "wg-martin-windows2whitelodge-psk"
  # blacklodge2whitelodge WireGuard preshared key
  "wg-blacklodge2whitelodge-psk"
]
