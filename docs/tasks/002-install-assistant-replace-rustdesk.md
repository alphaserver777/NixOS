# Task 002: установка «Ассистент» как замена RustDesk

## Проверка Контекста Перед Работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: `docs/tasks/003-install-happ-proxy.md` (реализуется параллельно)

---

## Status

`done`

---

## Контекст

В commit `884cd39 "Убрал rustdesk"` (28.05.2026) был удалён модуль `nixos-config/home-manager/modules/rustdesk.nix` и из `flake.nix` исчез блок `allowedUnfreeNames` со ссылками на `rustdesk`/`libsciter`. Это означает: проект отказался от RustDesk в пользу другого remote access решения.

В качестве замены устанавливается **«Ассистент»** от ГК САФИБ — российский remote access (аналог TeamViewer/AnyDesk).
Источник: https://xn--80akicokc0aablc.xn--p1ai (сайт «ассистент.рф»), производитель: ГК «САФИБ».
Текущая версия на момент задачи: **6.5 (27.10.2025)**.

Дистрибутив: `.deb` по прямой ссылке `https://lk2.xn--80akicokc0aablc.xn--p1ai/WebApi/Platforms/Download/1375` (URL без версии в пути — отдаёт latest).

---

## Цель

«Ассистент» 6.5 установлен и запускается на всех трёх desktop-хостах (`x-disk`, `Huawei`, `main`). RustDesk-следов в репозитории не осталось.

---

## Scope

**Входит в scope:**
- Derivation `nixos-config/packages/assistant.nix` (`stdenv.mkDerivation` + `autoPatchelfHook` + `dpkg`)
- System-модуль `nixos-config/nixos/modules/assistant.nix`, подключающий пакет через `environment.systemPackages`
- Подключение модуля в `nixos-config/nixos/modules/default.nix`
- Применение на `x-disk`, `Huawei`, `main`
- Обновление `docs/constitution.md`: убрать упоминание `allowedUnfreeNames` (секция уже удалена из flake.nix, текущий механизм — глобальный `allowUnfree = true` в [home-packages.nix:2](../../nixos-config/home-manager/home-packages.nix#L2))
- Обновление `docs/architecture.md`: подтвердить, что `main` — активный desktop-хост, а не «статус неизвестен»

**НЕ входит в scope:**
- Настройка автозапуска «Ассистент» при логине
- Установка серверной части
- Установка на серверные хосты (`srv-home`, `srv-home-gui`, `srv-home-min`)
- Реализация Happ — это задача 003

---

## Ограничения

- Пакет проприетарный, unfree. `nixpkgs.config.allowUnfree = true` уже включён глобально в [home-packages.nix:2](../../nixos-config/home-manager/home-packages.nix#L2) — отдельных правок `allowedUnfreePredicate` не нужно. **Проверить**, что unfree-проверка не падает (если падает — добавить `nixpkgs.config.allowUnfreePredicate` или `nixpkgs.config.allowUnfree = true` в системной конфигурации, а не только в HM).
- Изменение в `nixos/modules/default.nix` затронет все desktop-хосты — это и есть цель.
- URL `.deb` не содержит версию — `sha256` зафиксирован для текущего файла. При обновлении upstream `fetchurl` упадёт явно, и понадобится bump через новую задачу.

---

## Текущее состояние

- RustDesk удалён (см. commit `884cd39`)
- В `nixos-config/packages/` есть только `lazyssh.nix` (Go-пакет)
- Шаблона для упаковки `.deb` в репо ещё нет — задача 002 заводит этот паттерн (его потом переиспользует задача 003 для Happ)
- В `nixos/modules/default.nix` нет ни `assistant.nix`, ни `happ.nix`

---

## Предлагаемое изменение

- [ ] Создать `nixos-config/packages/assistant.nix` — derivation на базе `stdenv.mkDerivation` + `autoPatchelfHook` + `dpkg`
  - `pname = "assistant"`, `version = "6.5"`
  - `src = fetchurl { url = "https://lk2.xn--80akicokc0aablc.xn--p1ai/WebApi/Platforms/Download/1375"; sha256 = "..."; }`
  - `buildInputs` — финализировать после первого dry-build (типично: Qt5/6, gtk3, openssl, libxcb, alsa)
  - Если бинарь в `/opt/...`, а не в `usr/bin/` — добавить symlink/makeWrapper в `$out/bin/`
- [ ] Создать `nixos-config/nixos/modules/assistant.nix` — system модуль:
  ```nix
  { pkgs, ... }:
  {
    environment.systemPackages = [
      (pkgs.callPackage ../../packages/assistant.nix { })
    ];
  }
  ```
- [ ] Добавить `./assistant.nix` в imports в [`nixos/modules/default.nix`](../../nixos-config/nixos/modules/default.nix)
- [ ] Обновить `docs/constitution.md` — поправить устаревшее упоминание `allowedUnfreeNames`
- [ ] Обновить `docs/architecture.md` — поправить запись про `main` (активный хост)
- [ ] Обновить `docs/devplan.md` — отметить задачу 002 в Этапе 0

---

## Затронутые области

- **Хосты:** `x-disk`, `Huawei`, `main` (все импортируют `nixos/modules/default.nix`)
- **Модули:** новый `nixos/modules/assistant.nix`, новый `packages/assistant.nix`, изменён `nixos/modules/default.nix`
- **Сервисы:** нет (без systemd-юнитов)
- **Сетевые порты:** «Ассистент» работает через outbound HTTPS к серверам ГК САФИБ; локальные порты не открываем

---

## Acceptance Criteria

- [x] `nix build .#nixosConfigurations.x-disk.config.system.build.toplevel`
      проходит без ошибок
- [x] `sudo nixos-rebuild switch --flake .#x-disk` проходит — подтверждено
      пользователем
- [ ] `sudo nixos-rebuild switch --flake .#Huawei` — отложено до фактического
      использования на ноутбуке
- [ ] `sudo nixos-rebuild switch --flake .#main` — отложено до фактического
      использования
- [x] Бинарь «Ассистент» запускается без `error loading shared libraries`
- [x] `.desktop`-файл подхватывается launcher'ом (wofi) — иконка в меню
- [x] Главное окно открывается, получен ID/пароль, виден список партнёров
- [x] Подключение к удалённому компьютеру KOMPUTER устанавливается, и
      окно удалённого desktop корректно рендерится (а не серый прямоугольник)
- [x] Изменения зафиксированы в семи коммитах:
      `395c3a8 87d9e8b f9f00a8 eb546d4 f0b27a8 8220537` (последний —
      решающий, плюс cleanup ложных фиксов)

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config

# 1. Получить sha256
nix-prefetch-url 'https://lk2.xn--80akicokc0aablc.xn--p1ai/WebApi/Platforms/Download/1375'

# 2. Подставить sha256 в packages/assistant.nix

# 3. Dry-build на текущем хосте
nixos-rebuild dry-build --flake .#$(hostname)

# 4. Если упало на autoPatchelfHook («cannot find: libXXX»):
#    дополнить buildInputs соответствующим пакетом из nixpkgs,
#    перезапустить dry-build, итерировать пока не пройдёт

# 5. Применить на main (наименее критичный)
sudo nixos-rebuild switch --flake .#main

# 6. Запуск и проверка
which assistant 2>/dev/null || ls /run/current-system/sw/bin/ | grep -i assist
assistant &  # должно открыться окно

# 7. Если ок — применить на x-disk и Huawei
sudo nixos-rebuild switch --flake .#x-disk
sudo nixos-rebuild switch --flake .#Huawei
```

---

## Rollback / Safety

Изменение аддитивное — новый модуль + новая строка импорта.

```bash
sudo nixos-rebuild switch --rollback
```

Либо удалить строку `./assistant.nix` из `nixos/modules/default.nix` и пересобрать.

При проблемах со сборкой derivation — пакет не попадёт в систему, текущая конфигурация не нарушится.

---

## Заметки

- **Имя бинаря:** `/opt/assistant/bin/assistant` (главный), плюс sub-процессы
  `master`, `slave`, `astrct`, `asts`, `st`, и бандлёный `ffmpeg`.

### Хронология фиксов (полезно для будущих LLM)

1. **Итерация 1 (`395c3a8`) — autoPatchelfHook.** Бинарь стартовал, открывал
   GTK2 окно на долю секунды и падал с `Runtime error 203` (heap overflow
   в TGtk2WidgetSet). Причина: bundled libs в `/opt/assistant/lib/`
   (`libstdc.so.6.0.31` без `++`, bundled `libssl/libcrypto`) ABI-несовместимы
   с системными nixpkgs-эквивалентами, на которые autoPatchelf переписал
   RPATH'ы бинаря.

2. **Итерация 2 (`87d9e8b`, `f9f00a8`) — переход на `buildFHSEnv`.** Бинарь
   начал проходить инициализацию ("Init started, libraries loaded,
   settings loaded"). Структура:
   - `rawData` (внутренний `stdenv.mkDerivation` с `dontPatchELF /
     dontStrip / dontAutoPatchelf`) — раскладывает `.deb` в `/nix/store`
     без модификации бинарей
   - Основной derivation — `buildFHSEnv` с расширенным `targetPkgs` (GTK2
     runtime, sqlite, nss, openssl, libv4l, pipewire и т.д.)
   - `runScript` (через `writeShellScript`) делает `cd` в `bin/`,
     `LD_LIBRARY_PATH=$rawData/opt/assistant/lib` и `exec ./assistant`

3. **Итерации 3-4 (`eb546d4`, `f0b27a8`) — ложный фикс «шрифты».**
   stdout-лог Lazarus сообщал `Can not load the font`. Перебирали core X11
   bitmap fonts сначала в FHS env, потом через `fonts.packages` на
   системном уровне. **Не помогло.** Выяснилось, что XWayland имеет
   `built-ins` шрифты (`xset q` → `Font Path: built-ins`), и в `xlsfonts`
   видны `fixed`, `-misc-fixed-*`. Шрифты были не причиной серого экрана.
   В рамках финального фикса оба ложных изменения вычищены (commit `<cleanup>`).

4. **Итерация 5 (`8220537`) — решающий фикс.** В файловом логе
   `~/.config/assistant/log/AstCln*.log` (Lazarus пишет туда без stdout-
   буферизации) обнаружено:
   ```
   Failed to load libastrct.so: libXinerama.so.1: cannot open shared object file
   libusbast.so: Unable to load ... (libuuid.so.1: cannot open shared object file)
   ```
   `libastrct.so` — это и есть Remote Control runtime, без неё рендер
   удалённого desktop не работает (serый прямоугольник при успешном
   handshake). Добавлены `xorg.libXinerama`, `util-linux.lib` (libuuid),
   `efivar` (UEFI info, второстепенно).

### Уроки

- При диагностике GUI-приложений на NixOS **stdout-логи Lazarus
  буферизуются** — смотри файловые логи приложения, если они есть
  (`~/.config/<app>/log/...`).
- bundled libs из `.deb` могут иметь свои runtime-зависимости, которые не
  ловит autoPatchelfHook (он патчит только NEEDED). При загрузке через
  `dlopen` в FHS env эти зависимости должны быть в `targetPkgs`.

### Связь с задачей 003

Шаблон `stdenv.mkDerivation + autoPatchelfHook + dpkg` всё равно остался
работающим — для Happ (задача 003) с bundled Qt6 он подошёл. В репозитории
сейчас два валидных паттерна упаковки `.deb`:
- **autoPatchelfHook** — когда bundled libs совместимы с системой (Happ)
- **buildFHSEnv** — когда bundled libs требуют Debian-like окружения
  (Assistant)

### Follow-up задачи

- Применить на `Huawei` и `main` (есть соответствующий пункт в `devplan.md`)
- Автозапуск/трей-иконка через home-manager — если потребуется
- Аудио в чате не работает (`Failed to init Alsa` в логе) — отдельная
  задача если понадобится голосовая связь
