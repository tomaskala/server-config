{ secrets, ... }:

{
  config.age.secrets = {
    users-tomas-password.file = "${secrets}/secrets/users/tomas-bob.age";
    users-root-password.file = "${secrets}/secrets/users/root-bob.age";

    wg-pk = {
      file = "${secrets}/secrets/wg-pk/bob.age";
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
  };
}
