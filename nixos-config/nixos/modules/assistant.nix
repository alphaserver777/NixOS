{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../packages/assistant.nix { })
  ];
}
