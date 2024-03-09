let
  whitelodge =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqZXcy8lb24LirRJ4X77olNBGZkSnB6EGHwXF3MYbi8";

  bob =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIEQcZR1q25+ZASKxM2L0xuTZu2w9zQ25lIySG08n4/Q";
in {
  # Users
  "secrets/users/tomas-whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/users/root-whitelodge.age".publicKeys = [ whitelodge ];

  "secrets/users/tomas-bob.age".publicKeys = [ bob ];
  "secrets/users/root-bob.age".publicKeys = [ bob ];

  # WireGuard private keys
  "secrets/wg-pk/whitelodge-internal.age".publicKeys = [ whitelodge ];
  "secrets/wg-pk/whitelodge-isolated.age".publicKeys = [ whitelodge ];
  "secrets/wg-pk/whitelodge-passthru.age".publicKeys = [ whitelodge ];
  "secrets/wg-pk/bob.age".publicKeys = [ bob ];

  # WireGuard preshared keys
  "secrets/wg-psk/bob2whitelodge.age".publicKeys = [ bob whitelodge ];
  "secrets/wg-psk/cooper2whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-psk/tomas-phone2whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-psk/blacklodge2whitelodge.age".publicKeys = [ whitelodge ];
  "secrets/wg-psk/audrey2whitelodge.age".publicKeys = [ whitelodge ];

  # Other

  # miniflux admin credentials of the following form (password length >= 6)
  # ADMIN_USERNAME=admin username
  # ADMIN_PASSWORD=correct horse battery staple
  "secrets/other/miniflux-whitelodge.age".publicKeys = [ whitelodge ];

  # grafana user in PostgreSQL password
  "secrets/other/postgresql-grafana.age".publicKeys = [ whitelodge ];

  # grafana admin password
  "secrets/other/grafana-admin.age".publicKeys = [ whitelodge ];

  # radicale htpasswd of the following form
  # user1:password1
  # user2:password2
  "secrets/other/radicale-htpasswd.age".publicKeys = [ whitelodge ];

  # Cloudflare API tokens passed to the lego ACME client
  # CLOUDFLARE_ZONE_API_TOKEN=<zone-read-token>
  # CLOUDFLARE_DNS_API_TOKEN=<dns-edit-token>
  "secrets/other/cloudflare-dns-challenge-api-tokens.age".publicKeys =
    [ whitelodge ];
}
