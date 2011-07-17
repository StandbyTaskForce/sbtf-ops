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
ROLES=$@
echo -n "Doing core configuration... "

echo "en_US.UTF-8 UTF-8" > /var/lib/locales/supported.d/local
dpkg-reconfigure locales > /dev/null 2>&1

rm /etc/localtime
ln -s /usr/share/zoneinfo/UTC /etc/localtime

# TODO possibly, hostname configuration

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
echo "sbtf  ALL=NOPASSWD: /home/sbtf/sbtf/scripts/sbtf-bootstrap.sh" > /etc/sudoers.d/sbtf
chmod 440 /etc/sudoers.d/sbtf

useradd -c 'SBTF System User' -d /home/sbtf -m -s /bin/bash -u 7777 -U sbtf || true
echo "done."


# Set up sbtf user to connect to github
echo -n "Generating ssh key for sbtf... "
su - sbtf -c 'ssh-keygen -q -t rsa -N "" -f /home/sbtf/.ssh/id_rsa'
echo 'github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' > /home/sbtf/.ssh/known_hosts
chown sbtf:sbtf /home/sbtf/.ssh/known_hosts
echo "done."

echo "-------------------------------------------------------------"
echo "This is the public key for the sbtf user. Put it in github as a deploy key:"
cat /home/sbtf/.ssh/id_rsa.pub
echo "-------------------------------------------------------------"
echo "Once you've done that, hit [enter] to contiue"
read junk


# Clone the repo & run bootstrap
su - sbtf -c 'git clone git@github.com:nigelmcnie/sbtf.git'
su - sbtf -c "cd sbtf && sudo bash ./scripts/sbtf-bootstrap.sh production $ROLES"


# Finish up!
echo "All done. Now, please set the root password, using the output of 'pwgen -s 15 1':"
passwd
echo "Build complete. Save the root password in a safe place!"
