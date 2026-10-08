{ pkgs, ... }:

{
  # Allows generic Linux binaries bundled by editor extensions to run on NixOS.
  # Claude Code for VS Code ships a dynamically linked native binary.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };
}
