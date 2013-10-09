#__DIR__="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#================================================================================
# Utils.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


# ************************************************************** #
# Create a directory 

create_dir () {
    DIR=$1
    USER_GROUP=$2
    
    if [ -d "$DIR" ]; then
	echo "[INFO] Directory allready exists: $DIR"
    else
        echo "[INFO] Creating directory: $DIR"
        launch_cmd "mkdir -p $DIR"
	launch_cmd "chown -R $USER_GROUP $DIR"	
    fi
}



# ************************************************************** #
# Show given title

show_title () {
    
    TITLE=$1
    echo "--------------------------------------------"
    echo "INFO $TITLE"

}



# ************************************************************** #
# Check if user is allowed to use this script

check_sudo () {
    CMD=$1
    
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
}


# ************************************************************** #
# Check if user is allowed to use this script

launch_cmd () {

    CMD=$1   
    echo "[INFO] cmd => $CMD"
    eval $CMD
    retval=$?    
    if [ $retval -ne 0 ]; then
        echo "[Error] failed. Exiting..."
        exit $retval
    fi
}



