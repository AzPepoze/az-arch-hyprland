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
)
from PyQt6.QtCore import Qt


#-------------------------------------------------------
# Main Application Window
#-------------------------------------------------------
class InstallerApp(QWidget):
    def __init__(self):
        super().__init__()
        self.repo_dir = os.path.dirname(os.path.abspath(__file__))
        self.installation_items = []
        self.all_list_widgets = []
        self.grid_columns = 2

        self.populate_install_items()
        self.init_ui()
        self._apply_stylesheet() # Apply custom styles

    def init_ui(self):
        self.setWindowTitle("Az Arch Hyprland Installer - Launcher")
        self.setGeometry(100, 100, 850, 700)

        self._setup_main_layout()
        self._create_tab_widget()
        self._create_action_buttons()
        self._create_launch_button()

        self.populate_tabs_and_groups()

    #-------------------------------------------------------
    # UI Creation Methods
    #-------------------------------------------------------
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

        self.select_essential_btn = QPushButton("Select Essentials")
        self.select_essential_laptop_btn = QPushButton("Select Essentials (Laptop)")
        self.select_all_btn = QPushButton("Select All")
        self.deselect_all_btn = QPushButton("Deselect All")

        self.select_essential_btn.clicked.connect(self.select_essential)
        self.select_essential_laptop_btn.clicked.connect(self.select_essential_laptop)
        self.select_all_btn.clicked.connect(lambda: self._set_all_items_checked(True))
        self.deselect_all_btn.clicked.connect(lambda: self._set_all_items_checked(False))

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

    def _apply_stylesheet(self):
        # Styles are now only applied to Tabs and GroupBoxes
        stylesheet = """
            /* --- GroupBox Container --- */
            QGroupBox {
                border: 1px solid #45475a; /* Surface1 */
                border-radius: 8px;
                margin-top: 10px;
                padding: 10px;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                subcontrol-position: top center;
                padding: 0 10px;
                font-weight: bold;
            }

            QListWidget {
                background-color: transparent; /* Make list background same as groupbox */
            }
        """
        self.setStyleSheet(stylesheet)

    #-------------------------------------------------------
    # Data & UI Population
    #-------------------------------------------------------
    def populate_tabs_and_groups(self):
        tabs_data = defaultdict(lambda: defaultdict(list))
        current_tab_name = "Unknown"
        for item_data in self.installation_items:
            if item_data["type"] == "header":
                current_tab_name = item_data["text"].replace("---", "").strip()
            else:
                group_name = item_data.get("group", "General")
                tabs_data[current_tab_name][group_name].append(item_data)

        for tab_name, groups in tabs_data.items():
            tab_content_widget = QWidget()
            tab_layout = QGridLayout(tab_content_widget)
            tab_layout.setContentsMargins(15, 15, 15, 15)
            tab_layout.setSpacing(15)

            current_row, current_col = 0, 0

            for group_name, items_in_group in sorted(groups.items()):
                group_box = QGroupBox(group_name)
                group_box_layout = QVBoxLayout(group_box)
                group_box_layout.setContentsMargins(10, 15, 10, 10)
                group_box_layout.setSpacing(0)

                list_widget = QListWidget()
                self.all_list_widgets.append(list_widget)

                for item_data in items_in_group:
                    list_item = QListWidgetItem()
                    list_item.setData(Qt.ItemDataRole.UserRole, item_data)
                    
                    item_text = item_data['text']
                    if item_data["type"] == "essential_laptop":
                         item_text += " (Laptop)"
                    list_item.setText(item_text)
                    
                    list_item.setFlags(list_item.flags() | Qt.ItemFlag.ItemIsUserCheckable)
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
        # Data remains unchanged
        self.installation_items = [
            {'type': 'header', 'text': '--- Core System ---'},
            {'type': 'essential', 'text': 'Install Linux Headers', 'func': 'install_linux_headers', 'group': 'System Kernel'},
            {'type': 'essential', 'text': 'Install systemd-oomd.service', 'func': 'install_systemd_oomd', 'group': 'System Services'},
            {'type': 'essential', 'text': 'Install ananicy-cpp', 'func': 'install_ananicy_cpp', 'group': 'System Optimization'},
            {'type': 'essential', 'text': 'Install inotify-tools', 'func': 'install_inotify_tools', 'group': 'System Monitoring'},
            {'type': 'essential', 'text': 'Install Mission Center', 'func': 'install_mission_center', 'group': 'System Monitoring'},
            {'type': 'essential_laptop', 'text': 'Install Power Options (TLP)', 'func': 'install_power_options', 'group': 'Power Management'},
            {'type': 'header', 'text': '--- Package Management ---'},
            {'type': 'essential', 'text': 'Install paru (AUR Helper)', 'func': 'install_paru', 'group': 'Package Managers'},
            {'type': 'essential', 'text': 'Install Flatpak', 'func': 'install_flatpak', 'group': 'Package Managers'},
            {'type': 'essential', 'text': 'Install FUSE', 'func': 'install_fuse', 'group': 'System Libraries'},
            {'type': 'essential', 'text': 'Install npm', 'func': 'install_npm', 'group': 'Development Runtimes'},
            {'type': 'essential', 'text': 'Install pnpm', 'func': 'install_pnpm', 'group': 'Development Runtimes'},
            {'type': 'essential', 'text': 'Install jq', 'func': 'install_jq', 'group': 'CLI Utilities'},
            {'type': 'optional', 'text': 'Install Fisher', 'func': 'install_fisher', 'group': 'CLI Utilities'},
            {'type': 'optional', 'text': 'Install Gemini CLI', 'func': 'install_gemini_cli', 'group': 'CLI Utilities'},
            {'type': 'header', 'text': '--- Desktop & Theming ---'},
            {'type': 'essential', 'text': "Install end-4's Hyprland Dots", 'func': 'install_end4_hyprland_dots', 'group': 'Hyprland Core'},
            {'type': 'special', 'text': 'Load all configurations (GPU, cursor, etc)', 'func': f'bash {self.repo_dir}/load_configs.sh', 'group': 'Hyprland Configuration'},
            {'type': 'essential', 'text': 'Install and Run nwg-displays', 'func': 'install_nwg_displays', 'group': 'Hyprland Utilities'},
            {'type': 'essential', 'text': 'Install SDDM Astronaut Theme', 'func': 'install_sddm_theme', 'group': 'Login Manager (SDDM)'},
            {'type': 'essential', 'text': 'Install Catppuccin Theme for GRUB', 'func': 'select_and_install_catppuccin_grub_theme', 'group': 'Bootloader (GRUB)'},
            {'type': 'essential', 'text': 'Adjust GRUB menu resolution', 'func': 'adjust_grub_menu', 'group': 'Bootloader (GRUB)'},
            {'type': 'essential', 'text': 'Enable os-prober for GRUB', 'func': 'enable_os_prober', 'group': 'Bootloader (GRUB)'},
            {'type': 'essential', 'text': 'Install Catppuccin Fish Theme', 'func': 'install_catppuccin_fish_theme', 'group': 'Shell (Fish)'},
            {'type': 'essential', 'text': 'Install Ulauncher', 'func': 'install_ulauncher', 'group': 'Application Launcher'},
            {'type': 'essential', 'text': 'Install Ulauncher Catppuccin Theme', 'func': 'install_ulauncher_catppuccin_theme', 'group': 'Application Launcher'},
            {'type': 'optional', 'text': 'Copy thai_fonts.css for Vesktop', 'func': 'copy_thai_fonts_css', 'group': 'Application Tweaks'},
            {'type': 'header', 'text': '--- Applications ---'},
            {'type': 'optional', 'text': 'Install VS Code Insiders', 'func': 'install_vscode_insiders', 'group': 'Development Tools'},
            {'type': 'essential', 'text': 'Fix VSCode Insiders permissions', 'func': 'fix_vscode_permissions', 'group': 'Development Tools'},
            {'type': 'essential', 'text': 'Install Vesktop', 'func': 'install_vesktop', 'group': 'Communication'},
            {'type': 'essential', 'text': 'Set up Vesktop Activity Status', 'func': 'setup_vesktop_rpc', 'group': 'Communication'},
            {'type': 'essential', 'text': 'Install Steam', 'func': 'install_steam', 'group': 'Gaming'},
            {'type': 'essential', 'text': 'Install Pinta', 'func': 'install_pinta', 'group': 'Graphics & Media'},
            {'type': 'essential', 'text': 'Install Gwenview', 'func': 'install_gwenview', 'group': 'Graphics & Media'},
            {'type': 'essential', 'text': 'Install YouTube Music', 'func': 'install_youtube_music', 'group': 'Graphics & Media'},
            {'type': 'optional', 'text': 'Install HandBrake', 'func': 'install_handbrake', 'group': 'Graphics & Media'},
            {'type': 'optional', 'text': 'Install EasyEffects', 'func': 'install_easyeffects', 'group': 'Audio'},
            {'type': 'optional', 'text': 'Install Microsoft Edge (Dev)', 'func': 'install_ms_edge', 'group': 'Web Browsers'},
            {'type': 'optional', 'text': 'Install Zen Browser', 'func': 'install_zen_browser', 'group': 'Web Browsers'},
            {'type': 'essential', 'text': 'Install Switcheroo', 'func': 'install_switcheroo', 'group': 'General Utilities'},
            {'type': 'essential', 'text': 'Install BleachBit', 'func': 'install_bleachbit', 'group': 'System Cleanup'},
            {'type': 'essential', 'text': 'Install QDirStat', 'func': 'install_qdirstat', 'group': 'Disk Usage'},
            {'type': 'essential', 'text': 'Install Flatseal', 'func': 'install_flatseal', 'group': 'Flatpak Management'},
            {'type': 'optional', 'text': 'Install rclone', 'func': 'install_rclone', 'group': 'Cloud Storage'},
            {'type': 'optional', 'text': 'Setup Google Drive with rclone', 'func': 'setup_rclone_gdrive', 'group': 'Cloud Storage'},
            {'type': 'header', 'text': '--- Hardware & Peripherals ---'},
            {'type': 'essential', 'text': 'Install v4l2loopback (for Droidcam/OBS)', 'func': 'install_v4l2loopback', 'group': 'Drivers & Modules'},
            {'type': 'optional', 'text': 'Install Droidcam', 'func': 'install_droidcam', 'group': 'Webcam'},
            {'type': 'optional', 'text': 'Install MX002 Tablet Driver', 'func': 'install_mx002_driver', 'group': 'Drivers & Modules'},
            {'type': 'essential', 'text': 'Install CoolerControl', 'func': 'install_coolercontrol', 'group': 'Hardware Control'},
            {'type': 'optional', 'text': 'Install Linux Wallpaper Engine', 'func': 'install_wallpaper_engine', 'group': 'Wallpaper Engine'},
            {'type': 'optional', 'text': 'Install LWE GUI (Manual)', 'func': 'install_wallpaper_engine_gui_manual', 'group': 'Wallpaper Engine'},
        ]

    #-------------------------------------------------------
    # Core Logic & Event Handlers
    #-------------------------------------------------------
    def run_installation(self):
        commands_to_run = self._get_selected_commands()
        if not commands_to_run:
            QMessageBox.information(self, "No Selection", "No items were selected for installation.")
            return
        script_content = self._generate_install_script(commands_to_run)
        try:
            with tempfile.NamedTemporaryFile(mode='w+', delete=False, suffix='.sh', prefix='az-installer-') as temp_script:
                temp_script.write(script_content)
                script_path = temp_script.name
            os.chmod(script_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)
            subprocess.Popen(["kitty", "--title", "Installation Process", "bash", script_path])
        except FileNotFoundError:
            QMessageBox.critical(self, "Error", "Could not find 'kitty'. Please ensure it is installed and in your PATH.")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to launch installer script: {e}")

    def _get_selected_commands(self):
        commands = []
        for list_widget in self.all_list_widgets:
            for i in range(list_widget.count()):
                item = list_widget.item(i)
                if item.checkState() == Qt.CheckState.Checked:
                    item_data = item.data(Qt.ItemDataRole.UserRole)
                    if item_data:
                        commands.append(item_data["func"])
        return commands
    
    def _generate_install_script(self, commands):
        modules_dir = os.path.join(self.repo_dir, "scripts", "install_modules")
        script_lines = ["#!/bin/bash", "set -e\n", f"export repo_dir=\"{self.repo_dir}\"\n"]
        for filename in sorted(os.listdir(modules_dir)):
            if filename.endswith(".sh"):
                script_lines.append(f"source {os.path.join(modules_dir, filename)}")
        script_lines.append("\n# Ensures terminal stays open after script finishes or fails")
        script_lines.append("trap 'echo; read -p \"--- Script finished. Press Enter to close terminal. --- \"' EXIT\n")
        for command in commands:
            script_lines.append(f"echo -e '\\n\\e[1;34m--- Running: {command} ---\\e[0m'")
            script_lines.append(f"{command}")
        return "\n".join(script_lines)

    #-------------------------------------------------------
    # Selection Methods
    #-------------------------------------------------------
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

#-------------------------------------------------------
# Application Entry Point
#-------------------------------------------------------
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