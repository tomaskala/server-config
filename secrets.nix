let
  whitelodge =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqZXcy8lb24LirRJ4X77olNBGZkSnB6EGHwXF3MYbi8";

  bob = ""; # TODO
in {
  # Users
  "secrets/users/tomas-whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/users/tomas-bob.age".publicKeys = [ bob ];

  # WireGuard private keys
  "secrets/wg-pk/whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-pk/bob.age".publicKeys = [ bob ];

  # WireGuard preshared keys
  "secrets/wg-psk/bob2whitelodge.age".publicKeys = [ bob whitelodge ];
  "secrets/wg-psk/tomas-phone2whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-psk/blacklodge2whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-psk/martin-windows2whitelodge.age".publicKeys = [ whitelodge ];

  # Other
  # miniflux admin credentials of the following form (password length >= 6)
  # ADMIN_USERNAME=admin username
  # ADMIN_PASSWORD=correct horse battery staple
  "secrets/other/miniflux-whitelodge.age".publicKeys = [ whitelodge ];
}
