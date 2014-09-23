#!/bin/bash

# Load VHOST CONFIGURATION
source $(pwd)"/../lib/Utils.sh"
source $(pwd)"/../conf.sh"
source $(pwd)"/../myhostconf/lecasf.fr_conf.sh"
BACKUP_DIR=$BACKUP_ROOT"backup_"$CUR_DATE"/"

root_check

create_dir $BACKUP_ROOT "ousama"
create_dir $BACKUP_DIR "ousama"
#launch_cmd "chmod 777 $BACKUP_DIR"
launch_cmd "tar -cvzf "$BACKUP_DIR"WEB_"$VHOST_NAME"_"$CUR_DATE".tgz "$WEB_ROOT ""
launch_cmd "mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"  > "$BACKUP_DIR"DB_"$VHOST_NAME"_"$CUR_DATE
launch_cmd "cd "$PROJECT_NAME" && tar -cvzf "$BACKUP_ROOT$VHOST_NAME"_"$CUR_DATE".tgz backup_"$CUR_DATE"/"

# remove backup directory
launch_cmd "rm -rf backup_"$CUR_DATE"/"

