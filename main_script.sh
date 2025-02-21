#!/bin/bash

clear
##print the banner by tool with AP2KMO(author)
echo "................................................................................................................"
echo "................................................................................................................"
echo "..####...#####....####...##..##..##...##...####............####....####...........##..##...####...#####...######."
echo ".##..##..##..##......##..##.##...###.###..##..##..........##..##......##..........###.##..##..##..##..##..##....."
echo ".######..#####....####...####....##.#.##..##..##..######..##.......####...........##.###..##..##..##..##..####..."
echo ".##..##..##......##......##.##...##...##..##..##..........##..##..##..............##..##..##..##..##..##..##....."
echo ".##..##..##......######..##..##..##...##...####............####...######..######..##..##...####...#####...######."
echo "................................................................................................................."
echo "................................................................................................................"

declare -a WORKING_DEVICES

#updates working_devices list
update_working_devices() {
    mapfile -t WORKING_DEVICES < <(adb devices | awk 'NR>1 && $2=="device" {print $1}')
}

#sends ADB_orders to working_devices concurrently
send_adb_command_to_working() {
    local COMMAND="$1"
    if [ ${#WORKING_DEVICES[@]} -eq 0 ]; then
        echo "No working devices available."
        return
    fi
    echo "Sending command '$COMMAND' to working devices..."
    for DEVICE in "${WORKING_DEVICES[@]}"; do
        adb -s "$DEVICE" shell "$COMMAND" &
    done
    wait
    echo "Command executed on working devices."
}

#type text on working_devices
type_text_on_working() {
    read -rp "Enter the text to type on working devices: " TEXT
    send_adb_command_to_working "input text '$(echo "$TEXT" | sed "s/ /%s/g")'"
}

#sends click orders to working_devices
click_on_working() {
    read -rp "Enter the coordinates (x y) to click on working devices: " X Y
    if [[ -z "$X" || -z "$Y" ]]; then
        echo "Invalid input. Please enter valid coordinates."
        return
    fi
    send_adb_command_to_working "input tap $X $Y"
}

#unlock working_devices
unlock_working() {
    send_adb_command_to_working "input keyevent 82"
}

#starts selected_devices and updates working_list
start_selected_devices() {
    mapfile -t UUIDS < <(gmtool admin list devices | tail -n +3 | awk -F'|' '{print $3}' | sed 's/  */ /g')
    mapfile -t NAMES < <(gmtool admin list devices | tail -n +3 | awk -F'|' '{print $4}' | sed 's/  */ /g')
    
    echo "Available devices:"
    for i in "${!NAMES[@]}"; do
        echo "$((i + 1)). ${NAMES[$i]}"
    done
    
    read -rp "Enter the index numbers of the devices to start (comma-separated) or type 'all' to start all devices: " input
    
    if [[ "$input" == "all" ]]; then
        echo "Starting all devices..."
        for i in "${!UUIDS[@]}"; do
            echo "Starting: ${NAMES[$i]}"
            gmtool admin start "${UUIDS[$i]}" &
        done
    else
        IFS=',' read -ra indices <<< "$input"
        for idx in "${indices[@]}"; do
            idx=$((idx - 1))
            if [[ $idx -ge 0 && $idx -lt ${#UUIDS[@]} ]]; then
                echo "Starting: ${NAMES[$idx]}"
                gmtool admin start "${UUIDS[$idx]}" &
            else
                echo "Invalid index: $((idx + 1))"
            fi
        done
    fi
    wait
    update_working_devices
    echo "Selected devices started."
}

# Menu-based interface
while true; do
    echo "-----------------------------------"
    echo " Genymotion ADB Command Executor "
    echo "-----------------------------------"
    echo "1. Start Genymotion Devices"
    echo "2. Type Text on Working Devices"
    echo "3. Click on Working Devices"
    echo "4. Unlock Working Devices"
    echo "5. Exit"
    echo "-----------------------------------"
    read -rp "Choose an option: " option

    case $option in
        1) start_selected_devices ;;
        2) update_working_devices; type_text_on_working ;;
        3) update_working_devices; click_on_working ;;
        4) update_working_devices; unlock_working ;;
        5) echo "Exiting..."; break ;;
        *) echo "Invalid option! Please try again." ;;
    esac
done