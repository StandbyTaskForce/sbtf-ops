#!/bin/sh
#
# Bootstraps a PRODUCTION machine
#
# bootstrap-server.sh sends this script to a production server, then
# runs it.
#
# This script takes the presumed pristine ubuntu lucid server, and performs
# initial bootstrapping, so that:
#
# 1. the sbtf user is installed;
# 2. the SBTF repository is checked out; and
# 3. sbtf-bootstrap.sh has been run in the repository
#
# sbtf-bootstrap.sh then takes over and ensures the environment is correctly
# configured, etc.
set -e

if [ $(id -u) != 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi


# TODO assert that machine is lucid


# Core config
echo -n "Doing core configuration... "

echo "en_US.UTF-8 UTF-8" > /var/lib/locales/supported.d/local
dpkg-reconfigure locales > /dev/null 2>&1

rm /etc/localtime
ln -s /usr/share/zoneinfo/UTC /etc/localtime

echo "done."


# Install core packages
echo -n "Updating sources... "
apt-get update -qq
echo "done."

echo -n "Installing core packages... "
apt-get install -qq -y git-core > /dev/null
echo "done."


# Add sbtf user
echo -n "Adding sbtf user... "
echo "sbtf  ALL=NOPASSWD: /bin/bash /home/sbtf/sbtf/scripts/sbtf-bootstrap.sh *" > /etc/sudoers.d/sbtf
chmod 440 /etc/sudoers.d/sbtf

# Make sure includedir directive is present
if ! grep includedir /etc/sudoers > /dev/null; then
    chmod u+w /etc/sudoers
    echo '#includedir /etc/sudoers.d' >> /etc/sudoers
    chmod u-w /etc/sudoers
fi

useradd -c 'SBTF System User' -d /home/sbtf -m -s /bin/bash -u 5555 -U sbtf || true
echo "done."


# Clone the repo & run the bootstrap
su - sbtf -c 'git clone git://github.com/StandbyTaskForce/sbtf-ops.git sbtf'
su - sbtf -c "cd sbtf && sudo bash /home/sbtf/sbtf/scripts/sbtf-bootstrap.sh production"

# Finish up!
echo "All done. Now, please set the root password, using the output of 'pwgen -s 15 1':"
passwd
echo "Build complete. Save the root password in a safe place!"
