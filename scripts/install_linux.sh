#!/bin/bash

# Exit on error
set -e

APP_NAME="muses"
APP_ID="com.advaitv.muses"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/128x128/apps"

echo "Building $APP_NAME for Linux..."
flutter build linux --release

echo "Installing to $INSTALL_DIR..."
# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

# Copy bundle
rm -rf "$INSTALL_DIR"
cp -r build/linux/x64/release/bundle "$INSTALL_DIR"

# Create symlink                                                                                                                                                        │
ln -sf "$INSTALL_DIR/$APP_NAME" "$BIN_DIR/$APP_NAME"

# Install Icon
# Assuming assets/muses_logo.png exists and is a good resolution
cp assets/muses_logo.png "$ICON_DIR/$APP_ID.png"

# Install Desktop File
DESKTOP_FILE="linux/$APP_ID.desktop"
INSTALLED_DESKTOP_FILE="$DESKTOP_DIR/$APP_ID.desktop"

# Copy desktop file and replace Exec and Icon paths
cp "$DESKTOP_FILE" "$INSTALLED_DESKTOP_FILE"

# Use sed to update the Exec and Icon lines.
# We use full path for Exec to be safe.
# We also set LD_LIBRARY_PATH to ensure the bundled libraries are found.
sed -i "s|^Exec=.*|Exec=env LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/$APP_NAME|g" "$INSTALLED_DESKTOP_FILE"
sed -i "s|^Icon=.*|Icon=$APP_ID|g" "$INSTALLED_DESKTOP_FILE"

echo "Updating desktop database..."
update-desktop-database "$DESKTOP_DIR" || echo "Warning: update-desktop-database not found or failed. You might need to log out and log back in."

echo "$APP_NAME installed successfully!"
echo "You can launch it by typing '$APP_NAME' in the terminal (if $BIN_DIR is in your PATH) or from your application menu."
