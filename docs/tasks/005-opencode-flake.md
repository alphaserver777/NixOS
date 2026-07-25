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

`in progress`

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

## Текущее состояние

- `nixos-25.05#opencode`: `0.3.112`.
- `nixos-unstable#opencode`: `1.17.12`.
- Официальная документация OpenCode для самой свежей версии указывает
  `nix run github:anomalyco/opencode`.

---

## Предлагаемое изменение

- [x] `nixos-config/flake.nix` — добавить `opencode` input.
- [x] `nixos-config/flake.nix` — добавить `opencodePackage` и передать через
  `specialArgs`.
- [x] `nixos-config/hosts/x-disk/local-packages.nix` — добавить `opencodePackage`.

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
- [ ] После применения `opencode --version` показывает актуальную версию из
      официального flake.

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config
nix --extra-experimental-features 'nix-command flakes' flake lock --update-input opencode
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
  Собран `opencode 1.17.15+77429f5`.
