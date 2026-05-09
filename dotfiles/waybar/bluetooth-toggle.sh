#!/bin/bash
MAC="9C:0D:AC:14:8D:42"

# Check if device is connected
if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
    echo "Disconnecting..."
    bluetoothctl disconnect "$MAC"
else
    echo "Connecting..."
    bluetoothctl connect "$MAC"
fi

# Wait for device to register, then refresh waybar bt-battery module
sleep 1
pkill -RTMIN+1 waybar
