# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Перед началом любой работы

Этот репозиторий использует **spec-driven development**. Перед созданием задачи или
началом реализации обязательно прочитать (именно в этом порядке):

1. [`docs/WORKFLOW.md`](docs/WORKFLOW.md) — процесс работы, ключевые документы
2. [`docs/constitution.md`](docs/constitution.md) — инженерные правила, чего нельзя
3. [`docs/architecture.md`](docs/architecture.md) — топология хостов, source of truth
4. [`docs/devplan.md`](docs/devplan.md) — текущие приоритеты и follow-up'ы
5. [`docs/tasks/PROCESS.md`](docs/tasks/PROCESS.md) — как заводить task spec'и
6. [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — если задача затрагивает deploy/infra
7. Связанные task specs из [`docs/tasks/`](docs/tasks/) (закрытые тоже — там
   хронология решений и причин)

**Следующий номер задачи** — узнать из [`docs/tasks/`](docs/tasks/) (последний
`NNN-*.md` + 1). Шаблон — [`docs/tasks/TEMPLATE.md`](docs/tasks/TEMPLATE.md).

## Workspace layout

Главная точка входа — `nixos-config/flake.nix`. Все nix-команды запускаются из
`/home/admsys/Nixos/nixos-config/` (не из корня).

```
/home/admsys/Nixos/
├── nixos-config/        ← Flake: hosts/, nixos/modules/, home-manager/, packages/
├── docs/                ← SDD-документация (читать первой)
├── docs/diagrams/       ← Архитектурные диаграммы (archify HTML + source JSON)
├── guides/              ← Раздельные how-to (отдельно от SDD-док)
├── VM/                  ← Отдельный flake для VM-конфигов
├── disko/               ← Шаблон disko-разметки дисков
└── scripts/             ← install-nixos.sh и утилиты
```

## Основные команды

Все `nix` команды требуют `--extra-experimental-features 'nix-command flakes'`
если запущены не из NixOS-сессии (например через subagent в headless).

### Сборка и применение

```bash
cd /home/admsys/Nixos/nixos-config

# Проверка перед apply — обязательно для shared-модулей и production-хостов
nixos-rebuild dry-build --flake .#x-disk

# Полная сборка без apply (быстрее обнаружить ошибки derivation/autoPatchelf)
nix build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link

# Применить на текущей машине
sudo nixos-rebuild switch --flake .#$(hostname)

# Откат
sudo nixos-rebuild switch --rollback
```

### Home Manager

Home Manager интегрирован в NixOS-модуль (`nixos/modules/home-manager.nix`), так
что `nixos-rebuild switch` применяет одновременно систему + HM. Отдельный запуск
нужен только для теста HM-изменений без rebuild системы:

```bash
home-manager switch --flake .#admsys@$(hostname)
```

### Обновление flake

```bash
nix flake update                              # все inputs
nix flake update nixpkgs-unstable             # только один input
```

После `flake update` — обязательно `dry-build` перед apply.

### Custom-пакет: цикл итерации

```bash
# 1. Получить sha256 для нового .deb / архива
nix-prefetch-url '<URL>'

# 2. Поправить packages/<name>.nix

# 3. Если файл новый — добавить в Git как intent-to-add, иначе Flake его не увидит
git add -N nixos-config/packages/<name>.nix

# 4. Полная пересборка
nix build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link

# 5. При autoPatchelf-ошибках — log покажет конкретный пропущенный .so → добавить
#    нужный nixpkgs-пакет в buildInputs, перезапустить шаг 4
```

## Хосты

Полный список и роли — [`docs/architecture.md`](docs/architecture.md). Минимум что
нужно знать:

- **Desktop** (`x-disk`, `Huawei`, `main`) — импортируют `nixos/modules/default.nix`.
  Изменение любого файла оттуда автоматически затрагивает все три.
- **Server** (`srv-home-min`, `srv-home`, `srv-home-gui`) — импортируют
  `nixos/modules/server/default.nix`. Отдельный набор.
- **`x-disk`** — основная рабочая станция, единственный с rsyslog-форвардингом на
  Germany VDS (`64.188.64.23:514`) и Samba-шарой на `/home/admsys`.

## Каналы и cherry-pick из unstable

`flake.nix` имеет два `nixpkgs`-input'а:
- `nixpkgs` (nixos-25.05) — базовый канал для всего
- `nixpkgs-unstable` — для отдельных пакетов где 25.05 слишком устарел

Пакеты из unstable подключаются через `pkgs-unstable` в `specialArgs` (см.
[task 004](docs/tasks/004-gemini-cli-from-unstable.md)):

```nix
{ pkgs, pkgs-unstable, ... }: {
  environment.systemPackages = [ pkgs-unstable.<name> ];
}
```

Не плодить unstable-пакеты бесконтрольно — только когда стабильная версия
реально блокирует. Каждый случай — task spec с обоснованием.

## Паттерны упаковки `.deb`

Есть три рабочих derivation-шаблона в `nixos-config/packages/`:

| Паттерн | Когда применять | Пример |
|---|---|---|
| `buildGoModule` | Go-проекты с source на GitHub | `lazyssh.nix` |
| `autoPatchelfHook + dpkg` | bundled libs совместимы с системными nixpkgs | `happ.nix` |
| `buildFHSEnv` + raw derivation с `dontPatchELF` | bundled libs требуют Debian-like окружение (часто Lazarus/FPC, старые Qt-апп) | `assistant.nix` |

Если `autoPatchelfHook` падает с `Runtime error 203` (FPC heap overflow) или
непредсказуемыми крашами на старте — это сигнал переходить на `buildFHSEnv`.
Подробная хронология такого фикса — [task 002](docs/tasks/002-install-assistant-replace-rustdesk.md).

## Известные подводные камни

Это места, на которых уже терялись часы. Сохранено чтобы не повторять.

### Stylix задаёт `QT_STYLE_OVERRIDE=kvantum` глобально

[`home-manager/modules/stylix.nix`](nixos-config/home-manager/modules/stylix.nix)
автоматически проставляет `QT_STYLE_OVERRIDE=kvantum` для всех Qt-приложений в
сессии пользователя. Qt6-приложения, для которых нет kvantum (kvantum в nixpkgs
есть только для Qt5), падают.

Если упаковываешь Qt6-приложение — в wrapper используй `--set` (не
`--set-default`!) чтобы перебить:
```nix
makeWrapper $out/opt/<app>/bin/<app> $out/bin/<app> \
  --set QT_STYLE_OVERRIDE Fusion \
  --set QT_QUICK_CONTROLS_STYLE Fusion
```

### Lazarus/Qt apps буферизуют stdout — смотреть файловые логи

Если приложение падает или ведёт себя странно, его stdout-вывод может не
показать реальную причину (буферизация при flush). Реальные runtime-сообщения
обычно живут в `~/.config/<app>/log/*.log`. Это вытащило корневую причину серого
экрана в [task 002](docs/tasks/002-install-assistant-replace-rustdesk.md) (была
`libXinerama.so.1`, а stdout молчал).

### `flake.lock` в `.gitignore`

Это решение пользователя ([.gitignore](.gitignore)). При первом клоне репо
нужен `nix flake update` для создания lock. Не пытаться `git add -f flake.lock`
без обсуждения.

### `secrets.nix` существует локально, но **не** в gitignore

Файл `nixos-config/secrets.nix` существует на машине, не tracked Git'ом, но в
`.gitignore` его нет. Один `git add .` положит секрет в публичную историю.
SOPS подключён ([`flake.nix`](nixos-config/flake.nix)) — долгосрочно мигрировать
туда. Зафиксировано в [task spec при появлении]. До тех пор —
явно stage'ить файлы, не использовать `git add -A` / `git add .`.

### Новые .nix файлы — `git add -N` перед сборкой

Flake читает только tracked файлы. Если создал новый `.nix` и сразу запустил
`nix build` — получишь `path does not exist`. Решение:
```bash
git add -N nixos-config/packages/<new>.nix
```
Файл становится «intent-to-add» — Flake видит, но не staged ещё для коммита.

### Wheel без пароля + docker в группах — root-equivalent

См. [audit findings в этом архиве сессии]. На фикс заведено follow-up в
[`docs/devplan.md`](docs/devplan.md). При работе с правами не считать sudo
барьером.

## Git конвенция

- Active ветка: `develop`. Merge в `main` через PR.
- Remote: `git@github.com:alphaserver777/NixOS.git` (переехал с `GitOps`, см.
  commit `6e6a83b`).
- Commit-сообщения — на русском, формат из [`docs/tasks/PROCESS.md`](docs/tasks/PROCESS.md):
  `<тип>: <что>` + `Closes: docs/tasks/NNN-*.md`. Типы: `feat`, `fix`,
  `refactor`, `docs`, `chore`.
- Атомарные коммиты — один логический change на коммит. Не bundle nix-фиксы
  с docs-обновлениями.
- Push в `origin/develop` **только по явному запросу пользователя**. Локальные
  коммиты накапливать пачкой и пушить разом, когда скажут.

## Что в репо НЕ работает с наскока

- **Happ** (`docs/tasks/003`) — status `partial`. Главное окно работает, но
  диалоги Add Configuration / Settings заблокированы upstream-багом (нужен
  QML-модуль `kvantum`, которого нет ни в bundled, ни в nixpkgs для Qt6). См.
  spec для обходных путей.
- **Audio в Ассистенте** — `Failed to init Alsa` в логе, голосовой чат не
  работает. Отдельный follow-up в devplan'е.

## Memory-система

Между сессиями ключевые факты хранятся в
`~/.claude/projects/-home-admsys-Nixos/memory/`. Особенно
`project-nixos-config.md` — там краткая сводка проекта и текущий номер задачи.
Обновлять при значимых изменениях (смена паттернов, удаление/добавление
хостов, новые следствия из закрытых задач).
