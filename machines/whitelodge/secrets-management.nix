{
  config.age.secrets = {
    users-tomas-password.file = "/root/secrets/users/tomas-whitelodge.age";
    users-root-password.file = "/root/secrets/users/root-whitelodge.age";
    miniflux-admin-credentials.file =
      "/root/secrets/other/miniflux-whitelodge.age";
    postgresql-grafana-password.file =
      "/root/secrets/other/postgresql-grafana.age";
    cloudflare-dns-challenge-api-tokens.file =
      "/root/secrets/other/cloudflare-dns-challenge-api-tokens.age";

    radicale-htpasswd = {
      file = "/root/secrets/other/radicale-htpasswd.age";
      mode = "0640";
      owner = "root";
      group = "radicale";
    };

    grafana-admin-password = {
      file = "/root/secrets/other/grafana-admin.age";
      mode = "0640";
      owner = "root";
      group = "grafana";
    };

    wg-pk = {
      file = "/root/secrets/wg-pk/whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-bob2whitelodge = {
      file = "/root/secrets/wg-psk/bob2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-cooper2whitelodge = {
      file = "/root/secrets/wg-psk/cooper2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-tomas-phone2whitelodge = {
      file = "/root/secrets/wg-psk/tomas-phone2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-blacklodge2whitelodge = {
      file = "/root/secrets/wg-psk/blacklodge2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-martin-windows2whitelodge = {
      file = "/root/secrets/wg-psk/martin-windows2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };
  };
}
