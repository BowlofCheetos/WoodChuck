#!/usr/bin/env python3.11
import paramiko
import time
import sys
import json
import os

def get_running_config(hostname, username, password):
    # Establish SSH connection
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=username, password=password)

    # Start an interactive shell session
    remote_conn = ssh.invoke_shell()
    time.sleep(1)

    # Clear the buffer
    remote_conn.recv(65535)

    # Send commands to the router
    remote_conn.send("terminal length 0\n")
    time.sleep(1)
    remote_conn.send("show running-config\n")
    time.sleep(5)

    # Receive the output in chunks to ensure complete capture
    output = ""
    while True:
        if remote_conn.recv_ready():
            output += remote_conn.recv(65535).decode('utf-8')
        else:
            break

    # Close the SSH connection
    ssh.close()

    # Parse the hostname from the running-config
    config_lines = output.splitlines()
    device_hostname = None
    for line in config_lines:
        if line.startswith('hostname'):
            device_hostname = line.split()[1]
            break

    if not device_hostname:
        raise ValueError("Hostname not found in the running configuration.")

    # Save the hostname to the context file
    context_file = os.path.expanduser("~/WoodChuck/woodchuck_main/context.json")
    with open(context_file, 'r+') as f:
        context = json.load(f)
        context["current_hostname"] = device_hostname
        f.seek(0)
        json.dump(context, f, indent=4)
        f.truncate()

    # Define the output directory and file name
    output_dir = os.path.expanduser("~/WoodChuck/woodchuck_captures")
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, f"{device_hostname}_secondary.cfg")

    # Save the output to the file, starting from the desired line
    with open(output_file, 'w') as file:
        start_saving = False
        for line in config_lines:
            if "Last configuration change" in line:
                start_saving = True
            if start_saving:
                file.write(line + "\n")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 capture_sec.py <hostname> <username> <password>")
        sys.exit(1)

    hostname = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]

    get_running_config(hostname, username, password)
