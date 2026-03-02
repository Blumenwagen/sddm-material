#!/bin/bash

# SDDM Material 3 Theme Installer

if [ "$EUID" -ne 0 ]; then
  echo "Please run this installer as root (with sudo)."
  exit 1
fi

THEME_NAME="sddm-material"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
FONT_DIR="/usr/share/fonts/TTF"

# 1. Ask for wallpaper
echo -e "\n🎨 Welcome to the SDDM Material Installation."
read -p "Enter the absolute path to your chosen wallpaper image (e.g. /home/user/Pictures/wall.jpg): " WALLPAPER_PATH

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "❌ Error: Wallpaper file not found at $WALLPAPER_PATH"
    exit 1
fi

# 2. Extract Colors
echo "⏳ Extracting dynamic Material 3 colors from wallpaper..."
# Ensure Python dependencies are available for root if run via sudo
sudo -u "$SUDO_USER" python3 update_theme_colors.py "$WALLPAPER_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Error: Color extraction failed."
    exit 1
fi

# 3. Install Fonts
echo "⏳ Installing 'Unique' fonts globally for SDDM..."
mkdir -p "$FONT_DIR"
cp -r fonts/Unique_*.otf "$FONT_DIR/"
fc-cache -f "$FONT_DIR"

# 4. Install Theme
echo "⏳ Copying theme files to $THEME_DIR..."
mkdir -p "$THEME_DIR"
cp -r ./* "$THEME_DIR/"

# Make sure permissions are correct
chmod -R 755 "$THEME_DIR"

# 5. Apply Theme to SDDM configuration
# Note: Usually configured in /etc/sddm.conf or /etc/sddm.conf.d/
SDDM_CONF_DIR="/etc/sddm.conf.d"
mkdir -p "$SDDM_CONF_DIR"

echo -e "[Theme]\nCurrent=$THEME_NAME" > "$SDDM_CONF_DIR/99-material.conf"

echo "\n✅ Installation Complete!"
echo "Your new Material 3 SDDM theme is active."
echo "You can test it by running: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
