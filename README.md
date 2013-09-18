LampBasicsManager
=================

This script helps you managing LAMP basic needs (virtualHost, Ftp users, Mysql Database)


Usage: LampBasicsManager.sh -H -p -d -h -u
  -H: Host .
  -p: Project name. (if you want to group others host on the same project directory)
  -d: Domains(fr|com|net). (it activates aliases)
  -u: User:Group apache owner (If you need to do a chown after vhost creation)
  -h: Print this Help.



$ LampBasicsManager.sh -p projectname -H api.projectname -d "fr|com|tk" -u "www-data:www-data" 

First This will create "/var/www/projectname/api.projectname" directory (also create log directories)

Then the apache virutalHost is created and enable (a2ensite).
Apache is restarted.


#Todo
Ftp Users & Database user creation 
