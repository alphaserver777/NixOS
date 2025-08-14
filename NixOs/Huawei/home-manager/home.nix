{ config, pkgs, ... }: {

  home = {
    username = "admsys";
    homeDirectory = "/home/admsys";
    stateVersion = "25.05";
  };
  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ./";
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
      comment-nvim
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

  # Минимальная конфигурация Hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Переменные (горячие клавиши)
      "$mainMod" = "SUPER";

      #Клавиатура - переключение на Капс
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:caps_toggle";
      };

      # Основные бинды
      bind = [
        # Запуск терминала
        "$mainMod, T, exec, kitty"

        # Закрыть активное окно
        "$mainMod, Q, killactive,"

        # Выход из Hyprland
        "$mainMod, M, exit,"

        # Запуск лаунчера приложений
        "$mainMod, R, exec, wofi --show drun"

        # Переключение между рабочими столами
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"

        # Громкость
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86AudioMute, exec, pamixer -t"

        # Яркость
        ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

      ];
    };
  };

  # Обязательно установите программы, которые вы используете
  home.packages = with pkgs; [
    kitty # Терминал
    wofi # Лаунчер
    nixpkgs-fmt
    dunst
    libnotify
    waybar
    wl-clipboard
    qbittorrent
    wev
    pamixer
    brightnessctl
  ];

}
	

