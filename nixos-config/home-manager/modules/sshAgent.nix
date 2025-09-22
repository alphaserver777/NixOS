{ lib, pkgs, ... }:

let
  sshAgentBinary = lib.getExe' pkgs.openssh "ssh-agent";
  socketPath = "%t/ssh-agent";
  lifetime = "12h";

in
{
  services.ssh-agent.enable = true;

  # Force the shipped systemd unit to honour the desired lifetime
  systemd.user.services.ssh-agent.Service.ExecStart = lib.mkForce
    "${sshAgentBinary} -D -a ${socketPath} -t ${lifetime}";
}
