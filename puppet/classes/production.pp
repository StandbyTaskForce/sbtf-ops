# vim: filetype=puppet
# "production" environment setup

class production {
    file { "/etc/hosts":
        ensure  => "present",
        content => "# WARNING: managed by puppet!
127.0.0.1       localhost localhost.localdomain\n",
        owner   => "root",
        group   => "root",
        mode    => "644",
    }

    server_user { "sbtf":
        uid      => 5555,
        fullname => "SBTF System User",
        password => "locked",
    }

    file { "/home/sbtf/.ssh/known_hosts":
        ensure  => present,
        content => "github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==\n",
        owner   => "sbtf",
        group   => "sbtf",
        mode    => 644,
        require => User["sbtf"],
    }

    # Admittedly, this doesn't really grant much security, the sbtf user could
    # change the contents of this file to whatever they wanted.
    file { "/etc/sudoers.d/sbtf":
        ensure  => present,
        content => "# WARNING: managed by puppet!
sbtf   ALL=NOPASSWD: /home/sbtf/sbtf/bin/sbtf-update.sh\n",
        owner   => "root",
        group   => "root",
        mode    => 440,
    }

    # SSH
    package { "ssh":
        ensure  => latest,
        require => Class["apt-setup"],
    }

    service { "ssh":
        hasrestart => true,
        ensure     => "running",
        require    => Package["ssh"],
    }

    augeas { "sshd_config":
        context => "/files/etc/ssh/sshd_config",
        changes => [
            "set PasswordAuthentication no",
            "set ChallengeResponseAuthentication no",
            "set PermitRootLogin no",
            "set ListenAddress 0.0.0.0",
            "set Port 22",
        ],
        notify  => Service["ssh"],
        require => Package["ssh"],
    }

    # NTP
    package { "ntp":
        ensure  => latest,
        require => Class["apt-setup"],
    }

    service { "ntp":
        ensure  => "running",
        require => Package["ntp"],
    }


    # Developer/admin accounts here

    server_user { "nigel":
            uid             => 2000,
            fullname        => "Nigel McNie",
            password        => '$6$pZA7NlIv$EJr6uSwptv2UziF504E2lJx34MSifJGK4EE8qk9xyExXyP7Dso3NNcphwTpDaWKbDpWezIp8eLxlWuagxJqBM0',
            groups          => [ "sbtf", "admin" ],
            authorized_keys => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApFJAa4+l7bQRIAhFx/Y60ozZm2e7qZwCY5TQsw9NYBgGtNVKqMVmEw6l7XMzs9KcPl4lozMZuQbJtKq8voP/e0PIuij4a4E3Qr3QZwAKVc++v8y/uLym/A1yzJps72QtguynOrDP1GLguR1igsTbWFoU9leG6Wo/ROieFNVJ6bQ4bOPvTZKc0vQZzK+HOpBaMOnvPK9eeHDluQK3MSObU3IJcRvH/838nzT1CP4YU8oqDnpWvd6o9jEcVzbyD3l7SKNBmKulwTQnNC7aDN0j+/LCj+nOhFtPkKTnQSsf2PtzJ5tOAk2s5HxiUpO5OX8uIuBhXQ50nSU8MHB2Oq/4cQ== nigel@bubbles",
    }
}
