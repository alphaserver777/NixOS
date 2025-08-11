{ homeStateVersion, user, ... }: {
  imports = [
    ./modules
    ./home-packages.nix
    inputs.astronix.homeModules.default
  ];

  home = {
    username = admsys;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };
}
