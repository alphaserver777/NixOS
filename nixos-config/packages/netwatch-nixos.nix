{ pkgs, upstream }:

pkgs.symlinkJoin {
  name = "netwatch-${upstream.version}";
  pname = "netwatch";
  inherit (upstream) version meta;
  paths = [ upstream ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/netwatch" \
      --add-flags "--no-sandbox" \
      --prefix PATH : ${pkgs.iproute2}/bin
  '';
}
