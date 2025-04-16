#!/bin/bash

# Nerd Fonts symbols with colors
folder_symbol="\e[34m\e[0m"  # Blue folder symbol
list_symbol="\e[36m󰯁\e[0m"  # Green list symbol

# Your scripts directory
scripts_dir=~/scripts

echo -e "$folder_symbol Your scripts directory: $scripts_dir"

# Check if the directory exists
if [ -d "$scripts_dir" ]; then
    # If it exists, list the scripts
    scripts=$(ls $scripts_dir)
    if [ -z "$scripts" ]; then
        # If no scripts found
        echo "No scripts found in the directory."
    else
        # If scripts are found
        for script in $scripts; do
            echo -e "$list_symbol $script"
        done
    fi
else
    # If the directory doesn't exist
    echo "The scripts directory does not exist."
fi
