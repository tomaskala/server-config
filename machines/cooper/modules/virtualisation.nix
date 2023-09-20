{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [ kind qemu ];

    persistence."/persistent" = {
      directories = [ "/var/lib/containers" ];
      users.tomas.directories = [ ".local/share/containers" "VMs" ];
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
