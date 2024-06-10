#!/usr/bin/env python3.11
import difflib
import json
import os

def capture_blocks_with_changes(file1_path, file2_path, output_file_path):
    def get_blocks(file_path):
        with open(file_path, 'r') as file:
            lines = file.readlines()
        
        blocks = []
        block = []
        inside_block = False
        
        for line in lines:
            stripped_line = line.strip()
            # Skip the line that contains 'Last configuration change'
            if 'Last configuration change' in line or stripped_line == "file prompt quiet":
                continue
            if stripped_line and not line.startswith(' '):  # Start of a new block
                if block:
                    blocks.append(block)
                block = [line]
                inside_block = True
            elif line.startswith(' '):  # Inside a block
                block.append(line)
            elif inside_block and not line.startswith(' '):  # End of block
                inside_block = False
                blocks.append(block)
                block = [line]
        
        if block:
            blocks.append(block)
        
        return blocks

    def blocks_to_dict(blocks):
        block_dict = {}
        for block in blocks:
            if block:  # Ensure the block is not empty
                header = block[0].strip()
                block_dict[header] = block
        return block_dict

    def compare_blocks(dict1, dict2):
        changes = []
        for key in dict2:
            if key in dict1:
                # Compare blocks line by line using difflib
                diff = list(difflib.ndiff(dict1[key], dict2[key]))
                if any(line for line in diff if line.startswith('+ ') or line.startswith('- ')):
                    # Check if this is an interface block and if it was shutdown
                    if key.startswith('interface'):
                        was_shutdown = any('shutdown' in line for line in dict1[key])
                        is_unshut = not any('shutdown' in line for line in dict2[key])
                        if was_shutdown and is_unshut:
                            # Add 'no shutdown' if the interface was previously shut down and is now unshut
                            dict2[key].append(' no shutdown\n')
                    changes.append(dict2[key])
            else:
                changes.append(dict2[key])
        
        return changes

    blocks1 = get_blocks(file1_path)
    blocks2 = get_blocks(file2_path)
    
    dict1 = blocks_to_dict(blocks1)
    dict2 = blocks_to_dict(blocks2)
    
    changed_blocks = compare_blocks(dict1, dict2)
    
    # Append the changed blocks to the output file
    with open(output_file_path, 'a') as output_file:
        for block in changed_blocks:
            output_file.write(''.join(block))
            if block and block[-1].strip() != '!':
                output_file.write('!\n')

def main():
    # Read the context file
    context_file = os.path.expanduser("~/WoodChuck/woodchuck_main/context.json")
    with open(context_file, 'r') as f:
        context = json.load(f)

    hostname = context["current_hostname"]
    file1_path = os.path.expanduser(f'~/WoodChuck/woodchuck_captures/{hostname}_master.cfg')
    file2_path = os.path.expanduser(f'~/WoodChuck/woodchuck_captures/{hostname}_secondary.cfg')
    output_file_path = os.path.expanduser('~/WoodChuck/woodchuck_main/final.cfg')

    capture_blocks_with_changes(file1_path, file2_path, output_file_path)

if __name__ == '__main__':
    main()
