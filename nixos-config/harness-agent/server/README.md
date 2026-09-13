# Серверный маркетинговый агент «Профессор IT»

## Устройство

- DeepSeek Harness работает в отдельном контейнере.
- Рабочая копия маркетингового репозитория находится рядом с базой знаний.
- Точный и смысловой поиск доступны по путям `/root/professor_ot/bin` и
  `/root/professor_ot/rag`.
- Telegram-бот напрямую использует Telegram Bot API и принимает команды
  только от перечисленных идентификаторов чатов.
- Ежедневный таймер запускает самостоятельный анализ в 08:00 по Москве.

Контейнер получает доступ к `/root/professor_ot`, но не к Docker-сокету и
остальной файловой системе узла.

## Версии

- `@deepseek-ai/dsh`: `0.1.5-rc.1`.
- `dsh-plugin-telegram`: `0.1.2`.
- Node.js: `22`.

Версии закреплены, потому что Harness находится на стадии предварительной
версии и может менять совместимость.

## Установка

```bash
sudo ./install.sh
```

Настоящие ключи не хранятся в репозитории. Для Telegram нужен отдельный бот,
созданный через `@BotFather`, и его токен в
`/etc/professorit-agent/telegram.env`.

## Управление

```bash
systemctl status professorit-marketing-agent-bot.service
systemctl status professorit-marketing-agent-daily.timer
journalctl -u professorit-marketing-agent-bot.service -f
```

Ручная ежедневная проверка:

```bash
systemctl start professorit-marketing-agent-daily.service
journalctl -u professorit-marketing-agent-daily.service -n 100
```
