#__DIR__="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#================================================================================
# Utils.sh

# by Ben Younes Ousama <benyounes.ousama@gmail.com>
#================================================================================


declare -r TRUE=0
declare -r FALSE=1


##################################################################
# Purpose: Create a directory
# Arguments:
#   $1 (DIR) -> Directory you want to create
#   $1 (USER_GROUP) -> User Group of the new directory
##################################################################
function create_dir() 
{
    DIR=$1
    USER_GROUP=$2
    
    if [ -d "$DIR" ]; then
	mylog "[INFO] Directory allready exists: $DIR"
    else
        mylog "[INFO] Creating directory: $DIR"
        launch_cmd "mkdir -p $DIR"
	launch_cmd "chown -R $USER_GROUP $DIR"	
    fi
}


##################################################################                                                                                                                                           
# Purpose: Log or simply Echo information                                                                                                                                                                                  
# Arguments:                                                                                                                                                                                                 
#   $1 (INFO) -> String to print                                                                                                                                                                            
##################################################################                                                                                                                                           
function mylog()
{
    local INFO=$1
    
    if  [ $LOG_TYPE == 'echo' ]; then
	echo $INFO
    else
	echo -e $INFO >> "$LOG_DIR/"$HOST
    fi

}



##################################################################
# Purpose: Show given title
# Arguments:
#   $1 (TITLE) -> String to print
##################################################################
function show_title() 
{    
    local TITLE=$1
    mylog "--------------------------------------------"
    mylog "$TITLE"
}


##################################################################
# Purpose: Check if user is allow to use this script
# Arguments:
#   $1 -> String to convert to lower case
##################################################################
function check_sudo () 
{
    local CMD=$1    
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
}


##################################################################
# Purpose: Launch given command, print it or exit if error occurs
# Arguments:
#   $1 (CMD) -> the given command 
##################################################################
function launch_cmd() 
{
    local CMD=$1   
    mylog "[INFO] cmd => $CMD"
    eval $CMD
    retval=$?    
    if [ $retval -ne 0 ]; then
        mylog "[Error] failed. Exiting..."
        exit $retval
    fi
}


##################################################################
# Purpose: Return true $INF exits in $FILE
# Arguments: 
#   $1 (INF) -> The searched term
#   $2 (FILE) -> The file where we need to search
#   $3 (TYPE) -> The object type (group, user, hostile 
# Return: True or False
##################################################################
function check_existing_inf() 
{
    local INF="$1"
    local FILE="$2"
  
    grep -q "^${INF}" $FILE && return 1 || return 0
}
