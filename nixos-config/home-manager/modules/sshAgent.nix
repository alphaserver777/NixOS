{ pkgs, lib, ... }:
let
  # Задача 030: приложения рабочего стола могут не получить SSH_AUTH_SOCK.
  # Существующий адрес, в том числе переданный по SSH, имеет приоритет.
  clientConfig = pkgs.writeText "ssh-agent-client.conf" ''
    Match exec "test -z \"$SSH_AUTH_SOCK\" && test -S /run/user/%i/ssh-agent"
      IdentityAgent /run/user/%i/ssh-agent
    Match all
  '';
  setup = pkgs.writeShellScript "ssh-agent-client-setup" ''
    exec ${pkgs.python3}/bin/python3 ${./ssh-agent-config.py} ${clientConfig}
  '';
in {
  services.ssh-agent.enable = true;
  # Основной файл остаётся изменяемым: LazySSH добавляет в него серверы.
  home.activation.sshAgentClientConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${setup}
  '';
}
