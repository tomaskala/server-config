{ lib, pkgs, secrets, ... }:

{
  homebrew = {
    masApps = { Slack = 803453959; };

    casks = [ "tunnelblick" "visual-studio-code" ];
  };

  age.secrets.work-ssh-config = {
    file = "${secrets}/secrets/other/gordon/work-ssh-config.age";
    path = "/Users/tomas/.ssh/config.d/work";
    owner = "tomas";
  };

  home-manager.users.tomas = {
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      git.includes = [{
        condition = "gitdir:~/IPFabric/";
        contents.user.email = "tomas.kala@ipfabric.io";
      }];

      neovim = {
        extraPackages = with pkgs; [
          biome
          nodePackages.typescript-language-server
        ];

        extraLuaConfig = lib.mkAfter ''
          do
            local lspconfig = require("lspconfig")
            lspconfig.biome.setup({})
            lspconfig.tsserver.setup({
              on_attach = function(client)
                -- We format using biome instead of the tsserver.
                client.server_capabilities.documentFormattingProvider = false
              end,
            })
          end
        '';
      };

      ssh.includes = [ "/Users/tomas/.ssh/config.d/work" ];
    };
  };
}
