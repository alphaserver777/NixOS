{ pkgs, lib, ... }:
let
  pcmanfmReveal = pkgs.writeShellApplication {
    name = "pcmanfm-reveal";
    runtimeInputs = [ pkgs.pcmanfm pkgs.python3Minimal pkgs.dbus ];
    text = ''
      set -eu

      decode_uri() {
        python3 - "$1" <<'PY'
import sys
import urllib.parse

uri = sys.argv[1]
uri = uri[7:] if uri.startswith("file://") else uri
if uri.startswith("localhost/"):
    uri = "/" + uri[len("localhost/"):]
uri = uri.split("?", 1)[0]
uri = uri.split("#", 1)[0]
sys.stdout.write(urllib.parse.unquote(uri))
PY
      }

      path_to_uri() {
        python3 - "$1" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1]).resolve()
sys.stdout.write(path.as_uri())
PY
      }

      show_via_dbus() {
        local uri="$1"
        dbus-send --session --dest=org.freedesktop.FileManager1 \
          --type=method_call /org/freedesktop/FileManager1 \
          org.freedesktop.FileManager1.ShowItems \
          array:string:"$uri" string:"" >/dev/null 2>&1
      }

      open_target() {
        local path="$1"
        if [ -d "$path" ]; then
          exec pcmanfm --new-window "$path"
        else
          local parent
          parent=$(dirname "$path")
          exec pcmanfm --new-window "$parent"
        fi
      }

      main() {
        if [ "$#" -eq 0 ]; then
          exec pcmanfm
        fi

        for arg in "$@"; do
          if [ -z "$arg" ]; then
            continue
          fi

          local target=""
          case "$arg" in
            file://*)
              target=$(decode_uri "$arg")
              ;;
            /*)
              target="$arg"
              ;;
            *)
              target="$PWD/$arg"
              ;;
          esac

          if [ -e "$target" ]; then
            if [ -f "$target" ]; then
              local uri
              uri=$(path_to_uri "$target")
              if show_via_dbus "$uri"; then
                exit 0
              fi
            fi
            open_target "$target"
          fi
        done

        exec pcmanfm "$@"
      }

      main "$@"
    '';
  };

  desktopEntry = {
    name = "PCManFM (Select)";
    exec = "pcmanfm-reveal %u";
    icon = "system-file-manager";
    terminal = false;
    type = "Application";
    mimeType = [
      "inode/directory"
      "application/x-directory"
    ];
  };

  defaults = {
    "inode/directory" = [ "pcmanfm-reveal.desktop" ];
    "application/x-directory" = [ "pcmanfm-reveal.desktop" ];
    "x-scheme-handler/file" = [ "pcmanfm-reveal.desktop" ];
  };

in {
  home.packages = [ pcmanfmReveal ];

  xdg.desktopEntries."pcmanfm-reveal" = desktopEntry;

  xdg.mimeApps.defaultApplications = defaults;

  xdg.mimeApps.associations.added = defaults;
}
