{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.hiddify-app ];
}
