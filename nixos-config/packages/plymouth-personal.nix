{ lib, adi1090x-plymouth-themes, callPackage, python3 }:
let
  anurati = callPackage ./anurati.nix { };
  python = python3.withPackages (p: [ p.pillow ]);
  base = adi1090x-plymouth-themes.override { selected_themes = [ "black_hud" ]; };
in base.overrideAttrs (old: {
  pname = "plymouth-black-hud-personal";
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ python ];
  # Исходный installPhase не вызывает postInstall, поэтому дополняем его явно.
  installPhase = old.installPhase + ''
    theme="$out/share/plymouth/themes/black_hud"
    python3 ${./plymouth-signature.py} \
      ${anurati}/share/fonts/opentype/Anurati-Regular.otf "$theme/signature.png"
    python3 - "$theme/black_hud.script" ${./plymouth-signature.script} <<'PY'
    import pathlib, sys
    script, signature = map(pathlib.Path, sys.argv[1:])
    text = script.read_text()
    for marker in ("progress = 0;", "    progress++;"):
        if text.count(marker) != 1:
            raise SystemExit("Изменилась исходная тема Plymouth: " + marker)
    text = text.replace("progress = 0;", signature.read_text() + "\nprogress = 0;")
    text = text.replace("    progress++;", "    signature_refresh(progress);\n    progress++;")
    script.write_text(text)
    PY
    install -Dm644 \
      ${anurati}/share/licenses/anurati/Personal_use_only_read_this.rtf \
      "$out/share/licenses/plymouth-personal/Anurati.rtf"
  '';
  meta = old.meta // {
    description = "Black HUD с анимированной личной подписью";
    license = [ lib.licenses.gpl3 lib.licenses.unfree ];
  };
})
