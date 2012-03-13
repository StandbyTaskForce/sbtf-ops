# vim: filetype=puppet
# "production" environment setup

class sbtf::production inherits sbtf::base {
    file { "/etc/hosts":
        ensure  => "present",
        content => "# WARNING: managed by puppet!
$ipaddress      $hostname.ops.standbytaskforce.com $hostname
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

    file { "/home/sbtf/sbtf/puppet/local.pp":
        ensure => present,
        owner  => "sbtf",
        group  => "sbtf",
        mode   => 644,
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
            groups          => [ "sbtf", "sudo" ],
            authorized_keys => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApFJAa4+l7bQRIAhFx/Y60ozZm2e7qZwCY5TQsw9NYBgGtNVKqMVmEw6l7XMzs9KcPl4lozMZuQbJtKq8voP/e0PIuij4a4E3Qr3QZwAKVc++v8y/uLym/A1yzJps72QtguynOrDP1GLguR1igsTbWFoU9leG6Wo/ROieFNVJ6bQ4bOPvTZKc0vQZzK+HOpBaMOnvPK9eeHDluQK3MSObU3IJcRvH/838nzT1CP4YU8oqDnpWvd6o9jEcVzbyD3l7SKNBmKulwTQnNC7aDN0j+/LCj+nOhFtPkKTnQSsf2PtzJ5tOAk2s5HxiUpO5OX8uIuBhXQ50nSU8MHB2Oq/4cQ== nigel@bubbles",
    }

    server_user { "robbie":
            uid             => 2001,
            fullname        => "Robbie MacKay",
            password        => '$6$pZA7NlIv$EJr6uSwptv2UziF504E2lJx34MSifJGK4EE8qk9xyExXyP7Dso3NNcphwTpDaWKbDpWezIp8eLxlWuagxJqBM0',
            groups          => [ "sbtf", "sudo" ],
            authorized_keys => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxFlAN12WU1gQCVyRUeON3YrcZTOLy3VN0PQCvef9jB0mMho1163wMkoH6dIFVgwWsw/A1nQTYYUlnA+3cc6mvoqgFtZfuCNf9kKQiCE4b1/uahvVBpDmPnRESujdD8IZb5g8kD4BwYYgF8OWFj59Vl92o8Oj9NAccqinIOIechcTguVG4xwxxqQdqyu2WE3rrDWvLNthJpa8uv0aux9bh50mGcbAeKEdrtVuS5Qa10FtNx3aGS01VVmok7fuSfgNHCdQVMV4x8QPMo8LY7lYs57wSzHc2XqGJCnCB5947XwB/msq9ZoyCZlUvdav2qNbp+VK9KtMctlX6kyceuBWKw== robbie@Grenache\nssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAsGY/zd2QS36JKh979msu1jBi8ECGG+h8uAIJuAEoT2L5R1ol7ll4j08pNd3HT/QujlSkQ0DfT2+BZPx8+GjX2hyPGFtjyzOEc9bLyHN9pcu+8S8YQTol+auq/4+Us4QQsmeDl7+DMYTid6j7r5+Dg4aBeibQqunuv08LeYx0p2ZoqvHw/oZJSQdI1Pb3xCXQjh458A3WG22CGyWCrhv5HsIxcP3udF+tDTYHFWlO19P1lPf7Q1/sGSPlwtwU3NPw7aPJPu9/k1AqnMYAlF1nS8ZEB+jCtt+cqAcYoMm6pNqQv/1A9VAUhlbQJiEVD6JxT++O5KeM/X+ZlDBFxky8mw== robbie@rjmackay1.robbiemackay.com",
    }
}
