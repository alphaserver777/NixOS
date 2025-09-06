#!/usr/bin/env bash

if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
  # Указываем "text" и "class" JSON корректно для Waybar
  echo '{"text":"","class":"online"}'
else
  echo '{"text":"󰖪","class":"offline"}'
fi
