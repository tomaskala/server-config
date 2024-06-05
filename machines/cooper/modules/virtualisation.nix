{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ kind qemu ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
