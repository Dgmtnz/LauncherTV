# LauncherTV

**An open-source, lightweight Android TV-style launcher for Linux desktops.**

When looking for alternatives to KDE Plasma Bigscreen for turning a Linux PC into a TV/couch experience, I found almost nothing viable. The few projects that existed were either closed-source, visually underwhelming, or required painful manual configuration just to get running. LauncherTV was born out of that frustration — a clean, fast, open-source launcher that just works.

![Python](https://img.shields.io/badge/Python_3-3776AB?style=flat&logo=python&logoColor=white)
![Qt](https://img.shields.io/badge/PySide6_+_QML-41CD52?style=flat&logo=qt&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

---

## Features

- **Android TV / Leanback UI** — Dark theme, horizontal scrollable rows of app cards grouped by category, smooth hardware-accelerated animations (scale, glow, crossfade).
- **Hero Widget** — Top section with live clock, weather (auto-detected location via IP), and quick-launch row of your 6 most-used apps.
- **Full Keyboard & Gamepad Navigation** — Arrow keys, Enter, Escape. Designed for TV remotes and controllers. Mouse/touchscreen also fully supported.
- **Automatic App Discovery** — Parses all `.desktop` files from the system. No manual configuration needed.
- **Fullscreen App Launching** — Every app launched from LauncherTV opens fullscreen and without window decorations, providing a true TV experience.
- **Home Key** — Press the **Menu/Context key** to return to LauncherTV from any app. Optionally overrides the key's default function via `xmodmap` (configurable in Settings).
- **Wallpaper Slideshow** — Set a single background image or a folder for automatic crossfade slideshow with configurable interval and black tint.
- **Auto Accent Color** — Toggleable mode that automatically extracts a vibrant accent color from the current wallpaper, updating in real time as the slideshow cycles.
- **Scalable UI** — Adjust the entire interface scale from 0.5x to 2.0x via Settings.
- **Built-in Settings** — Accessible via gear button or as a system app. Configure scale, accent color (presets, hex input, or auto), background tint, wallpaper, slideshow interval, weather location, autostart, and home key override.
- **Ultra-Lightweight** — Shares Qt libraries already loaded by LXQt. No Electron, no web stack, no bloat.

## Target Environment

| Component | Supported |
|---|---|
| **OS** | CachyOS, Arch Linux, or any Arch-based distro |
| **Desktop Environment** | LXQt (primary target), also works on any X11-based DE |
| **Display Server** | X11 / Xwayland (Home key + fullscreen features require X11) |
| **Window Manager** | Openbox (LXQt default), any EWMH-compliant WM |

> **Note:** The home key override, forced fullscreen, and window activation features use X11 tools (`xprop`, `xinput`, `xmodmap`, `libX11`). On a pure Wayland session without Xwayland these features won't work, but the launcher UI itself will still run.

## Controls

| Key | Action |
|---|---|
| `←` `→` | Navigate between apps in a row |
| `↑` `↓` | Navigate between rows |
| `Enter` / `Space` | Launch selected app |
| `Escape` | Close settings overlay |
| `Menu key` | Return to LauncherTV from any app |
| `Mouse click` | Full mouse/touch support throughout |
| `Mouse wheel` | Scroll rows and settings |

## Installation

### Quick Install (Arch/CachyOS)

```bash
git clone https://github.com/Dgmtnz/LauncherTV.git
cd LauncherTV
sudo ./install.sh
```

This installs dependencies (`pyside6`, `xorg-xprop`, `xorg-xinput`, `xorg-xmodmap`), copies the app to `/opt/LauncherTV/`, and creates the `launchertv` command and desktop entry.

### Run Without Installing

```bash
sudo pacman -S pyside6 xorg-xprop xorg-xinput xorg-xmodmap
cd LauncherTV
python3 main.py
```

### Uninstall

```bash
sudo ./install.sh --uninstall
```

## Project Structure

```
LauncherTV/
├── main.py                  # Entry point
├── install.sh               # Installer/uninstaller
├── launchertv.desktop       # Desktop entry template
├── backend/
│   ├── config.py            # Persistent settings (~/.config/LauncherTV/)
│   ├── models.py            # .desktop file parser & Qt models
│   ├── launcher.py          # App launching + fullscreen enforcement
│   ├── icon_provider.py     # System icon theme resolver
│   ├── weather.py           # Weather data via wttr.in + ipinfo.io
│   ├── hotkey.py            # Menu key listener + xmodmap management
│   └── x11.py               # X11 helpers via xprop + libX11 ctypes
└── qml/
    ├── main.qml             # Root window, background, layout
    └── components/
        ├── HeroWidget.qml   # Clock, weather, quick launch
        ├── AppRow.qml        # Category row with horizontal cards
        ├── AppCard.qml       # Individual app card with animations
        └── SettingsPage.qml  # Full settings overlay
```

## Configuration

All settings are stored in `~/.config/LauncherTV/config.json` and can be edited via the built-in Settings panel.

## Author

**Diego Martinez Fernandez** — [@Dgmtnz](https://github.com/Dgmtnz)

## License

MIT

---

---

# LauncherTV (Español)

**Un launcher open-source y ligero estilo Android TV para escritorios Linux.**

Cuando busqué alternativas a KDE Plasma Bigscreen para convertir un PC Linux en una experiencia de salón/TV, no encontré casi nada viable. Los pocos proyectos que existían eran de código cerrado, visualmente pobres, o requerían una configuración manual dolorosa solo para funcionar. LauncherTV nació de esa frustración — un launcher limpio, rápido y open-source que simplemente funciona.

## Características

- **Interfaz Android TV / Leanback** — Tema oscuro, filas horizontales de tarjetas de apps agrupadas por categoría, animaciones suaves aceleradas por hardware (escala, brillo, crossfade).
- **Hero Widget** — Sección superior con reloj en tiempo real, clima (ubicación auto-detectada por IP) y fila de acceso rápido con las 6 apps más usadas.
- **Navegación completa por teclado y gamepad** — Flechas, Enter, Escape. Diseñado para mandos de TV y controladores. Ratón y táctil también completamente soportados.
- **Descubrimiento automático de apps** — Lee todos los archivos `.desktop` del sistema. Sin configuración manual.
- **Lanzamiento en pantalla completa** — Cada app lanzada desde LauncherTV se abre en pantalla completa y sin decoración de ventanas, proporcionando una verdadera experiencia TV.
- **Tecla Home** — Pulsa la **tecla Menú contextual** para volver a LauncherTV desde cualquier app. Opcionalmente anula la función por defecto de la tecla vía `xmodmap` (configurable en Ajustes).
- **Slideshow de fondos** — Configura una imagen de fondo o una carpeta para slideshow automático con crossfade, intervalo configurable y tinte negro ajustable.
- **Color de acento automático** — Modo activable que extrae automáticamente un color de acento vibrante del fondo actual, actualizándose en tiempo real cuando cambia el slideshow.
- **UI escalable** — Ajusta la escala completa de la interfaz de 0.5x a 2.0x desde Ajustes.
- **Ajustes integrados** — Accesibles desde el botón de engranaje o como app del sistema. Configura escala, color de acento (presets, hex, o auto), tinte de fondo, wallpaper, intervalo de slideshow, ubicación del clima, autoarranque y override de la tecla Home.
- **Ultra-ligero** — Comparte las librerías Qt ya cargadas por LXQt. Sin Electron, sin web, sin bloat.

## Entorno objetivo

| Componente | Soportado |
|---|---|
| **SO** | CachyOS, Arch Linux o cualquier distro basada en Arch |
| **Entorno de escritorio** | LXQt (objetivo principal), funciona en cualquier DE con X11 |
| **Servidor gráfico** | X11 / Xwayland (las funciones de tecla Home + fullscreen requieren X11) |
| **Window Manager** | Openbox (default de LXQt), cualquier WM compatible con EWMH |

> **Nota:** El override de la tecla Home, el fullscreen forzado y la activación de ventanas usan herramientas X11 (`xprop`, `xinput`, `xmodmap`, `libX11`). En una sesión Wayland pura sin Xwayland estas funciones no estarán disponibles, pero la UI del launcher seguirá funcionando.

## Controles

| Tecla | Acción |
|---|---|
| `←` `→` | Navegar entre apps en una fila |
| `↑` `↓` | Navegar entre filas |
| `Enter` / `Space` | Lanzar app seleccionada |
| `Escape` | Cerrar overlay de ajustes |
| `Tecla Menú` | Volver a LauncherTV desde cualquier app |
| `Clic de ratón` | Soporte completo de ratón/táctil |
| `Rueda del ratón` | Scroll en filas y ajustes |

## Instalación

### Instalación rápida (Arch/CachyOS)

```bash
git clone https://github.com/Dgmtnz/LauncherTV.git
cd LauncherTV
sudo ./install.sh
```

Instala dependencias (`pyside6`, `xorg-xprop`, `xorg-xinput`, `xorg-xmodmap`), copia la app a `/opt/LauncherTV/` y crea el comando `launchertv` y la entrada de escritorio.

### Ejecutar sin instalar

```bash
sudo pacman -S pyside6 xorg-xprop xorg-xinput xorg-xmodmap
cd LauncherTV
python3 main.py
```

### Desinstalar

```bash
sudo ./install.sh --uninstall
```

## Autor

**Diego Martinez Fernandez** — [@Dgmtnz](https://github.com/Dgmtnz)

## Licencia

MIT
