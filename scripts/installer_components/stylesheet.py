def get_stylesheet():
    """Returns the Catppuccin Macchiato stylesheet for the application."""
    return """
        QWidget {
            background-color: #1E1E2E; /* Base */
            color: #CDD6F4; /* Text */
        }

        /* --- QTabWidget --- */
        QTabWidget::pane {
            border: 1px solid #313244; /* Surface0 */
            background-color: #181825; /* Mantle */
            border-radius: 8px;
        }

        QTabBar::tab {
            background: #313244; /* Surface0 */
            color: #CDD6F4; /* Text */
            padding: 8px 15px;
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
            margin-right: 2px;
        }

        QTabBar::tab:selected {
            background: #181825; /* Mantle */
            border-top: 2px solid #89B4FA; /* Blue */
            font-weight: bold;
        }

        QTabBar::tab:hover {
            background: #45475A; /* Surface1 */
        }

        /* --- QGroupBox Container --- */
        QGroupBox {
            border: 1px solid #45475A; /* Surface1 */
            border-radius: 8px;
            margin-top: 10px;
            padding: 10px;
            background-color: #181825; /* Mantle */
        }
        QGroupBox::title {
            subcontrol-origin: margin;
            subcontrol-position: top center;
            padding: 0 10px;
            font-weight: bold;
            color: #89B4FA; /* Blue */
        }

        /* --- QListWidget --- */
        QListWidget {
            background-color: transparent; /* Inherit from GroupBox */
            border: none;
        }

        QListWidget::item {
            padding: 5px;
        }

        QListWidget::item:hover {
            background-color: #313244; /* Surface0 */
            border-radius: 4px;
        }

        QListWidget::item:selected {
            background-color: #585B70; /* Surface2 */
            color: #CDD6F4; /* Text */
            border-radius: 4px;
        }

        QListWidget::indicator {
            width: 16px;
            height: 16px;
            border-radius: 4px;
        }

        QListWidget::indicator:unchecked {
            background-color: #45475A; /* Surface1 */
            border: 1px solid #6C7086; /* Overlay0 */
        }

        QListWidget::indicator:checked {
            background-color: #A6E3A1; /* Green */
            border: 1px solid #A6E3A1; /* Green */
        }

        /* --- QPushButton --- */
        QPushButton {
            background-color: #89B4FA; /* Blue */
            color: #1E1E2E; /* Base */
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            font-weight: bold;
        }

        QPushButton:hover {
            background-color: #74C7EC; /* Sapphire */
        }

        QPushButton:pressed {
            background-color: #6C7086; /* Overlay0 */
        }

        /* --- QLabel (for tip) --- */
        QLabel {
            color: #A6ADC8; /* Subtext0 */
            font-style: italic;
        }
    """