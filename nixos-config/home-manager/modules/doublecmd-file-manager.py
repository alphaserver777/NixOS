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
        # Отдельная служба приложения сохраняет окно при обновлении посредника.
        launcher = [sys.argv[2], "--user", "--collect", "--quiet", "--service-type=exec"]
        if startup_id:
            launcher += ["--setenv=DESKTOP_STARTUP_ID=" + startup_id,
                         "--setenv=XDG_ACTIVATION_TOKEN=" + startup_id]
        for path in paths:
            # Полное имя файла ставит курсор на него. Его содержимое не открывается.
            # Абсолютный путь и отдельные аргументы исключают обработку оболочкой.
            try:
                process = await asyncio.create_subprocess_exec(
                    *launcher, self.executable, "--client", "--no-splash", "-T", path,
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                )
            except OSError as error:
                raise DBusError("org.freedesktop.DBus.Error.Failed", str(error))
            if await process.wait() != 0:
                raise DBusError("org.freedesktop.DBus.Error.Failed",
                                "Не удалось запустить Double Commander")

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
