#!/bin/bash

# SDDM Material 3 Theme Installer

if [ "$EUID" -ne 0 ]; then
  echo "Please run this installer as root (with sudo)."
  exit 1
fi

THEME_NAME="sddm-material"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
FONT_DIR="/usr/share/fonts/TTF"

# Dependency check
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 is not installed. Please install it to extract colors."
    exit 1
fi

if ! python3 -c "import PIL" &> /dev/null; then
    echo "❌ Error: python3-pillow is not installed. Please install it (e.g., sudo apt install python3-pillow or pip install Pillow) to extract colors."
    exit 1
fi

# 1. Ask for wallpaper
echo -e "\n🎨 Welcome to the SDDM Material Installation."

if [ -n "$1" ]; then
    WALLPAPER_PATH="$1"
    echo "Using provided wallpaper path: $WALLPAPER_PATH"
else
    read -p "Enter the absolute path to your chosen wallpaper image (e.g. /home/user/Pictures/wall.jpg): " WALLPAPER_PATH
fi

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "❌ Error: Wallpaper file not found at $WALLPAPER_PATH"
    exit 1
fi

# 1.5 Ask for profile picture
if [ -n "$2" ]; then
    PFP_PATH="$2"
    echo "Using provided profile picture path: $PFP_PATH"
else
    read -p "Enter the absolute path to your profile picture (optional, press Enter to skip): " PFP_PATH
fi

if [ -n "$PFP_PATH" ] && [ -f "$PFP_PATH" ]; then
    TARGET_USER="${SUDO_USER:-$USER}"
    if [ "$TARGET_USER" == "root" ]; then
        read -p "Enter the username this profile picture is for: " TARGET_USER
    fi
    echo "⏳ Installing profile picture for $TARGET_USER..."
    mkdir -p "/usr/share/sddm/faces"
    cp "$PFP_PATH" "/usr/share/sddm/faces/$TARGET_USER.face.icon"
    chmod 644 "/usr/share/sddm/faces/$TARGET_USER.face.icon"
elif [ -n "$PFP_PATH" ]; then
    echo "⚠️ Warning: Profile picture file not found at $PFP_PATH. Skipping."
fi

# 2. Extract Colors
echo "⏳ Extracting dynamic Material 3 colors from wallpaper..."
# Ensure Python dependencies are available for root if run via sudo
if [ -n "$SUDO_USER" ]; then
    sudo -u "$SUDO_USER" python3 update_theme_colors.py "$WALLPAPER_PATH"
else
    python3 update_theme_colors.py "$WALLPAPER_PATH"
fi

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

# Define the explicit list of files and directories to copy
FILES_TO_COPY=(
    "Main.qml"
    "metadata.desktop"
    "theme.conf"
    "backgrounds"
    "components"
    "fonts"
)

for item in "${FILES_TO_COPY[@]}"; do
    if [ -e "$item" ]; then
        cp -r "$item" "$THEME_DIR/"
    fi
done

# Make sure permissions are correct
chmod -R 755 "$THEME_DIR"

# 5. Apply Theme to SDDM configuration
# Note: Usually configured in /etc/sddm.conf or /etc/sddm.conf.d/
SDDM_CONF_DIR="/etc/sddm.conf.d"
mkdir -p "$SDDM_CONF_DIR"

echo -e "[Theme]\nCurrent=$THEME_NAME" > "$SDDM_CONF_DIR/99-material.conf"

echo -e "\n✅ Installation Complete!"
echo "Your new Material 3 SDDM theme is active."
echo "You can test it by running: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"

