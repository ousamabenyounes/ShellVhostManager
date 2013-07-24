<VirtualHost *:80>
        ServerName ${HOST}
        DocumentRoot ${ROOTDIR}${HOST}
        
        ErrorLog ${APACHE_LOG_DIR}${HOST}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}${HOST}access.log combined
</VirtualHost>
