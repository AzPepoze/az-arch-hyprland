import sys
import subprocess
import os
import tempfile
import stat
from collections import defaultdict
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QPushButton,
    QListWidget,
    QListWidgetItem,
    QMessageBox,
    QTabWidget,
    QGroupBox,
    QGridLayout,
    QLabel,
)
from PyQt6.QtCore import Qt

# Add the script's directory to the Python path to find submodules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from installer_components.install_data import get_install_items
from installer_components.stylesheet import get_stylesheet


# -------------------------------------------------------
# Main Application Window
# -------------------------------------------------------
class InstallerApp(QWidget):
    def __init__(self):
        super().__init__()
        self.repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.installation_items = []
        self.all_list_widgets = []
        self.grid_columns = 2

        self.populate_install_items()
        self.init_ui()
        self._apply_stylesheet()  # Apply custom styles

    def init_ui(self):
        self.setWindowTitle("Az Arch Hyprland Installer - Launcher")
        self.setGeometry(100, 100, 850, 700)

        self._setup_main_layout()
        self._create_tip_label()
        self._create_tab_widget()
        self._create_action_buttons()
        self._create_launch_button()

        self.populate_tabs_and_groups()

    # -------------------------------------------------------
    # UI Creation Methods
    # -------------------------------------------------------
    def _setup_main_layout(self):
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(10, 10, 10, 10)
        self.main_layout.setSpacing(15)

    def _create_tab_widget(self):
        self.tab_widget = QTabWidget()
        self.main_layout.addWidget(self.tab_widget)

    def _create_action_buttons(self):
        selection_group_box = QGroupBox("Selection Actions")
        button_layout = QHBoxLayout(selection_group_box)
        button_layout.setSpacing(10)

        self.select_essential_btn = QPushButton("Select Essentials (PC)")
        self.select_essential_laptop_btn = QPushButton("Select Essentials (Laptop)")
        self.select_all_btn = QPushButton("Select All")
        self.deselect_all_btn = QPushButton("Deselect All")

        self.select_essential_btn.clicked.connect(self.select_essential)
        self.select_essential_laptop_btn.clicked.connect(self.select_essential_laptop)
        self.select_all_btn.clicked.connect(lambda: self._set_all_items_checked(True))
        self.deselect_all_btn.clicked.connect(
            lambda: self._set_all_items_checked(False)
        )

        button_layout.addWidget(self.select_essential_btn)
        button_layout.addWidget(self.select_essential_laptop_btn)
        button_layout.addStretch()
        button_layout.addWidget(self.deselect_all_btn)
        button_layout.addWidget(self.select_all_btn)

        self.main_layout.addWidget(selection_group_box)

    def _create_launch_button(self):
        self.launch_install_btn = QPushButton("Run Installation")
        # Removed objectName and height properties to revert to default button style
        self.launch_install_btn.clicked.connect(self.run_installation)
        self.main_layout.addWidget(self.launch_install_btn)

    def _create_tip_label(self):
        tip_label = QLabel("Tip: Hover over an option to see its description.")
        tip_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        tip_label.setStyleSheet("font-style: italic; color: #888;")  # Optional styling
        self.main_layout.addWidget(tip_label)

    def _apply_stylesheet(self):
        self.setStyleSheet(get_stylesheet())

    # -------------------------------------------------------
    # Data & UI Population
    # -------------------------------------------------------
    def populate_tabs_and_groups(self):
        tabs_data = defaultdict(lambda: defaultdict(list))
        current_tab_name = "Unknown"
        for item_data in self.installation_items:
            if item_data["type"] == "header":
                current_tab_name = item_data["text"].replace("---", "").strip()
            else:
                group_name = item_data.get("group", "General")
                tabs_data[current_tab_name][group_name].append(item_data)

        from PyQt6.QtWidgets import QScrollArea  # Import QScrollArea

        for tab_name, groups in tabs_data.items():
            tab_content_widget = QWidget()
            tab_main_layout = QVBoxLayout(
                tab_content_widget
            )  # Main layout for the tab content

            scroll_area = QScrollArea()
            scroll_area.setWidgetResizable(True)
            scroll_area.setHorizontalScrollBarPolicy(
                Qt.ScrollBarPolicy.ScrollBarAlwaysOff
            )  # Disable horizontal scrollbar

            scroll_content_widget = QWidget()
            tab_layout = QGridLayout(scroll_content_widget)
            tab_layout.setContentsMargins(15, 15, 15, 15)
            tab_layout.setSpacing(15)

            scroll_area.setWidget(scroll_content_widget)
            tab_main_layout.addWidget(
                scroll_area
            )  # Add scroll area to the tab's main layout

            current_row, current_col = 0, 0

            for group_name, items_in_group in sorted(groups.items()):
                group_box = QGroupBox(group_name)
                group_box_layout = QVBoxLayout(group_box)
                group_box_layout.setContentsMargins(10, 15, 10, 10)
                group_box_layout.setSpacing(0)

                list_widget = QListWidget()
                list_widget.setMinimumHeight(200)
                self.all_list_widgets.append(list_widget)

                for item_data in items_in_group:
                    list_item = QListWidgetItem()
                    list_item.setData(Qt.ItemDataRole.UserRole, item_data)

                    item_text = item_data["text"]
                    if item_data["type"] == "essential_laptop":
                        item_text += " (Laptop)"
                    list_item.setText(item_text)

                    if "description" in item_data:
                        list_item.setToolTip(item_data["description"])

                    list_item.setFlags(
                        list_item.flags() | Qt.ItemFlag.ItemIsUserCheckable
                    )
                    list_item.setCheckState(Qt.CheckState.Unchecked)
                    list_widget.addItem(list_item)

                group_box_layout.addWidget(list_widget)

                tab_layout.addWidget(group_box, current_row, current_col)

                current_col += 1
                if current_col >= self.grid_columns:
                    current_col = 0
                    current_row += 1

            tab_layout.setRowStretch(current_row + 1, 1)
            self.tab_widget.addTab(tab_content_widget, tab_name)

    def populate_install_items(self):
        self.installation_items = get_install_items(self.repo_dir)

    # -------------------------------------------------------
    # Core Logic & Event Handlers
    # -------------------------------------------------------
    def run_installation(self):
        commands_to_run = self._get_selected_commands()
        if not commands_to_run:
            QMessageBox.information(
                self, "No Selection", "No items were selected for installation."
            )
            return
        script_content = self._generate_install_script(commands_to_run)
        try:
            with tempfile.NamedTemporaryFile(
                mode="w+", delete=False, suffix=".sh", prefix="az-installer-"
            ) as temp_script:
                temp_script.write(script_content)
                script_path = temp_script.name
            os.chmod(script_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            subprocess.Popen(
                ["kitty", "--title", "Installation Process", "bash", script_path]
            )
        except FileNotFoundError:
            QMessageBox.critical(
                self,
                "Error",
                "Could not find 'kitty'. Please ensure it is installed and in your PATH.",
            )
        except Exception as e:
            QMessageBox.critical(
                self, "Error", f"Failed to launch installer script: {e}"
            )

    def _get_selected_commands(self):
        selected_funcs = set()
        for list_widget in self.all_list_widgets:
            for i in range(list_widget.count()):
                item = list_widget.item(i)
                if item.checkState() == Qt.CheckState.Checked:
                    item_data = item.data(Qt.ItemDataRole.UserRole)
                    if item_data and "func" in item_data:
                        selected_funcs.add(item_data["func"])

        ordered_commands = []
        for item_data in self.installation_items:
            if "func" in item_data and item_data["func"] in selected_funcs:
                ordered_commands.append(item_data["func"])
        return ordered_commands

    def _generate_install_script(self, commands):
        modules_dir = os.path.join(self.repo_dir, "scripts", "install_modules")

        # The new run_command function for the bash script
        run_command_func = """
run_command() {
    local command_to_run="$1"
    
    echo -e "\\n\\e[1;34m--- Running: ${command_to_run} ---\\e[0m"
    
    while true; do
        # Execute the command and capture output
        eval "${command_to_run}"
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            # Success
            echo -e "\\n\\e[1;32m--- Finished: ${command_to_run} ---\\e[0m"
            return 0
        else
            # Failure
            echo -e "\\n\\e[1;31m--- ERROR: Command \\"${command_to_run}\\" failed with exit code $exit_code. ---\\e[0m"
            read -p "      [R]etry, [I]gnore, or [A]bort? " choice
            case "$choice" in
                [rR])
                    echo -e "\n\e[1;33m--- Retrying... ---\e[0m"
                    continue
                    ;; 
                [iI])
                    echo -e "\n\e[1;33m--- Ignoring and continuing... ---\e[0m"
                    return 0 # Pretend it succeeded to continue the script
                    ;; 
                [aA])
                    echo -e "\n\e[1;31m--- Aborting installation. ---\e[0m"
                    exit 1
                    ;; 
                *)
                    echo -e "\n\e[1;33m--- Invalid option. Retrying by default. ---\e[0m"
                    continue
                    ;; 
            esac
        fi
    done
}
"""
        # Initial script setup. Note the removal of "set -e".
        script_lines = ["#!/bin/bash", f'export repo_dir="{self.repo_dir}"\n']
        script_lines.append(
            "trap 'echo; read -p \"--- Script finished. Press Enter to close terminal. ---\"' EXIT\n"
        )
        script_lines.append(run_command_func)

        # No sorting needed, commands are already ordered by _get_selected_commands

        for filename in sorted(os.listdir(modules_dir)):
            if filename.endswith(".sh"):
                script_lines.append(f"source {os.path.join(modules_dir, filename)}")

        for command in commands:
            # Wrap each command in the run_command function
            # Quote the command to handle spaces correctly.
            script_lines.append(f"run_command '{command}'")

        return "\n".join(script_lines)

    # -------------------------------------------------------
    # Selection Methods
    # -------------------------------------------------------
    def select_essential(self):
        self._set_all_items_checked(False)
        for list_widget in self.all_list_widgets:
            for i in range(list_widget.count()):
                item = list_widget.item(i)
                item_data = item.data(Qt.ItemDataRole.UserRole)
                if item_data and item_data["type"] == "essential":
                    item.setCheckState(Qt.CheckState.Checked)

    def select_essential_laptop(self):
        self._set_all_items_checked(False)
        for list_widget in self.all_list_widgets:
            for i in range(list_widget.count()):
                item = list_widget.item(i)
                item_data = item.data(Qt.ItemDataRole.UserRole)
                if item_data and item_data["type"] in ["essential", "essential_laptop"]:
                    item.setCheckState(Qt.CheckState.Checked)

    def _set_all_items_checked(self, is_checked):
        check_state = Qt.CheckState.Checked if is_checked else Qt.CheckState.Unchecked
        for list_widget in self.all_list_widgets:
            for i in range(list_widget.count()):
                item = list_widget.item(i)
                if item.flags() & Qt.ItemFlag.ItemIsUserCheckable:
                    item.setCheckState(check_state)


# -------------------------------------------------------
# Application Entry Point
# -------------------------------------------------------
def main():
    try:
        from PyQt6.QtWidgets import QApplication
    except ImportError:
        print("Error: PyQt6 is not installed.")
        print("Please install it using: pacman -S python-pyqt6")
        sys.exit(1)
    app = QApplication(sys.argv)
    ex = InstallerApp()
    ex.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
