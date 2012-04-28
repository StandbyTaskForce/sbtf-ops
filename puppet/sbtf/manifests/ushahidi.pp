# vim: filetype=puppet
# Sets up environment for running ushahidi

class sbtf::ushahidi inherits sbtf::base {
    Package {
        ensure  => installed,
        require => Bulkpackage["web-packages"],
    }

    $web_packages = [
        "nginx",
        "php5-cgi",
        "php5-mysql",
        "php5-mcrypt",
        "php5-curl",
        "php5-imap",
        "php5-gd",
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
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        content => template("sbtf/nginx/nginx.conf.erb"),
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    file { "/etc/nginx/sites-enabled/default":
        ensure  => "absent",
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    file { "/etc/nginx/sites-enabled/ushahidi":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        content => template("sbtf/nginx/ushahidi.erb"),
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    file { "/etc/nginx/conf.d/ushahidi-hostname":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        require => Package["nginx"],
        notify  => Service["nginx"],
    }

    file { "/etc/init.d/php":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 755,
        content => template("sbtf/ushahidi/init.d-php.erb"),
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
        content => template("sbtf/ushahidi/config.php.erb"),
        require => Exec["checkout_ushahidi"],
    }

    file { "/home/sbtf/ushahidi/application/config/database.php":
        ensure  => "present",
        owner   => "sbtf",
        group   => "sbtf",
        mode    => 644,
        content => template("sbtf/ushahidi/database.php.erb"),
        require => Exec["checkout_ushahidi"],
    }

    file {[
        "/home/sbtf/ushahidi/application/cache",
        "/home/sbtf/ushahidi/application/logs",
        "/home/sbtf/ushahidi/media/uploads",
        ]:
        ensure  => "directory",
        owner   => "www-data",
        group   => "sbtf",
        mode    => 750,
        require => Exec["checkout_ushahidi"],
    }

    file { "/etc/cron.d/ushahidi":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        content => template("sbtf/ushahidi/cron.erb"),
    }

    # MySQL
    $mysql_packages = [
        "mysql-server",
    ]

    bulkpackage { "mysql-packages":
        packages => $mysql_packages,
        require  => Class["apt-setup"],
    }

    package { $mysql_packages: }

    service { "mysql":
        ensure  => running,
        require => Package["mysql-server"],
    }

    $dbname = 'ushahidi'
    exec { "create-${dbname}-db":
        unless => "/usr/bin/mysql -uroot ${dbname}",
        command => "/usr/bin/mysql -uroot -e \"create database ${dbname}; grant all on ${dbname}.* to ushahidi@localhost identified by 'cheese';\"",
        require => Service["mysql"],
    }

    exec { "install-ush-db":
        command => "/usr/bin/mysql -uushahidi -pcheese ushahidi < /home/sbtf/ushahidi/sql/ushahidi.sql",
        require => [ Exec["create-${dbname}-db"], Exec["checkout_ushahidi"] ],
        unless => "/usr/bin/mysql -uushahidi -pcheese ushahidi -e 'select * from settings'",
    }

}
