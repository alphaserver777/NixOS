{ pkgs, ... }:
let
  calendar = pkgs.callPackage ../../../packages/dankcalendar.nix { };
  source = pkgs.fetchFromGitHub {
    owner = "luckjokerwang";
    repo = "dms-dankcalendar";
    rev = "3a42fb0c0551191376c1d27e2fc5b434e8acc709";
    hash = "sha256-TBVJCFxfumYV533FSNzEbBCSRZ5Jc+T0P+z1IwBe2RI=";
  };
  plugin = pkgs.runCommand "dank-calendar-plus-3.4.0" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p "$out"
    cp -r ${source}/. "$out/"
    chmod -R u+w "$out"
    patchShebangs "$out"
  '';
  setup = pkgs.writeShellApplication {
    name = "cosmic-calendar-setup";
    runtimeInputs = [ pkgs.python3 calendar ];
    text = ''exec python3 ${./calendar-initialize.py} "$@"'';
  };
in {
  home.packages = [ calendar pkgs.jq ];
  xdg.configFile."DankMaterialShell/plugins/DankCalendarPlus".source = plugin;
  systemd.user.services.dankcalendar = {
    Unit = {
      Description = "Календарь и звуковые напоминания";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${setup}/bin/cosmic-calendar-setup settings";
      ExecStart = "${calendar}/bin/dcal run --session --hidden";
      ExecStartPost = "${setup}/bin/cosmic-calendar-setup events";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
