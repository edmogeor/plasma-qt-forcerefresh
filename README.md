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

This patch adds a new DBus signal `forceRefresh` that unconditionally sends `QEvent::StyleChange` to all widgets, bypassing the style name comparison.

## Installation

### Prerequisites

- KDE Plasma 6
- Build dependencies: `cmake`, `make`, `git`, `extra-cmake-modules`, `qt6-base-dev`, etc.

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
2. Add a `forceStyleRefresh()` slot that iterates all widgets and sends `QEvent::StyleChange`:

```cpp
void KHintsSettings::forceStyleRefresh()
{
    if (!qobject_cast<QApplication *>(QCoreApplication::instance())) {
        return;
    }
    for (QWidget *widget : QApplication::allWidgets()) {
        QEvent event(QEvent::StyleChange);
        QApplication::sendEvent(widget, &event);
    }
}
```

## Use Cases

- Theme switchers that change color schemes without changing widget styles
- Dynamic theming tools
- Development/debugging of Qt styles

## License

This patch is provided under the same license as plasma-integration (LGPL-2.0-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL).

## Related

- [plasma-integration](https://invent.kde.org/plasma/plasma-integration) - KDE Plasma integration for Qt
