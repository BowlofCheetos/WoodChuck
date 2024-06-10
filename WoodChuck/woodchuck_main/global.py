#!/usr/bin/env python3.11
import difflib
import json
import os

def read_config(file_path):
    with open(file_path, 'r') as file:
        return file.readlines()

def write_output(output_path, changes):
    with open(output_path, 'w') as file:
        file.writelines(changes)

def compare_configs(config1, config2):
    config1_lines = [line.rstrip() for line in config1 if not line.startswith(' ') and not line.startswith('! Last')]
    config2_lines = [line.rstrip() for line in config2 if not line.startswith(' ') and not line.startswith('! Last')]

    # Using difflib to find the differences
    diff = list(difflib.ndiff(config1_lines, config2_lines))

    added = set()
    removed = set()
    for line in diff:
        if line.startswith('+ '):
            added.add(line[2:])
        elif line.startswith('- '):
            removed.add(line[2:])

    # Ensure that modified lines are not marked as both added and removed
    changes = []
    added_lines = list(added)
    removed_lines = list(removed)

    for line in added_lines:
        changes.append(line + '\n')
    
    for line in removed_lines:
        # Check if the removed line is similar to any added line
        similar = any(difflib.SequenceMatcher(None, line, added_line).ratio() > 0.8 for added_line in added_lines)
        if not similar:
            changes.append(f'no {line}\n')

    return changes

def main():
    # Read the context file
    context_file = os.path.expanduser("~/WoodChuck/woodchuck_main/context.json")
    with open(context_file, 'r') as f:
        context = json.load(f)

    hostname = context["current_hostname"]
    config1_path = os.path.expanduser(f'~/WoodChuck/woodchuck_captures/{hostname}_master.cfg')
    config2_path = os.path.expanduser(f'~/WoodChuck/woodchuck_captures/{hostname}_secondary.cfg')
    output_path = os.path.expanduser('~/WoodChuck/woodchuck_main/final.cfg')

    config1 = read_config(config1_path)
    config2 = read_config(config2_path)

    changes = compare_configs(config1, config2)
    write_output(output_path, changes)

if __name__ == '__main__':
    main()
