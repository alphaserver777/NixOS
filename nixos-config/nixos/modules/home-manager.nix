{ config, inputs, hostname, user, secrets, ... }: {
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit inputs hostname user secrets;
    };
    users.${user} = {
      imports = [ ../../home-manager/home.nix ];
      home.stateVersion = config.system.stateVersion;
    };
  };
}
