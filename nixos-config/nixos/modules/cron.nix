{ pkgs, user, ... }:

{
  services.cron = {
    enable = true;
    systemCronJobs = [
      "* * * * * ${user} ${pkgs.curl}/bin/curl -fsS https://pingwin.work/api/v1/task/eef077c9-0d80-4f05-9ce0-fc3db5b9247e/handle > /home/${user}/pingwin-curl.log 2>&1"
    ];
  };
}
