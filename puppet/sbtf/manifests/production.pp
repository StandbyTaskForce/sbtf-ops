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

    server_user { "jeremyb":
            uid             => 2002,
            fullname        => "jeremyb",
            password        => '$6$n2D0ipze/y2zb$aaj.Ni7a6CfNa92U9BcpOlqOha3bojWogXwgrXVR7QtLfcDYwpr6QeWqs.A/4BO4iVkzEu5fL.Esgs201vDCn/',
            groups          => [ "sbtf", "sudo" ],
            authorized_keys => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBda9j5FankpC+ZRhB4W9pxoi+7SJhbZFaNm8v4ZzL60iO7CBMRZgMZy9ch63MqUBtOIQm/COlPBrPCQurasbLQmaR7dTFVM+CgJ1kz9lLtzOAsdyDT4eQfymO55DQhkai28uHRu0X+Sgm6nhWBXL4Kg9bOxRYXUd7niFd8LCVJ7oIBkeCB8lSmShxRWdnY0jkGHOYUrxSwqC36Tt0akGxNAfbDjl1iLK7/WHtmk5V23CIuaA5yGayHgAVTInG++UU/n8Gw6opY/IJo/ygSTlZ1s2rRjVK/jtBq+EAMg5zcIUrBTv+qpUMBr58+lhTi6HuhLfSbH18ZW8sW5XZhkWglAo5RXIH6p7ed0IgOqmzhr1ErY67a3GiShPeuk9AUDKg3WwxZISzFfDJNKOmQydIisOzOQAGi5jcM9NhVIAnKXjnsWleD8Wm4c3NwT7EvhyuruN/zOedXGtKX5X7/c/TBn5jq5Nf/swm6l2tV45LSMLvfL78VvbIh8ZRWMpf3xZ13Uf8Xb7AWTgOL+qI9bvi/paX9nKOf1gRPQmE7Hd6g3bfRPH9y0gVsI0z2TJ6HLLDJ2rm6j2oJ5uo1VlttV3DIXLW5NS3ZdoR/FCPCR/JiF3JczYgg6WLbUR7n7QwrPLl2wN6QIe3tpk5nc5QyroMpwaZIIX00e4CMJlndb8PnQ== ssd1
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxP6aMwIps4Nxn3OOzqrtREmUQiccK5MoLK3a5TlrefAeucWwO4brk4tSutiNigOCfO3z9oRgFiqNYSRy7rmVfg0N+tgUY283p7x1dJdxsVmQyFeKnGgZT5/MkNSyt+QX4QEhDWFU/+lt0AoQ3ZQIxhbltcnk8b/xUgAFFvafR6vj2JY/wVeBz2CQWVSDEHfBz1c/nWFLUIrwsGq9rmUkzVxkQkKRKix8IToMxFdiKBZQVpNUEgDfIozlbJLc7AIIiVVDivZGgake+0W/krnFKccrZI1KV2cEdcDrRg98f8XSZDssLJV10//TEhmDY44SA2EtzzZL4T9JCgBu5fCiEQ==
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLMtFgDxKUnzEo+MOF4EvFwQ48uG77S8l7wXjzmxAFl3EidB5M7NR2GWCTztL6bJ94UgzhBZbdGF9PvXm2Zf5cYwz1p26rhLaqr5OT8vE9wA/wC1SwOR9zYQVbpcCFn+pX4uWUSKrheS5wfg0Aqs8gh2olHWUg74qFIf6Sqax+/gsO4AdJ1VqHewQA2+F7SAA+F24toihJP3CQ5Q5h2nAnUsC12RvQOvO/b4VLgodQwZZ3jD8G37lL35n6lJmByfWPv+tnSp4xoe6jlKO+pnk7HffX1Ig4xli+HFRJw9EETYmEqWHUUv0SvTnIzR5cL3TJNChFAs48LnRvw1BcW+u9l/9vejjwhqvQycMWc17mC6DixUEywFxP5WIRuc20OcMrlmyw8lmyloz9sNpYzR3hzgsv4kY3rBQcRqgNUPX5hjwhiLPOY0O2a44+Rfr+frMd9Pr44IoBI1sqPbwBFlG9wfl6NqhvG3vSpmKKBur8/AlheIk+Njeug9AXv1VHjJH/KeBqB4Y6aDTnDYoxCs2taTl2+dni9fbLSrmaCWpIoQhVQcOAGpg/bpvbBzZPtoUNsjMVhGtWL//5U/ZpUv/K/FxeUI9RvXJDFXPFL4Ia9n+JYHBb+8fSoEFK1IO+UfFoJyWBHfaC8TBXuWeFZGSqpqTO/gIfgGmBmCdOGisXdQ== allig-20120817",
    }

    server_user { "ben":
            uid             => 2003,
            fullname        => "Ben Bradshaw",
            password        => '$6$57vMqhMuiWnY$8KA62nD0a73jI7HfsuQQtgf53KHMtkrWPPz4cHpOC6djDMzkFYtFIFPPY0ynDbEi7NUnZ9E6jjGdGlLedx/Jx0',
            groups          => [ "sbtf", "sudo" ],
            authorized_keys => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2XanK8fbWVd6QesYzJDQs/d79eGHNWIUV2dOsWvIEXZ7/Wi8/9hdT22GkFhq6fbOy7hV3kWr1Q73qxBw/cnLYoXnMr3lZM55YE4Wk60kxFu0u+hmBDY2JWeQrSnZpofCMOyXns4rxH9hMQA7JJrbjhifMCtS+y4vr2VsftyOTrgVmWifJg6LS9n0qY2N65hul83p1jfrFAGZaJshUR4XBsplk76SH6jN6M+N7Y0rPdTVYylsqCsb4+J8uhOfhdzhhWSGKSeTD2wnTWmWxS8FNcmprLQi+hPbVf6uZ7FHlkIQi2R3ESNNXIMSW0gue/jMhkz51ekJriAYxTrCkdeL/ ben@helo
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxKfrJRhoARDir+mjBTPLH7S36BGPsYYfWaDEswVIDW8ntE60qwxXxPjIyVZC8pyOAWvg1iTnuSxvFcInB758/J7JSIPZFc4syuYWiGLSVegWbWyflECccWR/A8ETbmDU1DQySezMVUgQoCJ8vDASMEays+07WpzwwzT+nJxJcTkUnGK2LQE63QROrrGB9UIH5ElzVR2aCN1oTd970qvFbtx0ka4g7E12DR74nm3Zmh7Sylr456yAL6OC5suEq8tDk8t++FP+eYO5k4qOZ9h9AzGcis9pmhp0Cn73qY3zeCnr8kbZz8fuN2psgV9Boh7/PI42KVwd7bTZtdY/35qELw== ben@abutan
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxLWotp55uwlCpNFvyLXxpF1rX0Q7PzoVu3E+NwPuSPZJld14yJtX5I872D5uvz24Oto/oO2VqkY+qYnEK8wagpk22v8uVCIQXGIcS10NmLDUV9tZ75yoL7aFsXKmpDyVpD43DZEgL6En8U640x07FSlVXWHslCOVLg6AC+/xoy1vgZOkLsVARNhLcY9vH+xY662crags7d7Z/4NATDbJARIJMZinHvlnDrnn4+Si/cUXYO+jr04mKm1tOs06cDQjehYQmdIlwjfIH8in13+Q1Dj7159SEnkzb6vnt/lMxDcBj9KvWxfxs06X0le+9tDcZxqDv1YHJI/pRUPc2MRuQQ== ben@falcon.local",
    }
}
