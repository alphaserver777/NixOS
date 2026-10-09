"""Задача 011: стандартная команда «Показать в папке» для Double Commander."""

import asyncio
import os
from pathlib import Path
import sys
from urllib.parse import unquote_to_bytes, urlsplit

from dbus_next import BusType, DBusError
from dbus_next.aio import MessageBus
from dbus_next.constants import NameFlag, RequestNameReply
from dbus_next.service import ServiceInterface, method


def local_path(uri):
    parsed = urlsplit(uri)
    if (parsed.scheme != "file" or parsed.netloc not in ("", "localhost")
            or parsed.query or parsed.fragment):
        raise ValueError("Ожидался адрес локального файла")
    path = os.fsdecode(unquote_to_bytes(parsed.path))
    if not os.path.isabs(path) or "\0" in path or not Path(path).exists():
        raise ValueError("Локальный путь не существует")
    return path


class FileManager(ServiceInterface):
    def __init__(self, executable):
        super().__init__("org.freedesktop.FileManager1")
        self.executable = executable

    async def show(self, uris, startup_id):
        try:
            paths = [local_path(uri) for uri in uris]
        except ValueError as error:
            raise DBusError("org.freedesktop.DBus.Error.InvalidArgs", str(error))
        environment = os.environ.copy()
        if startup_id:
            environment["DESKTOP_STARTUP_ID"] = startup_id
            environment["XDG_ACTIVATION_TOKEN"] = startup_id
        for path in paths:
            # Полное имя файла ставит курсор на него. Его содержимое не открывается.
            # Абсолютный путь и отдельные аргументы исключают обработку оболочкой.
            try:
                process = await asyncio.create_subprocess_exec(
                    self.executable, "--client", "--no-splash", "-T", path,
                    env=environment,
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                )
            except OSError as error:
                raise DBusError("org.freedesktop.DBus.Error.Failed", str(error))
            # Первый запуск остаётся работать; ответ не ждёт закрытия окна.
            asyncio.create_task(process.wait())

    @method()
    async def ShowItems(self, uris: 'as', startup_id: 's'):
        await self.show(uris, startup_id)

    @method()
    async def ShowFolders(self, uris: 'as', startup_id: 's'):
        await self.show(uris, startup_id)

    @method()
    def ShowItemProperties(self, uris: 'as', startup_id: 's'):
        raise DBusError("org.freedesktop.DBus.Error.NotSupported",
                        "Просмотр свойств через эту службу не поддерживается")


async def main():
    bus = await MessageBus(bus_type=BusType.SESSION).connect()
    bus.export("/org/freedesktop/FileManager1", FileManager(sys.argv[1]))
    reply = await bus.request_name("org.freedesktop.FileManager1", NameFlag.DO_NOT_QUEUE)
    if reply != RequestNameReply.PRIMARY_OWNER:
        raise SystemExit("Имя файлового менеджера уже занято")
    await bus.wait_for_disconnect()


if __name__ == "__main__":
    asyncio.run(main())
