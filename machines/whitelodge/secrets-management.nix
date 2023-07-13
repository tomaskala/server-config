{
  config.age.secrets = {
    users-tomas-password-whitelodge.file =
      "/root/secrets/users/tomas-whitelodge.age";
    miniflux-admin-credentials.file =
      "/root/secrets/other/miniflux-whitelodge.age";
    postgresql-grafana-password.file =
      "/root/secrets/other/postgresql-grafana.age";

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
