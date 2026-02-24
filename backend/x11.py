"""
X11 window management helpers.

Uses xprop (subprocess) for property queries and libX11 (ctypes) for
sending EWMH client messages. No external tool dependencies beyond xprop
and the X11 shared library already loaded by Qt.
"""

import ctypes
import ctypes.util
import re
import subprocess


# ── libX11 via ctypes ─────────────────────────────────────────

class _XClientMessageEvent(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_int),
        ("serial", ctypes.c_ulong),
        ("send_event", ctypes.c_int),
        ("display", ctypes.c_void_p),
        ("window", ctypes.c_ulong),
        ("message_type", ctypes.c_ulong),
        ("format", ctypes.c_int),
        ("data_l", ctypes.c_long * 5),
        ("_pad", ctypes.c_byte * 64),
    ]


_lib = None


def _xlib():
    global _lib
    if _lib is not None:
        return _lib
    path = ctypes.util.find_library("X11")
    if not path:
        return None
    _lib = ctypes.CDLL(path)
    _lib.XOpenDisplay.restype = ctypes.c_void_p
    _lib.XOpenDisplay.argtypes = [ctypes.c_char_p]
    _lib.XCloseDisplay.argtypes = [ctypes.c_void_p]
    _lib.XDefaultRootWindow.restype = ctypes.c_ulong
    _lib.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    _lib.XInternAtom.restype = ctypes.c_ulong
    _lib.XInternAtom.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_int]
    _lib.XSendEvent.argtypes = [
        ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int,
        ctypes.c_long, ctypes.c_void_p,
    ]
    _lib.XFlush.argtypes = [ctypes.c_void_p]
    return _lib


def _send_ewmh(window_id, message_name, data):
    """Send an EWMH client message to the root window."""
    lib = _xlib()
    if not lib:
        return
    dpy = lib.XOpenDisplay(None)
    if not dpy:
        return
    try:
        root = lib.XDefaultRootWindow(dpy)
        atom = lib.XInternAtom(dpy, message_name, 0)

        evt = _XClientMessageEvent()
        evt.type = 33  # ClientMessage
        evt.send_event = 1
        evt.display = dpy
        evt.window = window_id
        evt.message_type = atom
        evt.format = 32
        for i, v in enumerate(data[:5]):
            evt.data_l[i] = v

        mask = (1 << 20) | (1 << 19)  # SubstructureRedirect | Notify
        lib.XSendEvent(dpy, root, 0, mask, ctypes.byref(evt))
        lib.XFlush(dpy)
    finally:
        lib.XCloseDisplay(dpy)


def _intern(name):
    lib = _xlib()
    if not lib:
        return 0
    dpy = lib.XOpenDisplay(None)
    if not dpy:
        return 0
    try:
        return lib.XInternAtom(dpy, name, 0)
    finally:
        lib.XCloseDisplay(dpy)


# ── subprocess helpers ────────────────────────────────────────

def _run(cmd, timeout=3):
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout
        ).stdout
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""


# ── Window discovery ──────────────────────────────────────────

def get_all_window_ids():
    """All managed window IDs as a set of hex strings."""
    out = _run(["xprop", "-root", "_NET_CLIENT_LIST"])
    m = re.search(r"#\s*(.+)", out)
    if not m:
        return set()
    return {w.strip().rstrip(",") for w in m.group(1).split(",") if w.strip()}


def find_windows_by_pid(pid):
    result = []
    for wid in get_all_window_ids():
        out = _run(["xprop", "-id", wid, "_NET_WM_PID"])
        m = re.search(r"=\s*(\d+)", out)
        if m and int(m.group(1)) == pid:
            result.append(wid)
    return result


def find_window_by_name(name):
    for wid in get_all_window_ids():
        out = _run(["xprop", "-id", wid, "_NET_WM_NAME", "WM_NAME"])
        if name in out:
            return wid
    return None


def window_name(wid):
    out = _run(["xprop", "-id", wid, "_NET_WM_NAME", "WM_NAME"])
    m = re.search(r'"(.+?)"', out)
    return m.group(1) if m else ""


# ── Window manipulation ──────────────────────────────────────

def remove_decorations(wid):
    _run([
        "xprop", "-id", str(wid),
        "-f", "_MOTIF_WM_HINTS", "32c",
        "-set", "_MOTIF_WM_HINTS", "0x2, 0x0, 0x0, 0x0, 0x0",
    ])


def set_fullscreen(wid):
    wid_int = int(wid, 16) if isinstance(wid, str) else int(wid)
    fs_atom = _intern(b"_NET_WM_STATE_FULLSCREEN")
    _send_ewmh(wid_int, b"_NET_WM_STATE", [1, fs_atom, 0, 1, 0])


def activate_window(wid):
    wid_int = int(wid, 16) if isinstance(wid, str) else int(wid)
    _send_ewmh(wid_int, b"_NET_ACTIVE_WINDOW", [2, 0, 0, 0, 0])


def activate_by_name(name):
    wid = find_window_by_name(name)
    if wid:
        activate_window(wid)
        return True
    return False
