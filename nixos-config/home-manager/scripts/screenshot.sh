#!/usr/bin/env sh

# Создаем временный файл для скриншота
TMP_FILE=$(mktemp /tmp/screenshot-XXXXXX.png)

# Делаем снимок выбранной области и сохраняем его во временный файл
grim -g "$(slurp -d)" "$TMP_FILE"

# Проверяем, был ли сделан скриншот (файл не пустой)
if [ -s "$TMP_FILE" ]; then
    # Открываем swappy и ждем его закрытия
    swappy -f "$TMP_FILE"
fi

# Удаляем временный файл после закрытия swappy или в случае отмены
rm "$TMP_FILE"