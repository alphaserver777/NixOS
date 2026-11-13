{ lib, stdenvNoCC, fetchFromGitHub, python3 }:
stdenvNoCC.mkDerivation {
  pname = "zsh-easy-motion";
  version = "0-unstable-2026-11-13";
  src = fetchFromGitHub {
    owner = "IngoMeyer441";
    repo = "zsh-easy-motion";
    rev = "61f470554f5ef9d18406804d009a87a12e49fac7";
    hash = "sha256-4PonI5ZY7WZuIoLpVcqP5tFSvFfOfVQSX221GZTzvKc=";
  };
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm444 easy_motion.plugin.zsh "$out/share/zsh-easy-motion/easy_motion.plugin.zsh"
    install -Dm755 easy_motion.py "$out/share/zsh-easy-motion/easy_motion.py"
    # Задача 054: целый символ UTF-8 и сохранение быстро введённых клавиш.
    substituteInPlace "$out/share/zsh-easy-motion/easy_motion.py" \
      --replace-fail '#!/usr/bin/env python' '#!${python3}/bin/python3' \
      --replace-fail 'os.read(fd, 80)[:1].decode("ascii")' 'sys.stdin.read(1)'
    runHook postInstall
  '';
  meta = {
    description = "Переходы по буквенным меткам в командной строке Zsh";
    homepage = "https://github.com/IngoMeyer441/zsh-easy-motion";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
