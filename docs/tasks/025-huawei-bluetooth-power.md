# Huawei: включение Bluetooth при загрузке

Состояние: done. Дата: 13 октября 2026 года.

Прочитаны WORKFLOW, constitution, architecture, devplan, PROCESS,
DEPLOYMENT и TEMPLATE; связанные задачи 021 и 024.

## Причина и область

Пользователь сообщил о неработающем Bluetooth на Huawei. Служба BlueZ
работает, Intel hci0 загрузил firmware, rfkill не блокирует радио.
Однако Powered=no: общий модуль bluetooth.nix задаёт powerOnBoot=false.
Ручное bluetoothctl power on успешно включило адаптер.

Закрепить hardware.bluetooth.powerOnBoot=true только для Huawei,
переопределив общий параметр в hosts/Huawei/configuration.nix.
Общий модуль, настройки других машин, драйверы и сопряжения сохраняются.
BlueZ получит Policy.AutoEnable=true; пользователь сможет выключать
Bluetooth вручную в текущем сеансе.

## Проверка

- [x] Адаптер включается без ошибок, поиск обнаруживает устройства.
- [x] Huawei вычисляется с powerOnBoot=true; остальные хосты сохраняют настройки.
- [x] Dry-build и switch из чистого commit успешны.
- [x] Установленный main.conf содержит AutoEnable=true, служба активна,
  адаптер включён и поиск работает после применения.

Команды: nixos-rebuild dry-build/switch --flake ./nixos-config#Huawei;
bluetoothctl show; bluetoothctl --timeout 10 scan on; rfkill list;
systemctl status bluetooth.service; проверка /etc/bluetooth/main.conf.
Перезагрузка не выполняется; подключение проверено на FreeBuds пользователя.

Дополнительно: HUAWEI FreeBuds 4 после включения адаптера подключились;
bluetoothctl показывает Paired/Bonded/Trusted/Connected=yes. Пользователь
подтвердил: «Всё пошло». Dry-build успешен, требуется только четыре
derivation: main.conf, etc, activate и итоговая система.

Применено из чистого commit f8b8617, поколение 147:
`/nix/store/8ab09ri389bdr1756xagijs3ycb8ag1z-nixos-system-Huawei-26.05.20261006.b253099`.
Switch завершился успешно, /etc/bluetooth/main.conf содержит AutoEnable=true.
После применения служба активна, Powered=yes, повторный поиск обнаруживает
устройства. FreeBuds остаются Connected=yes, PipeWire использует их как
выход по умолчанию; оба канала потока Chrome активны. Неисправных системных
служб нет. Остальные хосты не применялись.

Дополнительный bluetoothctl connect к уже подключённым наушникам вернул
le-connection-abort-by-local. Существующее A2DP-подключение и воспроизведение
сохранились; сопряжение не сбрасывали и службу BlueZ не перезапускали.

## Возврат

Предыдущее поколение 146: sudo nixos-rebuild switch --rollback.
Для отключения радио в текущем сеансе: bluetoothctl power off.
Ключи сопряжений и пользовательские данные не изменяются.
