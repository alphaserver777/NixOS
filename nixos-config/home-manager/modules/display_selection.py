"""Один основной экран независимо от имени разъёма и модели."""


def select_monitor(monitors):
    connected = [monitor for monitor in monitors if not monitor.get("disabled", False)]
    if not connected:
        raise RuntimeError("Нет подключённых экранов")
    origin = next((monitor for monitor in connected
                   if (monitor.get("x"), monitor.get("y")) == (0, 0)), None)
    return origin or next((monitor for monitor in connected if monitor.get("focused")),
                          connected[0])
