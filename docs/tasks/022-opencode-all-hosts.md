# OpenCode на всех хостах

Состояние: done. Дата: 13 октября 2026 года.

Прочитаны WORKFLOW, constitution, architecture, devplan, PROCESS,
DEPLOYMENT, TEMPLATE и задачи 005/013.

## Контекст и цель

На Huawei команда opencode отсутствует: официальный пакет установлен
только в hosts/x-disk/local-packages.nix. Пользователь попросил сделать
OpenCode доступным на любом компьютере, управляемом этим репозиторием.

## Изменение

- Добавить пакет из закреплённого официального flake в общий набор
  home-manager/home-packages.nix. Это охватывает интегрированный
  Home Manager и все самостоятельные homeConfigurations.
- Подключить из makeSystem отдельный модуль opencode.nix: на хостах
  без Home Manager устанавливать тот же пакет в users.users.admsys.packages.
  Это исключение для srv-home-min/srv-home-gui, где Home Manager
  не подключён; установка остаётся пользовательской и декларативной.
- Удалить установку из системного набора x-disk, чтобы версия была единой.
- flake.lock, ключи, модели и личные настройки не менять.
- Сначала проверить все конфигурации, затем собрать и применить Huawei
  из чистого commit. Другие физические машины получают изменение
  при следующем rebuild; удалённые адреса в этой задаче не заданы.

## Проверка

- [x] Все шесть nixosConfigurations содержат один официальный пакет.
- [x] Все шесть homeConfigurations содержат тот же пакет.
- [x] Dry-build Huawei, x-disk, main и серверов успешен.
- [x] Полная сборка Huawei и применение завершились успешно.
- [x] opencode доступен в PATH; --version и --help работают.
- [x] Интерактивный интерфейс запускается без ошибки.

## Результат

Вычисление всех 12 конфигураций подтвердило одинаковый пакет:
`/nix/store/azq8psn6zyyzb68ll12q9p8lq67mmgyr-opencode-1.18.30+95daf90`.
Dry-build каждого хоста завершился с кодом 0.
Huawei собран и применён из чистого commit `5df7581`:
поколение 143,
`/nix/store/9jipyl6w6gj9dfsdkymlswycyvjrn6hc-nixos-system-Huawei-26.05.20261006.b253099`.

Команда доступна как `/etc/profiles/per-user/admsys/bin/opencode`;
версия `1.18.30+95daf90`, справка и интерактивный экран работают.
Проверочный TUI открыт в /tmp, запросы моделям не отправлялись,
сеанс корректно завершён. Home Manager active, failed system units: 0.
На других физических машинах конфигурация ещё не применялась:
пакет появится после rebuild из репозитория с этим изменением.

## Возврат

Предыдущее поколение Huawei: 142, commit 71bb91c.
Откат: sudo nixos-rebuild switch --rollback.
Личные данные OpenCode не заменяются.
