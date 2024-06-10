#!/bin/bash
context_file="context.json"

# Show logo
show_logo() {
  cat start_text.txt
  sleep 1
}

# Function to show the main menu
show_menu() {
  dialog --title "WoodChuck Configuration" --menu "Choose an option:" 15 50 5 \
  1 "Set Master Config Update Interval" \
  2 "Set Secondary Config Update Interval" \
  3 "Set SSH Details" \
  4 "Start Application" \
  5 "Exit" 2>menu_choice

  menu_choice=$(<menu_choice)

  case $menu_choice in
    1) set_master_interval ;;
    2) set_secondary_interval ;;
    3) set_ssh_details ;;
    4) start_application ;;
    5) cleanup_and_exit ;;
  esac
}

# Function to update the JSON context file
update_context() {
  jq "$1" "$context_file" > tmp.$$.json && mv tmp.$$.json "$context_file"
}

# Function to set master config update interval
set_master_interval() {
  master_interval=$(dialog --inputbox "Enter the interval in seconds for updating the master config:" 8 40 3>&1 1>&2 2>&3 3>&-)
  update_context ".master_interval = $master_interval"
  show_menu
}

# Function to set secondary config update interval
set_secondary_interval() {
  secondary_interval=$(dialog --inputbox "Enter the interval in seconds for capturing the secondary config:" 8 40 3>&1 1>&2 2>&3 3>&-)
  update_context ".secondary_interval = $secondary_interval"
  show_menu
}

# Function to set SSH details
set_ssh_details() {
  ssh_host=$(dialog --inputbox "Enter the SSH IP address:" 8 40 3>&1 1>&2 2>&3 3>&-)
  update_context ".ssh_host = \"$ssh_host\""

  ssh_user=$(dialog --inputbox "Enter the SSH username:" 8 40 3>&1 1>&2 2>&3 3>&-)
  update_context ".ssh_user = \"$ssh_user\""

  ssh_pass=$(dialog --passwordbox "Enter the SSH password:" 8 40 3>&1 1>&2 2>&3 3>&-)
  update_context ".ssh_pass = \"$ssh_pass\""

  show_menu
}

# Function to start the application
start_application() {
  rm -f menu_choice

  dialog --msgbox "Starting the application with the current settings..." 6 40

  clear

  show_logo

  # Extract values from the context file
  ssh_host=$(jq -r '.ssh_host' $context_file)
  ssh_user=$(jq -r '.ssh_user' $context_file)
  ssh_pass=$(jq -r '.ssh_pass' $context_file)
  secondary_interval=$(jq -r '.secondary_interval' $context_file)
  master_interval=$(jq -r '.master_interval' $context_file)

  # Clear the final.cfg file to avoid stale data from previous runs
  > final.cfg

  # Run secondary config capture in the background
  (
    while true; do

      echo "Capturing secondary config..."
      python3 capture_sec.py "$ssh_host" "$ssh_user" "$ssh_pass" 2>/dev/null

      echo "Capturing global changes..."
      python3 global.py 2>/dev/null

      echo "Capturing contextual changes..."
      python3 context.py 2>/dev/null

      echo "Cleaning up output..."
      python3 cleanup.py 2>/dev/null

      check_and_backup_final_cfg

      echo "Parsing changes to YAML..."
      python3 to_yaml.py 2>/dev/null

      echo "Waiting for $secondary_interval seconds before next secondary capture..."
      sleep $secondary_interval
    done
  ) &

  # Main loop for master config updates
  while true; do
    echo "Capturing master config..."
    python3 capture_master.py "$ssh_host" "$ssh_user" "$ssh_pass" 2>/dev/null

    check_and_backup_final_cfg

    echo "Waiting for $master_interval seconds before updating master config..."
    sleep $master_interval
  done
}

# Function to check if final.cfg has lines and create a backup
check_and_backup_final_cfg() {
  if [ -s final.cfg ]; then
    hostname=$(jq -r '.current_hostname' $context_file)
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="${hostname}_${timestamp}.cfg"
    cp final.cfg "$HOME/WoodChuck/woodchuck_captures/$backup_file"
    echo "Backup created: $backup_file"

    # Check for duplicate backups and delete if necessary
    check_for_duplicates "$HOME/WoodChuck/woodchuck_captures"

    # Clear the final.cfg file to avoid repeated backups
    > final.cfg
  fi
}

# Function to check for duplicate backup files and delete the latest if they are identical
check_for_duplicates() {
  local backup_dir=$1

  # Get the list of files sorted by modification time and filter only the desired files
  files=$(find "$backup_dir" -maxdepth 1 -type f -name 'J-BR99-RTR_20*.cfg' -printf '%T@ %p\n' | sort -n -r | cut -d' ' -f2-)

  # Ensure there are at least two timestamped files before proceeding
  if [ $(echo "$files" | wc -l) -lt 2 ]; then
    echo "Not enough files to compare."
    return
  fi

  # Extract the most recently added file
  latest_file=$(echo "$files" | head -n 1)

  # Extract the second most recently added file
  second_latest_file=$(echo "$files" | head -n 2 | tail -n 1)

  # Output the results
  echo "New file: $latest_file"
  echo "Previous file: $second_latest_file"

  # Compare the two files
  if cmp -s "$latest_file" "$second_latest_file"; then
      echo "Files are the same. Deleting the latest file: $latest_file"
      rm "$latest_file"
  else
      echo "Files are different. No deletion performed."
  fi
}

# Function to clean up temporary files and exit
cleanup_and_exit() {
  rm -f menu_choice
  clear
  exit
}

# Initialize default wait times and context file
if [ ! -f "$context_file" ]; then
  echo '{
    "ssh_user": "",
    "ssh_pass": "",
    "ssh_host": "",
    "secondary_interval": 30,
    "master_interval": 600,
    "current_hostname": ""
  }' > $context_file
fi

# Show the main menu
show_menu
