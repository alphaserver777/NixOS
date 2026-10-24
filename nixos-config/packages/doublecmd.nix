{ lib, symlinkJoin, makeWrapper, doublecmd, libssh2 }:

# Задача 032: ftp.wfx загружает библиотеку по имени во время работы.
# Используем готовый Double Commander и библиотеки того же nixpkgs.
# Задача 033: без переданного адреса используем существующий локальный агент.
symlinkJoin {
  name = "doublecmd-${doublecmd.version}";
  paths = [ doublecmd ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/doublecmd" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libssh2 ]} \
      --run 'if [[ -z "''${SSH_AUTH_SOCK:-}" ]]; then
        doublecmd_agent_socket="''${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent"
        if [[ -S "$doublecmd_agent_socket" ]]; then
          export SSH_AUTH_SOCK="$doublecmd_agent_socket"
        fi
      fi'
  '';
  inherit (doublecmd) meta;
}
