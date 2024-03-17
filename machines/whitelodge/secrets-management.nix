{ secrets, ... }:

{
  config.age.secrets = {
    users-tomas-password.file = "${secrets}/secrets/users/tomas-whitelodge.age";
    users-root-password.file = "${secrets}/secrets/users/root-whitelodge.age";
    miniflux-admin-credentials.file =
      "${secrets}/secrets/other/miniflux-whitelodge.age";
    postgresql-grafana-password.file =
      "${secrets}/secrets/other/postgresql-grafana.age";
    cloudflare-dns-challenge-api-tokens.file =
      "${secrets}/secrets/other/cloudflare-dns-challenge-api-tokens.age";

    radicale-htpasswd = {
      file = "${secrets}/secrets/other/radicale-htpasswd.age";
      mode = "0640";
      owner = "root";
      group = "radicale";
    };

    grafana-admin-password = {
      file = "${secrets}/secrets/other/grafana-admin.age";
      mode = "0640";
      owner = "root";
      group = "grafana";
    };

    wg-vpn-internal-pk = {
      file = "${secrets}/secrets/wg-pk/whitelodge-internal.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-vpn-isolated-pk = {
      file = "${secrets}/secrets/wg-pk/whitelodge-isolated.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-vpn-passthru-pk = {
      file = "${secrets}/secrets/wg-pk/whitelodge-passthru.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-bob2whitelodge = {
      file = "${secrets}/secrets/wg-psk/bob2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-cooper2whitelodge = {
      file = "${secrets}/secrets/wg-psk/cooper2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-tomas-phone2whitelodge = {
      file = "${secrets}/secrets/wg-psk/tomas-phone2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-blacklodge2whitelodge = {
      file = "${secrets}/secrets/wg-psk/blacklodge2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };

    wg-audrey2whitelodge = {
      file = "${secrets}/secrets/wg-psk/audrey2whitelodge.age";
      mode = "0640";
      owner = "root";
      group = "systemd-network";
    };
  };
}
