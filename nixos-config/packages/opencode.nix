{ pkgs, upstream }:

let
  launcher = pkgs.replaceVars ./opencode-launcher.sh {
    bash = "${pkgs.bash}/bin/bash";
    opencode = "${upstream}/bin/opencode";
    python = "${pkgs.python3}/bin/python3";
    initializer = ../home-manager/modules/opencode-default.py;
    coreutils = "${pkgs.coreutils}/bin";
  };
in
pkgs.symlinkJoin {
  name = "opencode-${upstream.version}";
  pname = "opencode";
  inherit (upstream) version meta;
  paths = [ upstream ];
  postBuild = ''
    rm "$out/bin/opencode"
    install -m755 ${launcher} "$out/bin/opencode"
  '';
}
