{ lib, runCommand, python3, orbitron }:
let
  python = python3.withPackages (p: [ p.fonttools p.skia-pathops ]);
in runCommand "cosmic-stencil-1.0" {
  nativeBuildInputs = [ python ];
  meta = {
    description = "Космические цифры с диагональными прорезями";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
} ''
  python3 ${./build-cosmic-stencil.py} \
    "${orbitron}/share/fonts/truetype/Orbitron Bold.ttf" \
    "$out/share/fonts/truetype/CosmicStencil-Bold.ttf"
  install -Dm644 "${orbitron.src}/Open Font License.markdown" \
    "$out/share/licenses/cosmic-stencil/OFL.md"
''
