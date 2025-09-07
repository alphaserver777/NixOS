{
  programs.zathura = {
    enable = true;
    mappings = {
      D = "toggle_page_mode";
      d = "scroll half_down";
      u = "scroll half_up";
      "<C-y>" = "exec echo $FILE | wl-copy";
    };
    options = {
      font = "JetBrains Mono Bold 13";
      selection-clipboard = "clipboard";
    };
  };
}
