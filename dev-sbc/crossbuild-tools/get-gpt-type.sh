#!/bin/bash

# A script to look up the meaning of a GPT partition type GUID.
# Usage: ./get_gpt_type.sh /dev/sda

# Check for a single command-line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <device>"
    exit 1
fi

device="$1"

# Check if the device exists
if [ ! -b "$device" ]; then
    echo "Error: Device '$device' not found."
    exit 1
fi

echo "Looking up GPT partitions on $device..."

# Use gdisk to get partition information in a way that is easy to parse
output=$(gdisk -l "$device" 2>/dev/null)

if echo "$output" | grep -q "GPT fdisk not found"; then
    echo "Error: gptfdisk (gdisk) is not installed. Please install it."
    exit 1
fi

if ! echo "$output" | grep -q "Found valid GPT with protective MBR"; then
    echo "Error: Device '$device' does not appear to have a valid GPT."
    exit 1
fi

echo "--------------------------------------------------------"
echo "Partition Type Lookup for $device"
echo "--------------------------------------------------------"

# Extract partition GUIDs and iterate
#echo "$output" | awk '/^ *[0-9]+/{print $5}' | while read -r guid; do
echo "$output" | awk '/^ *[0-9]+/{print $6}' | while read -r guid; do
    # Remove leading/trailing whitespace
    clean_guid=$(echo "$guid" | tr -d '[:space:]')
    
    # Query systemd's partition type database via GitHub raw URL
    url="https://raw.githubusercontent.com/systemd/systemd/main/src/shared/partition-util.c"
    
    # Use curl and grep to find the matching GUID and its description
    description=$(curl -s "$url" | grep "$clean_guid" | head -n 1 | awk -F'"' '{print $2}')

    if [ -n "$description" ]; then
        echo "GUID: $clean_guid"
        echo "Type: $description"
        echo "--------------------------------------------------------"
    else
        echo "GUID: $clean_guid"
        echo "Type: Could not find a description for this GUID."
        echo "--------------------------------------------------------"
    fi
done

exit 0
