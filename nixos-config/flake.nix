{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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

    opencode.url = "git+https://github.com/anomalyco/opencode";

    };

  outputs = { self, nixpkgs, home-manager, sops-nix, opencode, ... }@inputs: let
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
  { hostname = "srv-home-gui"; stateVersion = "25.05"; }
  { hostname = "srv-home-min"; stateVersion = "25.05"; }
  { hostname = "x-disk"; stateVersion = "25.05"; }
  { hostname = "main"; stateVersion = "25.05"; }
  ];

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  opencodePackage = opencode.packages.${system}.default;

  makeSystem = { hostname, stateVersion }: nixpkgs.lib.nixosSystem {
    system = system;
    specialArgs = {
      inherit inputs stateVersion homeStateVersion hostname user secrets pkgs-unstable opencodePackage;
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
            { home.stateVersion = homeStateVersion; }
          ];
        };
      }) {} hosts;
  };
}
