import shlex
import subprocess
import threading
import time

from PySide6.QtCore import QObject, Signal, Slot

from . import x11


class AppLauncher(QObject):
    launched = Signal(str)
    settingsRequested = Signal()

    @Slot(str, str, str)
    def launch(self, exec_cmd: str, desktop_id: str = "", wm_class: str = ""):
        if exec_cmd == "__settings__":
            self.settingsRequested.emit()
            return

        if wm_class:
            existing = x11.find_window_by_class(wm_class)
            if existing:
                x11.activate_window(existing)
                return

        try:
            parts = shlex.split(exec_cmd)
        except ValueError:
            parts = exec_cmd.split()

        windows_before = x11.get_all_window_ids()

        try:
            proc = subprocess.Popen(
                parts,
                start_new_session=True,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            self.launched.emit(desktop_id)

            threading.Thread(
                target=self._make_fullscreen,
                args=(proc.pid, windows_before),
                daemon=True,
            ).start()
        except FileNotFoundError:
            pass

    @staticmethod
    def _make_fullscreen(pid, windows_before):
        """Wait for the launched app's window(s) and make them fullscreen."""
        applied = set()

        for attempt in range(120):
            time.sleep(0.1)

            candidates = set(x11.find_windows_by_pid(pid))

            if not candidates and attempt > 20:
                current = x11.get_all_window_ids()
                candidates = current - windows_before

            new = candidates - applied
            for wid in new:
                name = x11.window_name(wid)
                if "LauncherTV" in name:
                    continue
                time.sleep(0.15)
                x11.remove_decorations(wid)
                x11.set_fullscreen(wid)
                applied.add(wid)

            if applied:
                time.sleep(1.0)
                extra = set(x11.find_windows_by_pid(pid)) - applied
                for wid in extra:
                    name = x11.window_name(wid)
                    if "LauncherTV" not in name:
                        x11.remove_decorations(wid)
                        x11.set_fullscreen(wid)
                return
