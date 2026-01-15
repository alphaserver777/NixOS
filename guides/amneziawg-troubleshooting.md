# AmneziaWG: поиск проблем (NixOS)

Этот чек‑лист нужен, когда AmneziaWG/AmneziaVPN перестает подключаться после ребилда.
Запускай команды из TTY или терминала. Используй имя своего хоста (например, x-disk).

## 0) Быстрая проверка

- Убедись, что запущено нужное поколение:
  - `readlink /run/current-system`
  - `uname -r`
- Убедись, что сервис есть:
  - `systemctl list-unit-files | rg -i "amnezia|wg"`

## 1) Статус и логи сервиса

- Статус:
  - `systemctl status AmneziaVPN --no-pager`
- Логи текущей загрузки:
  - `journalctl -u AmneziaVPN -b --no-pager`
- Поиск ошибок по ключевым словам:
  - `journalctl -b | rg -i "amnezia|wg|wireguard|netlink|route|tailscale"`

## 2) Модуль WireGuard

- Проверить, загружен ли модуль:
  - `lsmod | rg -i wireguard`
- Статус интерфейсов (если есть):
  - `wg show`

## 3) Маршрутизация и DNS

- Маршруты:
  - `ip route`
- DNS:
  - `resolvectl status`

## 4) Влияние Tailscale (если включен)

Tailscale иногда конфликтует с маршрутами.

- Статус:
  - `systemctl status tailscaled --no-pager`
  - `tailscale status`

Если AmneziaVPN начинает работать после остановки Tailscale:
- `sudo systemctl stop tailscaled`
- Проверь AmneziaVPN еще раз.

## 5) Сравнение поколений

Найди рабочее и нерабочее поколение (пример: 100 и 115):
- `sudo nixos-rebuild list-generations`
- `nix diff-closures /nix/var/nix/profiles/system-100-link /nix/var/nix/profiles/system-115-link`

Смотри изменения в сети, VPN, ядре и firewall.

## 6) Быстрый откат

Если нужно срочно восстановить работу:
- Перезагрузись и выбери рабочее поколение в меню загрузки.
- Или переключись на рабочее поколение прямо в системе:
  - `sudo /nix/var/nix/profiles/system-100-link/bin/switch-to-configuration switch`

## 7) Если все еще не работает

Собери и пришли:
- `systemctl status AmneziaVPN --no-pager`
- `journalctl -u AmneziaVPN -b --no-pager`
- `ip route`
- `wg show`
- `systemctl status tailscaled --no-pager` (если установлен)
- `nix diff-closures` между рабочим и нерабочим поколениями
