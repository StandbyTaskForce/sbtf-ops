# vim: filetype=puppet
# Sets up environment for running ushahidi

class sbtf::ushahidi inherits sbtf::base {
    Package {
        ensure  => installed,
        require => Bulkpackage["web-packages"],
    }

    $web_packages = [
        "nginx",
        "php5-fpm",
        "php5-mysql",
        "php5-mcrypt",
        "php5-curl",
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

    # TODO will need to make an intelligent decision about server name
    file { "/etc/nginx/sites-enabled/ushahidi":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        content => template("sbtf/nginx/ushahidi.erb"),
        require => Package["nginx"],
        notify  => Service["nginx"], # TODO check this causes a reload only if changed
    }

    file { "/etc/init.d/php5-fpm":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 755,
        require => Package["php5-fpm"],
        notify => Service["php5-fpm"],
    }

    service { "php":
        ensure  => running,
        require => [ File["/etc/init.d/php5-fpm"], Package["php5-fpm"] ],
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

    file {[
        "/home/sbtf/ushahidi/application/cache",
        "/home/sbtf/ushahidi/application/logs",
        "/home/sbtf/ushahidi/media/uploads",
        ]:
        ensure  => "directory",
        owner   => "www-data",
        group   => "www-data",
        mode    => 600,
        require => Exec["checkout_ushahidi"],
    }

    file { "/etc/cron.d/ushahidi":
        ensure  => "present",
        owner   => "root",
        group   => "root",
        mode    => 644,
        content => template("sbtf/ushahidi/cron.erb"),
    }

}
