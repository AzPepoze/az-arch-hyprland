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


#-------------------------------------------------------
# Main Application Window
#-------------------------------------------------------
class InstallerApp(QWidget):
    def __init__(self):
        super().__init__()
        self.repo_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
        self._create_tip_label()
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

    def _create_tip_label(self):
        tip_label = QLabel("Tip: Hover over an option to see its description.")
        tip_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        tip_label.setStyleSheet("font-style: italic; color: #888;") # Optional styling
        self.main_layout.addWidget(tip_label)

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

        from PyQt6.QtWidgets import QScrollArea # Import QScrollArea
        for tab_name, groups in tabs_data.items():
            tab_content_widget = QWidget()
            tab_main_layout = QVBoxLayout(tab_content_widget) # Main layout for the tab content

            scroll_area = QScrollArea()
            scroll_area.setWidgetResizable(True)
            scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff) # Disable horizontal scrollbar

            scroll_content_widget = QWidget()
            tab_layout = QGridLayout(scroll_content_widget)
            tab_layout.setContentsMargins(15, 15, 15, 15)
            tab_layout.setSpacing(15)

            scroll_area.setWidget(scroll_content_widget)
            tab_main_layout.addWidget(scroll_area) # Add scroll area to the tab's main layout

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
                    
                    if 'description' in item_data:
                        list_item.setToolTip(item_data['description'])
                    
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
            {'type': 'essential', 'text': 'Install Linux Headers', 'func': 'install_linux_headers', 'group': 'System Kernel', 'description': 'Installs essential Linux kernel headers for building modules and other system components.'},
            {'type': 'essential', 'text': 'Install systemd-oomd.service', 'func': 'install_systemd_oomd', 'group': 'System Services', 'description': 'Installs and enables systemd-oomd, a userspace OOM killer that can prevent system freezes under heavy memory pressure.'},
            {'type': 'essential', 'text': 'Install ananicy-cpp', 'func': 'install_ananicy_cpp', 'group': 'System Optimization', 'description': 'Installs ananicy-cpp, a C++ port of ananicy, which automatically adjusts process nice values and I/O priorities for better system responsiveness.'},
            {'type': 'essential', 'text': 'Install inotify-tools', 'func': 'install_inotify_tools', 'group': 'System Monitoring', 'description': 'Installs inotify-tools, a set of command-line programs for monitoring filesystem events.'},
            {'type': 'essential', 'text': 'Install Mission Center', 'func': 'install_mission_center', 'group': 'System Monitoring', 'description': 'Installs Mission Center, a modern and fast system monitor for Linux.'},
            {'type': 'essential_laptop', 'text': 'Install Power Options (TLP)', 'func': 'install_power_options', 'group': 'Power Management', 'description': 'Installs TLP, an advanced power management tool for Linux, optimized for laptops to save battery power.'},
            {'type': 'header', 'text': '--- Package Management ---'},
            {'type': 'essential', 'text': 'Install paru (AUR Helper)', 'func': 'install_paru', 'group': 'Package Managers', 'description': 'Installs paru, an AUR helper that simplifies installing and managing packages from the Arch User Repository.'},
            {'type': 'essential', 'text': 'Install Reflector and Enable Timer', 'func': 'install_reflector_and_enable_timer', 'group': 'System Optimization', 'description': 'Installs Reflector, a script to find the fastest Arch Linux mirror servers, and enables its systemd timer for automatic updates.'},
            {'type': 'essential', 'text': 'Install Flatpak', 'func': 'install_flatpak', 'group': 'Package Managers', 'description': 'Installs Flatpak, a universal packaging system for Linux applications, providing sandboxed environments.'},
            {'type': 'essential', 'text': 'Install FUSE', 'func': 'install_fuse', 'group': 'System Libraries', 'description': 'Installs FUSE (Filesystem in Userspace), allowing non-privileged users to create their own file systems.'},
            {'type': 'essential', 'text': 'Install npm', 'func': 'install_npm', 'group': 'Development Runtimes', 'description': 'Installs npm (Node Package Manager), a package manager for JavaScript.'},
            {'type': 'essential', 'text': 'Install pnpm', 'func': 'install_pnpm', 'group': 'Development Runtimes', 'description': 'Installs pnpm, a fast, disk-space efficient package manager for Node.js.'},
            {'type': 'essential', 'text': 'Install jq', 'func': 'install_jq', 'group': 'CLI Utilities', 'description': 'Installs jq, a lightweight and flexible command-line JSON processor.'},
            {'type': 'optional', 'text': 'Install Fisher', 'func': 'install_fisher', 'group': 'CLI Utilities', 'description': 'Installs Fisher, a plugin manager for the Fish shell.'},
            {'type': 'optional', 'text': 'Install Gemini CLI', 'func': 'install_gemini_cli', 'group': 'CLI Utilities', 'description': 'Installs the Google Gemini CLI for interacting with Gemini models.'},
            {'type': 'essential', 'text': 'Set up Git Credential Management', 'func': 'setup_git_credential_management', 'group': 'Git Credentials', 'description': 'Sets up Git Credential Manager to securely store and manage Git credentials.'},
                        {'type': 'header', 'text': '--- Desktop & Theming ---'},
            {'type': 'essential', 'text': "Install end-4's Hyprland Dots", 'func': 'install_end4_hyprland_dots', 'group': 'Hyprland Core', 'description': 'Installs the core Hyprland configuration files and dependencies from end-4.'},
            {'type': 'essential', 'text': 'Install xorg-xhost and set root access', 'func': 'install_xorg_xhost_and_xhost_rule', 'group': 'Hyprland Core', 'description': 'Installs xorg-xhost for X server access control and sets a rule to allow root to connect to the X server.'},
            {'type': 'special', 'text': 'Load all configurations (GPU, cursor, etc)', 'func': f'bash {self.repo_dir}/cli/load_configs.sh', 'group': 'Hyprland Configuration', 'description': 'Loads and applies various system configurations, including GPU settings, cursor themes, and other dotfiles.'},
            {'type': 'essential', 'text': 'Install and Run nwg-displays', 'func': 'install_nwg_displays', 'group': 'Hyprland Utilities', 'description': 'Installs and runs nwg-displays, a small utility for managing displays in Wayland compositors like Hyprland.'},
            {'type': 'essential', 'text': 'Install SDDM Astronaut Theme', 'func': 'install_sddm_theme', 'group': 'Login Manager (SDDM)', 'description': 'Installs the Astronaut theme for SDDM, the Simple Desktop Display Manager.'},
            {'type': 'essential', 'text': 'Install Catppuccin Theme for GRUB', 'func': 'select_and_install_catppuccin_grub_theme', 'group': 'Bootloader (GRUB)', 'description': "Installs the Catppuccin theme for GRUB, enhancing the bootloader's appearance."},
            {'type': 'essential', 'text': 'Adjust GRUB menu resolution', 'func': 'adjust_grub_menu', 'group': 'Bootloader (GRUB)', 'description': 'Adjusts the resolution of the GRUB boot menu for better display compatibility.'},
            {'type': 'essential', 'text': 'Enable os-prober for GRUB', 'func': 'enable_os_prober', 'group': 'Bootloader (GRUB)', 'description': 'Enables os-prober in GRUB to detect and list other operating systems installed on the machine.'},
            {'type': 'essential', 'text': 'Install Catppuccin Fish Theme', 'func': 'install_catppuccin_fish_theme', 'group': 'Shell (Fish)', 'description': 'Installs the Catppuccin theme for the Fish shell, providing a visually pleasing command-line experience.'},
            {'type': 'essential', 'text': 'Install Ulauncher', 'func': 'install_ulauncher', 'group': 'Application Launcher', 'description': 'Installs Ulauncher, a fast application launcher for Linux.'},
            {'type': 'essential', 'text': 'Install Ulauncher Catppuccin Theme', 'func': 'install_ulauncher_catppuccin_theme', 'group': 'Application Launcher', 'description': 'Installs the Catppuccin theme for Ulauncher.'},
            {'type': 'optional', 'text': 'Copy thai_fonts.css for Vesktop', 'func': 'copy_thai_fonts_css', 'group': 'Application Tweaks', 'description': 'Copies a custom CSS file to enable proper display of Thai fonts in Vesktop.'},
            {'type': 'header', 'text': '--- Applications ---'},
            {'type': 'optional', 'text': 'Install VS Code Insiders', 'func': 'install_vscode_insiders', 'group': 'Development Tools', 'description': 'Installs VS Code Insiders, the daily updated version of Visual Studio Code with the latest features.'},
            {'type': 'essential', 'text': 'Fix VSCode Insiders permissions', 'func': 'fix_vscode_permissions', 'group': 'Development Tools', 'description': 'Fixes permissions for VS Code Insiders to ensure proper functionality.'},
            {'type': 'essential', 'text': 'Install Vesktop', 'func': 'install_vesktop', 'group': 'Communication', 'description': 'Installs Vesktop, a custom Discord client with additional features and optimizations.'},
            {'type': 'essential', 'text': 'Set up Vesktop Activity Status', 'func': 'setup_vesktop_rpc', 'group': 'Communication', 'description': 'Sets up Rich Presence for Vesktop to display your current activity on Discord.'},
            {'type': 'essential', 'text': 'Install Steam', 'func': 'install_steam', 'group': 'Gaming', 'description': 'Installs Steam, the popular digital distribution platform for video games.'},
            {'type': 'essential', 'text': 'Install Pinta', 'func': 'install_pinta', 'group': 'Graphics & Media', 'description': 'Installs Pinta, a free, open-source drawing/editing program.'},
            {'type': 'essential', 'text': 'Install Gwenview', 'func': 'install_gwenview', 'group': 'Graphics & Media', 'description': 'Installs Gwenview, a fast and easy-to-use image viewer by KDE.'},
            {'type': 'essential', 'text': 'Install YouTube Music', 'func': 'install_youtube_music', 'group': 'Graphics & Media', 'description': 'Installs YouTube Music as a standalone application.'},
            {'type': 'optional', 'text': 'Install HandBrake', 'func': 'install_handbrake', 'group': 'Graphics & Media', 'description': 'Installs HandBrake, a free and open-source video transcoder.'},
            {'type': 'optional', 'text': 'Install EasyEffects', 'func': 'install_easyeffects', 'group': 'Audio', 'description': 'Installs EasyEffects, a PulseAudio/PipeWire application for applying audio effects.'},
            {'type': 'optional', 'text': 'Install n8n', 'func': 'install_n8n', 'group': 'Automation', 'description': 'Installs n8n, a workflow automation tool.'},
            {'type': 'optional', 'text': 'Install Microsoft Edge (Dev)', 'func': 'install_ms_edge', 'group': 'Web Browsers', 'description': 'Installs the Microsoft Edge (Dev) browser.'},
            {'type': 'optional', 'text': 'Install Zen Browser', 'func': 'install_zen_browser', 'group': 'Web Browsers', 'description': 'Installs Zen Browser, a privacy-focused web browser.'},
            {'type': 'essential', 'text': 'Install Switcheroo', 'func': 'install_switcheroo', 'group': 'General Utilities', 'description': 'Installs Switcheroo, a simple application switcher for Wayland.'},
            {'type': 'essential', 'text': 'Install BleachBit', 'func': 'install_bleachbit', 'group': 'System Cleanup', 'description': 'Installs BleachBit, a system cleaner to free up disk space and maintain privacy.'},
            {'type': 'essential', 'text': 'Install QDirStat', 'func': 'install_qdirstat', 'group': 'Disk Usage', 'description': 'Installs QDirStat, a graphical disk usage display.'},
            {'type': 'essential', 'text': 'Install Flatseal', 'func': 'install_flatseal', 'group': 'Flatpak Management', 'description': 'Installs Flatseal, a graphical utility to review and modify permissions for your Flatpak applications.'},
            {'type': 'optional', 'text': 'Install rclone', 'func': 'install_rclone', 'group': 'Cloud Storage', 'description': 'Installs rclone, a command-line program to manage files on cloud storage.'},
            {'type': 'optional', 'text': 'Setup Google Drive with rclone', 'func': 'setup_rclone_gdrive', 'group': 'Cloud Storage', 'description': 'Sets up Google Drive integration with rclone for cloud storage synchronization.'},
            {'type': 'optional', 'text': 'Install Waydroid', 'func': 'install_waydroid', 'group': 'Android Emulation', 'description': 'Installs Waydroid, a container-based approach to boot a full Android system on a Linux device.'},
            {'type': 'optional', 'text': 'Install Waydroid Helper', 'func': 'install_waydroid_helper', 'group': 'Android Emulation', 'description': 'Installs Waydroid Helper, a utility to simplify Waydroid management.'},
            {'type': 'essential', 'text': 'Install Virtualization (libvirt, virt-manager, QEMU)', 'func': 'install_virt_packages', 'group': 'Virtualization', 'description': 'Installs essential virtualization tools including libvirt, virt-manager, QEMU, dnsmasq, and dmidecode, and enables the libvirtd service.'},
            {'type': 'header', 'text': '--- Hardware & Peripherals ---'},
            {'type': 'essential', 'text': 'Install v4l2loopback (for Droidcam/OBS)', 'func': 'install_v4l2loopback', 'group': 'Drivers & Modules', 'description': 'Installs v4l2loopback, a kernel module that creates virtual video devices, useful for Droidcam or OBS.'},
            {'type': 'optional', 'text': 'Install Droidcam', 'func': 'install_droidcam', 'group': 'Webcam', 'description': 'Installs Droidcam, allowing you to use your Android phone as a webcam.'},
            {'type': 'optional', 'text': 'Install MX002 Tablet Driver', 'func': 'install_mx002_driver', 'group': 'Drivers & Modules', 'description': 'Installs the necessary drivers for MX002 series drawing tablets.'},
            {'type': 'essential', 'text': 'Install CoolerControl', 'func': 'install_coolercontrol', 'group': 'Hardware Control', 'description': 'Installs CoolerControl, a GUI application for controlling fan speeds and RGB lighting on various liquid coolers.'},
            {'type': 'optional', 'text': 'Install Linux Wallpaper Engine', 'func': 'install_wallpaper_engine', 'group': 'Wallpaper Engine', 'description': 'Installs Linux Wallpaper Engine, a port of the popular Wallpaper Engine for Linux.'},
            {'type': 'optional', 'text': 'Install LWE GUI (Manual)', 'func': 'install_wallpaper_engine_gui_manual', 'group': 'Wallpaper Engine', 'description': 'Provides instructions for manually installing the GUI for Linux Wallpaper Engine.'},
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
        script_lines = ["#!/bin/bash", "set -e", f"export repo_dir=\"{self.repo_dir}\"\n"]
        script_lines.append("trap 'echo; read -p \"--- Script finished. Press Enter to close terminal. --- \"' EXIT\n")
        for filename in sorted(os.listdir(modules_dir)):
            if filename.endswith(".sh"):
                script_lines.append(f"source {os.path.join(modules_dir, filename)}")
        for command in commands:
            script_lines.append(f"echo -e '\n\e[1;34m--- Running: {command} ---\e[0m'")
            script_lines.append(f"{command}")
            script_lines.append(f"echo -e '\n\e[1;32m--- Finished: {command} ---\\e[0m'")
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