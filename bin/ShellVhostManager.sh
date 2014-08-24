#!/bin/bash

#================================================================================
# ShellVhostManager.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


source $(pwd)"/lib/Utils.sh"
source $(pwd)"/conf.sh"



# ************************************************************** #
# Print help message

function usage () {
    
    echo "Usage: ShellVhostManager.sh -H -p -d -f -m -l -c -v -s -h -t -r -k"
    echo "  -H: Host ."
    echo "  -p: Project name."
    echo "  -d: Domains(fr|com|net)."
    echo "  -f: Ftp User Name (will generate user pwd)"
    echo "  -m: Mysql username (will generate user pwd) DB name will be the host name"
    echo "  -l: Passwords length. (default 10 chars)"
    echo "  -c: CMS/Framework/Repository to install (allowed values are: wordpress, prestashop, sf2, owncloud, seafile, owncloud, import, git, hg, svn)"  
    echo "  -v: CMS/Framework Version (By Default last version is allready set)"
    echo "  -s: Subdomain."
    echo "  -h: Print this Help."
    echo "  -t: Log Type (echo|file) to get silent mode set it to file."
    echo "  -r: Repository to clone (git/hg/svn)."
    echo "  -k: Keep this vhost protected with htaccess/htpasswd (login|passwd)  ."



    exit 1;
}


# ************************************************************** #
# Import project from FTP host/login/pwd => Mysql dump / Apache Vhost / Source download

function install_import() {

    show_title "Importing project from External Host"

    launch_cmd "rm -rf /tmp/import/"
    launch_cmd "mkdir /tmp/import"
    launch_cmd "cd /tmp/import"

    read -e -p "[Import] Enter your Host:" IMPORT_HOST
    read -e -p "[Import] Enter FTP User:"  IMPORT_FTP_USR
    read -s -p "[Import] Enter FTP Password: " IMPORT_FTP_PWD

    launch_cmd "sudo wget -r ftp://$IMPORT_FTP_USR:$IMPORT_FTP_PWD@$IMPORT_HOST   -nH"
    launch_cmd "mysql -u $MYSQL_USR -p$MYSQL_PWD $MYSQL_DB < dump"
    launch_cmd "sudo rm dump"
    launch_cmd "cd /tmp"
    move_cms_tmp_to_vhost_dir "import"
}



# ************************************************************** #
# Create Vhost and Activate it

function create_vhost_conf () {

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
        if [ "$SUBDOMAIN" != "" ]; then
	    SITE="$SUBDOMAIN.$HOST.$i"
            ALIAS="$ALIAS $SITE"
	else
	    SITE="$HOST.$i"
	    ALIAS="$ALIAS $WWW.$SITE $SITE"
	fi
    }

    # Create Default Site web & log directories
    DEFAULT_SITE="$HOST.$1"
    create_dir $APACHE_WEB_DIR$DEFAULT_SITE $APACHE_WEB_USR
    create_dir $APACHE_LOG_DIR$DEFAULT_SITE $APACHE_LOG_USR
   
    if [ "$SUBDOMAIN" != "" ]; then
	create_dir $APACHE_WEB_DIR"/subdomains" $APACHE_WEB_USR
        create_dir $APACHE_WEB_DIR"/subdomains/"$SUBDOMAIN.$HOST.$1 $APACHE_WEB_USR
	create_dir $APACHE_LOG_DIR"/subdomains" $APACHE_LOG_USR
        create_dir $APACHE_LOG_DIR"/subdomains/"$SUBDOMAIN.$HOST.$1 $APACHE_LOG_USR
	APACHE_WEB_DIR=$APACHE_WEB_DIR"subdomains/"
	APACHE_LOG_DIR=$APACHE_LOG_DIR"subdomains/"
        DEFAULT_SITE="$SUBDOMAIN.$HOST.$1"
    fi
    
    launch_cmd "echo \"alias $DEFAULT_SITE='cd $APACHE_WEB_DIR$DEFAULT_SITE'\" >> ~/.bashrc "
    launch_cmd "echo \"alias "$DEFAULT_SITE"_access='tail -f $APACHE_LOG_DIR/$DEFAULT_SITE/access.log'\" >> ~/.bashrc "
    launch_cmd "echo \"alias "$DEFAULT_SITE"_error='tail -f $APACHE_LOG_DIR/$DEFAULT_SITE/error.log'\" >> ~/.bashrc "

    # Create site vhost file
    mylog "[INFO] Creating virtualhost file: $SUBDOMAIN_SITE"    
    
# cat $TEMPLATE_DIR$TPL_FILE | sed "s/\${HOST}/${DEFAULT_SITE}/"  | sed "s|\${ALIAS}|$ALIAS|"  | sed "s|\${APACHE_LOG_DIR}|$APACHE_LOG_DIR|" | 
#sed "s|\${APACHE_WEB_DIR}|${APACHE_WEB_DIR}|"
    cat $TEMPLATE_DIR$TPL_FILE | sed "s/\${HOST}/${DEFAULT_SITE}/"  | sed "s|\${ALIAS}|$ALIAS|" |  sed "s|\${APACHE_LOG_DIR}|$APACHE_LOG_DIR|" | sed "s|\${APACHE_WEB_DIR}|${APACHE_WEB_DIR}|" > "/tmp/${DEFAULT_SITE}"       
    launch_cmd "mv /tmp/${DEFAULT_SITE} /etc/apache2/sites-available/${DEFAULT_SITE}"
    launch_cmd "a2ensite $DEFAULT_SITE"
    launch_cmd "/etc/init.d/apache2 reload"   
    MAIN_HOST=$DEFAULT_SITE

    check_existing_inf $HOST /etc/hosts hostredirection
    if [ $? -eq 0 ]; then
        mylog "[INFO] Adding $DEFAULT_SITE to /etc/hosts"
	launch_cmd "echo \"127.0.0.1       $DEFAULT_SITE\" >> /etc/hosts"
    fi
}


function create_logrotate_conf()
{
    cat $TEMPLATE_DIR"logrotate.tpl" | sed "s/\${HOST}/${DEFAULT_SITE}/" | sed "s|\${APACHE_LOG_DIR}|$APACHE_LOG_DIR|"   > "/tmp/logrotate${DEFAULT_SITE}"
    launch_cmd "mv /tmp/logrotate${DEFAULT_SITE} /etc/logrotate.d/${DEFAULT_SITE}"
    launch_cmd "logrotate -f  /etc/logrotate.conf"
    
}




function move_cms_tmp_to_vhost_dir () 
{    
    CMS=$1

    launch_cmd "sudo cp -R $CMS/* $APACHE_WEB_DIR$MAIN_HOST"
    launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$MAIN_HOST"
}




function get_last_version() 
{    
    CMS_UPPER=${CMS^^}        
    if [ $CMS_VERSION == "LASTVERSION" ]; then
	DOWNLOAD_CMS_VERSION_VAR=$CMS_UPPER"_LASTVERSION"
	eval CMS_VERSION=\$$DOWNLOAD_CMS_VERSION_VAR
    fi
}


function install_git()
{
    launch_cmd "cd $APACHE_WEB_DIR$MAIN_HOST"
    launch_cmd "git clone $REPOSITORY ."
    launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$MAIN_HOST"
}


function install_hg()
{
    launch_cmd "cd $APACHE_WEB_DIR$MAIN_HOST"
    launch_cmd "hg clone $REPOSITORY ."
    launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$MAIN_HOST"
}

function install_svn()
{
    launch_cmd "cd $APACHE_WEB_DIR$MAIN_HOST"
    launch_cmd "svn checkout $REPOSITORY ."
    launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$MAIN_HOST"
}


function install_seafile() 
{

    get_last_version
    show_title "Installing Seafile V"$CMS_VERSION
    launch_cmd "cd /tmp"

    SEAFILE_ARCHI="i386"
    ARCHI=$(uname -m)
    if [ $ARCHI == "x86_64" ]; then
	SEAFILE_ARCHI="x86-64"
    fi  
    launch_cmd "wget -O seafile.tgz http://seafile.googlecode.com/files/seafile-server_"$CMS_VERSION"_"$SEAFILE_ARCHI".tar.gz"
    launch_cmd "tar xvzf seafile.tgz  > /dev/null"
    move_cms_tmp_to_vhost_dir "seafile-server-"$CMS_VERSION
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "sudo apt-get -y install python2.7 python-setuptools python-simplejson python-imaging sqlite3 python-mysqldb" 
}

function install_owncloud() 
{
    get_last_version
    show_title "Installing OwnCloud V"$CMS_VERSION
    launch_cmd "cd /tmp"
    launch_cmd "wget -O owncloud.tar.bz2 http://download.owncloud.org/community/owncloud-"$CMS_VERSION".tar.bz2"
    launch_cmd "tar xjf owncloud.tar.bz2  > /dev/null"
    move_cms_tmp_to_vhost_dir "owncloud"
    launch_cmd "sudo apt-get install apache2 php5 php5-gd php-xml-parser php5-intl"
    launch_cmd "sudo apt-get install php5-sqlite php5-mysql smbclient curl libcurl3 php5-curl"
#    launch_cmd "sudo chown ww-data:www-data "$APACHE_WEB_DIR$DEFAULT_SITE"/install/data"
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "chown -R $APACHE_WEB_USR $APACHE_WEB_DIR$DEFAULT_SITE/config"
    launch_cmd "chown -R $APACHE_WEB_USR $APACHE_WEB_DIR$DEFAULT_SITE/apps"
    create_dir $APACHE_WEB_DIR$DEFAULT_SITE"/data" $APACHE_WEB_USR
}


function install_sf2() 
{
    get_last_version
    show_title "Installing Symfony2 V"$CMS_VERSION
    launch_cmd "cd /tmp"
    launch_cmd "wget -O symfony2.tgz http://symfony.com/download?v=Symfony_Standard_Vendors_"$CMS_VERSION".tgz"
    launch_cmd "tar xvzf symfony2.tgz > /dev/null"
    move_cms_tmp_to_vhost_dir "Symfony"
    launch_cmd "sudo chmod 777 "$APACHE_WEB_DIR$DEFAULT_SITE"/app/cache/"
    launch_cmd "sudo chmod 777 "$APACHE_WEB_DIR$DEFAULT_SITE"/app/logs/"
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
}


# ************************************************************** #
# Download Prestashop v1.5.5.0 and copy file to the vhost dir

function install_prestashop() 
{    
    get_last_version
    show_title "Installing prestashop V"$CMS_VERSION
    launch_cmd "cd /tmp"
    launch_cmd "wget http://www.prestashop.com/download/prestashop_"$CMS_VERSION".zip"
    launch_cmd "unzip prestashop_"$CMS_VERSION".zip > /dev/null"    
    move_cms_tmp_to_vhost_dir "prestashop"
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/config/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/cache/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/log/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/img/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/mails/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/modules/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/themes/default/lang/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/themes/default/cache/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/translations/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/upload/"
    launch_cmd "chmod -R 777 $APACHE_WEB_DIR$DEFAULT_SITE/download/"

}


# ************************************************************** #
# Install Wordpress on the default Vhost Directory

function install_wordpress() 
{
    get_last_version

    if [ $CMS_VERSION != 'latest' ]; then
	CMS_VERSION="wordpress-"$CMS_VERSION
    fi

    
    show_title "Installing wordpress V"$CMS_VERSION
    launch_cmd "cd /tmp"
    launch_cmd "wget http://wordpress.org/"$CMS_VERSION".tar.gz"
    launch_cmd "tar xvzf "$CMS_VERSION".tar.gz > /dev/null"
    #launch_cmd "mv wordpress/* $APACHE_WEB_DIR$MAIN_HOST"
    #launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    move_cms_tmp_to_vhost_dir "wordpress"

    read -e -p "[WP] Enter your Blog Title:"  BLOG_TITLE
    read -e -p "[WP] Enter your Blog Admin Email:" ADMIN_EMAIL
    read -e -p "[WP] Enter your Blog Admin User:"  ADMIN_USR
    read -s -p "[WP] Enter your Blog Admin Password: " ADMIN_PWD

    MYSQL_DB_CLEAN=$(clean_string $MYSQL_DB)
        
    launch_cmd "cd $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "touch wp-config.php"
    launch_cmd "chmod 777 wp-config.php"    
    launch_cmd "sed  -e \"s/username_here/${MYSQL_USR}/g\"  -e \"s/password_here/${MYSQL_PWD}/g\"   -e \"s/database_name_here/${MYSQL_DB_CLEAN}/g\" wp-config-sample.php > wp-config.php"
    launch_cmd "chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
    launch_cmd "chmod 755 wp-config.php"
    launch_cmd "curl -d \"weblog_title=$BLOG_TITLE&user_name=$ADMIN_USR&admin_password=$ADMIN_PWD&admin_password2=$ADMIN_PWD&admin_email=$ADMIN_EMAIL\" http://$DEFAULT_SITE/wp-admin/install.php?step=2"
    launch_cmd "cd /tmp/"
    launch_cmd "rmdir wordpress"
    launch_cmd "rm latest.tar.gz"
    launch_cmd "rm /tmp/wp.keys"
}


function clean_string() 
{    
    CLEAN_STR=${1/ //}
    CLEAN_STR=${CLEAN_STR/_//}
    CLEAN_STR=${CLEAN_STR/-//}
    CLEAN_STR=${CLEAN_STR//[^a-zA-Z0-9]/}
    echo $CLEAN_STR
}



# ************************************************************** #
# Create MySQL User needed for the installed CMS

function create_mysql_user() 
{    
    MYSQL_USR=$1
    MYSQL_DB=$2
    
    MYSQL_DB_CLEAN=$(clean_string $MYSQL_DB) 
    # Generate random pwd for the new user
    MYSQL_PWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $PWD_LENGHT | head -n 1)

    launch_cmd "mysql -u $MYSQL_ADMINISTRATOR_USR -p$MYSQL_ADMINISTRATOR_PWD -e \"CREATE DATABASE IF NOT EXISTS $MYSQL_DB_CLEAN; GRANT ALL PRIVILEGES ON $MYSQL_DB_CLEAN.* TO $MYSQL_USR@localhost IDENTIFIED BY '$MYSQL_PWD'\" "
    echo -e "******************************************" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
    echo -e "[MYSQL CREDENTIALS]" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
    echo -e "DB: '$MYSQL_DB_CLEAN'" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
    echo -e "USER: '$MYSQL_USR'" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
    echo -e "PASSWORD: '$MYSQL_PWD'\n" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
}



# ************************************************************** #
# Create FTP User needed for the installed CMS

function create_ftp_user() 
{
    FTP_USR=$1
    DB_NAME=$2
    
    # Try to search ftpgrp or create it
    check_existing_inf $FTP_GRP /etc/group group
    if [ $? -eq 0 ]; then
        mylog "[INFO] Creating group $FTP_GRP"
	launch_cmd "addgroup $FTP_GRP"
    fi


    
    # Try to find ftpusr or create it 
    check_existing_inf $FTP_USR /etc/passwd user 

    if [ $? -eq 0 ]; then
        mylog "[INFO] Creating user $FTP_USR"
        PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $PWD_LENGHT | head -n 1) 

#        useradd $FTP_USR --ingroup $FTP_GRP --shell /bin/false --home $APACHE_WEB_DIR$DEFAULT_SITE -p $PASSWD
        launch_cmd "useradd $FTP_USR -g $FTP_GRP -d $APACHE_WEB_DIR$DEFAULT_SITE -s /bin/false"
	launch_cmd "echo $FTP_USR:$PASSWD | sudo chpasswd"      
        launch_cmd "sudo chown -R $FTP_USR:$FTP_GRP $APACHE_WEB_DIR$DEFAULT_SITE"
	echo -e "******************************************" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
	echo -e "[FTP CREDENTIALS]" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
        echo -e "USER: '$FTP_USR'" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
	echo -e "PASSWORD: '$PASSWD'\n" >> "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
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
  echo "You must start this under your regular user account (not root) using sudo."
  echo "Rerun using: sudo $0 $*"
  exit 1
fi


function lamp_init()
{
    launch_cmd "sudo apt-get -y install lamp-server^"
    launch_cmd "sudo apt-get -y install proftpd"
    launch_cmd "sudo apt-get -y install logrotate"
}


while [[ $1 == -* ]]; do
    case "$1" in
      -H|--host|-\?) if (($# > 1)); then
            HOST=$2; shift 2
          else 
            echo "--host requires an argument" 1>&2
            exit 1
      fi ;;
      -d|--domains|-\?) if (($# > 1)); then
            DOMAINS=$2; shift 2
          else
            echo "--domains requires an argument" 1>&2
            exit 1
      fi ;;
      -p|--project|-\?) if (($# > 1)); then
            PROJECT=$2; shift 2
          else
            echo "--project requires an argument" 1>&2
            exit 1
      fi ;;
      -f|--ftpuser|-\?) if (($# > 1)); then
           FTP_USR=$2; shift 2
        else
           echo "--ftpuser requires an argument" 1>&2
           exit 1
      fi ;;
      -m|--mysqluser|-\?) if (($# > 1)); then
           MYSQL_USR=$2; shift 2
        else
           echo "--mysqluser requires an argument" 1>&2
           exit 1
      fi ;;
      --passwordlenght|-\?) if (($# > 1)); then
           PWD_LENGHT=$2; shift 2
        else
           echo "--passwordlenght requires an argument" 1>&2
           exit 1
      fi ;;
      -c|--cms|-\?) if (($# > 1)); then
           CMS=$2; shift 2
        else
           echo "--cms requires an argument" 1>&2
           exit 1
      fi ;;
      -v|--cmsversion|-\?) if (($# > 1)); then
           CMS_VERSION=$2; shift 2
        else
           echo "--cmsversion requires an argument" 1>&2
           exit 1
      fi ;;
      -s|--subdomain|-\?) if (($# > 1)); then
           SUBDOMAIN=$2; shift 2
        else
           echo "--subdomain requires an argument" 1>&2
           exit 1
      fi ;;
      -t|--logtype|-\?) if (($# > 1)); then
           LOG_TYPE=$2; shift 2
        else
           echo "--logtype requires an argument" 1>&2
           exit 1
      fi ;;
      -r|--repository|-\?) if (($# > 1)); then
            REPOSITORY=$2; shift 2
          else
            echo "--respository requires an argument" 1>&2
            exit 1
      fi ;;
      
      -k|--keep-private|-\?) if (($# > 1)); then
            HTACCESS_CONFIG=$2; shift 2
          else
            echo "--keep-private requires an argument" 1>&2
            exit 1
      fi ;;

      --lampinit|-\?) lamp_init; exit 0 ;; 
      -h|--help|-\?) usage; exit 0;;
      --) shift; break;;
      -*) echo "invalid option: $1" 1>&2; usage; exit 1;;
    esac
done


if [ $CMS == "sf2" ]; then
    TPL_FILE="vhost_sf2.tpl"
fi
create_vhost_conf $DOMAINS $PROJECT 
create_logrotate_conf
echo -e "--------------- CONFIG FILE FOR HOST $DEFAULT_SITE --------------\n\n" > "$CONFIG_DIR/"$DEFAULT_SITE"_conf"
if [ "$FTP_USR" != "" ]; then
    create_ftp_user $FTP_USR
fi

if [ "$MYSQL_USR" != "" ]; then
    create_mysql_user $MYSQL_USR $HOST
fi

if [ "$MYSQL_USR" != "" ] && [ $CMS != "" ]; then
    launch_cmd "install_$CMS"
fi

  # Generate Htaccess/Htpasswd file to protect the current vhost                                                                             
if [ "$HTACCESS_CONFIG" != "" ]; then
    IFS='|' read -a login_pwd <<< "${HTACCESS_CONFIG}"
    output=$(htpasswd -nb ${login_pwd[0]} ${login_pwd[1]})
    echo $output > $APACHE_WEB_DIR$DEFAULT_SITE"/.htpasswd"
    echo -e "AuthType Basic\nAuthName \"Accès privé projet\"\nAuthUserFile "$APACHE_WEB_DIR$DEFAULT_SITE"/.htpasswd\nRequire valid-user" > $APACHE_WEB_DIR$DEFAULT_SITE"/.htaccess"
fi


launch_cmd "cd && source .bashrc"
