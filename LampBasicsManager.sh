#!/bin/bash


#================================================================================
# lampManager.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


APACHE_PORT="80"
WWW="www"
APACHE_WEB_DIR="/var/www/"
PUBDIR="${SITEDIR}/public"
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
    fi
}


# create vhost Directories
create_vhost_directories () {

    DOMAINS=$1
    PROJECT=$2
    WWW_ROOT_DIR=$APACHE_WEB_DIR
    
    # Check if this web dir belongs to a project directory (then create it)
    if [ "$PROJECT" != "" ]; then
	PROJECT="$PROJECT/"
	WWW_ROOT_DIR=$APACHE_WEB_DIR$PROJECT
	create_dir $WWW_ROOT_DIR
	create_dir
    fi
    
    # Parse all given domains
    var=$(echo $DOMAINS | awk -F"|" '{print $1,$2,$3}')
    set -- $var
    for i in $*
    {
	SITE="$HOST.$i"
	ALIAS="$ALIAS $WWW.$SITE $SITE"
    }
    DEFAULT_SITE="$HOST.$1"
    create_dir $WWW_ROOT_DIR$DEFAULT_SITE
    
    exit 1
    # Create site vhost file
    echo "Creating virtualhost file"
    cat vhost.tmpl | sed "s/\${HOSTNAME}/${HOSTNAME}/" | sed "s|\${PUBDIR}|$PUBDIR|" | sed "s|\${LOGDIR}|${LOGDIR}|" > "/tmp/${HOSTNAME}"
    sudo mv "/tmp/${HOSTNAME}" "/etc/apache2/sites-available/${HOSTNAME}"

    # Enable site
    echo "Enabling site."
    sudo a2ensite $HOSTNAME

    # Add site to hosts file
    #sudo $(cat "127.0.0.1 ${HOSTNAME}" >> /etc/hosts)

    # Restart webserver
    /etc/init.d/apache2 restart
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


