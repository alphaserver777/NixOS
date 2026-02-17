{ lib, hostname, ... }:

{
  config = lib.mkIf (hostname == "x-disk") {
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        # Forward only important events from x-disk to Germany via TCP.

        # auth/authpriv warning and above
        if ((($syslogfacility-text == "auth") or ($syslogfacility-text == "authpriv")) and ($syslogseverity <= 4)) then {
          action(type="omfwd"
            target="64.188.64.23"
            port="514"
            protocol="tcp"
            action.resumeRetryCount="-1"
            queue.type="linkedList"
            queue.filename="fwd-germany-auth")
        }

        # kernel warning and above
        if (($syslogfacility-text == "kern") and ($syslogseverity <= 4)) then {
          action(type="omfwd"
            target="64.188.64.23"
            port="514"
            protocol="tcp"
            action.resumeRetryCount="-1"
            queue.type="linkedList"
            queue.filename="fwd-germany-kern")
        }

        # global critical/alert/emergency
        if ($syslogseverity <= 2) then {
          action(type="omfwd"
            target="64.188.64.23"
            port="514"
            protocol="tcp"
            action.resumeRetryCount="-1"
            queue.type="linkedList"
            queue.filename="fwd-germany-crit")
        }
      '';
    };
  };
}
