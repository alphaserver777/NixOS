{ lib, runCommand, stdenvNoCC, curl, python3, cacert, unzip }:
let
  # Автор размещает архив на MediaFire: адрес страницы постоянный,
  # ссылка скачивания меняется. Содержимое проверяется по SHA-256.
  archive = runCommand "anurati-font-personal-use-only.zip" {
    nativeBuildInputs = [ curl python3 ];
    CURL_CA_BUNDLE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-RGutbF+zTQsPJeAUQ5tvIY8j3F91d+LYZeLi2qOny0k=";
  } ''
    python3 ${./fetch-anurati.py} "$out"
  '';
in stdenvNoCC.mkDerivation {
  pname = "anurati";
  version = "1.0";
  src = archive;
  sourceRoot = "anurati_font";
  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 Anurati-Regular.otf $out/share/fonts/opentype/Anurati-Regular.otf
    install -Dm644 Personal_use_only_read_this.rtf $out/share/licenses/anurati/Personal_use_only_read_this.rtf
    runHook postInstall
  '';
  meta = {
    description = "Декоративный шрифт Anurati для личного использования";
    homepage = "https://troisieme-type.com/anurati-pro";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
