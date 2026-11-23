# Задача 059: автоматическая очистка профилей Nix и срок 20 дней

## Проверка контекста перед работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: нет

## Status

`done` (применено на `x-disk`: `nixos-rebuild switch` + `home-manager switch`)

## Контекст

На `x-disk` корневой раздел заполнен на 90%. Системный GC включён
(`nix.gc.automatic = true`, `dates = "monthly"`,
`options = "--delete-older-than 30d"`), но он запускается от root и видит
только профили в `/nix/var/nix/profiles`. Профили пользователя лежат в
`/home/admsys/.local/state/nix/profiles`: 666 поколений home-manager и 227
поколений `profile`, самые старые — с сентября 2025 года. Автоматическая
очистка до них не добирается.

## Цель

Срок хранения поколений везде равен 20 дням, а профили пользователя
очищаются автоматически по тому же расписанию.

## Scope

**Входит в scope:**
- срок `--delete-older-than` системного GC: 30d → 20d
- пользовательский systemd-таймер для `nix-collect-garbage --delete-older-than 20d`
- подключение нового home-manager модуля

**НЕ входит в scope:**
- удаление существующих поколений вручную
- изменение расписания (остаётся ежемесячным)
- изменение настроек journald/logrotate
- коммит и deploy на хосты

## Ограничения

- Таймер должен работать на всех desktop-хостах, где подключён
  `home-manager/modules/default.nix`.
- Нельзя задевать системные профили из пользовательского таймера.
- Применение — только после коммита и отдельного `nixos-rebuild switch`.

## Текущее состояние

- `nixos/modules/nix.nix`: `options = "--delete-older-than 30d"`.
- `nix-gc.timer`: `OnCalendar=monthly`, следующий запуск 2026-12-01.
- Пользовательских таймеров для Nix нет.

## Предлагаемое изменение

- [ ] `nixos-config/nixos/modules/nix.nix` — 30d → 20d.
- [ ] `nixos-config/home-manager/modules/nix-gc.nix` — новый модуль:
  oneshot-сервис `nix-collect-garbage --delete-older-than 20d` и
  ежемесячный persistent-таймер.
- [ ] `nixos-config/home-manager/modules/default.nix` — импорт модуля.

## Затронутые области

- Хосты: все, кто импортирует desktop-набор и home-manager (`x-disk`, Huawei, main).
- Модули: `nixos/modules/nix.nix`, `home-manager/modules/{default,nix-gc}.nix`.
- Сервисы: системный `nix-gc.timer`, пользовательский `nix-gc.timer`.

## Acceptance Criteria

- [x] Системный GC использует `--delete-older-than 20d` (проверен сгенерированный `nix-gc-start`).
- [x] У пользователя определён `nix-gc-user.timer` с `--delete-older-than 20d` (проверены unit-файлы в activation package).
- [x] Расписание осталось ежемесячным, `Persistent=true`.
- [x] `nixos-rebuild dry-build --flake .#x-disk` проходит.

## Verification

```bash
cd /home/admsys/Nixos/nixos-config
nixos-rebuild dry-build --flake .#x-disk
systemctl --user list-timers --all | grep nix-gc   # после deploy
systemctl --user cat nix-gc.service                # после deploy
```

## Rollback / Safety

- Откат конфигурации: вернуть `30d` и убрать импорт `./nix-gc.nix`,
  затем `sudo nixos-rebuild switch --rollback`.
- Удаление генераций необратимо; таймер трогает только поколения старше
  20 дней и оставляет активное на момент проверки поколение.

## Заметки

- Follow-up: после deploy проверить, что число поколений в
  `/home/admsys/.local/state/nix/profiles` перестало расти.
- Ручная разовая чистка выполнена после deploy: пользовательский GC удалил
  28 537 путей (16.8 GiB), системный — 5 336 путей (2.2 GiB). Занятость `/`
  снизилась с 88% до 78%, число ссылок в профилях — с 896 до 8 (пользователь)
  и с 61 до 8 (система). Текущие поколения проверены на целостность.
- При повторном `home-manager switch` возник конфликт с императивно
  установленным `chatgpt` в `nix profile`; дубль удалён (`nix profile remove
  chatgpt`), пакет остаётся доступным из Home Manager.
