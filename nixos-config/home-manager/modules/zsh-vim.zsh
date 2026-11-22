# Штатное чтение клавиш Zsh сохраняет совместимость с Atuin и Navi.
ZVM_READKEY_ENGINE=zle
ZVM_INIT_MODE=sourcing
ZVM_LAZY_KEYBINDINGS=false
ZVM_LINE_INIT_MODE=i
ZVM_KEYTIMEOUT=0.1
ZVM_VI_EDITOR='@nvim@'

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

_cosmic_vi_bindings() {
  local keymap
  if (( $+widgets[_navi_widget] )); then
    zle -N _cosmic_vi_navi
    bindkey -M viins '^G' _cosmic_vi_navi
    bindkey -M vicmd '^G' _cosmic_vi_navi
  fi
  if (( $+widgets[atuin-search-viins] )); then
    bindkey -M viins '^R' atuin-search-viins
  fi
  for keymap in viins vicmd; do
    bindkey -M "$keymap" '^[[3~' delete-char
    if (( $+terminfo[kdch1] )); then
      bindkey -M "$keymap" "$terminfo[kdch1]" delete-char
    fi
    bindkey -M "$keymap" '^U' backward-kill-line
    bindkey -M "$keymap" '^[[1;5D' backward-word
    bindkey -M "$keymap" '^[[1;5C' forward-word
    bindkey -M "$keymap" '^[[5D' backward-word
    bindkey -M "$keymap" '^[[5C' forward-word
  done
  bindkey -M viins '^?' backward-delete-char
  bindkey -M vicmd '^R' redo
}

# Подсказки истории показываются только при вводе.
typeset -g -i _cosmic_vi_restore_suggestions=0
_cosmic_vi_mode() {
  local label
  case "$ZVM_MODE" in
    n) label=ОБЫЧНЫЙ ;;
    v|vl) label=ВЫДЕЛЕНИЕ ;;
    r) label=ЗАМЕНА ;;
    *) label=ВВОД ;;
  esac
  if [[ "$ZVM_MODE" == i ]]; then
    if (( _cosmic_vi_restore_suggestions )); then
      _cosmic_vi_restore_suggestions=0
      zle autosuggest-enable
    fi
  elif (( $+widgets[autosuggest-disable] && ! ${+_ZSH_AUTOSUGGEST_DISABLED} )); then
    _cosmic_vi_restore_suggestions=1
    zle autosuggest-disable
  fi
  if [[ -n "$TMUX" && -n "$TMUX_PANE" ]]; then
    @tmux@ set-option -p -t "$TMUX_PANE" @zsh_mode "$label" 2>/dev/null
  fi
  return 0
}

_cosmic_vi_finish() {
  if [[ -n "$TMUX" && -n "$TMUX_PANE" ]]; then
    @tmux@ set-option -pu -t "$TMUX_PANE" @zsh_mode 2>/dev/null
  fi
  return 0
}

zvm_after_init_commands+=(_cosmic_vi_bindings)
zvm_after_select_vi_mode_commands+=(_cosmic_vi_mode)
# Регистрируем обработчики до zsh-vi-mode: оно сохраняет существующие
# обработчики ZLE. Повторная обёртка после него замкнула бы цепочку вызовов.
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _cosmic_vi_mode
add-zle-hook-widget line-finish _cosmic_vi_finish
source '@viMode@'
