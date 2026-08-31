{ fetchurl, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  version = "1.1.22";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.22-5711547746615296/linux-x64/cli_linux_x64.tar.gz";
    hash = "sha512-QCJdSx8AlBLpBfCiNLo9UUhwONGtG4+hkzHIS+VWEKAfWwrZkW+4cRUcxFRWxrwwzAsepdq2wGFryPsmK83XqQ==";
  };

  unpackPhase = ''
    mkdir source
    tar -xzf "$src" -C source
  '';
  sourceRoot = "source";

  installPhase = ''
    install -Dm755 antigravity "$out/bin/agy"
  '';

  meta = {
    description = "Antigravity CLI from Google";
    mainProgram = "agy";
    platforms = [ "x86_64-linux" ];
  };
}
