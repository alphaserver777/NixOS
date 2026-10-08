{ pkgs, ... }:
let
  launcher = pkgs.writeShellScript "flameshot-all-screens" ''
    exec ${pkgs.python3}/bin/python3 ${./flameshot-launch.py} \
      --flameshot ${pkgs.flameshot}/bin/flameshot \
      --hyprctl ${pkgs.hyprland}/bin/hyprctl -- "$@"
  '';
  flameshotAllScreens = pkgs.symlinkJoin {
    name = "flameshot-all-screens";
    meta.mainProgram = "flameshot";
    paths = [ pkgs.flameshot ];
    postBuild = ''
      unlink "$out/bin/flameshot"
      ln -s ${launcher} "$out/bin/flameshot"
    '';
  };
in
{
  services.flameshot = {
    enable = true;
    package = flameshotAllScreens;
    settings = {
      General = {
        disabledGrimWarning = true;
        useGrimAdapter = true;
      };
    };
  };
  systemd.user.services.flameshot.Service.Environment = [ "QT_QPA_PLATFORM=wayland" ];
}
