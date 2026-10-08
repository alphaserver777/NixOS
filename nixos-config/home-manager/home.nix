{ lib, pkgs, hostname, user, ... }: {
  imports = [
    ./modules
    ./home-packages.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";

    file."screens/.keep".text = "";

    sessionVariables = {
      # Идентификатор проекта Google Cloud для Antigravity CLI.
      GOOGLE_CLOUD_PROJECT = "nixos-ai-001";
      QT_SCREEN_SCALE_FACTORS = "1;1";
    };
  };

  programs.neovim.extraPackages = lib.mkIf (hostname == "srv-home") (lib.mkForce (with pkgs; [
    lua-language-server
    nixd
    vimPlugins.nvim-treesitter-parsers.hyprlang
    fd
    ripgrep
    tree-sitter
  ]));
}
