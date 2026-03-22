#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONFIG_ROOT="${REPO_ROOT}/nixos-config"
DISKO_TEMPLATE="${REPO_ROOT}/disko/disko.nix"
TARGET_REPO_PARENT_DEFAULT="/mnt/etc"
TARGET_REPO_NAME="nixos"
MOUNT_ROOT="/mnt"
TMP_DISKO=""
NIX_FLAKE_ARGS=(--extra-experimental-features "nix-command flakes")
RUN_PREFLIGHT="${RUN_PREFLIGHT:-0}"
RESUME_MODE=0

STATE_VERSION_DEFAULT="25.05"

red() { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
blue() { printf '\033[1;34m%s\033[0m\n' "$*"; }

die() {
  red "Ошибка: $*"
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  install-nixos.sh [--resume] [--preflight]

Options:
  --resume     Продолжить установку без повторного запуска disko.
               Ожидается, что /mnt и /mnt/boot уже смонтированы.
  --preflight  Включить дополнительный nix eval перед nixos-install.
  -h, --help   Показать эту справку.
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Не найдена команда: $1"
}

prompt() {
  local message="$1"
  local default="${2-}"
  local value=""

  if [[ -n "$default" ]]; then
    read -r -p "${message} [${default}]: " value
    printf '%s' "${value:-$default}"
  else
    read -r -p "${message}: " value
    printf '%s' "$value"
  fi
}

prompt_optional_with_default() {
  local message="$1"
  local default="${2-}"
  local value=""

  if [[ -n "$default" ]]; then
    read -r -p "${message} [${default}] (Enter = использовать значение, '-' = пропустить): " value
    case "$value" in
      "") printf '%s' "$default" ;;
      "-") printf '' ;;
      *) printf '%s' "$value" ;;
    esac
  else
    read -r -p "${message} (Enter = пропустить): " value
    printf '%s' "$value"
  fi
}

confirm() {
  local message="$1"
  local answer=""
  while true; do
    read -r -p "${message} [y/N]: " answer
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) echo "Введите y или n." ;;
    esac
  done
}

print_section() {
  printf '\n' >&2
  blue "== $* ==" >&2
}

discover_hosts() {
  find "${CONFIG_ROOT}/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

choose_from_list() {
  local prompt_text="$1"
  shift
  local options=("$@")
  local index=""

  if ((${#options[@]} == 0)); then
    die "Список вариантов пуст."
  fi

  echo "${prompt_text}" >&2
  local i=1
  for option in "${options[@]}"; do
    printf '  %d - %s\n' "$i" "$option" >&2
    ((i++))
  done

  while true; do
    read -r -p "Введите номер варианта: " index >&2
    [[ "$index" =~ ^[0-9]+$ ]] || { echo "Нужен номер." >&2; continue; }
    if (( index >= 1 && index <= ${#options[@]} )); then
      printf '%s' "${options[index-1]}"
      return 0
    fi
  done
}

choose_disk() {
  mapfile -t DISKS < <(lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4 == "disk" {print}')
  ((${#DISKS[@]} > 0)) || die "Не найдено ни одного диска."

  echo "Доступные диски:" >&2
  local i=1
  local disk_names=()
  local row=""
  for row in "${DISKS[@]}"; do
    printf '  %d - %s\n' "$i" "$row" >&2
    disk_names+=("$(awk '{print $1}' <<<"$row")")
    ((i++))
  done

  local choice=""
  while true; do
    read -r -p "Введите номер диска: " choice >&2
    [[ "$choice" =~ ^[0-9]+$ ]] || { echo "Нужен номер." >&2; continue; }
    if (( choice >= 1 && choice <= ${#disk_names[@]} )); then
      printf '%s' "${disk_names[choice-1]}"
      return 0
    fi
  done
}

backup_file_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

add_host_to_flake_if_missing() {
  local host="$1"
  local state_version="$2"
  local flake_file="${CONFIG_ROOT}/flake.nix"

  if grep -Fq "hostname = \"${host}\";" "$flake_file"; then
    return 0
  fi

  backup_file_if_exists "$flake_file"

  awk -v host="$host" -v stateVersion="$state_version" '
    BEGIN { inserted = 0; in_hosts = 0 }
    /^[[:space:]]*hosts = \[/ { in_hosts = 1; print; next }
    in_hosts && /^[[:space:]]*\];/ && !inserted {
      printf "  { hostname = \"%s\"; stateVersion = \"%s\"; }\n", host, stateVersion
      inserted = 1
    }
    { print }
  ' "$flake_file" > "${flake_file}.tmp"

  mv "${flake_file}.tmp" "$flake_file"
}

create_new_host_scaffold() {
  local host="$1"
  local state_version="$2"
  local host_dir="${CONFIG_ROOT}/hosts/${host}"

  [[ ! -e "$host_dir" ]] || die "Каталог host уже существует: ${host_dir}"
  mkdir -p "$host_dir"

  cat > "${host_dir}/configuration.nix" <<EOF
{ pkgs, stateVersion, hostname, user, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
  ];

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
EOF

  cat > "${host_dir}/local-packages.nix" <<'EOF'
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
  ];
}
EOF

  cat > "${host_dir}/hardware-configuration.nix" <<'EOF'
{ ... }:
{
}
EOF

  add_host_to_flake_if_missing "$host" "$state_version"
}

render_disko_config() {
  local disk="$1"
  local output="$2"

  [[ -f "$DISKO_TEMPLATE" ]] || die "Не найден шаблон disko: ${DISKO_TEMPLATE}"

  sed "s|device = \"/dev/sdX\";|device = \"${disk}\";|" "$DISKO_TEMPLATE" > "$output"
}

sync_repo_to_target() {
  local target_parent="$1"
  local target_repo="${target_parent}/${TARGET_REPO_NAME}"

  mkdir -p "$target_parent"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
      --exclude '.git' \
      --exclude '.direnv' \
      --exclude '.vscode' \
      --exclude 'result' \
      --exclude '.devenv' \
      --exclude 'VM' \
      "${REPO_ROOT}/" "${target_repo}/"
  else
    rm -rf "$target_repo"
    mkdir -p "$target_repo"
    cp -a "${REPO_ROOT}/." "$target_repo/"
    rm -rf "${target_repo}/.git"
    rm -rf "${target_repo}/VM"
    rm -rf "${target_repo}/.vscode"
  fi
}

check_network() {
  if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    green "Сеть доступна."
  else
    yellow "Сеть не проверена или недоступна. Установка может упасть на загрузке зависимостей."
  fi
}

cleanup() {
  if [[ -n "${TMP_DISKO:-}" && -f "${TMP_DISKO:-}" ]]; then
    rm -f "$TMP_DISKO"
  fi
}

cleanup_live_store() {
  print_section "Очистка временного nix-store live ISO"
  nix-collect-garbage -d >/dev/null 2>&1 || true
}

print_storage_summary() {
  print_section "Проверка свободного места"
  df -h /nix/store /nix/.rw-store "$MOUNT_ROOT" 2>/dev/null || true
}

preflight_evaluate_host() {
  local flake_ref="$1"
  local host="$2"

  print_section "Проверка flake перед установкой"
  nix "${NIX_FLAKE_ARGS[@]}" eval --no-write-lock-file "${flake_ref}#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" >/dev/null
}

require_resume_mounts() {
  mountpoint -q "$MOUNT_ROOT" || die "В режиме --resume ожидается смонтированный ${MOUNT_ROOT}"
  mountpoint -q "${MOUNT_ROOT}/boot" || die "В режиме --resume ожидается смонтированный ${MOUNT_ROOT}/boot"
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --resume)
        RESUME_MODE=1
        ;;
      --preflight)
        RUN_PREFLIGHT=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Неизвестный аргумент: $1"
        ;;
    esac
    shift
  done
}

main() {
  trap cleanup EXIT
  parse_args "$@"
  [[ "${EUID}" -eq 0 ]] || die "Скрипт нужно запускать от root."

  need_cmd awk
  need_cmd cp
  need_cmd find
  need_cmd lsblk
  need_cmd nix
  need_cmd nixos-generate-config
  need_cmd nixos-install
  need_cmd sed

  [[ -d "$CONFIG_ROOT" ]] || die "Не найден nixos-config в ${CONFIG_ROOT}"

  print_section "Проверка окружения"
  echo "Репозиторий: ${REPO_ROOT}"
  check_network
  print_storage_summary
  if (( RESUME_MODE == 1 )); then
    echo "Режим: resume"
    require_resume_mounts
  fi

  print_section "Выбор host"
  mapfile -t existing_hosts < <(discover_hosts)
  local install_mode
  install_mode="$(choose_from_list "Какой сценарий нужен?" \
    "Установить существующий host из flake" \
    "Создать новый host и сразу установить его")"

  local selected_host=""
  local state_version="$STATE_VERSION_DEFAULT"

  if [[ "$install_mode" == "Установить существующий host из flake" ]]; then
    selected_host="$(choose_from_list "Доступные host:" "${existing_hosts[@]}")"
  else
    while true; do
      selected_host="$(prompt "Имя нового host")"
      [[ "$selected_host" =~ ^[A-Za-z0-9._-]+$ ]] || {
        echo "Имя host может содержать только буквы, цифры, '.', '_' и '-'."
        continue
      }
      [[ ! -e "${CONFIG_ROOT}/hosts/${selected_host}" ]] || {
        echo "Такой host уже существует."
        continue
      }
      break
    done

    state_version="$(prompt "system.stateVersion для нового host" "$STATE_VERSION_DEFAULT")"
    create_new_host_scaffold "$selected_host" "$state_version"
    green "Создан новый host: ${selected_host}"
  fi

  local target_disk="(resume: не используется)"
  if (( RESUME_MODE == 0 )); then
    print_section "Выбор диска"
    target_disk="$(choose_disk)"
    echo "Выбран диск: ${target_disk}"
  fi

  local target_repo_parent
  target_repo_parent="$TARGET_REPO_PARENT_DEFAULT"

  local default_secrets_path=""
  if [[ -f "${CONFIG_ROOT}/secrets.nix" ]]; then
    default_secrets_path="${CONFIG_ROOT}/secrets.nix"
  fi
  local secrets_path
  secrets_path="$(prompt_optional_with_default "Путь к secrets.nix" "$default_secrets_path")"

  print_section "Подтверждение"
  echo "Host: ${selected_host}"
  echo "Disk: ${target_disk}"
  echo "Mount root: ${MOUNT_ROOT}"
  echo "Repo target: ${target_repo_parent}/${TARGET_REPO_NAME}"
  if [[ -n "$secrets_path" ]]; then
    echo "Secrets: ${secrets_path}"
  else
    echo "Secrets: не используются"
  fi

  if (( RESUME_MODE == 0 )); then
    confirm "Продолжить? Диск ${target_disk} будет полностью очищен." || die "Операция отменена."

    TMP_DISKO="$(mktemp /tmp/disko.XXXXXX.nix)"
    render_disko_config "$target_disk" "$TMP_DISKO"

    print_section "Разметка диска через disko"
    cleanup_live_store
    nix "${NIX_FLAKE_ARGS[@]}" run github:nix-community/disko -- --mode disko "$TMP_DISKO"
  else
    confirm "Продолжить в режиме --resume без повторной разметки?" || die "Операция отменена."
  fi

  print_section "Генерация hardware-configuration.nix"
  nixos-generate-config --root "$MOUNT_ROOT"
  install -Dm644 \
    "${MOUNT_ROOT}/etc/nixos/hardware-configuration.nix" \
    "${CONFIG_ROOT}/hosts/${selected_host}/hardware-configuration.nix"

  print_section "Копирование репозитория в установленную систему"
  sync_repo_to_target "$target_repo_parent"

  local target_repo
  target_repo="${target_repo_parent}/${TARGET_REPO_NAME}"

  if [[ "$RUN_PREFLIGHT" == "1" ]]; then
    cleanup_live_store
    preflight_evaluate_host "${target_repo}/nixos-config" "$selected_host"
  fi

  print_section "Установка NixOS"
  cleanup_live_store
  print_storage_summary
  if [[ -n "$secrets_path" ]]; then
    [[ -f "$secrets_path" ]] || die "Файл secrets.nix не найден: ${secrets_path}"
    env NIXOS_SECRETS_PATH="$secrets_path" \
      nixos-install --root "$MOUNT_ROOT" --flake "${target_repo}/nixos-config#${selected_host}" --impure --no-write-lock-file
  else
    nixos-install --root "$MOUNT_ROOT" --flake "${target_repo}/nixos-config#${selected_host}" --no-write-lock-file
  fi

  print_section "Готово"
  green "Установка завершена."
  echo "Host: ${selected_host}"
  echo "Репозиторий в установленной системе: ${target_repo}"
  echo "Перед reboot проверьте, что всё выглядит ожидаемо."
}

main "$@"
