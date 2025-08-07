{ homeStateVersion, user, ... }: {
  imports = [
    ./modules
    ./home-packages.nix
  ];

  home = {
    username = admsys;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };
}
