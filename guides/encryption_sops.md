# SOPS + NixOS/Home Manager: подробный гайд для этого репозитория

Этот документ описывает, как в этом репозитории правильно хранить и использовать секреты через `sops` и `sops-nix`.

## Что уже настроено

- `sops-nix` подключен во `flake`:
  - `nixos-config/flake.nix`
- Правила шифрования:
  - `nixos-config/.sops.yaml`
- Зашифрованный файл секретов:
  - `nixos-config/secrets/secrets.yaml`
- Пример использования секрета:
  - `nixos-config/home-manager/modules/google-drive.nix`

## Где лежат ключи

- Локальный ключ расшифровки Age:
  - `~/.config/sops/age/keys.txt`
- Этот файл **не должен** попадать в git.
- Без этого ключа расшифровать `nixos-config/secrets/secrets.yaml` нельзя.

## Быстрый сценарий: добавить/изменить секрет

1. Открой зашифрованный файл:

```bash
cd ~/Nixos
sops nixos-config/secrets/secrets.yaml
```

2. В редакторе измени или добавь ключ, например:

```yaml
my-secret: "value"
```

3. Сохрани и выйди. `sops` автоматически перешифрует файл.

4. Добавь изменения в git:

```bash
git add nixos-config/secrets/secrets.yaml
```

5. Примени конфигурацию:

```bash
home-manager switch -b backup --flake ./nixos-config#admsys@x-disk
```

## Как подключить новый секрет в Home Manager

Ниже шаблон для модуля Home Manager:

```nix
{ config, ... }:
{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets."my-secret" = {
    # Куда положить расшифрованный файл
    path = "${config.home.homeDirectory}/.config/my-app/secret.txt";
  };
}
```

После этого секрет будет доступен как файл по пути из `path`.

## Как добавить новый зашифрованный файл

Если нужен отдельный файл секретов:

1. Создай его в `nixos-config/secrets/`, например `app.yaml`
2. Открой через `sops`:

```bash
sops nixos-config/secrets/app.yaml
```

3. Добавь в модуль:

```nix
sops.defaultSopsFile = ../../secrets/app.yaml;
```

Важно: путь должен попадать под правило из `nixos-config/.sops.yaml`:

```yaml
path_regex: secrets/.*\.ya?ml$
```

## Проверка, что всё работает

Проверить наличие `sops`:

```bash
which sops
sops --version
```

Проверить, что сервисы стартуют:

```bash
systemctl --user status sops-nix.service
systemctl --user status rclone-gdrive-mount.service
```

## Частые ошибки

1. `error loading config: no matching creation rules found`
- Файл не подпадает под `path_regex` из `.sops.yaml`.
- Используй путь внутри `nixos-config/secrets/*.yaml`.

2. `path ... does not exist` при `home-manager switch`
- Новый файл не добавлен в git index.
- Выполни:

```bash
git add nixos-config/secrets/secrets.yaml nixos-config/.sops.yaml
```

3. `failed to decrypt` / нет ключа
- Нет `~/.config/sops/age/keys.txt` или неправильный ключ.

4. `sops` не найден
- Убедись, что пакет установлен в Home Manager (`home-packages.nix`) и выполни `home-manager switch`.

## Рекомендации по безопасности

- Не хранить секреты в plaintext-файлах (`secrets.nix`, `*.backup`, `Downloads/*.json`).
- Не отправлять токены и `client_secret` в чат/лог.
- Делать бэкап `~/.config/sops/age/keys.txt` в безопасное место.
- При утечке ключей/токенов делать ротацию (перевыпуск) немедленно.

## Мини-чеклист перед коммитом

- [ ] В git только зашифрованные секреты (`nixos-config/secrets/*.yaml`)
- [ ] `~/.config/sops/age/keys.txt` не в репозитории
- [ ] Нету plaintext-копий секретов
- [ ] `home-manager switch` проходит без ошибок

