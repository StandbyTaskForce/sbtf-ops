# vim: filetype=puppet
# Sets up MySQL

class sbtf::mysql inherits sbtf::base {
    Package {
        ensure  => installed,
        require => Bulkpackage["web-packages"],
    }

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
        require => Exec["create-${dbname}-db"],
        unless => "/usr/bin/mysql -uushahidi -pcheese ushahidi -e 'select * from settings'",
    }
}

