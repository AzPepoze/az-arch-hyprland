# az-arch-hyprland Dotfiles

This repository contains my personal dotfiles for Arch Linux, heavily based on [end-4&#39;s dotfiles](https://github.com/end-4/dots-hyprland), and configured for a personalized development and desktop experience with the Hyprland window manager (for me specifically).

The setup is designed to be automated, allowing for a quick and easy installation of a complete environment and program on a new system.

## ✨ Features

- **Automated Setup:** Scripts to install [end-4&#39;s dotfiles](https://github.com/end-4/dots-hyprland), essential applications, command-line tools, and system services.
- **Additional Utility Scripts:** A collection of helper scripts for managing the system, handling keybinds, and syncing files.
- **Cursor** Custom cursor.

## 🚀 Installation

### Clone the repository

```bash
cd ~
git clone https://github.com/AzPepoze/az-arch-hyprland.git
```

### Run the script

```bash
cd ~/az-arch-hyprland
bash install.sh
```

## 🔄 Update

To update your system, run the following command:

```bash
cd ~/az-arch-hyprland
bash update.sh --auto
```

## 🎨 Customization

To override default configurations, create a `dots-custom` directory. Files inside `dots-custom` will overwrite the corresponding files in the `dots` directory if they have the same path.

This lets you keep your personal tweaks separate from the main configuration, making updates easier.

**Example:** To use a custom Kitty config:

1. Create your custom config file at `dots-custom/config/kitty/kitty.conf`.
   - You can copy the original from `dots/config/kitty/kitty.conf` as a starting point.
2. Edit your new file.

To apply your change.

```bash
bash cli/load_configs.sh
```

or

```bash
bash update.sh --auto
```

## 🙏 Acknowledgements

The foundation of this setup, especially the Hyprland configuration and overall structure, is heavily inspired by and built upon the excellent work from [end-4&#39;s dotfiles](https://github.com/end-4/dots-hyprland).
