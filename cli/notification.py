#!/usr/bin/env python3
import sys
import json
import os
from datetime import datetime, timedelta

try:
    from PyQt6.QtWidgets import (
        QApplication,
        QMainWindow,
        QListWidget,
        QListWidgetItem,
        QVBoxLayout,
        QHBoxLayout,
        QWidget,
        QLabel,
        QSizePolicy,
    )
    from PyQt6.QtCore import Qt, QSize, QPropertyAnimation
    from PyQt6.QtGui import QPixmap, QFont, QAction
except ImportError:
    print("Error: PyQt6 is not installed.", file=sys.stderr)
    sys.exit(1)


def parse_log_file(log_path):
    notifications = []
    try:
        with open(log_path, "r") as f:
            for line in f:
                if line.strip():
                    try:
                        notifications.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
    except FileNotFoundError:
        print(f"Error: Log file not found at '{log_path}'", file=sys.stderr)
    return notifications


class NotificationItemWidget(QWidget):
    def __init__(self, notif_data):
        super().__init__()

        # Ensure the widget expands horizontally but keeps a compact height
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
        self.setMinimumHeight(64)

        main_layout = QHBoxLayout(self)
        # larger contents margins so the "card" has internal padding
        main_layout.setContentsMargins(12, 12, 12, 12)
        main_layout.setSpacing(10)

        # Icon area with fixed width (only for the image)
        icon_label = QLabel()
        icon_label.setFixedWidth(48)
        icon_label.setFixedHeight(48)
        icon_label.setAlignment(Qt.AlignmentFlag.AlignTop)

        icon_path = notif_data.get("appIcon") or notif_data.get("image")
        pixmap = (
            QPixmap(icon_path) if icon_path and os.path.exists(icon_path) else QPixmap()
        )
        if not pixmap.isNull():
            pixmap = pixmap.scaled(
                40,
                40,
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
            icon_label.setPixmap(pixmap)

        main_layout.addWidget(icon_label, alignment=Qt.AlignmentFlag.AlignTop)

        # Text area
        text_layout = QVBoxLayout()
        text_layout.setSpacing(4)
        text_layout.setContentsMargins(
            0, 0, 0, 0
        )  # text area uses its own spacing only

        summary_label = QLabel(notif_data.get("summary", "No Summary"))
        summary_label.setFont(QFont("Arial", 11, QFont.Weight.Bold))
        summary_label.setTextInteractionFlags(
            Qt.TextInteractionFlag.TextSelectableByMouse
        )
        text_layout.addWidget(summary_label)

        body_label = QLabel(notif_data.get("body", ""))
        body_label.setWordWrap(True)
        body_label.setFont(QFont("Arial", 10))
        body_label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        text_layout.addWidget(body_label)

        timestamp_ms = notif_data.get("time", 0)
        try:
            dt_object = datetime.fromtimestamp(timestamp_ms / 1000)
            today = datetime.now().date()
            if dt_object.date() == today:
                time_str = dt_object.strftime("Today at %H:%M")
            elif dt_object.date() == today - timedelta(days=1):
                time_str = dt_object.strftime("Yesterday at %H:%M")
            else:
                time_str = dt_object.strftime("%m/%d/%Y %H:%M")
        except Exception:
            time_str = "Invalid Time"
        time_label = QLabel(time_str)
        time_label.setAlignment(Qt.AlignmentFlag.AlignRight)
        time_label.setFont(QFont("Arial", 8))
        time_label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        text_layout.addWidget(time_label)

        main_layout.addLayout(text_layout)

        self.setWindowOpacity(0.0)
        self.anim = QPropertyAnimation(self, b"windowOpacity")
        self.anim.setDuration(400)  # ความยาวแอนิเมชัน 400 มิลลิวินาที
        self.anim.setStartValue(0.0)
        self.anim.setEndValue(1.0)
        self.anim.start()


class NotificationWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Notification Center")
        self.resize(520, 720)

        clear_action = QAction("Clear All", self)
        clear_action.triggered.connect(self.clear_notifications)
        self.toolbar = self.addToolBar("Main Toolbar")
        self.toolbar.addAction(clear_action)

        self.list_widget = QListWidget()
        # spacing between items (gives visual margin between the item widgets)
        self.list_widget.setSpacing(8)
        # add an outer padding around the whole list so items don't touch the window edge
        self.list_widget.setContentsMargins(8, 8, 8, 8)
        # allow selection like the old code
        self.list_widget.setSelectionMode(QListWidget.SelectionMode.SingleSelection)
        # make scrolling smoother
        self.list_widget.setVerticalScrollMode(QListWidget.ScrollMode.ScrollPerPixel)

        # small stylesheet to add padding inside the list (uses theme colors only)
        # we avoid setting background colors so the app follows the system theme
        self.list_widget.setStyleSheet(
            """
            QListWidget::item:selected {
                background-color: palette(light);
                border-radius: 8px;
            }
            QListWidget {
                padding: 6px;
            }
            """
        )

        self.setCentralWidget(self.list_widget)

    def load_log_data(self, log_path):
        notifications = parse_log_file(log_path)
        notifications.sort(key=lambda x: x.get("time", 0), reverse=True)
        self.list_widget.clear()
        for notif in notifications:
            list_item = QListWidgetItem()
            widget = NotificationItemWidget(notif)
            # increase the size hint slightly so layout margins are visible
            size = widget.sizeHint()
            size.setHeight(size.height() + 12)
            list_item.setSizeHint(size)
            self.list_widget.addItem(list_item)
            self.list_widget.setItemWidget(list_item, widget)

    def clear_notifications(self):
        self.list_widget.clear()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = NotificationWindow()
    if len(sys.argv) > 1 and os.path.exists(sys.argv[1]):
        win.load_log_data(sys.argv[1])
    win.show()
    sys.exit(app.exec())
