{ pkgs, lib, ... }:
let
  sshAgentLifetimeSeconds = toString (12 * 60 * 60);
in {
  services.ssh-agent.enable = true;

  # Override the default ExecStart to keep keys for 12h, matching the old agentTimeout.
  systemd.user.services.ssh-agent.Service.ExecStart =
    lib.mkForce "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent -t ${sshAgentLifetimeSeconds}";
}
