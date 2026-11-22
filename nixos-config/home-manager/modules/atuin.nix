{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      sync_address = "https://api.atuin.sh";
      sync_frequency = "10m";
      search_mode = "fuzzy";
      # Задача 058: поиск сразу принимает текст, Esc включает выбор Vim.
      keymap_mode = "vim-insert";
      enter_accept = true;
      exit_mode = "return-original";
      inline_height = 18;
      style = "full";
      invert = true;
      show_help = true;
      show_preview = true;
      max_preview_height = 3;
      show_numeric_shortcuts = true;
    };
  };
}
