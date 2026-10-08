# Развёртывание конфигураций

## Рабочий каталог

Все команды выполнять из:
```bash
cd /home/admsys/Nixos/nixos-config
```

---

## Применение конфигурации хоста

### На текущей машине

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Или явно указать хост:
```bash
sudo nixos-rebuild switch --flake .#x-disk
sudo nixos-rebuild switch --flake .#Huawei
```

### Пробная сборка без применения

```bash
nixos-rebuild dry-build --flake .#<hostname>
```

Используй это перед применением на production-хосте для раннего обнаружения
ошибок синтаксиса и несовместимостей.

### Удалённое применение (на сервер через SSH)

```bash
nixos-rebuild switch --flake .#srv-home-min \
  --target-host admsys@<ip-сервера> \
  --build-host localhost
```

_Примечание: требует, чтобы пользователь имел sudo без пароля на целевом хосте._

---

## Home Manager

### Применение только пользовательских конфигов

```bash
home-manager switch --flake .#admsys@$(hostname)
```

Или явно:
```bash
home-manager switch --flake .#admsys@x-disk
home-manager switch --flake .#admsys@Huawei
```

### Home Manager интегрирован в NixOS

В этом репозитории Home Manager подключён как NixOS-модуль через
`nixos/modules/home-manager.nix`. Это означает, что `nixos-rebuild switch`
применяет **и системную конфигурацию, и Home Manager одновременно**.

Отдельная команда `home-manager switch` нужна только для тестирования
пользовательских изменений без rebuild системы.

---

## Rollback

### Откат системы на предыдущее поколение

```bash
sudo nixos-rebuild switch --rollback
```

Или через загрузчик: при загрузке выбрать предыдущее поколение в меню GRUB.

### Откат к конкретному поколению

```bash
# Список поколений
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Откат к поколению N
sudo nix-env --switch-generation N --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

---

## Правила безопасного deploy

1. **Только из чистого Git-состояния.** Перед deploy выполни:
   ```bash
   git status  # должно быть чисто или только известные изменения
   ```

2. **Сначала dry-build.** Особенно при изменении shared-модулей.

3. **Тестируй на менее критичном хосте.** Порядок: `Huawei` → `x-disk` → серверы.

4. **Не меняй несколько shared-модулей за один раз** без явного плана
   в task spec.

5. **После успешного apply — коммит.** Чтобы rollback через Git всегда
   был возможен.

---

## Хосты и их расположение

| Хост | Тип | Примечание |
|---|---|---|
| `x-disk` | Рабочая станция | Физически локально |
| `Huawei` | Ноутбук | Физически локально |
| `srv-home-min` | Сервер (headless) | Домашняя сеть |
| `srv-home` | Сервер | Домашняя сеть |
| `srv-home-gui` | Сервер + GUI | Домашняя сеть |
| `main` | Шаблон/тест | Статус неизвестен |

---

## Germany VDS (внешний)

- **IP:** `64.188.64.23`
- **Управление:** НЕ через этот репозиторий
- **Связь:** Принимает rsyslog от `x-disk` по TCP:514
- **Логи:** `/var/log/important/remote-auth.log`, `remote-kernel.log`,
  `remote-critical.log`

Проверка форвардинга с `x-disk`:
```bash
logger -p authpriv.err "TEST_FROM_XDISK auth"
logger -p daemon.crit "TEST_FROM_XDISK crit"
```

На Germany VDS:
```bash
tail -n 20 /var/log/important/remote-auth.log
tail -n 20 /var/log/important/remote-critical.log
```

---

## Обновление flake.lock

```bash
cd /home/admsys/Nixos/nixos-config
nix flake update
```

После обновления — обязательно `dry-build` на всех хостах перед применением.
Изменение `flake.lock` = потенциальное обновление всех пакетов.

---

## Очистка nix store

```bash
# Удалить старые поколения и неиспользуемые пакеты
sudo nix-collect-garbage -d

# Оптимизировать store (hardlink)
sudo nix store optimise
```

Автоматически настроено: ежемесячная GC через `nixos/modules/nix.nix`.
