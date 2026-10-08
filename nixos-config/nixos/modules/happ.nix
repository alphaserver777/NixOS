{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.callPackage ../../packages/happ.nix { })
  ];
}
