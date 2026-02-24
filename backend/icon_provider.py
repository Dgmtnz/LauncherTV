from PySide6.QtCore import QSize, Qt
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtQuick import QQuickImageProvider


FALLBACK_ICON = "application-x-executable"


class IconProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Pixmap)

    def requestPixmap(self, icon_id, size, requested_size):
        w = requested_size.width() if requested_size.width() > 0 else 128
        h = requested_size.height() if requested_size.height() > 0 else 128
        target = QSize(w, h)

        icon = QIcon.fromTheme(icon_id)
        if icon.isNull():
            pixmap = QPixmap(icon_id)
            if pixmap.isNull():
                icon = QIcon.fromTheme(FALLBACK_ICON)
                if icon.isNull():
                    pm = QPixmap(target)
                    pm.fill(Qt.transparent)
                    return pm
                return icon.pixmap(target)
            return pixmap.scaled(target, Qt.KeepAspectRatio, Qt.SmoothTransformation)

        return icon.pixmap(target)
