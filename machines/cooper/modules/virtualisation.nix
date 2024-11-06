{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.qemu ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
