# Задача 060: сетевые TUI и совместимость netwatch с NixOS

## Проверка контекста перед работой

- [x] `docs/WORKFLOW.md`
- [x] `docs/constitution.md`
- [x] `docs/architecture.md`
- [x] `docs/devplan.md`
- [x] `docs/tasks/PROCESS.md`
- [x] `docs/DEPLOYMENT.md`
- [x] Связанные task specs: `004-gemini-cli-from-unstable.md` (паттерн `pkgs-unstable`), `043-mantaray-network-tool-paths.md` (сетевые команды в NixOS), `059-nix-gc-20d-profiles.md` (соседние незакоммиченные изменения)

## Status

`done` (применено на `x-disk`: `sudo nixos-rebuild switch --flake .#x-disk`)

## Контекст

Для диагностики сети пользователю нужны TUI-утилиты на всех хостах. В закреплённом
`nixpkgs` есть `trippy 0.13.0` и `rustnet 1.3.0`, но нет `netwatch`; он доступен
только в `nixpkgs-unstable` как `netwatch-tui 0.30.0`. Пакеты добавлены в общий
`nixos/modules/net.nix`, который импортируется всеми шестью хостами.

После установки `netwatch` показывал дашборд, но вкладка `connections` была пустой:
`0 connections`, `0 process`, `No connections match this filter`. При этом `ss -tunap`
в той же системе показывает десятки соединений с процессами. Запуск
`netwatch --no-sandbox` сразу показал 222 соединения и корректные имена процессов
(`.dcal-wrapped`, `chrome`, `ssh`, `Telegram-wrapped` и др.).

В исходнике 0.30.0 `parse_linux_connections()` получает список через
`Command::new("ss").args(["-tunap"]).output()`. Landlock-sandbox разрешает
`/proc`, `/sys`, `/usr`, `/bin`, `/sbin`, `/lib` и `/etc`, но не `/nix/store`,
где в NixOS находятся и `netwatch`, и `ss`, и их библиотеки. Sandbox применяется
после старта, поэтому сам процесс работает, а дочерний `ss` — нет. Результат:
пустой список соединений без сообщения об ошибке в UI.

## Цель

`netwatch`, `trippy` и `rustnet` доступны на всех хостах, а вкладка соединений
`netwatch` показывает реальные соединения без ручного добавления флагов.

## Scope

**Входит в scope:**
- системные пакеты `trippy`, `rustnet`, `netwatch` из `pkgs-unstable`
- локальная обёртка над `netwatch` с `--no-sandbox`
- явное добавление `iproute2` в PATH обёртки для вызова `ss`
- task spec и verification на всех шести конфигурациях

**НЕ входит в scope:**
- обновление `nixpkgs-unstable` или версии `netwatch`
- патч upstream-исходника и сборка собственного Rust-пакета
- изменение правил межсетевого экрана, VPN/ Happ / MantaRay
- коммит и push

## Ограничения

- Не менять сетевые настройки, маршруты и службы.
- Не назначать дополнительные capabilities вручную: `--no-sandbox` сохраняет
  обычный режим запуска пользователя/root и не требует `cap_net_raw=eip` и т.п.
- Обёртка должна сохранить `meta` и версию исходного пакета.
- Изменение shared-модуля требует `dry-build` для всех шести хостов.

## Текущее состояние

- `nixos/modules/net.nix` уже содержит `pkgs.trippy`, `pkgs.rustnet`,
  `pkgs-unstable.netwatch` (изменение не закоммичено).
- `netwatch 0.30.0` установлен, дашборд работает,connections — пустая.
- `ss` доступен как `/run/current-system/sw/bin/ss`.
- `netwatch --no-sandbox` показывает 222 соединения с атрибуцией процессов.

## Предлагаемое изменение

- [x] `nixos-config/nixos/modules/net.nix` — использовать локальную обёртку
  вместо `pkgs-unstable.netwatch`.
- [x] `nixos-config/packages/netwatch-nixos.nix` — новый derivation на базе
  `symlinkJoin`, который вызывает исходный бинарь с `--no-sandbox` и
  добавляет `${pkgs.iproute2}/bin` в PATH.
- [x] `docs/tasks/060-netwatch-nixos-sandbox.md` — этот spec.
- [ ] `git add -N` для нового `.nix`, `dry-build` всех хостов, deploy на `x-disk`.

## Затронутые области

- Хосты: `x-disk`, `Huawei`, `main`, `srv-home`, `srv-home-gui`, `srv-home-min`.
- Модули: `nixos/modules/net.nix`, `packages/netwatch-nixos.nix`.
- Пакеты: `trippy 0.13.0`, `rustnet 1.3.0`, `netwatch-tui 0.30.0`, `iproute2`.
- Сервисы: не меняются.
- Пользователи: `admsys` на всех хостах.

## Acceptance Criteria

- [x] В `net.nix` остаются `trippy`, `rustnet` и обёрнутый `netwatch`.
- [x] Обёртка передаёт `--no-sandbox` и содержит `iproute2` в PATH.
- [x] `netwatch` без ручных флагов показывает ненулевое число соединений.
- [x] `netwatch --version` остаётся `netwatch 0.30.0`.
- [x] `nixos-rebuild dry-build` проходит для всех шести хостов.
- [x] `sudo nixos-rebuild switch --flake .#x-disk` применён и повторная проверка UI пройдена.

## Verification

```bash
cd /home/admsys/Nixos/nixos-config

git add -N packages/netwatch-nixos.nix

for h in x-disk Huawei main srv-home srv-home-gui srv-home-min; do
  nixos-rebuild dry-build --flake .#$h || exit 1
done

sudo nixos-rebuild switch --flake .#$(hostname)
command -v netwatch
netwatch --version
readlink -f "$(command -v netwatch)"

tmux new-session -d -s nwverify -x 160 -y 45 'netwatch'
sleep 4
tmux send-keys -t nwverify '2'
sleep 3
tmux capture-pane -p -t nwverify -S -20
tmux kill-session -t nwverify
```

Ожидаемо: в выводе вкладки `connections` должно быть `N connections`, где `N > 0`,
и строки с именами процессов. Повторить проверку с `sudo netwatch`.

## Rollback / Safety

- Откат конфигурации: вернуть в `net.nix` прямую строку
  `pkgs-unstable.netwatch`, удалить `packages/netwatch-nixos.nix`, затем
  `sudo nixos-rebuild switch --rollback`.
- Никакие сетевые 서비스 и правила не меняются; откат не затрагивает сеть.
- `ss` доступен из `iproute2`; при откате обёртки `ss` остаётся в системе.

## Заметки

- Spec создан после факта установки пакетов: исходное добавление в
  `net.nix` было сделано без отдельного spec, что зафиксировано здесь же.
- `--no-sandbox` — временный обход несовместимости upstream-allowlist с NixOS;
  при обновлении `netwatch` нужно проверить, появилась ли поддержка `/nix/store`
  или настройка дополнительных путей, и тогда убрать обёртку.
- Ранее предлагалась выдача `cap_net_raw,cap_bpf,cap_perfmon=eip`, но она не
  решает проблему запуска дочернего `ss` и в этой задаче не применяется.
- `trippy` показывает 1 хоп до `1.1.1.1` через туннель `happ-xray`; это
  отдельное наблюдение, не часть текущего исправления.
- Проверено до deploy: сборка `system.path` дала wrapper с
  `--no-sandbox` и `iproute2-7.0.0/bin` в PATH; `netwatch --version` →
  `netwatch 0.30.0`; вкладка connections показала 252 соединения от
  пользователя и 260 под `sudo`, включая `xray`, `nmbd`, `sshd`, `chrome`,
  `.dcal-wrapped` и `syncthing`.
- После deploy из чистого дерева: новое поколение
  `/nix/store/cira2p4i7jzkgjfyrbiqngax8gms60x0-nixos-system-x-disk-26.05.20261006.b253099`;
  `netwatch` → `/run/current-system/sw/bin/netwatch`, версия `0.30.0`, вкладка
  connections показывает 236 соединений; пользовательский `nix-gc-user.timer`
  активен, следующий запуск 2026-12-01.
