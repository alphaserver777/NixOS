{ pkgs, ... }:
let
  rustdeskX11 = pkgs.writeShellScriptBin "rustdesk-x11" ''
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    unset WAYLAND_DISPLAY
    unset NIXOS_OZONE_WL
    exec ${pkgs.rustdesk}/bin/rustdesk "$@"
  '';
in {
  home.packages = [
    pkgs.rustdesk
    rustdeskX11
  ];

  home.file.".local/share/applications/rustdesk-x11.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=RustDesk (X11)
    GenericName=Remote Desktop
    Exec=${rustdeskX11}/bin/rustdesk-x11
    Icon=rustdesk
    Terminal=false
    Categories=Network;RemoteAccess;
  '';
}
