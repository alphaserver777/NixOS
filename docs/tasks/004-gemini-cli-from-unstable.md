# Task 004: обновление gemini-cli через nixpkgs-unstable

## Проверка Контекста Перед Работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: нет

---

## Status

`done`

---

## Контекст

Gemini CLI при запуске показал уведомление:
```
Gemini CLI update available! 0.1.5 → 0.46.0
```

В текущем канале `nixos-25.05` (см. `flake.nix:6`) `gemini-cli`
зафиксирован на **0.1.5** и обновлений до перехода на новый канал
(`25.11`) не будет. В `nixos-unstable` сейчас доступна версия
**0.43.0** (близко к latest 0.46.0).

`npm install -g @google/gemini-cli` — инструкция из uphstream — против
духа NixOS и этого репо (нет writable global prefix по умолчанию,
ломается декларативность).

---

## Цель

`gemini-cli` обновляется автоматически вслед за `nixos-unstable`
каналом, не затрагивая остальные пакеты, которые остаются на
стабильном `25.05`.

---

## Scope

**Входит в scope:**
- Добавление `nixpkgs-unstable` в `inputs` `flake.nix`
- Передача `pkgs-unstable` через `specialArgs` в NixOS-конфигурации
- Переключение `gemini-cli` в `hosts/x-disk/local-packages.nix` на
  `pkgs-unstable.gemini-cli`
- Зафиксированный паттерн «cherry-pick из unstable» — на будущее, для
  других bleeding-edge пакетов

**НЕ входит в scope:**
- Перевод всей системы на nixos-unstable
- Перенос других пакетов на unstable (только gemini-cli)
- Изменения на других хостах (`Huawei`, `main`, серверы) — у них
  своего gemini-cli нет, но паттерн станет доступен и для них
- `homeConfigurations` — пока не трогаем, gemini-cli идёт через
  system path

---

## Ограничения

- `unstable` обновляется часто → при каждом `nix flake update` будет
  большой diff в `flake.lock`. Это окей, регулярные обновления.
- Не смешивать unstable-пакеты, которые тянут общие зависимости с
  системой (например, glibc) — иначе двойные копии в `/nix/store` и
  потенциальный ABI mismatch. `gemini-cli` — это Node.js приложение,
  riskа нет.
- Стабильный `nixos-25.05` остаётся канонiчным каналом, в `architecture.md`
  и `constitution.md` это правило не меняется.

---

## Текущее состояние

- В `flake.nix` один nixpkgs-input: `github:nixos/nixpkgs/nixos-25.05`
- `gemini-cli` подключается в `hosts/x-disk/local-packages.nix:96`
  через `environment.systemPackages = with pkgs; [ ... gemini-cli ... ]`

---

## Предлагаемое изменение

- [ ] В `flake.nix` добавить input:
  ```nix
  nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  ```
- [ ] В `flake.nix` → `makeSystem` → `specialArgs` добавить:
  ```nix
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  ```
- [ ] В `hosts/x-disk/local-packages.nix`:
  - Принять `pkgs-unstable` в args: `{ pkgs, pkgs-unstable, ... }:`
  - Заменить `gemini-cli` в списке на `pkgs-unstable.gemini-cli`
- [ ] Запустить `nix flake lock --update-input nixpkgs-unstable` (или
  `nix flake update` для добавления нового input)
- [ ] Проверить через `nix build .#nixosConfigurations.x-disk...`
- [ ] Применить через `sudo nixos-rebuild switch`

---

## Затронутые области

- **Хосты:** `x-disk` (только он использует gemini-cli)
- **Модули:** `flake.nix` (shared), `hosts/x-disk/local-packages.nix`
- **Сервисы:** нет
- **Disk size:** +~200-400 MB в /nix/store (отдельный nixpkgs снимок)

---

## Acceptance Criteria

- [x] `nix build .#nixosConfigurations.x-disk.config.system.path`
      проходит
- [x] `sudo nixos-rebuild switch --flake .#x-disk` проходит без ошибок
- [x] `gemini --version` показывает **0.43.0** (поднялся с 0.1.5)
- [x] Остальные пакеты не подскочили — diff системы только nodejs +
      gemini-cli + их deps
- [x] Изменения зафиксированы в commit'е `8ffb79a` +
      `Closes: docs/tasks/004-gemini-cli-from-unstable.md`

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config

# 1. Локк свежего unstable
nix --extra-experimental-features 'nix-command flakes' flake update

# 2. Dry-build
nixos-rebuild dry-build --flake .#x-disk

# 3. Apply
sudo nixos-rebuild switch --flake .#x-disk

# 4. Verify version
gemini --version
# Ожидаемый вывод: 0.43.x или выше
```

---

## Rollback / Safety

Аддитивное изменение — новый input + переключение одного пакета.

```bash
sudo nixos-rebuild switch --rollback
```

Если в `nix flake update` подтянулось что-то ломающее — можно
откатить `flake.lock` через `git checkout flake.lock`.

---

## Заметки

- Паттерн «cherry-pick из unstable» через `pkgs-unstable` в
  `specialArgs` повторно используется для любого пакета: в нужном
  месте просто `pkgs-unstable.<name>` вместо `pkgs.<name>`.
- При следующем переходе на `nixos-25.11` (или новее) — этот
  override можно убрать, если в стабильном канале появится свежая
  версия `gemini-cli`.

### Breaking change в settings.json при обновлении

Между 0.1.5 и 0.43.0 в Gemini CLI изменилась JSON-схема:
поле `model` перестало быть строкой и стало объектом. После
`nixos-rebuild switch` приложение выдало:
```
Invalid configuration in ~/.gemini/settings.json:
Error in: model
    Expected object, received string
```
Фикс: `"model": "auto"` → `"model": {"name": "auto"}`.
Backup сохранён как `~/.gemini/settings.json.bak`. Это файл вне
репозитория (user state), nix-конфиг не меняет — правка ручная.

### Follow-up

- В `constitution.md` добавить пункт про cherry-pick правила, чтобы
  не плодить unstable-пакеты бесконтрольно — отдельная задача.
