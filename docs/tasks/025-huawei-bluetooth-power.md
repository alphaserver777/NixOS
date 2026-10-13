# Huawei: включение Bluetooth при загрузке

Состояние: in progress. Дата: 13 октября 2026 года.

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
- [ ] Dry-build и switch из чистого commit успешны.
- [ ] Установленный main.conf содержит AutoEnable=true, служба активна,
  адаптер включён и поиск работает после применения.

Команды: nixos-rebuild dry-build/switch --flake ./nixos-config#Huawei;
bluetoothctl show; bluetoothctl --timeout 10 scan on; rfkill list;
systemctl status bluetooth.service; проверка /etc/bluetooth/main.conf.
Перезагрузка и подключение к конкретному устройству в проверку не входят.

Дополнительно: HUAWEI FreeBuds 4 после включения адаптера подключились;
bluetoothctl показывает Paired/Bonded/Trusted/Connected=yes. Пользователь
подтвердил: «Всё пошло». Dry-build успешен, требуется только четыре
derivation: main.conf, etc, activate и итоговая система.

## Возврат

Предыдущее поколение 146: sudo nixos-rebuild switch --rollback.
Для отключения радио в текущем сеансе: bluetoothctl power off.
Ключи сопряжений и пользовательские данные не изменяются.
