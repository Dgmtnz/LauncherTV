import json
import os
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, Property, Qt
from PySide6.QtGui import QImage, QColor

CONFIG_DIR = Path.home() / ".config" / "LauncherTV"
CONFIG_FILE = CONFIG_DIR / "config.json"
AUTOSTART_DIR = Path.home() / ".config" / "autostart"
AUTOSTART_FILE = AUTOSTART_DIR / "launchertv.desktop"
PROJECT_DIR = Path(__file__).resolve().parent.parent

DEFAULTS = {
    "scale": 1.0,
    "highlightColor": "#5EB8FF",
    "autoAccentColor": False,
    "backgroundTint": 0.75,
    "backgroundImage": "",
    "backgroundFolder": "",
    "slideshowInterval": 60,
    "weatherLocation": "",
    "grabHomeKey": True,
    "launchCounts": {},
}


class AppConfig(QObject):
    configChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._data = dict(DEFAULTS)
        self._load()

    # ── persistence ──────────────────────────────────────────────

    def _load(self):
        if CONFIG_FILE.is_file():
            try:
                with open(CONFIG_FILE) as f:
                    self._data.update(json.load(f))
            except Exception:
                pass

    def _save(self):
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_FILE, "w") as f:
            json.dump(self._data, f, indent=2)

    def _set(self, key, value):
        if self._data.get(key) != value:
            self._data[key] = value
            self._save()
            self.configChanged.emit()

    # ── QML properties (all share configChanged for simplicity) ──

    def _get_scale(self):
        return float(self._data.get("scale", 1.0))

    def _set_scale(self, v):
        self._set("scale", round(max(0.5, min(2.0, v)), 2))

    scale = Property(float, _get_scale, _set_scale, notify=configChanged)

    def _get_highlight(self):
        return self._data.get("highlightColor", "#5EB8FF")

    def _set_highlight(self, v):
        self._set("highlightColor", v)

    highlightColor = Property(str, _get_highlight, _set_highlight, notify=configChanged)

    def _get_auto_accent(self):
        return bool(self._data.get("autoAccentColor", False))

    def _set_auto_accent(self, v):
        self._set("autoAccentColor", bool(v))

    autoAccentColor = Property(bool, _get_auto_accent, _set_auto_accent, notify=configChanged)

    def _get_tint(self):
        return float(self._data.get("backgroundTint", 0.75))

    def _set_tint(self, v):
        self._set("backgroundTint", round(max(0.0, min(1.0, v)), 2))

    backgroundTint = Property(float, _get_tint, _set_tint, notify=configChanged)

    def _get_bg_image(self):
        return self._data.get("backgroundImage", "")

    def _set_bg_image(self, v):
        self._set("backgroundImage", v)

    backgroundImage = Property(str, _get_bg_image, _set_bg_image, notify=configChanged)

    def _get_bg_folder(self):
        return self._data.get("backgroundFolder", "")

    def _set_bg_folder(self, v):
        self._set("backgroundFolder", v)

    backgroundFolder = Property(str, _get_bg_folder, _set_bg_folder, notify=configChanged)

    def _get_interval(self):
        return int(self._data.get("slideshowInterval", 60))

    def _set_interval(self, v):
        self._set("slideshowInterval", max(10, min(300, int(v))))

    slideshowInterval = Property(int, _get_interval, _set_interval, notify=configChanged)

    def _get_weather_loc(self):
        return self._data.get("weatherLocation", "")

    def _set_weather_loc(self, v):
        self._set("weatherLocation", v)

    weatherLocation = Property(str, _get_weather_loc, _set_weather_loc, notify=configChanged)

    def _get_grab_home(self):
        return bool(self._data.get("grabHomeKey", True))

    def _set_grab_home(self, v):
        self._set("grabHomeKey", bool(v))

    grabHomeKey = Property(bool, _get_grab_home, _set_grab_home, notify=configChanged)

    def _get_autostart(self):
        return AUTOSTART_FILE.is_file()

    isAutostart = Property(bool, _get_autostart, notify=configChanged)

    # ── slots ────────────────────────────────────────────────────

    @Slot(bool, result=bool)
    def setAutostart(self, enabled):
        try:
            if enabled:
                AUTOSTART_DIR.mkdir(parents=True, exist_ok=True)
                main_py = PROJECT_DIR / "main.py"
                AUTOSTART_FILE.write_text(
                    "[Desktop Entry]\n"
                    "Type=Application\n"
                    "Name=LauncherTV\n"
                    "Comment=Android TV-style launcher for Linux\n"
                    f"Exec=python3 {main_py}\n"
                    "Icon=preferences-desktop\n"
                    "Terminal=false\n"
                    "Categories=System;\n"
                    "StartupWMClass=LauncherTV\n"
                )
            else:
                AUTOSTART_FILE.unlink(missing_ok=True)
            self.configChanged.emit()
            return True
        except Exception:
            return False

    @Slot(str)
    def recordLaunch(self, desktop_id):
        if not desktop_id or desktop_id.startswith("__"):
            return
        counts = self._data.setdefault("launchCounts", {})
        counts[desktop_id] = counts.get(desktop_id, 0) + 1
        self._save()

    def top_launched(self, n=6):
        counts = self._data.get("launchCounts", {})
        return sorted(counts, key=lambda k: counts[k], reverse=True)[:n]

    @Slot(result=list)
    def backgroundImages(self):
        folder = self._data.get("backgroundFolder", "")
        if not folder or not os.path.isdir(folder):
            return []
        exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
        return [
            f"file://{p}"
            for p in sorted(Path(folder).iterdir())
            if p.is_file() and p.suffix.lower() in exts
        ]

    def _extract_color(self, img_path):
        if not img_path or not os.path.isfile(img_path):
            return "#5EB8FF"
        img = QImage(img_path)
        if img.isNull():
            return "#5EB8FF"
        scaled = img.scaled(50, 50, Qt.IgnoreAspectRatio, Qt.FastTransformation)
        r_total = g_total = b_total = 0
        count = 0
        for y in range(scaled.height()):
            for x in range(scaled.width()):
                c = scaled.pixelColor(x, y)
                r_total += c.red()
                g_total += c.green()
                b_total += c.blue()
                count += 1
        if count == 0:
            return "#5EB8FF"
        avg = QColor(r_total // count, g_total // count, b_total // count)
        h = avg.hsvHueF()
        s = min(1.0, max(0.45, avg.hsvSaturationF() * 2.0))
        v = min(1.0, max(0.65, avg.valueF() * 1.5))
        result = QColor.fromHsvF(h if h >= 0 else 0.0, s, v)
        return result.name()

    @Slot(result=str)
    def averageBackgroundColor(self):
        img_path = self._data.get("backgroundImage", "")
        if not img_path or not os.path.isfile(img_path):
            folder = self._data.get("backgroundFolder", "")
            if folder and os.path.isdir(folder):
                exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
                for p in sorted(Path(folder).iterdir()):
                    if p.is_file() and p.suffix.lower() in exts:
                        img_path = str(p)
                        break
        return self._extract_color(img_path)

    @Slot(str, result=str)
    def colorFromImage(self, src):
        path = src
        if path.startswith("file://"):
            path = path[7:]
        return self._extract_color(path)
