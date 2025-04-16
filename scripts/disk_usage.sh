#!/bin/bash

# Nerd Fonts symbols with colors
question_symbol="\e[35m\e[0m"  # Purple question symbol
check_symbol="\e[32m\e[0m"  # Green check symbol
disk_symbol="\e[34m\e[0m"  # Blue disk symbol
folder_symbol="\e[33m\e[0m"  # Yellow folder symbol
cancel_symbol="\e[31m\e[0m"  # Red cancel symbol

dir=${1:-$HOME}

echo -e "${question_symbol} This will calculate the disk usage of ${folder_symbol} $dir. Proceed? (y/n) "
read -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${cancel_symbol} Operation cancelled by the user."
    exit 1
fi

echo -e "${disk_symbol} Disk usage for ${folder_symbol} $dir:"
du -sh "$dir"
echo -e "${check_symbol} Disk usage calculation completed."
