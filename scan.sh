#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Set the log directory
LOG_DIR="$SCRIPT_DIR/log"
# Create the log directory if it does not exist
mkdir -p "$LOG_DIR"

# Function to scan network and log MAC addresses
scan_network() {
    echo "Scanning network"
    # Get the current timestamp
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Scan network and extract MAC addresses and IPs
    # Using `arp-scan` to scan local network; requires sudo
    local scan_results=$(sudo arp-scan -g --localnet --interface=$(ip route | grep default | awk '{print $5}'))
    
    echo "$scan_results" | while read -r line
    do
        local ip=$(echo "$line" | awk '{print $1}')
        local mac_address=$(echo "$line" | awk '{print $2}')

        # Skip entries where either the IP or MAC address is empty or IP is invalid
        if [[ -z "$ip" || -z "$mac_address" ]] || ! validate_ip "$ip"; then
            continue
        fi

        local hostname=$(nslookup $ip | grep 'name = ' | sed 's/.*name = \(.*\)\./\1/')
        echo " - Hostname $hostname found for $ip / [$mac_address]" 

        # Convert MAC address to uppercase and replace colons with dashes
        local formatted_mac=$(echo "$mac_address" | tr '[:lower:]:' '[:upper:]-')

        # Create a log file name using MAC and hostname
        local file_name="${formatted_mac}_${hostname:-unknown}"

        # Log the current timestamp to a file named after the formatted MAC address and hostname
        echo "$current_time" >> "$LOG_DIR/$file_name.log"
    done
    echo "Scan complete"
}

# Sync logs to AWS S3 using rclone
sync_logs() {
    echo "Syncing logs to AWS S3 bucket..."
    rclone sync "$LOG_DIR" "ovh:coworking-metz/pti-poulailler/network-log" --progress
}


# Function to validate IP addresses (both IPv4 and IPv6)
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 0  # Valid IPv4
    elif [[ $ip =~ ^([0-9a-fA-F:]+:+)+[0-9a-fA-F]{1,4}$ ]]; then
        return 0  # Valid IPv6
    else
        return 1  # Invalid IP
    fi
}
# Main loop to run the scan every 5 minutes
while true
do
    scan_network
    sync_logs
    sleep 300 # Sleep for 300 seconds (5 minutes)
done
