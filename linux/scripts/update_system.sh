#!/bin/bash

# Nerd Fonts symbols with colors
update_symbol="\e[34m\e[0m"  # Blue update symbol
warning_symbol="\e[33m\e[0m"  # Yellow warning symbol
check_symbol="\e[32m\e[0m"  # Green check symbol
terminal_symbol="\e[36m\e[0m"  # Cyan terminal symbol

echo -e "${warning_symbol} This will update your system. Are you sure you want to proceed? (y/n) "
read -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${warning_symbol} Update cancelled by the user."
    exit 1
fi

echo -e "${update_symbol} Updating system..."
echo -e "${terminal_symbol} Running: sudo apt-get update"
sudo apt-get update
echo -e "${terminal_symbol} Running: sudo apt-get upgrade -y"
sudo apt-get upgrade -y
echo -e "${terminal_symbol} Running: sudo apt-get dist-upgrade -y"
sudo apt-get dist-upgrade -y
echo -e "${terminal_symbol} Running: sudo apt-get autoremove -y"
sudo apt-get autoremove -y
echo -e "${check_symbol} System updated!"
