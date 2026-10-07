{ lib, rustPlatform, fetchzip, pkg-config, cmake, makeWrapper
, wayland, wayland-protocols, libGL, libxkbcommon, mesa }:
rustPlatform.buildRustPackage {
  pname = "hyprsaver";
  version = "0.4.7";
  src = fetchzip {
    url = "https://codeload.github.com/maravexa/hyprsaver/tar.gz/31f8a1da60df85ef574afbf2d911c53a0e7297a6";
    extension = "tar.gz";
    hash = "sha256-Wt3msO/uTrfnzZ6yZdTlepqA2Bjx4Pi3jsoWUoQn1Qw=";
  };
  cargoLock.lockFile = ./hyprsaver-Cargo.lock;
  nativeBuildInputs = [ pkg-config cmake makeWrapper ];
  buildInputs = [ wayland wayland-protocols libGL libxkbcommon mesa ];
  postInstall = ''
    install -Dm644 shaders/starfield.frag $out/share/hyprsaver/starfield.frag
    install -Dm644 LICENSE $out/share/licenses/hyprsaver/LICENSE
    wrapProgram $out/bin/hyprsaver \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland libGL libxkbcommon mesa ]} \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
  '';
  meta = {
    description = "Заставка для Hyprland на всех подключённых экранах";
    homepage = "https://github.com/maravexa/hyprsaver";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "hyprsaver";
  };
}
