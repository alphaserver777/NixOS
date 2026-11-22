{ pkgs, ... }:
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # Задача 058: постоянные номера всех результатов и выбор многозначного номера.
    package = pkgs.atuin.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../../packages/atuin-numbered-history.patch ];
    });
    settings = {
      sync_address = "https://api.atuin.sh";
      sync_frequency = "10m";
      search_mode = "fuzzy";
      # Задача 058: поиск сразу принимает текст, Esc включает выбор Vim.
      keymap_mode = "vim-insert";
      enter_accept = true;
      exit_mode = "return-original";
      inline_height = 0;
      style = "full";
      invert = false;
      show_help = true;
      show_preview = true;
      max_preview_height = 3;
      show_numeric_shortcuts = true;
    };
  };
}
