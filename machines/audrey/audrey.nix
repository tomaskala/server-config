{ runCommand, identifyProfile, build }:

let
  profile = "mikrotik_routerboard-952ui-5ac2nd";
  profileCfg = identifyProfile profile;
in build (profileCfg // {
  packages = [
    "travelmate"
    "luci-app-travelmate"

    "qrencode"

    "kmod-wireguard"
    "luci-proto-wireguard"
    "wireguard-tools"
  ];

  files = runCommand "image-files" { } ''
    mkdir -p $out/etc/uci-defaults

    cat > $out/etc/uci-defaults/99-custom <<EOF
    uci set system.@system[0].hostname='audrey'
    uci commit
    EOF
  '';
})
