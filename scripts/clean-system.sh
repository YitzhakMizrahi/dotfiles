#!/bin/bash

# Nerd Fonts symbols with colors
check_symbol="\e[32m\e[0m"  # Green check symbol
cross_symbol=$(echo -e "\e[31m\e[0m")  # Red cross
bin_symbol="\e[90m\e[0m"  # Grey bin symbol
folder_symbol="\e[33m\e[0m"  # Yellow folder symbol (folders are typically yellow)
question_symbol=$(echo -e "\e[34m\e[0m")  # Blue question (questions can be seen as uncertain - blue)
information_symbol="\e[36m\e[0m"  # Cyan information symbol (information can be seen as neutral - cyan)
cleanup_symbol="\e[92m󰃢\e[0m"  # Light green cleanup symbol (cleaning can be associated with green)
trash_symbol="\e[33m\e[0m"  # Yellow trash symbol
screenshot_symbol="\e[34m\e[0m"  # Blue screenshot symbol (screenshots capture light - blue)
thumbnail_symbol="\e[36m\e[0m"  # Cyan thumbnail symbol (thumbnails are small previews - cyan)
chromium_symbol="\e[94m\e[0m"  # Light Blue chromium symbol (chromium browser logo color)
mozilla_symbol="\e[38;5;214m\e[0m"  # Orange Mozilla symbol
checklist_symbol="\e[32m\e[0m"






# Function to get directory size
get_dir_size() {
    local dir=$1
    if [ -d "$dir" ]; then
        if [ "$(ls -A $dir)" ]; then
            du -sh $dir | cut -f1
        else
            echo "0"
        fi
    else
        echo "Directory does not exist."
    fi
}

# Function to get number of files
get_num_files() {
    local dir=$1
    if [ -d "$dir" ]; then
        if [ "$(ls -A $dir)" ]; then
            find $dir -type f | wc -l
        else
            echo "0"
        fi
    else
        echo "Directory does not exist."
    fi
}

# Function to clear directory
clear_dir() {
    local dir=$1
    local dir_name=$2
    local dir_symbol=$3

    if [ -d "$dir" ]; then
        if [ "$(ls -A $dir)" ]; then
            local total_size=$(get_dir_size $dir)
            local num_files=$(get_num_files $dir)
            echo -e "$information_symbol There are $num_files file(s) in the $dir_symbol $dir_name directory. Total size: $total_size."
            read -p ""$question_symbol" Are you sure you want to delete all files? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$dir"/*
                echo -e "$bin_symbol All files in $dir_symbol $dir_name have been cleared. Total cleared space: $total_size $check_symbol"
            else
                echo "$cross_symbol Operation cancelled by the user."
            fi
        else
            echo -e "$dir_symbol $dir_name is empty. $check_symbol No action needed."
        fi
    else
        echo -e "$cross_symbol Directory $dir_symbol $dir_name does not exist."
    fi
}

echo -e "$cleanup_symbol Welcome to system clean-up script!"

# Array of directory names
declare -a dir_names=("Trash" "Screenshots" "Cache Thumbnails" "Cache Chromium" "Cache Mozilla")

# Array of directory symbols
declare -a dir_symbols=("$trash_symbol" "$screenshot_symbol" "$thumbnail_symbol" "$chromium_symbol" "$mozilla_symbol")

# Associative array of directories to clean
declare -A dir_to_clean
dir_to_clean=(
    ["Trash"]=~/.local/share/Trash/files
    ["Screenshots"]=~/Pictures/Screenshots
    ["Cache Thumbnails"]=~/.cache/thumbnails
    ["Cache Chromium"]=~/snap/chromium/common/.cache/
    ["Cache Mozilla"]=~/snap/firefox/common/.cache/
)

# Clear directories in the order specified in dir_names
for index in "${!dir_names[@]}"; do
    dir_name="${dir_names[$index]}"
    dir_symbol="${dir_symbols[$index]}"
    dir="${dir_to_clean[$dir_name]}"
    clear_dir "$dir" "$dir_name" "$dir_symbol"
done

echo -e "$checklist_symbol System clean-up complete!"
