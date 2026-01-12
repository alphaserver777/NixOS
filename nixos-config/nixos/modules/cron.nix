{ pkgs, user, lib, hostname, secrets, ... }:

{
  services.cron = lib.mkIf (hostname == "x-disk") {
    enable = true;
    systemCronJobs = lib.optionals (secrets ? pingwin-cron-url) [
      "* * * * * ${user} ${pkgs.curl}/bin/curl --max-time 15 -fsS ${secrets.pingwin-cron-url} > /home/${user}/pingwin-curl.log 2>&1"
    ];
  };
}
