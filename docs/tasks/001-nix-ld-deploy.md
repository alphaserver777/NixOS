# Task 001: nix-ld — поддержка dynamically-linked бинарей

## Проверка Контекста Перед Работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [ ] Связанные task specs: нет

---

## Status

`in progress`

---

## Контекст

При установке расширения Claude Code для VS Code обнаружено, что встроенный
бинарь расширения динамически слинкован и не запускается на NixOS без
специальной настройки. Стандартный путь на NixOS — включить `programs.nix-ld`,
который предоставляет `ld.so`-совместимость для таких бинарей.

Модуль `nixos-config/nixos/modules/nix-ld.nix` был создан и добавлен в
`nixos/modules/default.nix`. На момент создания этого spec — файл staged
в Git, но не закоммичен. `default.nix` также изменён (unstaged).

---

## Цель

Обеспечить запуск dynamically-linked бинарей (в первую очередь бинарь
Claude Code для VS Code) на всех desktop-хостах через `programs.nix-ld`.

---

## Scope

**Входит в scope:**
- Модуль `nixos/modules/nix-ld.nix` — создан, подключить к `default.nix`
- Проверить на `x-disk` (основная рабочая станция) и `Huawei` (ноутбук)
- Зафиксировать изменения в commit

**НЕ входит в scope:**
- Настройка nix-ld на серверных хостах (`srv-home-min` и др.) — отдельная
  задача, если понадобится
- Другие проблемы с dynamically-linked бинарями помимо Claude Code

---

## Ограничения

- `programs.nix-ld` применяется через `default.nix`, то есть включится на
  **всех** desktop-хостах: `Huawei`, `x-disk`, `main`.
  Убедиться, что это не вызывает конфликтов ни на одном из них.
- Минимальный набор библиотек (`stdenv.cc.cc`, `zlib`, `openssl`) — не
  добавлять лишнего без явной причины.

---

## Текущее состояние

```
A  nixos-config/nixos/modules/nix-ld.nix     ← новый файл, staged
 M nixos-config/nixos/modules/default.nix    ← изменён (import добавлен), unstaged
 M nixos-config/hosts/x-disk/local-packages.nix   ← параллельные изменения
 M nixos-config/nixos/modules/udisks.nix     ← параллельные изменения
```

Содержимое `nix-ld.nix`:
```nix
{ pkgs, ... }:
{
  # Allows generic Linux binaries bundled by editor extensions to run on NixOS.
  # Claude Code for VS Code ships a dynamically linked native binary.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };
}
```

---

## Предлагаемое изменение

- [x] `nixos-config/nixos/modules/nix-ld.nix` — создан
- [ ] `nixos-config/nixos/modules/default.nix` — добавить `./nix-ld.nix`
      в imports (файл уже изменён, нужно staged + commit)
- [ ] Применить `nixos-rebuild switch` на `x-disk`
- [ ] Применить `nixos-rebuild switch` на `Huawei`
- [ ] Зафиксировать всё в commit

---

## Затронутые области

- **Хосты:** `x-disk`, `Huawei`, `main` (все импортируют `nixos/modules/default.nix`)
- **Модули:** `nixos/modules/default.nix`, новый `nixos/modules/nix-ld.nix`
- **Сервисы:** нет
- **Серверные хосты:** не затронуты (используют `nixos/modules/server/`)

---

## Acceptance Criteria

- [ ] `programs.nix-ld.enable = true` присутствует в итоговой конфигурации
      `x-disk` и `Huawei`
- [ ] `nixos-rebuild switch` проходит без ошибок на `x-disk`
- [ ] `nixos-rebuild switch` проходит без ошибок на `Huawei`
- [ ] Бинарь Claude Code для VS Code запускается без ошибки
      `cannot execute binary file` или `error loading shared libraries`
- [ ] Изменения зафиксированы в commit с понятным сообщением

---

## Verification

```bash
# 1. Dry-build перед применением
cd /home/admsys/Nixos/nixos-config
nixos-rebuild dry-build --flake .#x-disk

# 2. Применить
sudo nixos-rebuild switch --flake .#x-disk

# 3. Проверить, что опция активна
nixos-option programs.nix-ld.enable
# Ожидаемый вывод: true

# 4. Проверить наличие ld-linux в системе
ls /run/current-system/sw/share/nix-ld/
# Должен быть ld-linux-x86-64.so.2 или аналог

# 5. Запустить Claude Code в VS Code и убедиться, что расширение загружается
# (ручная проверка)

# 6. На Huawei — аналогично шагам 1-4
```

---

## Rollback / Safety

`programs.nix-ld` — аддитивное изменение. Оно не ломает существующие
нативные NixOS-бинари. Если возникнут проблемы:

```bash
sudo nixos-rebuild switch --rollback
```

Или убрать `./nix-ld.nix` из imports в `default.nix` и пересобрать.

---

## Заметки

- Параллельно в этом же staging-наборе: изменения в `udisks.nix` и
  `x-disk/local-packages.nix`. Их можно закоммитить в одном commit или
  раздельно — по усмотрению.
- Если потребуются дополнительные библиотеки для других инструментов
  (например, Python-расширений VS Code) — создать отдельную задачу,
  не расширять этот модуль молча.
- Follow-up: рассмотреть нужность nix-ld на `srv-home-min`, если
  планируется remote development через SSH.
