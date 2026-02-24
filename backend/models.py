import os
import configparser
from pathlib import Path

from PySide6.QtCore import (
    Qt, QAbstractListModel, QModelIndex, QByteArray, Slot,
)

CATEGORY_PRIORITY = [
    "Games",
    "Media",
    "Internet",
    "Productivity",
    "Development",
    "System",
    "Utilities",
]

CATEGORY_MAP = {
    "Game": "Games",
    "AudioVideo": "Media",
    "Audio": "Media",
    "Video": "Media",
    "Graphics": "Media",
    "Photography": "Media",
    "Network": "Internet",
    "WebBrowser": "Internet",
    "Email": "Internet",
    "InstantMessaging": "Internet",
    "Chat": "Internet",
    "Office": "Productivity",
    "Finance": "Productivity",
    "Calendar": "Productivity",
    "WordProcessor": "Productivity",
    "Spreadsheet": "Productivity",
    "Development": "Development",
    "IDE": "Development",
    "TextEditor": "Development",
    "System": "System",
    "Settings": "System",
    "Monitor": "System",
    "TerminalEmulator": "System",
    "PackageManager": "System",
    "Utility": "Utilities",
    "Accessibility": "Utilities",
    "Archiving": "Utilities",
    "Compression": "Utilities",
    "FileManager": "Utilities",
    "Calculator": "Utilities",
}

DESKTOP_DIRS = [
    Path("/usr/share/applications"),
    Path.home() / ".local" / "share" / "applications",
]

SETTINGS_ENTRY = {
    "name": "LauncherTV Settings",
    "icon_source": "image://icons/preferences-system",
    "exec_cmd": "__settings__",
    "categories": ["System", "Settings"],
    "desktop_id": "__settings__",
}


def _strip_field_codes(exec_str: str) -> str:
    return " ".join(p for p in exec_str.split() if not p.startswith("%"))


def _categorize(categories: list[str]) -> str:
    for cat in categories:
        if cat in CATEGORY_MAP:
            return CATEGORY_MAP[cat]
    return "Utilities"


def _resolve_icon_source(icon: str) -> str:
    if not icon:
        return "image://icons/application-x-executable"
    if os.path.isabs(icon):
        return f"file://{icon}" if os.path.isfile(icon) else "image://icons/application-x-executable"
    return f"image://icons/{icon}"


def _parse_desktop_file(path: Path) -> dict | None:
    cfg = configparser.ConfigParser(interpolation=None, strict=False)
    try:
        cfg.read(str(path), encoding="utf-8")
    except Exception:
        return None

    if not cfg.has_section("Desktop Entry"):
        return None

    e = cfg["Desktop Entry"]
    if e.get("Type", "") != "Application":
        return None
    if e.get("NoDisplay", "").lower() == "true":
        return None
    if e.get("Hidden", "").lower() == "true":
        return None

    name = e.get("Name", "").strip()
    exec_cmd = e.get("Exec", "").strip()
    if not name or not exec_cmd:
        return None

    icon = e.get("Icon", "").strip()
    cats_raw = e.get("Categories", "")
    categories = [c.strip() for c in cats_raw.split(";") if c.strip()]

    return {
        "name": name,
        "icon_source": _resolve_icon_source(icon),
        "exec_cmd": _strip_field_codes(exec_cmd),
        "categories": categories,
        "desktop_id": path.stem,
    }


def discover_applications() -> dict[str, dict]:
    apps: dict[str, dict] = {}
    for d in reversed(DESKTOP_DIRS):
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.desktop")):
            if f.stem in apps:
                continue
            entry = _parse_desktop_file(f)
            if entry:
                apps[f.stem] = entry
    return apps


def get_most_used_apps(all_apps: dict, config, n: int = 6) -> list[dict]:
    top_ids = config.top_launched(n)
    items: list[dict] = []
    seen: set[str] = set()
    for did in top_ids:
        if did in all_apps and did not in seen:
            items.append(all_apps[did])
            seen.add(did)
    if len(items) < n:
        for did, app in all_apps.items():
            if did not in seen and not did.startswith("__"):
                items.append(app)
                seen.add(did)
            if len(items) >= n:
                break
    return items[:n]


class AppListModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    IconSourceRole = Qt.UserRole + 2
    ExecCmdRole = Qt.UserRole + 3
    DesktopIdRole = Qt.UserRole + 4

    _role_names = {
        NameRole: QByteArray(b"name"),
        IconSourceRole: QByteArray(b"iconSource"),
        ExecCmdRole: QByteArray(b"execCmd"),
        DesktopIdRole: QByteArray(b"desktopId"),
    }

    def __init__(self, apps: list[dict] | None = None, parent=None):
        super().__init__(parent)
        self._apps: list[dict] = apps or []

    def roleNames(self):
        return self._role_names

    def rowCount(self, parent=QModelIndex()):
        return len(self._apps)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._apps):
            return None
        app = self._apps[index.row()]
        if role == self.NameRole:
            return app["name"]
        if role == self.IconSourceRole:
            return app["icon_source"]
        if role == self.ExecCmdRole:
            return app["exec_cmd"]
        if role == self.DesktopIdRole:
            return app["desktop_id"]
        return None

    @Slot(int, result=str)
    def execCmdAt(self, row: int) -> str:
        if 0 <= row < len(self._apps):
            return self._apps[row]["exec_cmd"]
        return ""

    @Slot(int, result=str)
    def desktopIdAt(self, row: int) -> str:
        if 0 <= row < len(self._apps):
            return self._apps[row]["desktop_id"]
        return ""

    def reset_apps(self, apps: list[dict]):
        self.beginResetModel()
        self._apps = apps
        self.endResetModel()


class CategoryListModel(QAbstractListModel):
    NameRole = Qt.UserRole + 1
    AppsModelRole = Qt.UserRole + 2
    AppCountRole = Qt.UserRole + 3

    _role_names = {
        NameRole: QByteArray(b"categoryName"),
        AppsModelRole: QByteArray(b"appsModel"),
        AppCountRole: QByteArray(b"appCount"),
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self._categories: list[tuple[str, AppListModel]] = []

    def roleNames(self):
        return self._role_names

    def rowCount(self, parent=QModelIndex()):
        return len(self._categories)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._categories):
            return None
        name, model = self._categories[index.row()]
        if role == self.NameRole:
            return name
        if role == self.AppsModelRole:
            return model
        if role == self.AppCountRole:
            return model.rowCount()
        return None

    def load_from(self, all_apps: dict):
        grouped: dict[str, list[dict]] = {}
        for entry in all_apps.values():
            cat = _categorize(entry["categories"])
            grouped.setdefault(cat, []).append(entry)

        grouped.setdefault("System", []).append(SETTINGS_ENTRY)

        self.beginResetModel()
        self._categories.clear()

        for cat_name in CATEGORY_PRIORITY:
            apps = grouped.pop(cat_name, None)
            if apps:
                apps.sort(key=lambda a: a["name"].lower())
                self._categories.append((cat_name, AppListModel(apps, self)))

        for cat_name in sorted(grouped):
            apps = grouped[cat_name]
            apps.sort(key=lambda a: a["name"].lower())
            self._categories.append((cat_name, AppListModel(apps, self)))

        self.endResetModel()
