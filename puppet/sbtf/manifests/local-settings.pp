# vim: filetype=puppet
# Reads in local settings for puppet, to save people editing the puppet config.

class sbtf::local-settings {
    $local_settings_dir = 'puppet/classes/local-settings'

    $ubuntu_mirror_f = "$local_settings_dir/ubuntu-mirror"
    $ubuntu_mirror   = inline_template("<%= File.file?(\"$ubuntu_mirror_f\") ? IO.read(\"$ubuntu_mirror_f\").chomp! : \"http://nz.archive.ubuntu.com/ubuntu/\" %>")

    $partner_mirror_f = "$local_settings_dir/partner-mirror"
    $partner_mirror   = inline_template("<%= File.file?(\"$partner_mirror_f\") ? IO.read(\"$partner_mirror_f\").chomp! : \"http://archive.canonical.com/ubuntu/\" %>")
}
