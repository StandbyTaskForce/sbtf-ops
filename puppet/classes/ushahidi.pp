# vim: filetype=puppet
# Sets up environment for running ushahidi

class ushahidi inherits base {
    Package {
        ensure  => installed,
        require => Bulkpackage["web-packages"],
    }

    $web_packages = [
        "nginx",
        "php5-cgi",
    ]

    bulkpackage { "web-packages":
        packages => $web_packages,
        require  => Class["apt-setup"],
    }

    package { $web_packages: }

    # nginx
    service { "nginx":
        ensure  => running,
        require => Package["nginx"],
    }

    # TODO check whether there's hasreload/standard puppet stuff can trigger reloads
    exec { "nginx-reload":
        command     => "service nginx reload",
        refreshonly => true,
    }

    file { "/etc/nginx/nginx.conf":
        ensure => "present",
        owner  => "root",
        group  => "root",
        mode   => 644,
        content => "# WARNING: managed by puppet!
user www-data;

error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format detailed
            '\$remote_ip - \$remote_user [\$time_local] '
            '\"\$request\" \$status \$body_bytes_sent '
            '\"\$http_referer\" \"\$http_user_agent\" \$request_time'
    ;

    include /etc/nginx/mime.types;
    access_log /var/log/nginx/access.log;

    sendfile on;

    keepalive_timeout 65;
    tcp_nodelay on;

    server_tokens off;

    gzip on;
    gzip_disable \"MSIE [1-6]\\.(?!.*SV1)\";
    gzip_types text/css application/x-javascript;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
",
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    file { "/etc/nginx/sites-enabled/default":
        ensure  => "absent",
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    # TODO will need to make an intelligent decision about server name
    file { "/etc/nginx/sites-enabled/ushahidi":
        ensure => "present",
        owner  => "root",
        group  => "root",
        mode   => 644,
        content => "# WARNING: managed by puppet!
# Ushahidi nginx server configuration
server {
    listen 80 default;
    root /home/sbtf/ushahidi;
    index index.php;

    client_max_body_size 20m;
    client_body_buffer_size 8192k;

    set \$remote_ip \$remote_addr;
    if ( \$http_x_real_ip ) {
            set \$remote_ip \$http_x_real_ip;
    }

    access_log  /var/log/nginx/ushahidi.access.log detailed;

    location / {
        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
        expires 3d;
    }

    location ~ \\.php$ {
        fastcgi_intercept_errors on;

        fastcgi_read_timeout 120;
        fastcgi_send_timeout 120;

        include fastcgi_params;
        #fastcgi_param SCRIPT_NAME '';
        #fastcgi_param PATH_INFO \$fastcgi_script_name;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}
",
        require => Package["nginx"],
        notify  => Service["nginx"], # TODO check this causes a reload only if changed
    }

    file { "/etc/init.d/php":
        ensure => "present",
        owner  => "root",
        group  => "root",
        mode   => 755,
        content => "#! /bin/sh
# WARNING: managed by puppet!

### BEGIN INIT INFO
# Provides:          php
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the php fastcgi server
# Description:       starts php using start-stop-daemon
### END INIT INFO

BIND=127.0.0.1:9000
USER=www-data
PHP_FCGI_CHILDREN=5
PHP_FCGI_MAX_REQUESTS=1000

PHP_CGI=/usr/bin/php-cgi
PHP_CGI_NAME=`basename \$PHP_CGI`
PHP_CGI_ARGS=\"- USER=\$USER PATH=/usr/bin PHP_FCGI_CHILDREN=\$PHP_FCGI_CHILDREN PHP_FCGI_MAX_REQUESTS=\$PHP_FCGI_MAX_REQUESTS \$PHP_CGI -b \$BIND\"
RETVAL=0

start() {
      echo -n \"Starting PHP FastCGI: \"
      start-stop-daemon --quiet --start --background --chuid \"\$USER\" --exec /usr/bin/env -- \$PHP_CGI_ARGS
      RETVAL=$?
      echo \"\$PHP_CGI_NAME.\"
}
stop() {
      echo -n \"Stopping PHP FastCGI: \"
      killall -q -w -u \$USER \$PHP_CGI
      RETVAL=$?
      echo \"\$PHP_CGI_NAME.\"
}

case \"\$1\" in
    start)
      start
  ;;
    stop)
      stop
  ;;
    restart)
      stop
      start
  ;;
    *)
      echo \"Usage: php-fastcgi {start|stop|restart}\"
      exit 1
  ;;
esac
exit \$RETVAL
",
    }

    service { "php":
        ensure  => running,
        require => [ File["/etc/init.d/php"], Package["php5-cgi"] ],
    }


    # Ushahidi
    exec { "checkout_ushahidi":
        command => "git clone git://github.com/StandbyTaskForce/Ushahidi_Web.git ushahidi",
        cwd     => "/home/sbtf",
        creates => "/home/sbtf/ushahidi",
        user    => "sbtf",
        group   => "sbtf",
    }

    file { "/home/sbtf/ushahidi/application/config/config.php":
        ensure  => "present",
        owner   => "sbtf",
        group   => "sbtf",
        mode    => 644,
        content => "<?php defined('SYSPATH') or die('No direct script access.');
// WARNING: managed by puppet!

\$config['site_domain'] = 'http://dev.standbytaskforce.com/';
\$config['site_protocol'] = 'http';
\$config['index_page'] = 'index.php';
\$config['url_suffix'] = '';
\$config['internal_cache'] = TRUE;
\$config['output_compression'] = FALSE;
\$config['global_xss_filtering'] = TRUE;
\$config['enable_hooks'] = TRUE;

\$config['log_threshold'] = 3;
\$config['log_directory'] = APPPATH.'logs';
if (@!is_writable(\$config['log_directory'])) {
        \$config['log_threshold'] = 0;
}
\$config['display_errors'] = TRUE;
\$config['render_stats'] = TRUE;
\
\$config['enable_mhi'] = FALSE;
\$config['extension_prefix'] = 'MY_';
\$config['modules'] = array
(
        MODPATH.'auth',      // Authentication
        // MODPATH.'forge',     // Form generation
        // MODPATH.'formation',     // Form generation
        // MODPATH.'kodoc',     // Self-generating documentation
        // MODPATH.'media',     // Media caching and compression
        // MODPATH.'archive',   // Archive utility
        // MODPATH.'unit_test', // Unit testing
);
",
        require => Exec["checkout_ushahidi"],
    }

}
