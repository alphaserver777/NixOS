# Task 003: установка Happ proxy-клиента

## Проверка Контекста Перед Работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: `docs/tasks/002-install-assistant-replace-rustdesk.md` (вводит общий packaging-паттерн)

---

## Status

`partial` — установка и запуск работают, основное окно открывается,
backend daemon подключается, прокси-конфиги из существующего хранилища
загружаются. Но **диалоги Add Configuration / Settings нерабочие** из-за
upstream-бага: Happ зависит от не-bundled QML-модуля `kvantum`, без
которого custom QML-типы (`isDark`, `iconName`, `onButtonClicked`)
отваливаются и фейлят создание диалогов.

---

## Контекст

Пользователь запросил установку **Happ** — кроссплатформенного proxy-клиента на базе Xray-ядра. Поддерживает VLESS (Reality), VMess, Trojan, Shadowsocks, Socks. Также есть TUN/VPN-режим через sing-box и anti-censorship (byedpi).

Производитель: FlyFrog LLC, дистрибутив на GitHub (`Happ-proxy/happ-desktop`), `.deb`/`.rpm`/`.pkg.tar.zst`. Качество запакован — bundled Qt6 + core/xray + tun/sing-box + tun2 + antifilter.

Версия на момент задачи: **2.17.1** (опубликована 2026-06-02).

---

## Цель

Happ 2.17.1 (GUI) установлен и запускается на всех трёх desktop-хостах (`x-disk`, `Huawei`, `main`).

---

## Scope

**Входит в scope:**
- Derivation `nixos-config/packages/happ.nix` (`stdenv.mkDerivation` + `autoPatchelfHook` + `dpkg`), переиспользует паттерн из задачи 002
- System-модуль `nixos-config/nixos/modules/happ.nix` — пакет через `environment.systemPackages`
- Подключение модуля в `nixos-config/nixos/modules/default.nix`
- Применение на `x-disk`, `Huawei`, `main`
- В `.deb` лежит `/usr/share/applications/Happ.desktop` с `Exec=/opt/happ/bin/Happ` — в derivation нужно перешить путь под `$out`
- Иконка `/usr/share/icons/hicolor/256x256/apps/happ.png` — копируем как есть в `$out/share/icons/`

**НЕ входит в scope:**
- **systemd-юнит `happd.service`** (daemon для TUN-режима, лежит в `.deb` как `/etc/systemd/system/happd.service`). Daemon работает с `User=root` и требует privileged операций (sing-box + TUN-интерфейс). В этой задаче — **только GUI без TUN-режима**. Прокси через VLESS/VMess/Trojan/Shadowsocks из user-space работает без daemon. TUN-режим — отдельная задача (требует `systemd.services.happd` в NixOS-модуле, polkit-правил, открытия `tun` device).
- Настройка прокси-серверов: пользователь добавляет вручную через GUI (`~/.config/Happ`)
- `antifilter`/`byedpi` функциональность (зависит от daemon)
- Установка CLI-only `xray` (есть в nixpkgs как отдельный пакет, не пересекается)

---

## Ограничения

- Пакет проприетарный (GUI), unfree. `nixpkgs.config.allowUnfree = true` уже включён глобально.
- Конфиги Happ (прокси-серверы, ключи) хранятся в `~/.config/Happ`. Это **вне SDD-scope** этой задачи (per-user runtime config, не управляется Nix).
- Bundled Xray-core может конфликтовать с системным `pkgs.xray`, если установить оба. Сейчас системного xray нет — конфликта не будет.
- В `.deb` есть symlink `/usr/bin/happ -> /opt/happ/bin/Happ` с захардкоженным путём — в derivation создаём свой wrapper в `$out/bin/happ`.

---

## Текущее состояние

- В `nixos-config/packages/` есть `lazyssh.nix` (Go), и параллельно задачей 002 заводится `assistant.nix` по нужному нам шаблону (`stdenv.mkDerivation + autoPatchelfHook + dpkg`)
- В `nixos/modules/` нет `happ.nix`
- В nixpkgs пакет Happ отсутствует (есть только `xray` ядро отдельно, и `v2rayn`/`v2raya` — другие GUI)

---

## Предлагаемое изменение

- [ ] Создать `nixos-config/packages/happ.nix`:
  - `pname = "happ"`, `version = "2.17.1"`
  - `src = fetchurl { url = "https://github.com/Happ-proxy/happ-desktop/releases/download/2.17.1/Happ.linux.x64.deb"; sha256 = "..."; }`
  - `nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ]`
  - `buildInputs` — стартовый набор: glibc, openssl, X11 base, libxkbcommon, mesa, alsa-lib, libpulseaudio, dbus, fontconfig, freetype. Bundled Qt6 в `/opt/happ/lib/` — autoPatchelfHook должен находить их через RPATH; если нет — добавить `appendRunpaths = [ "$out/opt/happ/lib" ]`
  - `installPhase`:
    - `mkdir -p $out/opt && cp -r opt/happ $out/opt/`
    - `install -Dm644 usr/share/applications/Happ.desktop $out/share/applications/Happ.desktop` + `substituteInPlace` `/opt/happ/bin/Happ` → `$out/opt/happ/bin/Happ`
    - `install -Dm644 usr/share/icons/hicolor/256x256/apps/happ.png $out/share/icons/hicolor/256x256/apps/happ.png`
    - `install -Dm644 usr/share/mime/packages/happ-mime.xml $out/share/mime/packages/happ-mime.xml`
    - Wrapper: `makeWrapper $out/opt/happ/bin/Happ $out/bin/happ` (или просто symlink, если `Happ` сам находит свои либы)
  - **Не** копировать `etc/systemd/system/happd.service` (вне scope, см. выше)
- [ ] Создать `nixos-config/nixos/modules/happ.nix`:
  ```nix
  { pkgs, ... }:
  {
    environment.systemPackages = [ (pkgs.callPackage ../../packages/happ.nix { }) ];
  }
  ```
- [ ] Добавить `./happ.nix` в imports в `nixos/modules/default.nix`

---

## Затронутые области

- **Хосты:** `x-disk`, `Huawei`, `main`
- **Модули:** новый `nixos/modules/happ.nix`, новый `packages/happ.nix`, изменён `nixos/modules/default.nix`
- **Сервисы:** нет (без systemd-юнитов в этой задаче)
- **Сетевые порты:** Happ слушает на `127.0.0.1` для локального прокси (порт настраивается в GUI, по умолчанию ~10808/10809)

---

## Acceptance Criteria

- [x] `nix build .#nixosConfigurations.x-disk.config.system.build.toplevel`
      проходит
- [x] `sudo nixos-rebuild switch --flake .#x-disk` проходит
- [ ] `sudo nixos-rebuild switch --flake .#Huawei` — отложено до фактического
      использования
- [ ] `sudo nixos-rebuild switch --flake .#main` — отложено до фактического
      использования
- [x] Бинарь `happ` доступен в `$PATH` и запускается без
      `error loading shared libraries`
- [x] `.desktop`-файл подхватывается launcher'ом, иконка в меню
- [x] Главное окно открывается (с `QT_STYLE_OVERRIDE=Fusion`), daemon
      подключается (`DaemonManager: Connected to daemon`), backend в idle
- [x] Изменения зафиксированы в коммитах `395c3a8`, `60da1a8`, `71eb4fa`

---

## Verification

```bash
cd /home/admsys/Nixos/nixos-config

# 1. SHA256 для Happ.linux.x64.deb версии 2.17.1
nix-prefetch-url 'https://github.com/Happ-proxy/happ-desktop/releases/download/2.17.1/Happ.linux.x64.deb'

# 2. Подставить sha256 в packages/happ.nix

# 3. Dry-build
nixos-rebuild dry-build --flake .#$(hostname)

# 4. Если упадёт на autoPatchelfHook — итерировать buildInputs

# 5. Применить на main
sudo nixos-rebuild switch --flake .#main

# 6. Запустить
happ &  # GUI должно открыться

# 7. На x-disk и Huawei
sudo nixos-rebuild switch --flake .#x-disk
sudo nixos-rebuild switch --flake .#Huawei
```

---

## Rollback / Safety

Аддитивно — новый модуль + строка импорта.

```bash
sudo nixos-rebuild switch --rollback
```

Либо удалить `./happ.nix` из `nixos/modules/default.nix` и пересобрать. Конфиги пользователя в `~/.config/Happ` Nix не трогает — они останутся независимо от состояния пакета.

---

## Заметки

- **Имя бинаря:** главный GUI — `Happ` (с большой H) в `/opt/happ/bin/`.
  Wrapper в `$out/bin/happ` (нижний регистр).
- **Bundled core:** `core/xray`, `tun/sing-box`, `tun2/tun2proxy-bin`,
  `antifilter/antifilter` — все в `/opt/happ/bin/...`, autoPatchelfHook
  пропатчил их вместе с главным бинарём.
- **`qt.conf`** рядом с `Happ` (`Prefix = ..`, `Plugins = lib/plugins`)
  — относительные пути, работает сразу.

### Хронология фиксов

1. **Итерация 1 (`395c3a8`) — autoPatchelfHook.** Бинарь стартовал, но
   фейлил с `qt.tlsbackend.ossl: Failed to load libssl/libcrypto`. Qt6 TLS
   plugin `libqopensslbackend.so` подгружает libssl/libcrypto через
   `dlopen` в runtime, autoPatchelf этого не видит (нет DT_NEEDED).

2. **Итерация 2 (`60da1a8`) — `LD_LIBRARY_PATH=${openssl}/lib`.** TLS
   заработал, но QML-движок ругался: `module "kvantum" is not installed`
   при загрузке `Main.qml`.

3. **Итерация 3 (`71eb4fa`) — `QT_STYLE_OVERRIDE=Fusion +
   QT_QUICK_CONTROLS_STYLE=Fusion` через `--set-default`.** Happ
   использует QML-import `kvantum`, которого нет в bundled `lib/qml/`
   и в nixpkgs (kvantum существует только для Qt5). С Fusion-стилем
   окно открывается, daemon подключается, backend в idle, прокси-конфиги
   подгружаются.

4. **Итерация 4 (`<followup>`) — `--set` вместо `--set-default`.**
   Stylix в проекте автоматически задаёт `QT_STYLE_OVERRIDE=kvantum`
   для всех Qt-приложений на уровне пользовательской сессии.
   `--set-default` не перебивает уже заданную переменную, поэтому
   Happ продолжал получать `kvantum`, Main.qml падал, приложение
   мгновенно exits. Заменили на `--set`, который форсит Fusion даже
   при наличии другого значения в окружении.

Оставшиеся QML-warning'и при работе (`Cannot assign to non-existent
property "iconName" / "isDark" / "onButtonClicked"`) — это kvantum-
specific properties в исходниках Happ, без kvantum они просто
игнорируются, на функциональность не влияют.

### Known limitation: kvantum upstream-баг

После всех фиксов Happ запускается, но **диалоги Add Configuration /
Settings не работают**. Корневая причина:

1. Happ зависит от QML-модуля `kvantum`. Без него Main.qml не загружается
   (фикс через `QT_STYLE_OVERRIDE=Fusion` обходит загрузку Main.qml,
   но не помогает с диалогами).
2. `kvantum` в nixpkgs есть только для Qt5 (`libsForQt5.qtstyleplugin-
   kvantum`) — это native style plugin, а не QML-модуль. Для Qt6 нет.
3. Upstream забыл его упаковать: в Arch `.pkg.tar.zst` (PKGINFO) нет
   зависимости от kvantum даже в `optdepend`.
4. Эксперимент со stub QML-модулем (`module kvantum` в `qmldir`)
   убрал import-ошибку, но проблема глубже — QML-типы `HappStyle`
   ссылаются на properties (`isDark`, `iconName`, `onButtonClicked`),
   которые определены в kvantum. Без реальной реализации kvantum-типов
   эти properties отсутствуют, и `Qt.createQmlObject()` фейлит.
5. CLI у Happ нет — `happd --help` показывает только версию/help.
   Headless-управления подписками не существует.

**Что работает:**
- Запуск и главное окно
- Backend daemon connect
- Загрузка существующих субскрипций из `~/.config/Happ/`
- Отображение существующих серверов

**Что не работает:**
- Добавление новых конфигов через GUI («+» / Add Configuration)
- Settings dialog
- Любое взаимодействие, требующее custom QML-типов из kvantum

**Обходные пути для пользователя:**
- Получить готовые subscription URLs/configs от провайдера на iOS/
  Windows Happ-клиенте, перенести `~/.config/Happ/` файлы вручную
  (если получится разобрать формат)
- Открыть upstream issue: https://github.com/Happ-proxy/happ-desktop —
  что Linux релиз неполный (либо bundle kvantum, либо убрать
  зависимость из QML)
- Альтернативные клиенты: `v2rayN`/`v2raya` в nixpkgs, но они не
  понимают проприетарный `happ://` URL-формат (нужны стандартные
  VLESS/VMess/Trojan URI)

### Follow-up

- TUN-mode (daemon `happd.service` через `systemd.services` + polkit) —
  отдельная задача, заводить только если нужен системный VPN-mode.
- Установка `pkgs.xray` (CLI из nixpkgs) — пока нет необходимости.
- Автозапуск в трее — через home-manager, если потребуется.
- Пакетирование `kvantum` для Qt6 — на уровне nixpkgs/upstream, не здесь.
