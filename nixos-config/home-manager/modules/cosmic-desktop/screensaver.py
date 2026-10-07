"""Часы поверх заставки: отдельный прозрачный слой на каждом экране."""

import datetime
import json
import locale
import signal
import subprocess
import sys
import time

from effects import selected

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell

WEEKDAYS = ("MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY")


def hypr_json(command):
    result = subprocess.run(
        ["hyprctl", "-j", command], check=True, capture_output=True,
        text=True, timeout=1,
    )
    return json.loads(result.stdout)


def locked():
    return subprocess.run(
        ["pgrep", "-x", "hyprlock"], stdout=subprocess.DEVNULL, timeout=1,
    ).returncode == 0


class Clock(Gtk.Window):
    def __init__(self, monitor):
        super().__init__()
        self.geometry = monitor.get_geometry()
        self.set_decorated(False)
        self.set_app_paintable(True)
        self.set_visual(self.get_screen().get_rgba_visual())
        self.set_accept_focus(False)
        self.get_style_context().add_class("cosmic-clock")
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "cosmic-screensaver-clock")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_monitor(self, monitor)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.NONE)
        GtkLayerShell.set_exclusive_zone(self, -1)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                     GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(self, edge, True)
        self.canvas = Gtk.Fixed()
        self.add(self.canvas)
        self.labels = [Gtk.Label() for _ in range(3)]
        for label in self.labels:
            self.canvas.put(label, 0, 0)
        self.canvas.connect("size-allocate", self.position_labels)
        self.connect("realize", self.pass_input)
        self.connect("draw", self.clear_background)
        self.refresh()
        self.show_all()

    def pass_input(self, *_):
        # Клавиши и мышь получает заставка, часы не перехватывают ввод.
        self.get_window().input_shape_combine_region(cairo.Region(), 0, 0)

    def clear_background(self, _widget, cr):
        cr.save()
        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(0, 0, 0, 0)
        cr.paint()
        cr.restore()
        # GTK рисует каждый текстовый элемент сам, с правильным повреждением
        # буфера на каждом выходе Wayland.
        return False

    def refresh(self):
        now = datetime.datetime.now().astimezone()
        self.content = [WEEKDAYS[now.weekday()], now.strftime("%H:%M"),
                        now.strftime("%d %B %Y").upper()]
        self.position_labels()

    def position_labels(self, *_):
        width, height = self.canvas.get_allocated_width(), self.canvas.get_allocated_height()
        # До первого размещения GTK сообщает размер 1 × 1. Сразу задаём
        # полноценный размер шрифта, чтобы не показывать мелкий текст в углу.
        if width <= 1 or height <= 1:
            width, height = self.geometry.width, self.geometry.height
        scale = min(1.0, height / 900, width / 1200)
        styles = [("Anurati", 52, 300, "#cdd6f4"),
                  ("Cosmic Stencil", 96, 180, "#cdd6f4"),
                  ("Orbitron", 20, 85, "#babbf1")]
        for label, text, (family, size, offset, color) in zip(
                self.labels, getattr(self, "content", ["", "", ""]), styles):
            markup = (f'<span font_desc="{family} {size * scale:.2f}" '
                      f'foreground="{color}">{GLib.markup_escape_text(text)}</span>')
            if label.get_label() != markup:
                label.set_markup(markup)
            natural = label.get_preferred_size()[1]
            self.canvas.move(label, round((width - natural.width) / 2),
                             round(height / 2 - offset * scale - natural.height / 2))



class Screensaver:
    def __init__(self, executable):
        self.display = Gdk.Display.get_default()
        if not self.display or not GtkLayerShell.is_supported():
            raise RuntimeError("Нет поддержки слоёв Wayland")
        self.windows = []
        self.minute = None
        self.mapping_deadline = 0
        self.ready = False
        self.child = subprocess.Popen([executable, "--shader", "cosmic-" + selected()])
        self.display.connect("monitor-added", self.monitors_changed)
        self.display.connect("monitor-removed", self.monitors_changed)
        self.monitors_changed()
        GLib.timeout_add_seconds(1, self.tick)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, self.quit)
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, self.quit)

    def monitors_changed(self, *_):
        self.ready = False
        self.mapping_deadline = time.monotonic() + 10
        GLib.timeout_add(200, self.map_clocks)

    def map_clocks(self):
        if self.ready:
            return GLib.SOURCE_REMOVE
        if self.child.poll() is not None:
            return self.quit()
        try:
            layers = hypr_json("layers")
            count = sum(
                any(surface.get("namespace") == "hyprsaver" and surface.get("w", 0) > 0
                    for level in output.get("levels", {}).values() for surface in level)
                for output in layers.values()
            )
            if count < self.display.get_n_monitors():
                if time.monotonic() > self.mapping_deadline:
                    raise RuntimeError("Заставка не появилась на всех экранах")
                return GLib.SOURCE_CONTINUE
            for window in self.windows:
                window.destroy()
            self.windows = [Clock(self.display.get_monitor(index))
                            for index in range(self.display.get_n_monitors())]
            self.ready = True
            return GLib.SOURCE_REMOVE
        except Exception as error:
            print(f"Заставка остановлена: {error}", file=sys.stderr)
            return self.quit()

    def tick(self):
        try:
            monitors = hypr_json("monitors")
            if (self.child.poll() is not None or locked() or not monitors
                    or not any(m.get("dpmsStatus", False) for m in monitors)):
                return self.quit()
            minute = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
            if minute != self.minute:
                self.minute = minute
                for window in self.windows:
                    window.refresh()
            # Полное обновление прозрачного слоя устраняет пропуски текста
            # при частичной перерисовке на нескольких выходах Wayland.
            for window in self.windows:
                window.queue_draw()
            return GLib.SOURCE_CONTINUE
        except Exception as error:
            print(f"Заставка остановлена: {error}", file=sys.stderr)
            return self.quit()

    def quit(self):
        Gtk.main_quit()
        return GLib.SOURCE_REMOVE

    def close(self):
        for window in self.windows:
            window.destroy()
        if self.child.poll() is None:
            self.child.terminate()
            try:
                self.child.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.child.kill()
                self.child.wait()


def main():
    locale.setlocale(locale.LC_TIME, "C")
    monitors = hypr_json("monitors")
    if locked() or not monitors or not any(m.get("dpmsStatus", False) for m in monitors):
        return
    css = Gtk.CssProvider()
    css.load_from_data(b"""
        .cosmic-clock, .cosmic-clock > * {
            background-color: transparent;
            background-image: none;
            box-shadow: none;
            border: none;
        }
        .cosmic-clock label { text-shadow: 0 2px 4px rgba(0, 0, 0, 0.95); }
    """)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css,
                                            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    saver = Screensaver(sys.argv[1])
    try:
        Gtk.main()
    finally:
        saver.close()


if __name__ == "__main__":
    main()
