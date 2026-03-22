# Интерактивная установка NixOS

Для нового железа вместо ручного прохода по `quick_start_NixOs.md` можно использовать интерактивный установщик:

```bash
sudo ./scripts/install-nixos.sh
```

Если разметка и монтирование уже сделаны, а установка сорвалась позже, можно продолжить без повторного `disko`:

```bash
sudo ./scripts/install-nixos.sh --resume
```

Что делает скрипт:

- показывает доступные host из `nixos-config/hosts`
- умеет создать новый host-шаблон и сразу добавить его в `nixos-config/flake.nix`
- предлагает выбрать диск из `lsblk`
- генерирует временный `disko`-конфиг из `disko/disko.nix`
- запускает `disko`
- генерирует `hardware-configuration.nix`
- кладёт его в `nixos-config/hosts/<hostname>/hardware-configuration.nix`
- копирует весь репозиторий в установленную систему в `/mnt/etc/nixos`
- запускает `nixos-install --flake /mnt/etc/nixos/nixos-config#<hostname>`
- перед тяжёлыми шагами чистит временный `nix`-store live ISO, чтобы не упираться в маленький overlay `/nix/store`
- пишет полный stdout/stderr в лог-файл вида `/tmp/nixos-install-logs/install-YYYYmmdd-HHMMSS.log`

Что нужно заранее:

- загрузиться в NixOS ISO
- поднять сеть
- при необходимости клонировать этот репозиторий
- если флейк зависит от `secrets.nix`, держать путь к нему под рукой

Что скрипт не делает:

- не настраивает пароль пользователя после установки
- не коммитит изменения в git
- не создаёт сложную схему разметки кроме шаблона из `disko/disko.nix`
- по умолчанию не делает отдельный `nix eval` preflight, чтобы не тратить место в live ISO; включить можно через `RUN_PREFLIGHT=1`
- в режиме `--resume` ожидает, что `/mnt` и `/mnt/boot` уже смонтированы

Для нестандартной разметки сначала поменяйте `disko/disko.nix`, потом запускайте скрипт.
