
````markdown
# Настройка `gemini-cli` на NixOS

Данный README описывает шаги для корректной настройки `gemini-cli` с использованием Google Cloud SDK на NixOS.

---

## Установка Google Cloud SDK

В NixOS рекомендуется ставить через `nix-shell` или в `configuration.nix`.

### Временная установка:
```bash
nix-shell -p google-cloud-sdk
````

### Постоянная установка (через configuration.nix):

```nix
environment.systemPackages = [
    pkgs.google-cloud-sdk
];
```

Проверка:

```bash
gcloud version
```

---

## Инициализация `gcloud`

Запускаем инициализацию:

```bash
gcloud init
```

* Входим через Google-аккаунт
* Создаём или выбираем проект

---

## Создание проекта (если нет)

`project_id` должен быть:

* 6–30 символов
* только **строчные буквы, цифры, дефисы**
* начинаться с буквы

Пример:

```bash
gcloud projects create nixos-ai-001 --name="NixOS Gemini"
```

---

## Выбор проекта

```bash
gcloud config set project nixos-ai-001
gcloud config get-value project
```

Ожидаемый вывод:

```
nixos-ai-001
```

---

## Включение API Gemini

```bash
gcloud services enable cloudaicompanion.googleapis.com --project=nixos-ai-001
```

Проверка:

```bash
gcloud services list --enabled --project=nixos-ai-001 | grep cloudaicompanion
```

Ожидаемый вывод:

```
cloudaicompanion.googleapis.com     Gemini for Google Cloud API
```

---

## Настройка переменной окружения (опционально)

Если `gemini-cli` не видит проект:

```bash
export GOOGLE_CLOUD_PROJECT=nixos-ai-001
```

---

## Использование `gemini-cli`

Запуск:

```bash
gemini
```

Вводим команды или вопросы в интерактивной сессии.

---

## Быстрый чек-лист

1. Установлен `google-cloud-sdk`
    2. Выполнен `gcloud init`
    3. Проект создан и выбран (`gcloud config set project`)
4. API включён (`gcloud services enable cloudaicompanion.googleapis.com`)
    5. Запуск `gemini` работает без ошибок `RESOURCE_PROJECT_INVALID`

    ```

    Хочешь, я ещё добавлю блок **"Типичные ошибки и их решение"** в этот README?
    ```
