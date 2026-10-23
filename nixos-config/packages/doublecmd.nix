{ lib, symlinkJoin, makeWrapper, doublecmd, libssh2 }:

# Задача 032: ftp.wfx загружает библиотеку по имени во время работы.
# Используем готовый Double Commander и библиотеки того же nixpkgs.
symlinkJoin {
  name = "doublecmd-${doublecmd.version}";
  paths = [ doublecmd ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/doublecmd" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libssh2 ]}
  '';
  inherit (doublecmd) meta;
}
