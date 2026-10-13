{ lib, options, opencodePackage, user, ... }:

{
  # Задача 022: хосты без Home Manager получают тот же пользовательский
  # пакет. На остальных он приходит из общего home-packages.nix.
  users.users.${user}.packages = lib.mkIf (!(options ? home-manager)) [
    opencodePackage
  ];
}
