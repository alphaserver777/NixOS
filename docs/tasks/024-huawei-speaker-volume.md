# Huawei: полная аппаратная громкость

Состояние: done. Дата: 13 октября 2026 года.

Прочитаны WORKFLOW, constitution, architecture, devplan, PROCESS,
DEPLOYMENT и TEMPLATE; связанная задача 021.

## Причина и изменение

Пользователь сообщил о тихих встроенных динамиках при громкости 100%.
PipeWire, DAC, Headphone Mixer и SOF PGA уже находятся на 0 dB.
Однако fix-sound-essx8336 задаёт Headphone Playback Volume 80%:
amixer переводит это в значение 2 из 3, то есть -12 dB.
Это аппаратный выход, используемый и для встроенных динамиков.

Поднять эту настройку до 100% (значение 3, 0 dB), как в штатном UCM
Intel/sof-essx8336 и codecs/es8316/EnableSeq.conf. Другие настройки,
громкость PipeWire и лимит клавиш громкости сохраняются.

Runtime уже изменён; пользователь подтвердил, что стало громче.
Изменение требуется закрепить только в hosts/Huawei/audio.nix.

## Проверка

- [x] Исходное состояние -12 dB и соответствие 80% подтверждены amixer.
- [x] Runtime теперь 100%, 0 dB, пользователь подтвердил улучшение.
- [x] Dry-build и применение Huawei из чистого commit успешны.
- [x] Установленный сервис задаёт 100%; после его выполнения значение 3/3,
  громкость PipeWire прежняя, ошибок службы нет.

Применено из чистого commit e93c3be, поколение 146:
`/nix/store/mwwkcmwbgzn3kxc8rbv86206hl1zk8wc-nixos-system-Huawei-26.05.20261006.b253099`.
Dry-build и switch завершились с кодом 0. Установленная служба повторно
выполнена: Result=success, ExecMainStatus=0; amixer показывает 3/3,
100%, 0 dB. Громкость PipeWire остаётся 1.00.

## Возврат

Предыдущее поколение: 145. sudo nixos-rebuild switch --rollback.
Для возврата runtime: amixer -c sofessx8336 cset
name='Headphone Playback Volume' 80%.
Другие хосты не затрагиваются.

Источник: ALSA UCM установленной версии и TLV шкала драйвера Linux:
https://github.com/gregkh/linux/blob/v6.18.55/sound/soc/codecs/es8316.c.
