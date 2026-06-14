# Архитектура системы

## Обзор

Репозиторий — это **Nix Flake**, управляющий NixOS-конфигурациями для нескольких
физических машин и серверов. Единый источник истины — `nixos-config/flake.nix`.

Все хосты работают под управлением пользователя `admsys`, используют
`nixos-25.05` и `home-manager release-25.05`.

---

## Топология хостов

### x-disk — основная рабочая станция

- **Роль:** Основная рабочая машина разработчика. Хранилище данных.
- **Desktop:** Hyprland (Wayland)
- **Модули:** `nixos/modules/default.nix` (полный desktop-набор)
- **Особенности:**
  - Samba-шара: `/home/admsys` → локальная сеть
  - rsyslog-форвардинг → Germany VDS (`64.188.64.23:514`)
  - Инструменты разработки: VSCode, Docker, Google Cloud SDK, Ansible
  - Инструменты пентеста: Nmap, Metasploit, Wireshark, Smbmap
  - `beekeeper-studio-5.1.5` в `permittedInsecurePackages`
- **Конфиг:** `hosts/x-disk/configuration.nix`

### Huawei — ноутбук

- **Роль:** Мобильная рабочая станция.
- **Desktop:** Hyprland (Wayland)
- **Модули:** `nixos/modules/default.nix` (полный desktop-набор)
- **Особенности:**
  - ALSA-патч для аудио (`snd-intel-dspcfg.dsp_driver=1`)
  - Samba-шара на `/home/admsys`
  - Те же WiFi-параметры: power_save=0, PCIE ASPM off
- **Конфиг:** `hosts/Huawei/configuration.nix`

### srv-home-min — минимальный домашний сервер

- **Роль:** Headless-сервер. Docker-хост.
- **Desktop:** нет
- **Модули:** `nixos/modules/server/` (серверный набор)
- **Особенности:**
  - Docker включён
  - DATA-партиция
  - Минимальный набор GUI-инструментов
- **Конфиг:** `hosts/srv-home-min/configuration.nix`

### srv-home — домашний сервер

- **Роль:** Лёгкий сервер без рабочего стола (headless или минимальный GUI).
- **Конфиг:** `hosts/srv-home/configuration.nix`
- _Детали конфига уточнить._

### srv-home-gui — домашний сервер с GUI

- **Роль:** Сервер с лёгким графическим интерфейсом (XFCE).
- **Desktop:** XFCE + Openbox
- **Конфиг:** `hosts/srv-home-gui/configuration.nix`

### main — активный desktop-хост

- **Роль:** Полноценная desktop-машина наравне с `x-disk` и `Huawei`.
- **Модули:** `nixos/modules/default.nix` (полный desktop-набор)
- **Конфиг:** `hosts/main/configuration.nix` (импортирует `../../nixos/modules`)
- **Примечание:** Ранее статус хоста был неясен; уточнено при работе над
  задачами 002/003 — `main` используется на реальном железе и должен
  получать все изменения shared-модулей.

---

## Внешние системы

### Germany VDS (не в этом репозитории)

- **IP:** `64.188.64.23`
- **Роль:** Получатель централизованных логов с `x-disk`
- **Управление:** Независимо, конфиг этого репозитория только настраивает
  rsyslog-форвардинг *отправителя*
- **Что принимает:** auth.warn+, kern.warn+, *.crit от x-disk

---

## Структура модулей

```
nixos-config/
├── flake.nix                    ← точка входа, список хостов
├── hosts/
│   ├── {hostname}/
│   │   ├── configuration.nix    ← точка входа хоста
│   │   ├── hardware-configuration.nix
│   │   └── local-packages.nix   ← пакеты, специфичные для хоста
├── nixos/
│   └── modules/
│       ├── default.nix          ← desktop-набор (Huawei, x-disk, main)
│       ├── *.nix                ← отдельные модули
│       └── server/
│           ├── default.nix      ← серверный набор
│           └── *.nix
└── home-manager/
    ├── home.nix                 ← точка входа Home Manager
    ├── home-packages.nix        ← общие пакеты пользователя
    └── modules/
        ├── default.nix          ← список HM-модулей (условные импорты)
        └── *.nix / */           ← dotfile-конфиги
```

### Что входит в desktop-набор (`nixos/modules/default.nix`)

`audio`, `bluetooth`, `boot`, `cron`, `env`, `home-manager`, `hyprland`,
`kernel`, `mime`, `net`, `nh`, `nix`, **`nix-ld`**, `ssh`,
`rsyslog-forwarding` (активен только на `x-disk`), `timezone`, `user`,
`zram`, `amneziavpn`, `power`, `displayManager`, `syncthing`, `docker`,
`udisks`, `virtualbox`, `wireshark`, **`assistant`**, **`happ`**.

**Замечание:** Набор широкий — `docker`, `virtualbox`, `syncthing` включены
глобально для всех desktop-хостов. Это не всегда нужно. Потенциальная область
рефакторинга (см. `devplan.md`).

### Что входит в серверный набор (`nixos/modules/server/`)

`shell` (Zsh + Starship + Atuin), `gui` (опциональный), `hypr-desktop`,
`hypr-home-manager`. _(Детали уточнить при необходимости.)_

---

## Управление секретами

- **SOPS** (`sops-nix`) для зашифрованных секретов в `nixos-config/secrets/`
- Fallback: `nixos-config/secrets.nix` (не в Git для публичного репозитория)
- Текущий секрет: `pingwin-cron-url`
- В `flake.nix`: если `$NIXOS_SECRETS_PATH` задан → использует его, иначе
  `secrets.nix`, иначе `{}` (пустые секреты)

---

## Управление темами

- **Stylix** — централизованное управление темами/стилями для всех приложений
- Конфигурация: `home-manager/modules/stylix.nix`

---

## Custom-пакеты

- `nixos-config/packages/lazyssh.nix` — LazySSH (Go-инструмент для SSH).
  Сборка: `pkgs.callPackage ../../packages/lazyssh.nix {}`. Используется на: `x-disk`.
- `nixos-config/packages/assistant.nix` — «Ассистент» (ГК САФИБ), remote access.
  Распаковка `.deb` через `autoPatchelfHook + dpkg`. Подключается shared-модулем
  `nixos/modules/assistant.nix` на все desktop-хосты.
- `nixos-config/packages/happ.nix` — Happ, proxy-клиент на базе Xray.
  Тот же паттерн `autoPatchelfHook + dpkg + dontWrapQtApps`. Bundled Qt6 в
  `/opt/happ/lib/`. Подключается через `nixos/modules/happ.nix`.

---

## Текущие ограничения

1. **Desktop-набор перегружен.** `docker`, `virtualbox`, `syncthing` включены
   через `default.nix` для всех desktop-хостов, хотя не каждому нужны.
   Решение: хост-специфичные опции или отдельные opt-in модули.

2. **`tailscale.nix` закомментирован** в `default.nix` без объяснения
   причины. Статус неизвестен. Нужна задача для прояснения.

3. **`main` — непонятный хост.** Нет чёткого назначения. Возможно, тестовый
   шаблон, который не применяется на реальном железе.

4. **README.md устарел.** Перечисляет только 3 хоста из 6. Не является
   source of truth — см. `flake.nix`.

5. **`beekeeper-studio-5.1.5` в insecure.** Временная мера. Нужна задача
   для обновления или замены.

---

## Целевое направление развития

- Вынести опциональные сервисы (`docker`, `virtualbox`, `syncthing`) из
  `default.nix` в host-specific конфиги или opt-in модули
- Унифицировать серверный набор: определить, какие server-хосты нужны и
  нужна ли srv-home-gui
- Прояснить статус `tailscale.nix`
- Поддержать запуск dynamically-linked бинарей (nix-ld) — см.
  `docs/tasks/001-nix-ld-deploy.md`
