{ config, inputs, lib, hostname, user, secrets, ... }: {
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = false;
    useUserPackages = true;
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit inputs hostname user secrets;
    };
    users.${user} = {
      imports = [ ../../home-manager/home.nix ];
      home.stateVersion = config.system.stateVersion;
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "rustdesk"
          "libsciter"
          "libsciter-4.4.8.23-bis"
        ];
    };
  };
}
