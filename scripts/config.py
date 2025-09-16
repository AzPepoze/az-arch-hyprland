import sys
import os
import json
import subprocess
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QPushButton,
    QMessageBox,
    QGroupBox,
    QLabel,
    QCheckBox,
    QLineEdit,
    QScrollArea,
    QComboBox,
)
from PyQt6.QtCore import Qt

# Add the script's directory to the Python path to find submodules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from installer_components.stylesheet import get_stylesheet


class ConfigApp(QWidget):
    def __init__(self):
        super().__init__()
        self.repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.config_path = os.path.join(self.repo_dir, "config.json")
        self.example_config_path = os.path.join(self.repo_dir, "config.example.json")
        self.config_data = {}
        self.widgets = {}

        self.init_ui()
        self.load_config()
        self._apply_stylesheet()

    def init_ui(self):
        self.setWindowTitle("Az Arch Hyprland - Configuration")
        self.setGeometry(100, 100, 500, 400)

        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(10, 10, 10, 10)
        self.main_layout.setSpacing(15)

        self._create_scroll_area()
        self._create_action_buttons()

    def _apply_stylesheet(self):
        self.setStyleSheet(get_stylesheet())

    def _create_scroll_area(self):
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)

        self.scroll_content_widget = QWidget()
        self.config_layout = QVBoxLayout(self.scroll_content_widget)
        self.config_layout.setContentsMargins(15, 15, 15, 15)
        self.config_layout.setSpacing(15)

        scroll_area.setWidget(self.scroll_content_widget)
        self.main_layout.addWidget(scroll_area)

    def _create_action_buttons(self):
        button_layout = QHBoxLayout()
        button_layout.setSpacing(10)

        self.save_btn = QPushButton("Save Changes")
        self.save_btn.clicked.connect(self.save_config)

        self.reset_btn = QPushButton("Reset to Default")
        self.reset_btn.clicked.connect(self.reset_to_default)

        button_layout.addStretch()
        button_layout.addWidget(self.reset_btn)
        button_layout.addWidget(self.save_btn)

        self.main_layout.addLayout(button_layout)

    def load_config(self, from_defaults=False):
        config_to_load = self.example_config_path if from_defaults else self.config_path

        if not from_defaults and not os.path.exists(config_to_load):
            self.load_config(from_defaults=True)
            return

        try:
            with open(config_to_load, "r") as f:
                self.config_data = json.load(f)
            self.populate_ui()
        except (FileNotFoundError, json.JSONDecodeError) as e:
            QMessageBox.critical(self, "Error", f"Failed to load configuration: {e}")
            self.config_data = {}

    def populate_ui(self):
        # Clear existing widgets
        for i in reversed(range(self.config_layout.count())):
            widget = self.config_layout.itemAt(i).widget()
            if widget is not None:
                widget.deleteLater()
        self.widgets = {}

        group_box = QGroupBox("General Settings")
        group_layout = QVBoxLayout(group_box)

        for key, value in sorted(self.config_data.items()):
            label = QLabel(f"{key.replace('_', ' ').title()}")

            if key == "model":
                widget = QComboBox()
                widget.addItems(["pc", "laptop"])
                if value in ["pc", "laptop"]:
                    widget.setCurrentText(value)
            elif isinstance(value, bool):
                widget = QCheckBox()
                widget.setChecked(value)
            elif isinstance(value, str):
                widget = QLineEdit()
                widget.setText(value)
            else:
                # For other types, just display as string for now
                widget = QLineEdit()
                widget.setText(str(value))
                widget.setReadOnly(True)  # Make it non-editable if type is not handled

            self.widgets[key] = widget

            row_layout = QHBoxLayout()
            row_layout.addWidget(label)
            row_layout.addStretch()
            row_layout.addWidget(widget)
            group_layout.addLayout(row_layout)

        self.config_layout.addWidget(group_box)
        self.config_layout.addStretch()  # Pushes everything to the top

    def save_config(self):
        updated_data = {}
        for key, widget in self.widgets.items():
            if isinstance(widget, QCheckBox):
                updated_data[key] = widget.isChecked()
            elif isinstance(widget, QComboBox):
                updated_data[key] = widget.currentText()
            elif isinstance(widget, QLineEdit):
                updated_data[key] = widget.text()
            else:
                # Keep original value if widget type is not handled for saving
                updated_data[key] = self.config_data.get(key)

        try:
            # Save the file
            with open(self.config_path, 'w') as f:
                json.dump(updated_data, f, indent=4)
            self.config_data = updated_data

            # Run the script
            script_path = os.path.join(self.repo_dir, 'cli', 'load_configs.sh')
            if not os.path.exists(script_path):
                QMessageBox.warning(self, "Warning", "Configuration saved, but load_configs.sh not found. Please run it manually.")
                return

            try:
                # Launch the script in a new kitty terminal
                subprocess.Popen(['kitty', '-e', 'bash', script_path])
                QMessageBox.information(self, "Success", "Configuration saved. Reloading in a new terminal window.")
            except FileNotFoundError:
                QMessageBox.warning(self, "Terminal Not Found", "Configuration saved, but 'kitty' terminal was not found. Please run 'load_configs.sh' manually.")
            except Exception as e:
                QMessageBox.critical(self, "Launch Error", f"Configuration saved, but failed to open new terminal.\n\nError: {e}")

        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to save configuration: {e}")

    def reset_to_default(self):
        reply = QMessageBox.question(
            self,
            "Reset Configuration",
            "Are you sure you want to reset all settings to their default values?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No,
        )

        if reply == QMessageBox.StandardButton.Yes:
            self.load_config(from_defaults=True)
            QMessageBox.information(self, "Defaults Loaded", "Default settings have been loaded. Please click 'Save Changes' to apply them.")


def main():
    app = QApplication(sys.argv)
    ex = ConfigApp()
    ex.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
