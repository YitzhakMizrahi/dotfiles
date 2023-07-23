#!/bin/bash

# Name of the font passed as argument
FONT_NAME=$1

# Ensure the font name is provided
if [[ -z "$FONT_NAME" ]]; then
    echo "Please provide the font name you would like to install as an argument."
    exit 1
fi

# Installing required packages
sudo apt install -y wget fontconfig

# Downloading and installing the font
wget -P ~/.local/share/fonts "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"
cd ~/.local/share/fonts
unzip "${FONT_NAME}.zip"
rm *Windows*
rm "${FONT_NAME}.zip"

# Updating the font cache
fc-cache -fv
