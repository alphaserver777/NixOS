#!@bash@
# Задача 023: новый процесс не должен стартовать со старым протоколом
# из встроенного снимка. Справка и управление клиентом остаются быстрыми.
case "${1:-}" in
  --version|-v|--help|-h|completion|models|debug|auth|providers|mcp|agent|upgrade|uninstall|stats|export|import|session|db|plugin|plug)
    exec "@opencode@" "$@"
    ;;
esac

# Home Manager вызывает ту же инициализацию при активации. Здесь она
# покрывает первый запуск на серверах без Home Manager.
"@python@" "@initializer@"

if [[ -z "${OPENCODE_MODELS_PATH:-}" && -z "${OPENCODE_MODELS_URL:-}" ]]; then
  case "${OPENCODE_DISABLE_MODELS_FETCH:-false}" in
    true|1) ;;
    *)
      opencode_cache="${XDG_CACHE_HOME:-$HOME/.cache}/opencode/models.json"
      opencode_now=$("@coreutils@/date" +%s)
      opencode_mtime=$("@coreutils@/stat" -c %Y "$opencode_cache" 2>/dev/null || true)
      if [[ ! -s "$opencode_cache" || $((opencode_now - ${opencode_mtime:-0})) -ge 300 ]]; then
        "@coreutils@/timeout" 20s "@opencode@" --pure models --refresh >/dev/null 2>&1 || true
      fi
      ;;
  esac
fi

exec "@opencode@" "$@"
