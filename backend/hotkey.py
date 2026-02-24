"""
Global Home key listener using the Menu/Context key (keycode 135).

Uses `xinput test-xi2 --root` to passively monitor raw key events
without grabbing them. Detects a Menu key tap and calls the callback.
"""

import subprocess
import threading
import time


MENU_KEYCODE = 135


class HomeKeyDaemon(threading.Thread):
    """Background daemon that detects Menu key taps to return home."""

    def __init__(self, callback):
        super().__init__(daemon=True)
        self._callback = callback

    def run(self):
        while True:
            try:
                self._listen()
            except Exception:
                time.sleep(2)

    def _listen(self):
        proc = subprocess.Popen(
            ["xinput", "test-xi2", "--root"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )

        event_type = None

        for line in proc.stdout:
            s = line.strip()

            if "RawKeyPress" in s:
                event_type = "press"
            elif "RawKeyRelease" in s:
                event_type = "release"
            elif s.startswith("detail:") and event_type:
                try:
                    keycode = int(s.split(":")[1].strip())
                except (ValueError, IndexError):
                    event_type = None
                    continue

                if event_type == "press" and keycode == MENU_KEYCODE:
                    pass  # wait for release

                elif event_type == "release" and keycode == MENU_KEYCODE:
                    self._callback()

                event_type = None


def apply_key_grab(enabled):
    """Use xmodmap to suppress or restore the Menu key's default function."""
    try:
        if enabled:
            subprocess.run(
                ["xmodmap", "-e", "keycode 135 = NoSymbol NoSymbol"],
                timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        else:
            subprocess.run(
                ["xmodmap", "-e", "keycode 135 = Menu NoSymbol Menu"],
                timeout=3, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
