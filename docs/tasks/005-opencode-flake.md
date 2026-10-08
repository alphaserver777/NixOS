# Task 005: opencode через официальный flake

## Проверка Контекста Перед Работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: `docs/tasks/004-gemini-cli-from-unstable.md`

---

## Status

`completed`

---

## Контекст

Нужно установить `opencode`. Официальная команда `curl -fsSL https://opencode.ai/install | bash`
скачивает и ставит бинарь императивно, что не подходит для этого NixOS-репозитория.
В `nixos-25.05` пакет `opencode` сильно старый, а требование — держать актуальную
версию.

---

## Цель

`opencode` установлен декларативно на `x-disk` и обновляется через обычный
механизм `nix flake update opencode`.

---

## Scope

**Входит в scope:**
- Добавить официальный `opencode` flake input.
- Передать пакет в NixOS-конфигурации через `specialArgs`.
- Установить `opencode` на `x-disk`.

**НЕ входит в scope:**
- Установка через `curl | bash`, npm, bun, pnpm или yarn.
- Перевод всего проекта на `nixos-unstable`.
- Установка на остальные хосты.

---

## Ограничения

- Базовый канал остаётся `nixos-25.05`.
- `opencode` должен обновляться отдельно от общего набора пакетов.
- Для GitHub-источника используется `git+https`, потому что короткий
  `github:anomalyco/opencode` может падать на распаковке архива.

---

## Итоговое состояние

- На `x-disk` установлен OpenCode `1.18.9+f720490` из официального flake.
- Базовый канал остаётся `nixos-25.05`.
- `opencode` из `nixos-25.05` версии `0.3.112` удалён из домашнего набора
  программ: он перекрывал более новую системную версию в `PATH`.

---

## Предлагаемое изменение

- [x] `nixos-config/flake.nix` — добавить `opencode` input.
- [x] `nixos-config/flake.nix` — добавить `opencodePackage` и передать через
  `specialArgs`.
- [x] `nixos-config/hosts/x-disk/local-packages.nix` — добавить `opencodePackage`.
- [x] `nixos-config/home-manager/home-packages.nix` — убрать устаревший
  `pkgs.opencode`, чтобы он не перекрывал пакет из официального flake.

---

## Затронутые области

- Хосты: `x-disk`.
- Модули: нет.
- Сервисы: нет.

---

## Acceptance Criteria

- [x] `nix flake lock --update-input opencode` проходит.
- [x] `nix build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link`
      проходит.
- [x] После применения `opencode --version` показывает актуальную версию из
      официального flake.

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config
nix --extra-experimental-features 'nix-command flakes' flake update opencode
nix --extra-experimental-features 'nix-command flakes' build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#x-disk
opencode --version
```

---

## Rollback / Safety

```bash
sudo nixos-rebuild switch --rollback
```

Или удалить `opencode` input, `opencodePackage` и запись в
`hosts/x-disk/local-packages.nix`.

---

## Заметки

- Обновлять только `opencode`:
  ```bash
  cd /home/admsys/Nixos/nixos-config
  nix flake update opencode
  ```
- `nix build` прошёл в `tmux`-сеансе `opencode-build` с `BUILD_EXIT=0`.
  После применения собран `opencode 1.18.9+f720490`.

---

## Подключение OpenCode к a6api

### Симптом и причина

При настройке OpenCode для `https://api.a6api.com/v1` модель отвечала, но
завершала работу ошибкой:

```text
Error: [DecimalError] Invalid argument: [object Object]
```

Это не ошибка ключа или модели. a6api возвращает расширенные сведения о токенах
как объект, а OpenCode `0.3.112` не умел корректно обработать этот ответ. Новая
версия OpenCode исправляет проблему. Дополнительно старый пакет из
`home-manager/home-packages.nix` имел приоритет в `PATH` и скрывал новую версию,
установленную системой.

### Постоянное решение

1. В `flake.nix` добавить вход:

   ```nix
   opencode.url = "git+https://github.com/anomalyco/opencode";
   ```

2. Получить пакет как `opencode.packages.${system}.default`, передать его через
   `specialArgs` и добавить `opencodePackage` в
   `hosts/x-disk/local-packages.nix`.
3. Удалить `opencode` из `home-manager/home-packages.nix`.
4. Обновить lock-файл, собрать и применить конфигурацию командами из раздела
   «Проверка».

Если сборка длительная, запускать её в видимом окне `tmux`:

```bash
tmux new-window -n opencode-update \
  'cd /home/admsys/Nixos/nixos-config && sudo nixos-rebuild switch --flake .#x-disk; exec zsh'
```

### Конфигурация a6api

Ключ хранить только в штатном хранилище OpenCode (`/connect` → `Other` →
идентификатор `a6api`), а не в файле конфигурации или репозитории.

Файл `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "a6api/gpt-5.6-sol",
  "provider": {
    "a6api": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "A6API",
      "options": {
        "baseURL": "https://api.a6api.com/v1"
      },
      "models": {
        "gpt-5.6-sol": {
          "name": "GPT-5.6 Sol"
        }
      }
    }
  }
}
```

### Финальная проверка

```bash
opencode --version
opencode run -m a6api/gpt-5.6-sol 'Ответь ровно: ОК'
```

Ожидаемый результат: версия новее `0.3.112`, затем ответ `ОК` без `400` и без
`DecimalError`.
