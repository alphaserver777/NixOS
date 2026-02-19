{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs: let
    system = "x86_64-linux";
    secretsPathEnv = builtins.getEnv "NIXOS_SECRETS_PATH";
    secretsPath =
      if secretsPathEnv != "" then secretsPathEnv
      else if builtins.pathExists ./secrets.nix then ./secrets.nix
      else null;
    secrets = if secretsPath == null then {} else import secretsPath;
  homeStateVersion = "25.05";
  user = "admsys";
  hosts = [
  { hostname = "Huawei"; stateVersion = "25.05"; }
  { hostname = "srv-home"; stateVersion = "25.05"; }
  { hostname = "x-disk"; stateVersion = "25.05"; }
  { hostname = "main"; stateVersion = "25.05"; }
  ];

  makeSystem = { hostname, stateVersion }: nixpkgs.lib.nixosSystem {
    system = system;
    specialArgs = {
      inherit inputs stateVersion hostname user secrets;
    };

    modules = [
      ./hosts/${hostname}/configuration.nix
    ];
  };

  in {
    nixosConfigurations = nixpkgs.lib.foldl' (configs: host:
        configs // {
        "${host.hostname}" = makeSystem {
        inherit (host) hostname stateVersion;
        };
        }) {} hosts;

    homeConfigurations = nixpkgs.lib.foldl' (configs: host:
      configs // {
        "${user}@${host.hostname}" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit inputs homeStateVersion user secrets;
            hostname = host.hostname;
          };

          modules = [
            sops-nix.homeManagerModules.sops
            ./home-manager/home.nix
          ];
        };
      }) {} hosts;
  };
}
