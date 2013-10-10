ShellVhostManager
=================

This shell script helps you managing LAMP basic needs (virtualHost, Ftp users, Mysql Database)


Usage: ShellVhostManager.sh -H -d -p -f -m -l -c -v -h
  -H: Host .
  -p: Project name.
  -d: Domains(fr|com|net).
  -h: Print this Help.
  -f: Ftp User Name (will generate user pwd)
  -m: Mysql username (will generate user pwd) DB name will be the host name
  -l: Passwords length. (default 10 chars)
  -c: CMS/Framework to install (allowed values are: wordpress, prestashop, sf2)
  -v: CMS/Framework Version (By Default last version is allready set)



$ ShellVhostManager.sh -p projectname -H api.projectname -d "fr|com|tk" -u "www-data:www-data" 

First This will create "/var/www/projectname/api.projectname" directory (also create log directories)

Then the apache virutalHost is created and enable (a2ensite).
Apache is restarted.


#Todo
Check /etc/hosts content before updating
Add dynamic log rotate
Subdomains creation
Dynamic shell library path including
Vhost BackUp commands 
Add docker & configure it to a real project isolation (security, light backup...) 
