{ pkgs, ... }:

{
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    excludePackages = with pkgs; [
      nixos-icons
      xorg.iceauth
      xorg.xauth
      xorg.xinput
      xorg.xlsclients
      xorg.xrdb
      xorg.xset
      xorg.xsetroot
      xterm
    ];

    serverFlagsSection = ''
      Option "DontVTSwitch" "True"
      Option "DontZap" "True"
      Option "NoBeep" "True"
    '';

    libinput.touchpad = {
      tapping = true;
      naturalScrolling = true;
    };

    displayManager.startx.enable = true;
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        arandr
        dunst
        feh
        i3lock
        i3status
        libnotify
        maim
        st
        xclip
      ];
    };
  };

  environment.persistence."/persistent".users.tomas = {
    directories = [ ".config/dunst" ".config/i3" ".config/i3status" ];

    files = [ ".config/xinitrc" ];
  };
}
