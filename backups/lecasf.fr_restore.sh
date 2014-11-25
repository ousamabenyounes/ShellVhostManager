#!/bin/bash

# Load VHOST CONFIGURATION
source $(pwd)"/../lib/Utils.sh"
source $(pwd)"/../conf.sh"
source $(pwd)"/../myhostconf/lecasf.fr_conf.sh"




RESTORE="lecasf.fr_2209141247.tgz"
PATH_TO="/var/www/lecasf/subdomains/dev5.lecasf.fr"

root_check


MODE="debug"

launch_cmd "cd /home/ousama" $MODE
launch_cmd "ls -la" $MODE
exit
launch_cmd "cd "$PATH_TO" && rm -rf *"
launch_cmd "cp "$VHOST_NAME"/"$RESTORE " "$PATH_TO
launch_cmd "cd "$PATH_TO
launch_cmd "tar xvzf "$RESTORE" ."



# remove backup directory
launch_cmd "rm -rf backup_"$CUR_DATE"/"

