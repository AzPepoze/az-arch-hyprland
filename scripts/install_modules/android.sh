#-------------------------------------------------------
# Android Emulation
#-------------------------------------------------------
install_waydroid() {
    echo "Installing Waydroid..."
    paru -S --noconfirm waydroid
    echo "If you experience dragging issues in Waydroid, try running: waydroid prop set persist.waydroid.fake_touch '*.*' or use waydroid-helper to configure it."
}

install_waydroid_helper() {
    echo "Installing Waydroid Helper..."
    paru -S --noconfirm waydroid-helper
}
