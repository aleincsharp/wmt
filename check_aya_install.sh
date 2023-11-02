#!/bin/bash

# ----------------------------------------------
# Author: Arthur
# Date: 2023-09-03
# Description: This script performs various checks to validate the AYA installation.
# ----------------------------------------------

# Fancy Header
echo -e "[35m==================================================[0m"
echo -e "[35m       WORLD MOBILE AYA INSTALLATION CHECK        [0m"
echo -e "[35m   powered by WMT-EXPLORER.COM - WiseEarth Node   [0m"
echo -e "[35m==================================================[0m"

# Function to display error messages
error_message() {
    echo -e "[31m✗[0m $1"
}

# Function to display success messages
success_message() {
    echo -e "[32m✔[0m $1"
}

echo -e "[34mStarting AYA Installation Checks...[0m"

# Check if AYA node1 is reachable
if ! curl -s "http://peer1-501.worldmobilelabs.com:26657/status" &> /dev/null; then
    error_message "Cannot reach AYA node1. Check your network connection."
else
    success_message "AYA node1 is reachable."
fi

# Check if AYA node2 is reachable
if ! curl -s "http://wmt-relay-eu-01.westeurope.cloudapp.azure.com:26657/status" &> /dev/null; then
    error_message "Cannot reach AYA node2. Check your network connection."
else
    success_message "AYA node2 is reachable."
fi

# Check if config files exist
if [[ ! -f "/opt/aya/config/config.toml" || ! -f "/opt/aya/config/app.toml" ]]; then
    error_message "Config files are missing. Please make sure they are in the correct path."
else
    success_message "Config files are present."
fi

# Check if log level is set to "error" in config.toml
if ! grep -q "log_level = \"error\"" "/opt/aya/config/config.toml"; then
    error_message "Log level in config.toml is not set to \"error\". Please update it."
else
    success_message "Log level in config.toml is set to \"error\"."
fi

# Check if gas price units are set to "uswmt" in app.toml
if ! grep -q "0uswmt" "/opt/aya/config/app.toml"; then
    error_message "Gas price units in app.toml are not set to \"uswmt\". Please update it."
else
    success_message "Gas price units in app.toml are set to \"uswmt\"."
fi

# Check the version of "ayad"
version_output=$(ayad version 2>/dev/null)

# Check if "ayad version" command was successful
if [ $? -ne 0 ]; then
    error_message "Failed to fetch ayad version. Make sure the ayad service is installed."
else
    if [ "$version_output" == "0.4.1" ]; then
        success_message "ayad version is correct: $version_output."
    else
        error_message "Incorrect ayad version: $version_output. Expected version is 0.4.1."
    fi
fi

# Fetch the output of "ayad status"
status_output=$(ayad status 2>/dev/null)

# Check if "ayad status" command was successful
if [ $? -ne 0 ]; then
    error_message "Failed to fetch node status using 'ayad status'. Make sure the ayad service is running."
else
    # Extract relevant information from the status output
    latest_block_height=$(echo "$status_output" | jq -r ".SyncInfo.latest_block_height")
    catching_up=$(echo "$status_output" | jq -r ".SyncInfo.catching_up")
    voting_power=$(echo "$status_output" | jq -r ".ValidatorInfo.VotingPower")

    # Check if the node is fully synced
    if [ "$catching_up" == "true" ]; then
        error_message "Node is still catching up. Latest block height: $latest_block_height."
    else
        success_message "Node is fully synced. Latest block height: $latest_block_height."
    fi

    # Check the voting power of the node
    if [ "$voting_power" -eq 0 ]; then
        error_message "Node has no voting power."
    else
        success_message "Node has voting power: $voting_power."
    fi
fi

# Check file permissions for folders and subfolders in /opt/aya
find /opt/aya -type d -exec stat -c "%a %n" {} \; | while read -r perm path; do
    if [ "$perm" -ne 755 ]; then
        error_message "Incorrect permissions on folder $path: $perm. Expected 755."
    else
        success_message "Correct permissions on folder $path: $perm."
    fi
done

# If all checks pass
echo -e "[34mAll checks completed. Please review any errors above.[0m"
