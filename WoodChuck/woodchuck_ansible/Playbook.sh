#!/bin/bash

# Function to show the menu for selecting a .cfg file and parsing it to YAML
parse_cfg_to_yaml() {
  local captures_dir="$HOME/WoodChuck/woodchuck_captures"
  local ansible_dir="$HOME/WoodChuck/woodchuck_ansible"

  # List .cfg files in the captures directory
  cfg_files=($(ls "$captures_dir"/*.cfg 2>/dev/null))
  if [ ${#cfg_files[@]} -eq 0 ]; then
    dialog --msgbox "No .cfg files found in $captures_dir" 8 40
    exit 1
  fi

  # Create a menu of .cfg files
  local menu_options=()
  for file in "${cfg_files[@]}"; do
    filename=$(basename "$file")
    menu_options+=("$filename" "")
  done

  # Display the menu to the user
  dialog --menu "Select a .cfg file to parse to YAML" 15 50 10 "${menu_options[@]}" 2>menu_choice
  local selected_file=$(<menu_choice)
  if [ -z "$selected_file" ]; then
    dialog --msgbox "No file selected. Exiting..." 8 40
    exit 1
  fi

  # Parse the selected .cfg file to YAML
  local cfg_file_path="$captures_dir/$selected_file"
  local yaml_file_path="$ansible_dir/${selected_file%.cfg}.yml"

  echo "Parsing $cfg_file_path to $yaml_file_path..."
  python3 "$HOME/WoodChuck/woodchuck_main/to_yaml.py" "$cfg_file_path" "$yaml_file_path" 2>/dev/null

  if [ $? -eq 0 ]; then
    dialog --msgbox "Successfully parsed $cfg_file_path to $yaml_file_path" 8 40
  else
    dialog --msgbox "Failed to parse $cfg_file_path to YAML" 8 40
  fi

  # Update the Ansible playbook with the new YAML file path
  local playbook_path="$ansible_dir/wc_playbook.yml"
  sed -i "s|file: .*|file: ${yaml_file_path}|g" "$playbook_path"

  dialog --msgbox "Updated Ansible playbook with $yaml_file_path" 8 40
}

# Function to update the Ansible inventory file with contents from context.json
update_inventory() {
  local context_file="$HOME/WoodChuck/woodchuck_main/context.json"
  local inventory_file="$HOME/WoodChuck/woodchuck_ansible/inventory"

  # Read values from context.json
  ssh_user=$(jq -r '.ssh_user' "$context_file")
  ssh_pass=$(jq -r '.ssh_pass' "$context_file")
  ssh_host=$(jq -r '.ssh_host' "$context_file")
  current_hostname=$(jq -r '.current_hostname' "$context_file")

  # Update the inventory file
  cat <<EOL > "$inventory_file"
[all:vars]
ansible_network_os=ios
ansible_user=$ssh_user
ansible_ssh_pass=$ssh_pass

[devices]
$current_hostname ansible_host=$ssh_host
EOL

  dialog --msgbox "Updated Ansible inventory with values from context.json" 8 40
}

# Run the parse function
parse_cfg_to_yaml
update_inventory
clear
rm -rf $HOME/WoodChuck/woodchuck_ansible/menu_choice
