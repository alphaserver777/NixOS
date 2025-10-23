{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      sync_address = "https://api.atuin.sh";
      sync_frequency = "10m";
      search_mode = "fuzzy";
    };
  };
}
