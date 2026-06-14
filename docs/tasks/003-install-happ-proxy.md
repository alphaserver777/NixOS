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

`in progress`

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

- [ ] `nixos-rebuild dry-build --flake .#x-disk` проходит
- [ ] `sudo nixos-rebuild switch` проходит на `main`, `x-disk`, `Huawei`
- [ ] Бинарь `happ` доступен в `$PATH` и запускается без `error loading shared libraries`
- [ ] `.desktop`-файл подхватывается launcher'ом (иконка появляется в меню приложений)
- [ ] При запуске GUI открывается главное окно Happ
- [ ] Прокси-конфиг можно добавить и подключиться (минимум: subscription import, VLESS connect)
- [ ] Изменения зафиксированы в commit'е `feat: установка Happ proxy-клиента` + `Closes: docs/tasks/003-install-happ-proxy.md`

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

- **Имя бинаря:** главный GUI — `Happ` (с большой H) в `/opt/happ/bin/`. Wrapper в `$out/bin/happ` (нижний регистр) для удобства.
- **Bundled core:** в пакете есть `core/xray` (Xray-core), `tun/sing-box`, `tun2/tun2proxy-bin`, `antifilter/antifilter`. Все они в `/opt/happ/bin/...` — autoPatchelfHook должен пропатчить их вместе с главным бинарём.
- **`qt.conf`** рядом с `Happ` бинарём (80 байт) указывает Qt-фреймворку, где искать plugins/qml. Если относительные пути — должно работать сразу, если абсолютные — потребуется substituteInPlace.
- **Follow-up:** включение TUN-mode (daemon happd через `systemd.services` + polkit) — отдельная задача, заводить только если действительно нужен системный VPN-mode, а не user-space proxy.
- **Follow-up:** проверить, есть ли смысл также установить `pkgs.xray` (CLI ядро из nixpkgs) для использования вне Happ. Пока не очевидно, что нужно.
- **Follow-up:** если пользователь захочет, чтобы Happ автозапускался в трее при логине — отдельная задача через home-manager.
