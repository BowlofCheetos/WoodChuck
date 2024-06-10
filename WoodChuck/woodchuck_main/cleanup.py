#!/usr/bin/env python3.11

def remove_duplicate_commands(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    last_seen_commands = {}
    block = []
    cleaned_lines = []

    for line in lines:
        stripped_line = line.rstrip()  # Use rstrip() to remove trailing spaces
        if not line.startswith(' ') and not line.startswith('!'):
            # Process the current block if it's not empty
            if block:
                command = block[0].rstrip()
                last_seen_commands[command] = block
                block = []
            # Start a new block with the current line
            block = [line]
        else:
            # Add nested command or comment to the current block
            block.append(line)

    # Add the last block if any
    if block:
        command = block[0].rstrip()
        last_seen_commands[command] = block

    # Collect the last seen commands in the order they appeared
    seen_commands = set()
    for command, block in last_seen_commands.items():
        if command not in seen_commands:
            cleaned_lines.extend(block)
            seen_commands.add(command)

    with open(file_path, 'w') as file:
        file.writelines(cleaned_lines)

# Usage
file_path = 'final.cfg'
remove_duplicate_commands(file_path)
