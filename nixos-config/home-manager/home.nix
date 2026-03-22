{ user, ... }: {
  imports = [
    ./modules
    ./home-packages.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";

    sessionVariables = {
      # Переменная для работы Gemini-cli
      GOOGLE_CLOUD_PROJECT = "nixos-ai-001";
      QT_SCREEN_SCALE_FACTORS = "1;1";
    };
  };
}
