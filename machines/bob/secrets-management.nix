{
  config.age.secrets = {
    users-tomas-password.file = "/root/secrets/users/tomas-bob.age";

    wg-pk = {
      file = "/root/secrets/wg-pk/bob.age";
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
  };
}
