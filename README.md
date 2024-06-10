# WoodChuck

## Description
WoodChuck is a local logging solution that monitors configuration changes on Cisco routers/switches and ensures those changes are capable of being used in automation if the need arises in the future. It does so with the following Features:
 1. Monitors and recognizes device changes.
 2. Stores changes made dynamically in Cisco recognizable formatting.
 3. As an optional feature, config lines are then parsed to YAML to be run from the local Ansible server that WC is hosted on.

## Installation
1. Download the entire WoodChuck directory (includes woodchuck_ansible, woodchuck_captures, woodchuck_install, woodchuck_main) and place it in your user's home folder.
2. Change to the WoodChuck directory and run the `install.sh` script (only CentOS and RHEL). It has `sudo` commands so you will have to input the password when the script runs.
3. If you are running another version of Linux that does not take the nomenclature inside the script please refer to the documentation contained in the project wiki and find the commands that are the equivalent for your version of Linux.
4. Below is the directory structure for verification.

```shell
└── WoodChuck
    ├── woodchuck_ansible
    │   ├── commands.yml
    │   ├── inventory
    │   └── wc_playbook.yml
    ├── woodchuck_captures
    ├── woodchuck_install
    │   ├── install.sh
    │   └── requirements.txt
    └── woodchuck_main
        ├── capture_master.py
        ├── capture_sec.py
        ├── cleanup.py
        ├── context.py
        ├── global.py
        ├── main.sh
        ├── start_text.txt
        └── to_yaml.py
```

**SYSLOG INFORMATION**

The `install.sh` script installs ryslog onto the server to be used. You will have to do the following steps to ensure that your server is configured properly to store these syslog messages:
1. Edit the `/etc/rsyslog.conf` file and the following lines are appended to the end of the file:
```shell
$ModLoad imudp
$UDPServerRun 514
```
2. Ensure the UDP section looks like the following:
```shell
# Provides UDP syslog reception
# for parameters see http://www.rsyslog.com/doc/imudp.html
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")
```
3. Example file down below:
```shell
# rsyslog configuration file

# For more information see /usr/share/doc/rsyslog-*/rsyslog_conf.html
# or latest version online at http://www.rsyslog.com/doc/rsyslog_conf.html 
# If you experience problems, see http://www.rsyslog.com/doc/troubleshoot.html

#### MODULES ####

module(load="imuxsock")  # provides support for local system logging (e.g. via logger command)
       SysSock.Use="off") # Turn off message reception via local log socket;
                          # local messages are retrieved through imjournal now.
module(load="imjournal") # provides access to the systemd journal
       UsePid="system" # PID nummber is retrieved as the ID of the process the journal entry originates from
       StateFile="imjournal.state") # File to store the position in the journal
#module(load="imklog") # reads kernel messages (the same are read from journald)
#module(load="immark") # provides --MARK-- message capability

# Provides UDP syslog reception
# for parameters see http://www.rsyslog.com/doc/imudp.html
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")

# Provides TCP syslog reception
# for parameters see http://www.rsyslog.com/doc/imtcp.html
#module(load="imtcp") # needs to be done just once
#input(type="imtcp" port="514")

#### GLOBAL DIRECTIVES ####

# Where to place auxiliary files
global(workDirectory="/var/lib/rsyslog")

# Use default timestamp format
module(load="builtin:omfile" Template="RSYSLOG_TraditionalFileFormat")

# Include all config files in /etc/rsyslog.d/
include(file="/etc/rsyslog.d/*.conf" mode="optional")

#### RULES ####

# Log all kernel messages to the console.
# Logging much else clutters up the screen.
#kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher.
# Don't log private authentication messages!
*.info;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.
authpriv.*                                              /var/log/secure

# Log all the mail messages in one place.
mail.*                                                  -/var/log/maillog


# Log cron stuff
cron.*                                                  /var/log/cron

# Everybody gets emergency messages
*.emerg                                                 :omusrmsg:*

# Save news errors of level crit and higher in a special file.
uucp,news.crit                                          /var/log/spooler

# Save boot messages also to boot.log
local7.*                                                /var/log/boot.log


# ### sample forwarding rule ###
#action(type="omfwd"  
# An on-disk queue is created for this action. If the remote host is
# down, messages are spooled to disk and sent when it is up again.
#queue.filename="fwdRule1"       # unique name prefix for spool files
#queue.maxdiskspace="1g"         # 1gb space limit (use as much as possible)
#queue.saveonshutdown="on"       # save messages to disk on shutdown
#queue.type="LinkedList"         # run asynchronously
#action.resumeRetryCount="-1"    # infinite retries if host is down
# Remote Logging (we use TCP for reliable delivery)
# remote_host is: name/ip, e.g. 192.168.0.1, port optional e.g. 10514
#Target="remote_host" Port="XXX" Protocol="tcp")

$ModLoad imudp
$UDPServerRun 514
```
4. On your Cisco device input the `logging host x.x.x.x` command to use the IP address of your server so that logs can be sent. The default location is in the `/var/log/messages` directory (you will need sudo permissions to view/tail it).

## Usage
1. To start the program, navigate to the following directory `~/WoodChuck/woodchuck_main` and run the `main.sh` script.
2. A TUI will appear and input all of the required information to the device that you are trying to connect to then start the application.
3. When the application starts you will see the master and secondary configs populate inside the `woodchuck_captures` directory in the form of `.cfg` files.
4. Stop the program anytime by going into the terminal in which it is running and pressing `CTRL+C` or by killing the process id.
5. After the set amount of time to capture the secondary config, the changes between the last interval will be saved to `woodchuck_captures` by the name of the device and the timestamp.
6. If you would like to push this change later locally to the router from WoodChuck, navigate to the `WoodChuck/woodchuck_ansible` directory and run the `playbook_cfg.sh` script.
7. You will see a TUI populate listing all of the `.cfg` files in the `woodchuck_captures` directory. Select your desired `.cfg` file and hit `Enter` until the TUI exits, it will give you status updates as it does its processes.
8. Once the `.yml` file is created, input the following command: `ansible-playbook wc_playbook.yml -i inventory` to push the most recently generated `.yml` to the router.

## Support
Current support is through the developer at travis.laprairie.mil@socom.mil

**COMMON EVENTS AND T/S**
- If the program is refusing the SSH connection to your device, you can modify the `context.json` inside the `woodchuck_main` directory with the correct values to connect to your device. You can also stop the previous WoodChuck process and run `main.sh` again, inputting the correct values into the TUI.
- If you see the latest config is not populating in the `woodchuck_captures` directory, that is because the file has the same configuration as the last and is being deleted. This can be viewed in the terminal output.
- Inside the `install.sh` script are all the commands that are needed to prep the server for the complete execution of WoodChuck. If the script is failing the commands can be individually run against your machine to identify the failure. Along with it is the `requirements.txt` that python uses to install the required packages. Check compatibility between your current environment and these requirements.
- If you are not seeing captures populate at all inside the `woodchuck_captures` directory, reference the `wc_log.txt` file to see all of the terminal output from WoodChuck.

## Roadmap
WoodChuck Release v0.1 - Connects to Cisco device, captures running-config with correct nomenclature (master/running).

WoodChuck Release v0.2 - Checks for changes made on device and stores only those changes with correct nomenclature (change id).

WoodChuck Release v0.3 - Stored log files are formatted correctly with extensive debugging testing.

WoodChuck Release v0.4 - Ansible playbook successfully runs against remote router, passing the commands that are stored in the files.

WoodChuck Release v0.5 - Version and change control are monitored for clean and concise configuration moderation.

WoodChuck Release v1.0 - Completed deployable application with all features from previous Alpha version working correctly.
  - Includes entire package with script that preps environment and makes all necessary directories.

WoodChuck Release v1.1 - TUI/GUI is generated for a cleaner user interface and script modification.

## Authors and acknowledgment
A special thanks to NSWDG and DEV-OTC(JCU) for their continued support of the development of WoodChuck.

## License
In the testing environment WoodChuck was deployed to run on a Rocky Linux 8.9 host, license information can be found below:
https://rockylinux.org/legal/licensing

## Project status
CURRENT VERSION DEVELOPMENT: WoodChuck v1.1

![WoodChuck](WoodChuck.png)
