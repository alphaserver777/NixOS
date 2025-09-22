{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "25.05";
      user = "admsys";
      hosts = {
        Huawei.stateVersion = "25.05";
        "srv-home".stateVersion = "25.05";
        "x-disk".stateVersion = "25.05";
        main.stateVersion = "25.05";
      };

      makeSystem = hostname: hostCfg: nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs user;
          hostname = hostname;
          stateVersion = hostCfg.stateVersion;
        };

        modules = [
          ./hosts/${hostname}/configuration.nix
        ];
      };

    in
    {
      nixosConfigurations = nixpkgs.lib.mapAttrs makeSystem hosts;

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs homeStateVersion user;
        };

        modules = [
          ./home-manager/home.nix
        ];
      };
    };
}
