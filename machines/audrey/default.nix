{ pkgs, openwrt-imagebuilder }:

let
  profile = "mikrotik_routerboard-952ui-5ac2nd";
  profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; };
  profileCfg = profiles.identifyProfile profile;
in openwrt-imagebuilder.lib.build (profileCfg // {
  packages = [
    "travelmate"
    "luci-app-travelmate"

    "qrencode"

    "kmod-wireguard"
    "luci-proto-wireguard"
    "wireguard-tools"
  ];

  files = pkgs.runCommand "image-files" { } ''
    mkdir -p $out/etc/uci-defaults

    cat > $out/etc/uci-defaults/99-custom <<EOF
    uci set system.@system[0].hostname='audrey'
    uci commit
    EOF
  '';
})
