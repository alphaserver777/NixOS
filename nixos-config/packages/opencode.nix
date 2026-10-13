{ pkgs, upstream }:

let
  # В runtime передаём только содержимое нужных файлов: путь всего flake
  # не должен менять derivation при изменении документации.
  launcherSource = pkgs.writeText "opencode-launcher.sh" (builtins.readFile ./opencode-launcher.sh);
  initializer = pkgs.writeText "opencode-default.py" (
    builtins.readFile ../home-manager/modules/opencode-default.py
  );
  launcher = pkgs.replaceVars launcherSource {
    bash = "${pkgs.bash}/bin/bash";
    opencode = "${upstream}/bin/opencode";
    python = "${pkgs.python3}/bin/python3";
    inherit initializer;
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
