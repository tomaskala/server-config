{ pkgs, ... }:

{
  programs.openvpn3.enable = true;

  environment.systemPackages = with pkgs; [
    python3
    poetry

    biome
    nodejs_18
    typescript
    yarn

    slack
    teams
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.tomas = {
    programs.vscode = {
      enable = true;
      enableExtensionUpdateCheck = true;
      enableUpdateCheck = true;

      extensions = with pkgs.vscode-extensions; [
        eamodio.gitlens
        vscodevim.vim
      ];

      userSettings = {
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.settings.enableNaturalLanguageSearch" = false;

        "vim.hlsearch" = true;
        "vim.joinspaces" = false;
        "vim.leader" = ",";
        "vim.useSystemClipboard" = true;

        "files.enableTrash" = false;
        "telemetry.telemetryLevel" = "off";

        "editor.lineNumbers" = "relative";
        "editor.tabSize" = 2;

        "javascript.format.insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces" =
          false;
        "[typescript]" = { "editor.defaultFormatter" = "biomejs.biome"; };

        "accessibility.signals.progress" = { "sound" = "off"; };
      };
    };
  };
}
