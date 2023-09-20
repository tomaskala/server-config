{
  age.secrets = {
    users-tomas-password.file = "/root/secrets/users/tomas-cooper.age";

    wg-pk = {
      file = "/root/secrets/wg-pk/cooper.age";
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
  };

  environment.persistence."/persistent".directories = [ "/root/secrets" ];
}
