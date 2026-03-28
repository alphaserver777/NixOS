{ config, inputs, hostname, user, ... }:

{
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs hostname user;
    };
    users.${user} = {
      imports = [ ../../../home-manager/server-hypr.nix ];
      home.stateVersion = config.system.stateVersion;
    };
  };
}
