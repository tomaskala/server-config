let
  whitelodge =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqZXcy8lb24LirRJ4X77olNBGZkSnB6EGHwXF3MYbi8";

  bob = ""; # TODO

  setKeys = keys: secrets:
    builtins.listToAttrs (builtins.map (secret: {
      name = secret;
      value.publicKeys = keys;
    }) secrets);
in (setKeys [ whitelodge ] [
  # tomas@whitelodge password
  "users-tomas-password-whitelodge"
  # miniflux admin credentials of the following form (password length >= 6)
  # ADMIN_USERNAME=admin username
  # ADMIN_PASSWORD=correct horse battery staple
  "miniflux-admin-credentials"
  # whitelodge WireGuard private key
  "wg-whitelodge-pk"
  # tomas-phone2whitelodge WireGuard preshared key
  "wg-tomas-phone2whitelodge-psk"
  # martin-windows2whitelodge WireGuard preshared key
  "wg-martin-windows2whitelodge-psk"
  # blacklodge2whitelodge WireGuard preshared key
  "wg-blacklodge2whitelodge-psk"
]) // (setKeys [ bob ] [
  # tomas@bob password
  "users-tomas-password-bob"
  # bob WireGuard private key
  "wg-bob-pk"
]) // (setKeys [ whitelodge bob ] [
  # bob2whitelodge WireGuard preshared key
  "wg-bob2whitelodge-psk"
])
