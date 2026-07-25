# Task 006: Telegram Desktop из unstable

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

В `nixos-25.05` пакет `telegram-desktop` имеет версию `5.13.1`, а актуальная
стабильная версия Telegram Desktop сейчас `6.9.3`. В `nixos-unstable` уже есть
`6.9.3`.

---

## Цель

На `x-disk` установлен актуальный Telegram Desktop из `nixpkgs-unstable`.

---

## Scope

**Входит в scope:**
- Переключить `telegram-desktop` на `pkgs-unstable.telegram-desktop` для `x-disk`.

**НЕ входит в scope:**
- Перевод всей системы на `nixos-unstable`.
- Обновление Telegram на других хостах.
- Изменение VSCode.

---

## Ограничения

- Базовый канал остаётся `nixos-25.05`.
- Используется уже заведённый паттерн `pkgs-unstable` из task 004.

---

## Acceptance Criteria

- [ ] `nix build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link`
      проходит.
- [ ] После применения `telegram-desktop` соответствует версии из
      `nixpkgs-unstable`.

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config
nix --extra-experimental-features 'nix-command flakes' build .#nixosConfigurations.x-disk.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#x-disk
telegram-desktop --version
```

---

## Rollback / Safety

Вернуть `telegram-desktop` в список `with pkgs; [ ... ]` и убрать
`pkgs-unstable.telegram-desktop`.
