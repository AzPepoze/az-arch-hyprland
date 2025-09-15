#!/bin/bash

#-------------------------------------------------------
# Group: Theming & Customization
#-------------------------------------------------------

install_wallpaper_engine() {
     install_paru_package "linux-wallpaperengine-git" "Wallpaper Engine"
}

install_wallpaper_engine_gui_manual() {
     echo "Starting manual installation of Linux Wallpaper Engine GUI..."
     echo "Installing build dependencies (base-devel, curl)..."
     sudo pacman -S --needed base-devel curl --noconfirm

     local build_dir="$HOME/linux-wallpaperengine-gui-build"
     local pkgbuild_url="https://raw.githubusercontent.com/AzPepoze/linux-wallpaperengine-gui/main/installer/PKGBUILD"

     echo "Creating temporary build directory: $build_dir"
     mkdir -p "$build_dir"

     local build_status=1
     (
          cd "$build_dir" || exit 1

          echo "Downloading PKGBUILD file..."
          if ! curl -O "$pkgbuild_url"; then
               _log ERROR "Failed to download PKGBUild from $pkgbuild_url"
               exit 1
          fi

          echo "Building and installing the package with makepkg..."
          makepkg -si --noconfirm

     )
     build_status=$?

     if [ $build_status -ne 0 ]; then
          _log ERROR "Build or installation failed with status $build_status."
     else
          _log SUCCESS "Linux Wallpaper Engine GUI installation completed successfully."
     fi

     echo "Cleaning up the build directory..."
     rm -rf "$build_dir"

     if [ $build_status -eq 0 ] && command -v pnpm &>/dev/null; then
          if ask_yes_no "The build may have installed 'pnpm' as a dependency. Do you want to remove it now?"; then
               echo "Removing pnpm..."
               sudo pacman -Rns --noconfirm pnpm
               echo "'pnpm' has been removed."
          fi
     fi
}

install_sddm_theme() {
     echo "Installing SDDM Astronaut Theme..."
     sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
     echo "SDDM Astronaut Theme installation attempted."
}

#-------------------------------------------------------
# Catppuccin Fish Theme Installation
#-------------------------------------------------------
install_catppuccin_fish_theme() {
    _log INFO "Installing Catppuccin theme for fish shell..."

    # Ensure fisher is available in the current script context
    if ! fish -c "type fisher >/dev/null 2>&1"; then
        _log WARN "Fisher command not found, attempting to source it for current session..."
        if [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
            # It seems we are in a bash script, so we can't source fish functions directly.
            # The call needs to be wrapped in a fish subshell.
            _log INFO "Fisher sourced successfully."
        else
            _log ERROR "Could not find fisher.fish to source. Please install Fisher first."
            return 1
        fi
    fi

    fish -c "fisher install catppuccin/fish"
    fish -c "fish_config theme save 'Catppuccin Mocha'"
    _log SUCCESS "Catppuccin Mocha theme installed and set for fish shell."
}

#-------------------------------------------------------
# Cursor Installation
#-------------------------------------------------------
install_cursors() {

    echo "Starting Cursor Theme Installation..."

    if [ ! -d "$BUILT_THEMES_DIR" ] || [ -z "$(ls -A "$BUILT_THEMES_DIR")" ]; then
        _log ERROR "Built cursor themes not found in '$BUILT_THEMES_DIR'."
        echo "Please run the './build_cursors.sh' script from the project root first."
        return 1 # Use return instead of exit for functions called by main script
    fi

    # Create a list of available themes from the directory names
    mapfile -t themes < <(find "$BUILT_THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    if [ ${#themes[@]} -eq 0 ]; then
        _log ERROR "No themes found in '$BUILT_THEMES_DIR'."
        return 1
    fi

    themes+=("Exit")

    # Display the menu
    echo "Select the cursor theme to install:"
    select theme_name in "${themes[@]}"; do
        case "$theme_name" in
            "Exit")
                echo "Exiting without installation."
                return 0
                ;;
            *)
                # Check if the selected option is valid
                if [[ " ${themes[*]} " =~ " ${theme_name} " ]]; then
                    echo "Installing theme: $theme_name"

                    # Ensure destination directory exists
                    mkdir -p "$USER_ICON_DIR"
                    echo "Ensured icon directory exists at '$USER_ICON_DIR'"

                    # Copy the theme files
                    cp -r "$BUILT_THEMES_DIR/$theme_name" "$USER_ICON_DIR/"
                    _log SUCCESS "Copied '$theme_name' to '$USER_ICON_DIR'"

                    # Update config.json
                    jq --arg theme "$theme_name" '.cursor.theme = $theme' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                    _log SUCCESS "Updated cursor theme in config file."

                    break
                else
                    _log ERROR "Invalid option '$REPLY'. Please try again."
                fi
                ;;
        esac
    done
}

#-------------------------------------------------------
# Font Theming
#-------------------------------------------------------
copy_thai_fonts_css() {
        local source_file="$repo_dir/settings/thai_fonts.css"
    local dest_file="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css"
    local dest_dir

    dest_dir=$(dirname "$dest_file")

    echo "Copying Thai fonts CSS for Vesktop..."

    if [ ! -f "$source_file" ]; then
        _log ERROR "Source file not found at $source_file"
        return 1
    fi

    echo "Ensuring destination directory exists: $dest_dir"
    mkdir -p "$dest_dir"

    cp -v "$source_file" "$dest_file"
    _log SUCCESS "Successfully copied thai_fonts.css to the Vesktop directory."
}

#-------------------------------------------------------
# Qt5 Theming
#-------------------------------------------------------
install_qt5ct() {
    install_paru_package "qt5ct" "Qt5 Configuration Tool"
}