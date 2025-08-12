{ config, pkgs, ... }:

{
  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "25.05";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch";
    };
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox-material
      nerdtree
      nvim-web-devicons
      which-key-nvim
      vim-fugitive
    ];
    extraConfig = ''
      set tabstop=2
      set expandtab
      set shiftwidth=2
      set number
      set relativenumber
      set hlsearch
      set incsearch
      set clipboard=unnamedplus
    '';
  };


  programs.git = {
    enable = true;
    userName = "crypto_mrx";
    userEmail = "maksim.ilonov@yandex.ru";
  };

  wayland.windowManager.hyprland = {
  enable = true;
  settings = {
    # Основная управляющая клавиша (обычно Super)
    "$mod" = "SUPER";

    # Горячие клавиши для запуска приложений
    bind = [
      "$mod, Q, killactive,"  # Закрыть активное окно
      "$mod, M, exit,"        # Выйти из Hyprland
      "$mod, T, exec, alacritty" # Запустить терминал
    ];

    # Разметка окон
    layout = "master";

    # Настройка анимаций
    animations = {
      enabled = true;
      animation = [
        "windows,1,7,default,popin"
        "windowsOut,1,7,default,popin"
        "border,1,10,default"
        "fade,1,7,default"
        "workspaces,1,6,default"
      ];
    };
  };
};

  programs.alacritty = {
  enable = true;
  settings = {
    font = {
      size = 12.0;
      normal = {
        family = "FiraCode Nerd Font";
      };
    };
    window = {
      padding = {
        x = 5;
        y = 5;
      };
      dimensions = {
        columns = 120;
        lines = 30;
      };
    };
  };
};
}

