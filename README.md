ShellVhostManager
=================

This shell script helps you managing LAMP basic needs (virtualHost, Ftp users, Mysql Database)
You have a linux server, and you always lose time configuring your websites, downloading last cms versions, installing mysql databases...
This script will help you earn time and let you focus on managing your contents.

This shell script was developped & tested on an Ubuntu 12.10 

Configuration
=================

First, rename conf.sh.dist to conf.sh  
And then you must just specify your mysql administrator login & password.  


Usage
=================

<pre>ShellVhostManager.sh -H -d -p -f -m -l -c -v -s -h  
  -H: Host .  
  -p: Project name.  
  -d: Domains(fr|com|net).  
  -f: Ftp User Name (will generate user pwd)  
  -m: Mysql username (will generate user pwd) DB name will be the host name  
  -l: Passwords length. (default 10 chars)  
  -c: CMS/Framework to install (allowed values are: wordpress, prestashop, sf2, import)  
  -v: CMS/Framework Version (By Default last version is allready set)  
  -s: Subdomain.  
  -h: Print this Help.  
</pre>

Sample
=================



    $ ./bin/ShellVhostManager.sh -p myprojects -H prestashop -d "fr|com|tk" -f ous -c prestashop -m ous

- First This will create web root directory (/var/www/myprojects/prestashop.fr/
- Create log directory & files (/var/log/apache2/myprojects/prestashop.fr/error.log & access.log
- Create FTP user: ous:ftpgroup with home directory => previous created web root dir
- Create MySQL config: database=prestashop User=ous Pwd=generatedPasswd
- Create Vhost: /etc/apache2/site-available/prestashop.fr from a vhost template  
Also added aliases for the given extentions: fr & com & tk  
Enable the vhost & reload apache 
- Add "127.0.0.1 prestashop.fr" on your /etc/hosts file
- Download last version of prestashop and install it on your web root directory (chown with the ftp user)

If you choose option "-c import ", you'll be asked your FTP host:login:pwd and it will download all available files
You must set a dump file of your mysql database, so it will install it with the previously created mysql user

Here is the Generated VHOST content:


    <VirtualHost *:80>
        ServerName prestashop.fr
        ServerAlias  www.prestashop.fr prestashop.fr www.prestashop.com prestashop.com www.prestashop.tk prestashop.tk
        DocumentRoot /var/www/myprojects/prestashop.fr
        
        ErrorLog /var/log/apache2/myprojects/prestashop.fr/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog /var/log/apache2/myprojects/prestashop.fr/access.log combined
    </VirtualHost>


#Requirements

- proftpd => apt-get install proftpd 
- logrotate => apt-get install logrotate
- Lamp Basics (Apache, MySql, Php)
  
#Todo
- Add others web project content:  
 Cloud opensource project (owncloud or seafile...)  
 Git clone repository  
- Fix Linux compatibility issues (apache home directory, log change...)  
- Add Nginx feature (asked by Melvyn)  
- Check /etc/hosts content before updating  
- Dynamic shell library path including  
- Vhost BackUp commands  
- Add docker & configure it to a real project isolation (security, light backup...)  
- Add Verbose or silent mode  
- Study capifony integration (asked by rocky)  
- Add shell alis ton easily move to the created vhost directory  
- Publish a video & a blog article to present some real sample  
