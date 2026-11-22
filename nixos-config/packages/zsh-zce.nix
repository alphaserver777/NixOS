{ lib, stdenvNoCC, fetchFromGitHub }:
stdenvNoCC.mkDerivation {
  pname = "zsh-zce";
  version = "0-unstable-2025-03-15";
  src = fetchFromGitHub {
    owner = "hchbaw";
    repo = "zce.zsh";
    rev = "ee71bfaf5c4d26266404d26b5429bd102c780b0d";
    hash = "sha256-CijCINFhcnuuOO9aSrmCyLTEHMMUedn+uH/Zhm2lB6w=";
  };
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm444 zce.zsh "$out/share/zsh-zce/zce.zsh"
    install -Dm444 COPYING "$out/share/licenses/zsh-zce/COPYING"
    runHook postInstall
  '';
  meta = {
    description = "Переходы по буквенным меткам в командной строке Zsh";
    homepage = "https://github.com/hchbaw/zce.zsh";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
  };
}
