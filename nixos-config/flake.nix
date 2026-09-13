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
  antigravityCliPackage = pkgs-unstable.callPackage ./packages/antigravity-cli.nix { };

  makeSystem = { hostname, stateVersion }: nixpkgs.lib.nixosSystem {
    system = system;
    specialArgs = {
      inherit inputs stateVersion homeStateVersion hostname user secrets pkgs-unstable opencodePackage antigravityCliPackage;
    };

    modules = [
      ./hosts/${hostname}/configuration.nix
    ];
  };

  in {
    packages.${system}.harness-agent =
      nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "harness-agent";
        runtimeInputs = [ nixpkgs.legacyPackages.${system}.nodejs_22 ];
        text = ''
          workspace="''${HARNESS_AGENT_WORKSPACE:-$PWD/harness-agent}"
          if [ ! -d "$workspace" ]; then
            echo "Не найдена рабочая папка: $workspace" >&2
            echo "Запустите команду из /home/admsys/Nixos/nixos-config." >&2
            exit 1
          fi
          cd "$workspace"
          # shellcheck disable=SC2016
          exec npx --yes --package=@deepseek-ai/dsh@latest -- sh -c '
            dsh_bin=$(readlink -f "$(command -v dsh)")
            exec node --expose-internals "$dsh_bin" web --no-open
          '
        '';
      };

    apps.${system}.harness-agent = {
      type = "app";
      program = "${self.packages.${system}.harness-agent}/bin/harness-agent";
    };

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
