#!/bin/bash


#================================================================================
# lampManager.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


WWW="www"
APACHE_WEB_DIR="/var/www/"
APACHE_LOG_DIR="/var/log/apache2/"
APACHEGRP="www-data"


# Print help message
usage () {
    echo "Usage: lampManager.sh -H -d -h"
    echo "  -H: Host ."
    echo "  -p: Project name."
    echo "  -d: Domains(fr|com|net)."
    echo "  -h: Print this Help."

    exit 1;
}

# Create a directory
create_dir () {
    DIR=$1
    
    if [ -d "$DIR" ]; then
	echo "[INFO] Directory allready exists: $DIR"
    else
        echo "[INFO] Creating directory: $DIR"
        mkdir -p $DIR
	chown -R "$APACHEGRP:$APACHEGRP" $DIR	
    fi
}


# create vhost Directories
create_vhost_directories () {

    DOMAINS=$1
    PROJECT=$2
    
    # Check if this web dir belongs to a project directory (then create it)
    if [ "$PROJECT" != "" ]; then
	PROJECT="$PROJECT/"
	APACHE_WEB_DIR=$APACHE_WEB_DIR$PROJECT
        APACHE_LOG_DIR=$APACHE_LOG_DIR$PROJECT
	create_dir $APACHE_WEB_DIR
	create_dir $APACHE_LOG_DIR
    fi
    
    # Parse all given domains
    var=$(echo $DOMAINS | awk -F"|" '{print $1,$2,$3}')
    set -- $var
    for i in $*
    {
	SITE="$HOST.$i"
	ALIAS="$ALIAS $WWW.$SITE $SITE"
    }

    # Create Default Site web & log directories
    DEFAULT_SITE="$HOST.$1"
    create_dir $APACHE_WEB_DIR$DEFAULT_SITE    
    create_dir $APACHE_LOG_DIR$DEFAULT_SITE

   
    # Create site vhost file
    echo "[INFO]Creating virtualhost file: $DEFAULT_SITE"
    
    cat vhost.tpl | sed "s/\${HOST}/${DEFAULT_SITE}/"  | sed "s|\${ALIAS}|$ALIAS|"  | sed "s|\${APACHE_LOG_DIR}|$APACHE_LOG_DIR|" | sed "s|\${APACHE_WEB_DIR}|${APACHE_WEB_DIR}|" > "/tmp/${DEFAULT_SITE}"
        
    sudo mv "/tmp/${DEFAULT_SITE}" "/etc/apache2/sites-available/${DEFAULT_SITE}"
    sudo a2ensite $DEFAULT_SITE

    # Add site to hosts file
    #sudo $(cat "127.0.0.1 ${HOSTNAME}" >> /etc/hosts)

    # Restart webserver
    sudo /etc/init.d/apache2 reload
}





# ------------------------------------------------------------------------------ #
# Check if user is allowed to use this script

if [ `whoami` != 'root' ]; then
echo "This script is only allowed for superuser."
  echo "Enter your password to continue..."
  sudo $0 $* || exit 1
  exit 0
fi
if [ "$SUDO_USER" = "root" ]; then
  /bin/echo "You must start this under your regular user account (not root) using sudo."
  /bin/echo "Rerun using: sudo $0 $*"
  exit 1
fi


# ------------------------------------------------------------------------------ #
# Parsing all parameters
while getopts ":H:d:h:p:" opt; do
  case "$opt" in
    H)  HOST="$OPTARG";;
    d)  DOMAINS="$OPTARG";;
    p)  PROJECT="$OPTARG";;

    h)  # print usage
        usage
        exit 0
        ;;
    :)  echo "Error: -$option requires an argument"
        usage
        exit 1
        ;;
    ?)  echo "Error: unknown option -$option"
        usage
        exit 1
        ;;
  esac
done



# Parse all given domains
#var=$(echo $DOMAINS | awk -F"|" '{print $1,$2,$3}')
#set -- $var
#for i in $*
#{
#  SITE="$HOST.$i"
  #ALIAS="$ALIAS $WWW.$site $site"
#}

#default_site="$HOST.$1"


create_vhost_directories $DOMAINS $PROJECT


