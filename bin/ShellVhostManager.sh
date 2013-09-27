#!/bin/bash

source "../lib/Utils.sh"

#================================================================================
# ShellVhostManager.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


TEMPLATE_DIR="../templates/"
WWW="www"
APACHE_WEB_DIR="/var/www/"
APACHE_LOG_DIR="/var/log/apache2/"
APACHEGRP="www-data"
APACHE_WEB_USR="$APACHEGRP:$APACHEGRP"
APACHE_LOG_USR="root:root"
FTP_USR=""
MYSQL_USR=""
MYSQL_PWD=""
MYSQL_DB=""
MYSQL_ADMINISTRATOR_USR="root" #You Must specify here your mysql admin account (db & user create)
FTP_GRP="ftpusers"
PWD_LENGHT=8
VHOST_CONF=""
WP_ADMIN_EMAIL=""
MAIN_HOST=""
DEFAULT_SITE=""
WP_CREATE=""
PS_CREATE=""

# ************************************************************** #
# Print help message

usage () {
    echo "Usage: lampManager.sh -H -p -d -u -h -f -m -w -l -s"
    echo "  -H: Host ."
    echo "  -p: Project name."
    echo "  -d: Domains(fr|com|net)."
    echo "  -u: User:Group apache owner"    
    echo "  -h: Print this Help."
    echo "  -f: Ftp User Name (will generate user pwd)"
    echo "  -m: Mysql username (will generate user pwd) DB name will be the host name"
    echo "  -l: Passwords length. (default 10 chars)"
    echo "  -w: (Will Install Wordpress) "  
    echo "  -s: (Will Install Prestashop) "

    exit 1;
}


# ************************************************************** #
# Create Vhost and Activate it

create_vhost_directories () {

    show_title "Create VHOST Directories"

    DOMAINS=$1
    PROJECT=$2

    
    # Check if this web dir belongs to a project directory (then create it)
    if [ "$PROJECT" != "" ]; then	
	PROJECT="$PROJECT/"
	APACHE_WEB_DIR=$APACHE_WEB_DIR$PROJECT      
	APACHE_LOG_DIR=$APACHE_LOG_DIR$PROJECT	
	create_dir $APACHE_WEB_DIR "$APACHE_WEB_USR"
	create_dir $APACHE_LOG_DIR "$APACHE_LOG_USR"
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

    create_dir $APACHE_WEB_DIR$DEFAULT_SITE $APACHE_WEB_USR
    create_dir $APACHE_LOG_DIR$DEFAULT_SITE $APACHE_LOG_USR
   
    # Create site vhost file
    echo "[INFO]Creating virtualhost file: $DEFAULT_SITE"    
    cat $TEMPLATE_DIR"vhost.tpl" | sed "s/\${HOST}/${DEFAULT_SITE}/"  | sed "s|\${ALIAS}|$ALIAS|"  | sed "s|\${APACHE_LOG_DIR}|$APACHE_LOG_DIR|" | sed "s|\${APACHE_WEB_DIR}|${APACHE_WEB_DIR}|" > "/tmp/${DEFAULT_SITE}"    
    launch_cmd "mv /tmp/${DEFAULT_SITE} /etc/apache2/sites-available/${DEFAULT_SITE}"
    launch_cmd "a2ensite $DEFAULT_SITE"
    launch_cmd "/etc/init.d/apache2 reload"   
    MAIN_HOST=$DEFAULT_SITE
    launch_cmd "echo \"127.0.0.1       $DEFAULT_SITE\" >> /etc/hosts"
}



# ************************************************************** #
# Searching for existing user or group in passwd or group file

check_existing_inf() {

    INF=$1
    FILE=$2
    TYPE=$3
    
    egrep "^$INF" $FILE >/dev/null
    if [ $? -eq 0 ]; then
        echo "[INFO] $INF $TYPE allready exists!"
	return 1
    fi
    return 0
}



move_cms_tmp_to_vhost_dir () {
    
    CMS=$1

    launch_cmd "mv $CMS/* $APACHE_WEB_DIR$MAIN_HOST"
    launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
}




# ************************************************************** #
# Download Prestashop v1.5.5.0 and copy file to the vhost dir

install_prestashop() {
    
    show_title "Installing prestashop V1.5.5.0"
    launch_cmd "cd /tmp"
    launch_cmd "wget http://www.prestashop.com/download/prestashop_1.5.5.0.zip"
    launch_cmd "unzip prestashop_1.5.5.0.zip"
    
    move_cms_tmp_to_vhost_dir "prestashop"
}


# ************************************************************** #
# Install Wordpress on the default Vhost Directory

install_wp() {

    show_title "Installing wordpress latest version"
    launch_cmd "cd /tmp"
    launch_cmd "wget http://wordpress.org/latest.tar.gz"
    launch_cmd "tar xvzf latest.tar.gz"
    #launch_cmd "mv wordpress/* $APACHE_WEB_DIR$MAIN_HOST"
    #launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    move_cms_tmp_to_vhost_dir "wordpress"
    
    read -e -p "[WP] Enter your Blog Title:" -i $DEFAULT_SITE BLOG_TITLE
    read -e -p "[WP] Enter your Blog Admin Email:" ADMIN_EMAIL
    read -e -p "[WP] Enter your Blog Admin User:"  ADMIN_USR
    read -s -p "[WP] Enter your Blog Admin Password: " ADMIN_PWD

        
    launch_cmd "cd $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "touch wp-config.php"
    launch_cmd "chmod 777 wp-config.php"    
    launch_cmd "sed  -e \"s/username_here/${MYSQL_USR}/g\"  -e \"s/password_here/${MYSQL_PWD}/g\"   -e \"s/database_name_here/${MYSQL_DB}/g\" wp-config-sample.php > wp-config.php"
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "chmod 755 wp-config.php"
    launch_cmd "curl -d \"weblog_title=$BLOG_TITLE&user_name=$ADMIN_USR&admin_password=$ADMIN_PWD&admin_password2=$ADMIN_PWD&admin_email=$ADMIN_EMAIL\" http://$DEFAULT_SITE/wp-admin/install.php?step=2"
    launch_cmd "rmdir wordpress"
    launch_cmd "rm latest.tar.gz"
    launch_cmd "rm /tmp/wp.keys"
}



# ************************************************************** #
# Create MySQL User needed for the installed CMS

create_mysql_user() {
    
    MYSQL_USR=$1
    MYSQL_DB=$2
    
    read -s -p "Please enter $MYSQL_ADMINISTRATOR_USR MySQL Password: " ADMINISTRATOR_PWD

    # Generate random pwd for the new user
    MYSQL_PWD=$(openssl rand -base64 $PWD_LENGHT)

    launch_cmd "mysql -u $MYSQL_ADMINISTRATOR_USR -p$ADMINISTRATOR_PWD -e \"CREATE DATABASE IF NOT EXISTS $MYSQL_DB; GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO $MYSQL_USR@localhost IDENTIFIED BY '$MYSQL_PWD'\""
    VHOST_CONF="$VHOST_CONF  [MYSQL CREDENTIALS]USER: $MYSQL_USR ___ PASSWORD: $MYSQL_PWD"
}



# ************************************************************** #
# Create FTP User needed for the installed CMS

create_ftp_user() {

    FTP_USR=$1
    DB_NAME=$2
    
    # Try to search ftpgrp or create it
    check_existing_inf $FTP_GRP /etc/group group
    if [ $? -eq 0 ]; then
        echo "[INFO] Creating group $FTP_GRP"
	launch_cmd "addgroup $FTP_GRP"
    fi

    # Try to find ftpusr or create it 
    check_existing_inf $FTP_USR /etc/passwd user 
    if [ $? -eq 0 ]; then
        echo "[INFO] Creating user $FTP_USR"
        PASSWD=$(openssl rand -base64 $PWD_LENGHT)

#        useradd $FTP_USR --ingroup $FTP_GRP --shell /bin/false --home $APACHE_WEB_DIR$DEFAULT_SITE -p $PASSWD
        launch_cmd "useradd $FTP_USR -g $FTP_GRP -d  $APACHE_WEB_DIR$DEFAULT_SITE"
	launch_cmd "echo $FTP_USR:$PASSWD | sudo chpasswd"      
        launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
	VHOST_CONF="$VHOST_CONF  [FTP CREDENTIALS]USER: $FTP_USR ___ PASSWORD: $PASSWD"
    fi
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

while getopts ":H:d:p:u:f:m:l:w:s:h:" opt; do
  case "$opt" in
    H)  HOST="$OPTARG";;
    d)  DOMAINS="$OPTARG";;
    p)  PROJECT="$OPTARG";;
    u)  APACHE_WEB_USR="$OPTARG";;
    f)  FTP_USR="$OPTARG";;
    m)  MYSQL_USR="$OPTARG";;
    l)  PWD_LENGHT="$OPTARG";;
    w)  WP_CREATE=1;;
    s)  PS_CREATE=1;;

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


create_vhost_directories $DOMAINS $PROJECT 

if [ "$FTP_USR" != "" ]; then
    create_ftp_user $FTP_USR
fi
if [ "$MYSQL_USR" != "" ]; then
    create_mysql_user $MYSQL_USR $HOST
fi
if [ "$WP_CREATE" != "" ]; then
    install_wp 
fi
if [ "$PS_CREATE" != "" ]; then
    install_prestashop
fi

echo "create:::$PS_CREATE"
exit
echo $VHOST_CONF