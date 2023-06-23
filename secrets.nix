let
  whitelodge =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqZXcy8lb24LirRJ4X77olNBGZkSnB6EGHwXF3MYbi8";

  bob = ""; # TODO
in {
  # Users
  "users-tomas-password-whitelodge.age".publicKeys = [ whitelodge ];
  "users-tomas-password-bob.age".publicKeys = [ bob ];

  # WireGuard private keys
  "wg-whitelodge-pk.age".publicKeys = [ whitelodge ];
  "wg-bob-pk.age".publicKeys = [ bob ];

  # WireGuard preshared keys
  "wg-tomas-phone2whitelodge-psk.age".publicKeys = [ whitelodge ];
  "wg-martin-windows2whitelodge-psk.age".publicKeys = [ whitelodge ];
  "wg-blacklodge2whitelodge-psk.age".publicKeys = [ whitelodge ];
  "wg-bob2whitelodge-psk.age".publicKeys = [ bob whitelodge ];

  # Other
  # miniflux admin credentials of the following form (password length >= 6)
  # ADMIN_USERNAME=admin username
  # ADMIN_PASSWORD=correct horse battery staple
  "miniflux-admin-credentials.age".publicKeys = [ whitelodge ];
}
