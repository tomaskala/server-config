{ config, pkgs, ... }:

let
  inherit (pkgs) infra;
  intranetCfg = config.infra.intranet;
in
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    serverAliveInterval = 60;

    extraConfig = # sshconfig
      ''
        IgnoreUnknown UseKeychain
        UseKeychain yes
      '';

    matchBlocks = {
      "github.com" = {
        user = "tomaskala";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_github";
      };

      whitelodge = {
        user = "tomas";
        hostname = infra.ipAddress intranetCfg.devices.whitelodge.wireguard.internal.ipv4;
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_whitelodge";
      };

      whitelodge-git = {
        user = "git";
        hostname = infra.ipAddress intranetCfg.devices.whitelodge.wireguard.internal.ipv4;
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_whitelodge_git";
      };

      bob = {
        user = "tomas";
        hostname = infra.ipAddress intranetCfg.devices.bob.external.lan.ipv4;
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_bob";
      };

      seedbox = {
        user = "return9826";
        hostname = "nexus.usbx.me";
        identitiesOnly = true;
        identityFile = "~/.ssh/id_ed25519_seedbox";
      };
    };
  };
}
