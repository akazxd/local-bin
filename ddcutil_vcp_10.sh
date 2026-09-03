#!/usr/bin/env bash

CACHE_FILE="/dev/shm/ddcutl_vcp_10"
PARAM=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Function to safely fetch live brightness from the monitor
get_live_brightness() {
    # 'ddcutil getvcp 10 --terse' outputs something like: VCP 10 Cnt 40 100
    # where 40 is current and 100 is max. We grab the 4th field.
    local live_val
    live_val=$(ddcutil getvcp 10 --terse 2>/dev/null | awk '{print $4}')

    # Fallback to 50 if command fails or output is empty
    if [[ -z "$live_val" || ! "$live_val" =~ ^[0-9]+$ ]]; then
        echo "50"
    else
        echo "$live_val"
    fi
}

# 1. If cache file doesn't exist, get live data and initialize it
if [ ! -f "$CACHE_FILE" ]; then
    VAL=$(get_live_brightness)
    echo "$VAL" > "$CACHE_FILE"
else
    # Read the stored value from memory
    VAL=$(cat "$CACHE_FILE")
fi

# 2. If an argument is provided, calculate the new step value
if [ "$PARAM" = "up" ]; then
    VAL=$((VAL + 5))
elif [ "$PARAM" = "down" ]; then
    VAL=$((VAL - 5))
elif [ -n "$1" ]; then
    echo "Error: Use 'up' or 'down' as an argument."
    exit 1
fi

# 3. Ensure the value stays within hardware limits (0 - 100)
if [ "$VAL" -gt 100 ]; then VAL=100; fi
if [ "$VAL" -lt 0 ]; then VAL=0; fi

# 4. Save the adjusted value back to RAM and apply it to the hardware
echo "$VAL" > "$CACHE_FILE"
/usr/bin/ddcutil setvcp 10 "$VAL" >/dev/null 2>&1

# 5. Trigger the Native Plasma 6 Brightness OSD Toast
/usr/bin/qdbus6 org.kde.plasmashell /org/kde/osdService org.kde.osdService.brightnessChanged "$VAL" >/dev/null 2>&1

# Print the value to stdout for terminal debugging
# echo "Brightness set to: $VAL%"
