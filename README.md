# plasma-qt-forcerefresh

A patch for KDE's `plasma-integration` that adds a DBus signal to force Qt applications to refresh their styles without changing the widget style.

## Problem

When building theme switchers or similar tools for KDE Plasma, you may need to refresh Qt application styles dynamically. The standard `org.kde.KGlobalSettings.notifyChange` signal with `StyleChanged` only triggers a refresh if the widget style has actually changed (checked in `khintssettings.cpp`):

```cpp
if (!app->style() || app->style()->name().compare(theme, Qt::CaseInsensitive) != 0) {
    app->setStyle(theme);
}
```

This means if you're only changing colors or other style properties without changing the widget style itself (e.g., Breeze), Qt apps won't refresh.

## Solution

This patch adds a new DBus signal `forceRefresh` that forces Qt to recreate the current style, bypassing the style name comparison. This is particularly useful for styles like Kvantum that cache their theme configuration internally.

## Installation

### Prerequisites

- KDE Plasma 6
- Build dependencies:

**Arch Linux:**
```bash
sudo pacman -S cmake make git extra-cmake-modules qt6-base plasma-wayland-protocols
```

**Debian/Ubuntu:**
```bash
sudo apt install cmake make git extra-cmake-modules qt6-base-dev plasma-wayland-protocols
```

### Install

```bash
git clone https://github.com/edmogeor/plasma-qt-forcerefresh.git
cd plasma-qt-forcerefresh
./plasma-integration-patch-manager.sh install
```

The script automatically clones and patches `plasma-integration`.

### Uninstall

```bash
./plasma-integration-patch-manager.sh uninstall
```

## Usage

Trigger a style refresh on all running Qt applications:

```bash
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.forceRefresh
```

**Note:** Applications must be restarted after installing the patch to pick up the new signal handler.

## How It Works

The patch modifies `qt6/src/platformtheme/khintssettings.cpp` to:

1. Register a new DBus signal handler for `org.kde.KGlobalSettings.forceRefresh`
2. Add a `forceStyleRefresh()` slot that reparses configuration and recreates the style:

```cpp
void KHintsSettings::forceStyleRefresh()
{
    QApplication *app = qobject_cast<QApplication *>(QCoreApplication::instance());
    if (!app) {
        return;
    }

    mKdeGlobals->reparseConfiguration();

    // Force style recreation by setting the same style again
    if (app->style()) {
        QString currentStyle = app->style()->name();
        app->setStyle(currentStyle);
    }

    loadPalettes();
}
```

This approach works because `app->setStyle()` creates a new style instance, forcing styles like Kvantum to reload their theme configuration from disk.

## Use Cases

- Theme switchers that change Kvantum themes without changing the widget style name
- Dynamic theming tools that modify style properties at runtime
- Day/night theme switchers (e.g., [plasma-daynight-sync](https://github.com/edmogeor/plasma-daynight-sync))
- Development/debugging of Qt styles

## License

This patch is provided under the same license as plasma-integration (LGPL-2.0-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL).

## Related

- [plasma-integration](https://invent.kde.org/plasma/plasma-integration) - KDE Plasma integration for Qt
