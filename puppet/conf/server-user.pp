# vim: filetype=puppet

define server_user($uid, $fullname, $password, $groups=[], $authorized_keys='') {
    if $password == 'locked' {
        user { $name:
            ensure     => "present",
            uid        => $uid,
            gid        => $name,
            comment    => $fullname,
            groups     => $groups,
            home       => "/home/$name",
            managehome => true,
            shell      => "/bin/bash",
            require    => Group[$name],
        }

        exec { "passwd -l $name":
            # TODO should make the unless test work
            refreshonly => true,
            #unless     => "test `passwd -S sbtf | cut -f 2 -d ' '` != 'L'",
            subscribe   => User[$name],
        }
    }
    else {
        user { $name:
            ensure     => "present",
            uid        => $uid,
            gid        => $name,
            comment    => $fullname,
            password   => $password,
            groups     => $groups,
            home       => "/home/$name",
            managehome => true,
            shell      => "/bin/bash",
            require    => Group[$name],
        }
    }

    group { $name:
        ensure => "present",
        gid    => $uid,
    }

    file { "/home/$name/.ssh":
        ensure  => "directory",
        owner   => $name,
        group   => $name,
        mode    => 700,
        require => User[$name],
    }

    file { "/home/$name/.ssh/authorized_keys":
        ensure  => "present",
        owner   => $name,
        group   => $name,
        mode    => 644,
        content => $authorized_keys,
        require => File["/home/$name/.ssh"],
    }
}
