{ lib, pkgs, ... }:
let
  easyMotion = pkgs.callPackage ../../packages/zsh-easy-motion.nix { };
in
{
  # Задача 054: после привычных сочетаний (1500) и Navi (1600).
  programs.zsh.initContent = lib.mkOrder 1700 ''
    if [[ $options[zle] = on ]]; then
      source ${easyMotion}/share/zsh-easy-motion/easy_motion.plugin.zsh
      bindkey -v
      KEYTIMEOUT=10

      EASY_MOTION_TARGET_KEYS=asdfghjklqwertyuiopzxcvbnm
      EASY_MOTION_DIM='fg=#6c7086'
      EASY_MOTION_HIGHLIGHT='fg=#cba6f7,bold'
      EASY_MOTION_HIGHLIGHT_2_FIRST='fg=#89b4fa,bold'
      EASY_MOTION_HIGHLIGHT_2_SECOND='fg=#94e2d5,bold'
      EASY_MOTION_SMART_CASE=true
      bindkey -M vicmd ' ' vi-easy-motion
      bindkey -M viopp ' ' vi-easy-motion

      # Navi читает LBUFFER; в режиме Vim справа остаётся символ под курсором.
      # Передаём всю строку, а при отмене возвращаем положение курсора.
      _cosmic_vi_navi() {
        local original_buffer="$BUFFER"
        local -i original_cursor=$CURSOR
        CURSOR=$#BUFFER
        zle _navi_widget
        if [[ "$BUFFER" == "$original_buffer" ]]; then
          CURSOR=$original_cursor
        fi
        zle redisplay
      }
      if (( $+widgets[_navi_widget] )); then
        zle -N _cosmic_vi_navi
        bindkey -M viins '^G' _cosmic_vi_navi
        bindkey -M vicmd '^G' _cosmic_vi_navi
      fi
      if (( $+widgets[atuin-search-viins] )); then
        bindkey -M viins '^R' atuin-search-viins
        bindkey -M vicmd '^R' atuin-search-vicmd
      fi

      for cosmic_keymap in viins vicmd; do
        bindkey -M "$cosmic_keymap" '^[[3~' delete-char
        if (( $+terminfo[kdch1] )); then
          bindkey -M "$cosmic_keymap" "$terminfo[kdch1]" delete-char
        fi
        bindkey -M "$cosmic_keymap" '^U' backward-kill-line
        bindkey -M "$cosmic_keymap" '^[[1;5D' backward-word
        bindkey -M "$cosmic_keymap" '^[[1;5C' forward-word
        bindkey -M "$cosmic_keymap" '^[[5D' backward-word
        bindkey -M "$cosmic_keymap" '^[[5C' forward-word
      done
      unset cosmic_keymap
      bindkey -M viins '^?' backward-delete-char
      bindkey -M viins '^A' beginning-of-line
      bindkey -M viins '^E' end-of-line
      bindkey -M viins '^K' kill-line
      bindkey -M viins '^W' backward-kill-word

      # Автоподсказка истории не должна приниматься движениями Vim.
      typeset -g -i _cosmic_vi_restore_suggestions=0
      _cosmic_vi_cursor() {
        case "''${KEYMAP:-viins}" in
          vicmd|viopp)
            printf '\e[2 q'
            if (( $+widgets[autosuggest-disable] )) && [[ -z ''${_ZSH_AUTOSUGGEST_DISABLED:-} ]]; then
              _cosmic_vi_restore_suggestions=1
              zle autosuggest-disable
            fi
            ;;
          *)
            printf '\e[6 q'
            if (( _cosmic_vi_restore_suggestions )); then
              _cosmic_vi_restore_suggestions=0
              zle autosuggest-enable
            fi
            ;;
        esac
      }
      _cosmic_vi_line_init() {
        zle -K viins
        _cosmic_vi_cursor
      }
      _cosmic_vi_line_finish() { printf '\e[0 q'; }
      autoload -Uz add-zle-hook-widget
      add-zle-hook-widget line-init _cosmic_vi_line_init
      add-zle-hook-widget keymap-select _cosmic_vi_cursor
      add-zle-hook-widget line-finish _cosmic_vi_line_finish
    fi
  '';
  programs.starship.settings.character.vimcmd_symbol = "[ ПЕРЕХОД ](bold purple)";
}
