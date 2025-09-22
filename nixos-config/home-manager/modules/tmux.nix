{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
            set -as terminal-features ",alacritty*:RGB"
            set-option -g focus-events on   # ✅ фикс для Neovim autoread

      # Автоматически переименовывать окна по активной программе
            set -g automatic-rename on
            set -g automatic-rename-format "#{b:pane_current_command}"

      # Формат кнопок для окон
            setw -g window-status-format "#[fg=white,bg=colour237] #{?window_index,#{window_index}:,}#{b:pane_current_command} #[default]"
            setw -g window-status-current-format "#[fg=black,bg=green,bold] #{?window_index,#{window_index}:,}#{b:pane_current_command} #[default]"

      # Между кнопками чуть больше места
            set -g window-status-separator " "

      # --- VI-режим и копирование ---
      # Настройки для полноценного Vi-режима в режиме копирования
            bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
            bind-key -T copy-mode-vi 'V' send-keys -X select-line
            bind-key -T copy-mode-vi 'C-v' send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel # Работает с tmux-yank

      # Индикатор режима в строке состояния (справа)
            set -g status-right "#[fg=black,bg=#{?pane_in_mode,yellow,green}] #{?pane_in_mode, COPY , NORMAL } #[default]| %a %d-%m-%Y | %H:%M "
      # --- Конец секции VI ---

            bind -n M-r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
            bind C-p previous-window
            bind C-n next-window

            bind -n M-1 select-window -t 1
            bind -n M-2 select-window -t 2
            bind -n M-3 select-window -t 3
            bind -n M-4 select-window -t 4
            bind -n M-5 select-window -t 5
            bind -n M-6 select-window -t 6
            bind -n M-7 select-window -t 7
            bind -n M-8 select-window -t 8
            bind -n M-9 select-window -t 9

            bind -n M-Left select-pane -L
            bind -n M-Right select-pane -R
            bind -n M-Up select-pane -U
            bind -n M-Down select-pane -D

            bind -n M-S-Left resize-pane -L 5
            bind -n M-S-Right resize-pane -R 5
            bind -n M-S-Up resize-pane -U 3
            bind -n M-S-Down resize-pane -D 3

            bind -n M-s split-window -v
            bind -n M-v split-window -h

            bind -n M-o new-window -c ~/para "nvim -c 'Telescope find_files' '0 Inbox/todolist.md'"
            bind -n M-f new-window -c ~/flake "nvim -c 'Telescope find_files' flake.nix"
            bind -n M-n new-window -c ~/.config/nvim "nvim -c 'Telescope find_files' init.lua"
            bind -n M-Enter new-window
            bind -n M-c kill-pane
            bind -n M-q kill-window
            bind -n M-Q kill-session
    '';
    plugins = with pkgs; [
      tmuxPlugins.catppuccin
      tmuxPlugins.yank # Для копирования в системный буфер обмена
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-save "C-s"
          set -g @resurrect-restore "C-r"
          set -g @resurrect-processes ':all:'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
          set -g @continuum-save-msg 'Tmux environment saved!'
          set -g @continuum-restore-msg 'Tmux environment restored!'
        '';
      }
    ];
  };
}
