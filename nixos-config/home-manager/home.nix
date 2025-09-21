{ homeStateVersion, user, ... }: {
  imports = [
    ./modules
      ./home-packages.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;

    sessionVariables = { # Переменная для работы Gemini-cli
      GOOGLE_CLOUD_PROJECT = "nixos-ai-001";
    };
  };
                                 }
