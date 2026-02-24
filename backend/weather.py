import json
import threading
import urllib.request

from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer

WEATHER_ICONS = {
    "113": "☀️", "116": "⛅", "119": "☁️", "122": "☁️",
    "143": "🌫️", "176": "🌦️", "179": "🌨️", "182": "🌨️",
    "185": "🌨️", "200": "⛈️", "227": "🌨️", "230": "❄️",
    "248": "🌫️", "260": "🌫️", "263": "🌦️", "266": "🌦️",
    "281": "🌨️", "284": "🌨️", "293": "🌦️", "296": "🌧️",
    "299": "🌧️", "302": "🌧️", "305": "🌧️", "308": "🌧️",
    "311": "🌨️", "314": "🌨️", "317": "🌨️", "320": "🌨️",
    "323": "🌨️", "326": "🌨️", "329": "❄️", "332": "❄️",
    "335": "❄️", "338": "❄️", "350": "🌨️", "353": "🌦️",
    "356": "🌧️", "359": "🌧️", "362": "🌨️", "365": "🌨️",
    "368": "🌨️", "371": "❄️", "374": "🌨️", "377": "🌨️",
    "386": "⛈️", "389": "⛈️", "392": "⛈️", "395": "❄️",
}


def _detect_city() -> str:
    try:
        req = urllib.request.Request(
            "https://ipinfo.io/json",
            headers={"User-Agent": "LauncherTV/1.0"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
        return data.get("city", "")
    except Exception:
        return ""


class WeatherProvider(QObject):
    weatherChanged = Signal()

    def __init__(self, location="", parent=None):
        super().__init__(parent)
        self._temp = "--°C"
        self._feels = "--°C"
        self._condition = "Loading…"
        self._icon = "☁️"
        self._location = location or ""

        self._timer = QTimer(self)
        self._timer.timeout.connect(self.refresh)
        self._timer.start(1_800_000)
        QTimer.singleShot(500, self.refresh)

    def _g_temp(self):
        return self._temp

    temperature = Property(str, _g_temp, notify=weatherChanged)

    def _g_feels(self):
        return self._feels

    feelsLike = Property(str, _g_feels, notify=weatherChanged)

    def _g_cond(self):
        return self._condition

    condition = Property(str, _g_cond, notify=weatherChanged)

    def _g_icon(self):
        return self._icon

    icon = Property(str, _g_icon, notify=weatherChanged)

    def _g_loc(self):
        return self._location

    location = Property(str, _g_loc, notify=weatherChanged)

    @Slot()
    def refresh(self):
        threading.Thread(target=self._fetch, daemon=True).start()

    @Slot(str)
    def setLocation(self, loc):
        self._location = loc
        self.refresh()

    def _fetch(self):
        try:
            loc = self._location
            if not loc:
                loc = _detect_city()
                if loc:
                    self._location = loc

            url = f"https://wttr.in/{loc}?format=j1"
            req = urllib.request.Request(url, headers={"User-Agent": "LauncherTV/1.0"})
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())

            curr = data["current_condition"][0]
            self._temp = curr.get("temp_C", "--") + "°C"
            self._feels = curr.get("FeelsLikeC", "--") + "°C"
            desc = curr.get("weatherDesc", [{}])
            self._condition = desc[0].get("value", "") if desc else ""
            code = curr.get("weatherCode", "")
            self._icon = WEATHER_ICONS.get(code, "☁️")

            if not self._location:
                area = data.get("nearest_area", [{}])[0]
                name = area.get("areaName", [{}])[0].get("value", "")
                if name:
                    self._location = name

            self.weatherChanged.emit()
        except Exception:
            self._condition = "Unavailable"
            self.weatherChanged.emit()
