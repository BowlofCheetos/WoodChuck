#!/usr/bin/env python3.11
import yaml
import sys
import os

def split_config_into_groups(file_path, output_file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    groups = []
    current_group = []

    for line in lines:
        stripped_line = line.strip()
        if stripped_line and not line.startswith(' '):
            if current_group:
                groups.append(current_group)
                current_group = []
            current_group.append(line)
        elif line.startswith(' ') or stripped_line == '!':
            current_group.append(line)
        else:
            if current_group:
                groups.append(current_group)
                current_group = []

    if current_group:
        groups.append(current_group)

    with open(output_file_path, 'w') as output_file:
        yaml.dump({"config_groups": groups}, output_file, default_flow_style=False)

# Ensure the correct number of arguments are passed
if len(sys.argv) != 3:
    print("Usage: to_yaml.py <input_cfg_file> <output_yaml_file>")
    sys.exit(1)

# Parse the command-line arguments
input_file_path = sys.argv[1]
output_file_path = sys.argv[2]

# Expand the user directory if needed
output_file_path = os.path.expanduser(output_file_path)

# Call the function with the provided arguments
split_config_into_groups(input_file_path, output_file_path)
