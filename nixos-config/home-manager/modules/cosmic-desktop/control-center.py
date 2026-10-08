"""Небольшой центр управления. Опрос работает только пока окно открыто."""

import concurrent.futures
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import signal
import socket
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell, Pango

from effects import EFFECTS, select, selected


def run(*args):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=2,
                                env={**os.environ, "LC_ALL": "C"}, check=False)
        return result.stdout.strip() if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def volume(target):
    value = run("wpctl", "get-volume", target)
    match = re.search(r"Volume:\s*([\d.]+)", value)
    return (float(match.group(1)) if match else None), "[MUTED]" in value


def collect():
    memory = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":", 1)
        memory[key] = int(value.split()[0])
    cpu = [int(v) for v in Path("/proc/stat").read_text().splitlines()[0].split()[1:9]]
    disk = shutil.disk_usage(Path.home())
    tun = Path("/sys/class/net/Meta").exists()
    service = run("systemctl", "is-active", "clash-verge-service") == "active"
    networks = run("nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status")
    connected = [line.split(":") for line in networks.splitlines()
                 if line.endswith(":connected") and not line.startswith("lo:")]
    physical = next((n for n in connected if n[1] in ("ethernet", "wifi")), None)
    network = ("По кабелю" if physical[1] == "ethernet" else "Беспроводная сеть") if physical else "Нет подключения"
    return {
        "cpu": [sum(cpu), cpu[3] + cpu[4]],
        "memory": 1 - memory["MemAvailable"] / memory["MemTotal"],
        "disk": disk.used / disk.total,
        "volume": volume("@DEFAULT_AUDIO_SINK@"),
        "microphone": volume("@DEFAULT_AUDIO_SOURCE@"),
        "network": network,
        "clash": "TUN включён" if service and tun else "Служба работает" if service else "Служба остановлена",
        "clash_tun": service and tun,
        "title": run("playerctl", "metadata", "--format", "{{title}}") or "Музыка не играет",
        "artist": run("playerctl", "metadata", "--format", "{{artist}}"),
        "playing": run("playerctl", "status") == "Playing",
    }


def styled(widget, *classes):
    for name in classes:
        widget.get_style_context().add_class(name)
    return widget


def label(text="", *classes):
    result = styled(Gtk.Label(label=text, xalign=0), *classes)
    result.set_ellipsize(Pango.EllipsizeMode.END)
    return result


def box(vertical=True, spacing=8):
    return Gtk.Box(orientation=Gtk.Orientation.VERTICAL if vertical else Gtk.Orientation.HORIZONTAL,
                   spacing=spacing)


class Center(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.pool = concurrent.futures.ThreadPoolExecutor(max_workers=1)
        self.pending = None
        self.previous_cpu = None
        self.refreshing = False
        self.closed = False
        self.set_title("Центр управления")
        self.set_decorated(False)
        self.set_app_paintable(True)
        self.set_visual(self.get_screen().get_rgba_visual())
        styled(self, "cosmic-center")
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "cosmic-control-center")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.EXCLUSIVE)
        GtkLayerShell.set_exclusive_zone(self, -1)
        display = Gdk.Display.get_default()
        outputs = json.loads(run("hyprctl", "-j", "monitors") or "[]")
        focused = next((m for m in outputs if m.get("focused")), None)
        for index in range(display.get_n_monitors()):
            monitor = display.get_monitor(index)
            geometry = monitor.get_geometry()
            if focused and geometry.x == focused["x"] and geometry.y == focused["y"]:
                GtkLayerShell.set_monitor(self, monitor)
                break
        self.connect("key-press-event", self.key_pressed)
        self.connect("destroy", self.close)

        body = styled(box(spacing=12), "center-body")
        body.set_size_request(760, -1)
        self.add(body)
        hero = styled(box(False, 20), "hero")
        headings = box(spacing=5)
        headings.pack_start(label("КОСМИЧЕСКИЙ РАБОЧИЙ СТОЛ", "subtitle"), False, False, 0)
        headings.pack_start(label("Центр управления", "heading"), False, False, 0)
        self.date = label("", "detail")
        headings.pack_start(self.date, False, False, 0)
        hero.pack_start(headings, True, True, 0)
        self.clock = label("", "clock")
        hero.pack_end(self.clock, False, False, 0)
        body.pack_start(hero, False, False, 0)

        grid = Gtk.Grid(column_spacing=12, row_spacing=12, column_homogeneous=True)
        body.pack_start(grid, False, False, 0)
        audio = self.card("ЗВУК", grid, 0, 0)
        self.volume_text = label("Громкость", "status")
        audio.pack_start(self.volume_text, False, False, 0)
        self.slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.slider.set_draw_value(False)
        self.slider.connect("value-changed", self.volume_changed)
        audio.pack_start(self.slider, False, False, 0)
        row = box(False)
        self.mute = self.button("Звук", lambda: self.audio_mute("@DEFAULT_AUDIO_SINK@"))
        self.mic = self.button("Микрофон", lambda: self.audio_mute("@DEFAULT_AUDIO_SOURCE@"))
        row.pack_start(self.mute, True, True, 0)
        row.pack_start(self.mic, True, True, 0)
        audio.pack_start(row, False, False, 0)

        network = self.card("СЕТЬ И CLASH", grid, 1, 0)
        self.network = label("Проверка подключения…", "status")
        self.clash = label("", "status")
        network.pack_start(self.network, False, False, 0)
        network.pack_start(self.clash, False, False, 0)
        row = box(False)
        row.pack_start(self.button("Сеть", lambda: self.launch("nm-connection-editor")), True, True, 0)
        row.pack_start(self.button("Открыть Clash", lambda: self.launch("hyprctl", "dispatch", "exec", "clash-verge")), True, True, 0)
        network.pack_end(row, False, False, 0)

        music = self.card("МУЗЫКА", grid, 0, 1)
        self.title = label("Музыка не играет", "music-title")
        self.artist = label("", "detail")
        self.title.set_max_width_chars(32)
        self.artist.set_max_width_chars(36)
        music.pack_start(self.title, False, False, 0)
        music.pack_start(self.artist, False, False, 0)
        row = box(False)
        row.pack_start(self.button("󰒮", lambda: self.player("previous"), "icon"), True, True, 0)
        self.play = self.button("󰐊", lambda: self.player("play-pause"), "icon")
        row.pack_start(self.play, True, True, 0)
        row.pack_start(self.button("󰒭", lambda: self.player("next"), "icon"), True, True, 0)
        music.pack_start(row, False, False, 0)

        stats = self.card("СИСТЕМА", grid, 1, 1)
        self.stats = {}
        for key, text in (("cpu", "Процессор"), ("memory", "Память"), ("disk", "Накопитель")):
            value = label(text, "detail")
            bar = Gtk.ProgressBar()
            stats.pack_start(value, False, False, 0)
            stats.pack_start(bar, False, False, 0)
            self.stats[key] = (value, bar, text)

        effects = styled(box(), "card")
        effects.pack_start(label("ЗАСТАВКА С ЧАСАМИ", "section-title"), False, False, 0)
        row = box(False)
        self.effect_buttons = {}
        for key, name in EFFECTS.items():
            button = self.button(name, lambda k=key: self.choose_effect(k), "effect")
            row.pack_start(button, True, True, 0)
            self.effect_buttons[key] = button
        effects.pack_start(row, False, False, 0)
        details = box(False)
        details.pack_start(label("После 2 минут простоя · часы на всех экранах", "detail"), True, True, 0)
        details.pack_end(self.button("Показать", self.start_saver, "primary"), False, False, 0)
        effects.pack_start(details, False, False, 0)
        body.pack_start(effects, False, False, 0)
        self.update_effects()

        footer = box(False)
        footer.pack_start(self.button("История копирования", lambda: self.launch("walker", "--provider", "clipboard")), False, False, 0)
        footer.pack_start(self.button("Настроить звук", lambda: self.launch("pavucontrol")), False, False, 0)
        footer.pack_end(self.button("⏻", lambda: self.power("poweroff"), "danger"), False, False, 0)
        footer.pack_end(self.button("Перезапуск", lambda: self.power("reboot")), False, False, 0)
        footer.pack_end(self.button("Сон", lambda: self.power("suspend")), False, False, 0)
        footer.pack_end(self.button("Блокировка", lambda: self.launch("loginctl", "lock-session")), False, False, 0)
        body.pack_start(footer, False, False, 0)
        self.confirmation = box(False)
        self.confirmation.set_no_show_all(True)
        self.confirmation_text = label("", "status")
        self.confirmation.pack_start(self.confirmation_text, True, True, 0)
        self.confirmation.pack_end(self.button("Отмена", lambda: self.confirmation.hide()), False, False, 0)
        self.confirmation.pack_end(self.button("Подтвердить", self.confirm_power, "danger"), False, False, 0)
        body.pack_start(self.confirmation, False, False, 0)
        self.power_action = None
        body.pack_start(label("Win + D — открыть / закрыть     Esc — закрыть     Win + V — история", "footer-note"), False, False, 0)
        self.show_all()
        self.refresh()
        GLib.timeout_add_seconds(3, self.refresh)
        GLib.timeout_add(100, self.receive)

    @staticmethod
    def button(text, action, *classes):
        button = styled(Gtk.Button(label=text), *classes)
        button.connect("clicked", lambda *_: action())
        return button

    @staticmethod
    def card(title, grid, column, row):
        card = styled(box(spacing=7), "card")
        card.pack_start(label(title, "section-title"), False, False, 0)
        grid.attach(card, column, row, 1, 1)
        return card

    def key_pressed(self, _widget, event):
        # Повторное Win+D закрывает меню, даже при захвате клавиатуры слоем.
        if event.keyval == Gdk.KEY_Escape or (event.state & Gdk.ModifierType.SUPER_MASK
                                             and event.keyval in (Gdk.KEY_d, Gdk.KEY_D)):
            self.close()
            return True
        return False

    def launch(self, *args):
        subprocess.Popen(args, start_new_session=True)
        self.close()

    def power(self, action):
        # Подтверждение в том же слое: отдельное окно было бы под панелью.
        self.power_action = action
        self.confirmation_text.set_text({"poweroff": "Выключить компьютер?",
                                        "reboot": "Перезапустить компьютер?",
                                        "suspend": "Перевести компьютер в сон?"}[action])
        for child in self.confirmation.get_children():
            child.show_all()
        self.confirmation.show()

    def confirm_power(self):
        if self.power_action:
            self.launch("systemctl", self.power_action)

    def volume_changed(self, *_):
        if not self.refreshing:
            subprocess.Popen(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@",
                              f"{round(self.slider.get_value())}%"], stdout=subprocess.DEVNULL)

    def audio_mute(self, target):
        run("wpctl", "set-mute", target, "toggle")
        self.refresh()

    def player(self, action):
        run("playerctl", action)
        self.refresh()

    def choose_effect(self, key):
        select(key)
        self.update_effects()

    def update_effects(self):
        current = selected()
        for key, button in self.effect_buttons.items():
            context = button.get_style_context()
            context.add_class("selected") if key == current else context.remove_class("selected")

    def start_saver(self):
        self.launch("cosmic-screensaver", "start")

    def refresh(self):
        if self.closed:
            return GLib.SOURCE_REMOVE
        now = datetime.datetime.now()
        self.clock.set_text(now.strftime("%H:%M"))
        self.date.set_text(now.strftime("%d %B %Y").upper())
        if self.pending is None:
            self.pending = self.pool.submit(collect)
        return GLib.SOURCE_CONTINUE

    def receive(self):
        if self.closed:
            return GLib.SOURCE_REMOVE
        if self.pending is None or not self.pending.done():
            return GLib.SOURCE_CONTINUE
        try:
            values = self.pending.result()
        except Exception as error:
            print(f"Не удалось обновить центр управления: {error}", file=sys.stderr)
            self.pending = None
            return GLib.SOURCE_CONTINUE
        self.pending = None
        cpu = values["cpu"]
        load = 0
        if self.previous_cpu and cpu[0] > self.previous_cpu[0]:
            load = 1 - (cpu[1] - self.previous_cpu[1]) / (cpu[0] - self.previous_cpu[0])
        self.previous_cpu = cpu
        for key, amount in (("cpu", load), ("memory", values["memory"]), ("disk", values["disk"])):
            text, bar, title = self.stats[key]
            text.set_text(f"{title} · {round(amount * 100)}%")
            bar.set_fraction(max(0, min(1, amount)))
        level, muted = values["volume"]
        self.refreshing = True
        self.slider.set_sensitive(level is not None)
        self.slider.set_value(min(100, round((level or 0) * 100)))
        self.volume_text.set_text(f"Громкость · {round((level or 0) * 100)}%" + (" · выключен" if muted else ""))
        self.mute.set_label("Включить звук" if muted else "Выключить звук")
        self.mic.set_label("Нет микрофона" if values["microphone"][0] is None else
                           "Включить микрофон" if values["microphone"][1] else "Микрофон включён")
        self.mic.set_sensitive(values["microphone"][0] is not None)
        self.refreshing = False
        self.network.set_text(values["network"])
        self.clash.set_text("Clash · " + values["clash"])
        context = self.clash.get_style_context()
        context.add_class("good") if values["clash_tun"] else context.remove_class("good")
        self.title.set_text(values["title"])
        self.artist.set_text(values["artist"] or "Управление текущим проигрывателем")
        self.play.set_label("󰏤" if values["playing"] else "󰐊")
        return GLib.SOURCE_CONTINUE

    def close(self, *_):
        if self.closed:
            return
        self.closed = True
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        self.hide()
        self.pool.shutdown(wait=False, cancel_futures=True)
        Gtk.main_quit()


def main():
    if "--check" in sys.argv:
        print(json.dumps(collect(), ensure_ascii=False))
        return
    endpoint = Path(os.environ["XDG_RUNTIME_DIR"]) / "cosmic-control-center.sock"
    lock_fd = os.open(endpoint.with_suffix(".lock"), os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        with socket.socket(socket.AF_UNIX) as client:
            try:
                client.connect(str(endpoint))
            except (FileNotFoundError, ConnectionRefusedError):
                pass  # Первый запуск ещё готовит окно.
        os.close(lock_fd)
        return
    endpoint.unlink(missing_ok=True)
    server = socket.socket(socket.AF_UNIX)
    server.bind(str(endpoint))
    endpoint.chmod(0o600)
    server.listen(1)
    server.setblocking(False)
    try:
        css = Gtk.CssProvider()
        css.load_from_path(str(Path(__file__).with_suffix(".css")))
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css,
                                                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        window = Center()
        def toggle(*_):
            connection, _address = server.accept()
            connection.close()
            window.close()
            return GLib.SOURCE_REMOVE
        GLib.io_add_watch(server.fileno(), GLib.IO_IN, toggle)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, lambda: window.close() or False)
        Gtk.main()
    finally:
        server.close()
        endpoint.unlink(missing_ok=True)
        os.close(lock_fd)


if __name__ == "__main__":
    main()
