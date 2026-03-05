import json
import threading
import time
import urllib.parse
import urllib.request

from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer

WMO_ICONS = {
    0: "☀️", 1: "🌤️", 2: "⛅", 3: "☁️",
    45: "🌫️", 48: "🌫️",
    51: "🌦️", 53: "🌦️", 55: "🌦️",
    56: "🌨️", 57: "🌨️",
    61: "🌧️", 63: "🌧️", 65: "🌧️",
    66: "🌨️", 67: "🌨️",
    71: "❄️", 73: "❄️", 75: "❄️", 77: "❄️",
    80: "🌧️", 81: "🌧️", 82: "🌧️",
    85: "❄️", 86: "❄️",
    95: "⛈️", 96: "⛈️", 99: "⛈️",
}

WMO_DESCRIPTIONS = {
    0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime fog",
    51: "Light drizzle", 53: "Moderate drizzle", 55: "Dense drizzle",
    56: "Freezing drizzle", 57: "Heavy freezing drizzle",
    61: "Light rain", 63: "Moderate rain", 65: "Heavy rain",
    66: "Freezing rain", 67: "Heavy freezing rain",
    71: "Light snow", 73: "Moderate snow", 75: "Heavy snow", 77: "Snow grains",
    80: "Light showers", 81: "Moderate showers", 82: "Heavy showers",
    85: "Light snow showers", 86: "Heavy snow showers",
    95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Heavy hail storm",
}

MAX_RETRIES = 3
RETRY_DELAY = 300
REFRESH_INTERVAL_MS = 3_600_000


def _detect_location():
    """City name + coordinates from IP geolocation."""
    try:
        req = urllib.request.Request(
            "https://ipinfo.io/json",
            headers={"User-Agent": "LauncherTV/1.0"},
        )
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
        city = data.get("city", "")
        loc = data.get("loc", "")
        if loc and "," in loc:
            lat, lon = loc.split(",", 1)
            return city, float(lat), float(lon)
    except Exception:
        pass
    return "", None, None


def _geocode_city(city_name):
    """Resolve a city name to coordinates via Open-Meteo geocoding."""
    try:
        encoded = urllib.parse.quote(city_name)
        url = (
            f"https://geocoding-api.open-meteo.com/v1/search"
            f"?name={encoded}&count=1&language=en"
        )
        req = urllib.request.Request(url, headers={"User-Agent": "LauncherTV/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
        results = data.get("results", [])
        if results:
            r = results[0]
            return r.get("name", city_name), r["latitude"], r["longitude"]
    except Exception:
        pass
    return city_name, None, None


class WeatherProvider(QObject):
    weatherChanged = Signal()

    def __init__(self, location="", parent=None):
        super().__init__(parent)
        self._temp = "--°C"
        self._feels = "--°C"
        self._condition = "Loading…"
        self._icon = "☁️"
        self._location = location or ""
        self._lat = None
        self._lon = None

        self._timer = QTimer(self)
        self._timer.timeout.connect(self.refresh)
        self._timer.start(REFRESH_INTERVAL_MS)

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
        threading.Thread(target=self._fetch_with_retries, daemon=True).start()

    @Slot(str)
    def setLocation(self, loc):
        self._location = loc
        self._lat = None
        self._lon = None
        self.refresh()

    def _fetch_with_retries(self):
        for attempt in range(MAX_RETRIES):
            if self._do_fetch():
                return
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY)
        if self._condition in ("Loading…", "Unavailable"):
            self._condition = "Unavailable"
            self.weatherChanged.emit()

    def _do_fetch(self):
        try:
            if self._lat is None or self._lon is None:
                if self._location:
                    name, lat, lon = _geocode_city(self._location)
                else:
                    name, lat, lon = _detect_location()
                if lat is not None:
                    self._lat, self._lon = lat, lon
                    if name:
                        self._location = name

            if self._lat is None or self._lon is None:
                return False

            url = (
                f"https://api.open-meteo.com/v1/forecast"
                f"?latitude={self._lat}&longitude={self._lon}"
                f"&current=temperature_2m,apparent_temperature,weather_code"
                f"&timezone=auto"
            )
            req = urllib.request.Request(
                url, headers={"User-Agent": "LauncherTV/1.0"}
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())

            current = data["current"]
            temp = current.get("temperature_2m")
            feels = current.get("apparent_temperature")
            code = current.get("weather_code", -1)

            self._temp = f"{temp:.0f}°C" if temp is not None else "--°C"
            self._feels = f"{feels:.0f}°C" if feels is not None else "--°C"
            self._condition = WMO_DESCRIPTIONS.get(code, "Unknown")
            self._icon = WMO_ICONS.get(code, "☁️")
            self.weatherChanged.emit()
            return True
        except Exception:
            return False
