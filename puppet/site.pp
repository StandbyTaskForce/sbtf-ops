# vim: filetype=puppet

Exec {
    path => "/usr/sbin:/usr/bin:/sbin:/bin",
}

import "conf/*.pp"
import "classes/*.pp"
import "local.pp"
