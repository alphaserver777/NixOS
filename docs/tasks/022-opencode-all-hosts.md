# OpenCode на всех хостах

Состояние: in progress. Дата: 13 октября 2026 года.

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

- [ ] Все шесть nixosConfigurations содержат один официальный пакет.
- [ ] Все шесть homeConfigurations содержат тот же пакет.
- [ ] Dry-build Huawei, x-disk, main и серверов успешен.
- [ ] Полная сборка Huawei и применение завершились успешно.
- [ ] opencode доступен в PATH; --version и --help работают.
- [ ] Интерактивный интерфейс запускается без ошибки.

## Возврат

Предыдущее поколение Huawei: 142, commit 71bb91c.
Откат: sudo nixos-rebuild switch --rollback.
Личные данные OpenCode не заменяются.
