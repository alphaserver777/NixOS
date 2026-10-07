{ pkgs, lib, ... }:
let
  python = pkgs.python3.withPackages (p: [ p.pygobject3 p.pycairo ]);
  scripts = pkgs.runCommand "cosmic-control-center-scripts" { } ''
    mkdir -p $out
    cp ${./control-center.py} $out/control-center.py
    cp ${./control-center.css} $out/control-center.css
    cp ${./effects.py} $out/effects.py
  '';
  center = pkgs.writeShellApplication {
    name = "cosmic-control-center";
    runtimeInputs = [
      pkgs.hyprland pkgs.systemd pkgs.networkmanager pkgs.networkmanagerapplet
      pkgs.wireplumber pkgs.playerctl pkgs.pavucontrol pkgs.walker
    ];
    text = ''
      export GDK_BACKEND=wayland GDK_GL=disable GTK_THEME=Adwaita LC_TIME=C
      export GI_TYPELIB_PATH="${lib.makeSearchPathOutput "out" "lib/girepository-1.0" [ pkgs.gtk3 pkgs.gtk-layer-shell pkgs.pango pkgs.gdk-pixbuf pkgs.atk pkgs.glib pkgs.cairo pkgs.harfbuzz pkgs.gobject-introspection ]}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      exec ${python}/bin/python3 ${scripts}/control-center.py "$@"
    '';
  };
in {
  home.packages = [ center ];
  xdg.desktopEntries.cosmic-control-center = {
    name = "Центр управления";
    exec = "${center}/bin/cosmic-control-center";
    icon = "preferences-system";
    terminal = false;
    categories = [ "Settings" "Utility" ];
  };
}
