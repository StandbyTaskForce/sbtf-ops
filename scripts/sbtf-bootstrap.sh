#!/bin/bash
#
# Bootstraps SBTF server environments
#
# When run from an SBTF checkout, it makes sure the server/container it's
# inside is configured to run ushahidi.
#
# Usage: bash scripts/sbtf-bootstrap.sh environment
#
# "environment" can be production or private.
#

SCRIPT=$(readlink -f $0)
SCRIPTDIR=$(dirname $SCRIPT)
CODEDIR=$(cd "$SCRIPTDIR/.." ; pwd)

bail () {
    echo $1
    exit 1
}

if [ "$(id -u)" != "0" ]; then
    bail "This script should be run as 'root'"
fi

if [ ! -d "$CODEDIR/.git" ]; then
    bail "Could not find .git for your repository that is supposed to be at $CODEDIR"
fi


ENVIRONMENT=$1
shift

if [ -z "$ENVIRONMENT" ]; then
    bail "Usage: bash scripts/bootstrap.sh environment"
fi

if  [ "$ENVIRONMENT" != "production" ] &&
    [ "$ENVIRONMENT" != "private" ]; then
    bail "Invalid environment specified; must be 'private' or 'production'";
fi

CREATING_USER="root"
if [ "$SUDO_USER" != "" ]; then
    CREATING_USER=$SUDO_USER
fi


# Now we're ready to create the environment
echo "Creating environment for checkout in $CODEDIR"

if dpkg -l | grep ^ii.*puppet > /dev/null; then
    echo "Puppet already installed"
else
    echo -n "Installing puppet... "
    apt-get install -qq -y puppet > /dev/null
    echo "done."
fi

PC=$CODEDIR/puppet/local.pp
cat<<EOF > $PC
\$envtype       = "$ENVIRONMENT"
\$creating_user = "$CREATING_USER"
EOF
for R in $ENVIRONMENT; do
    echo "include sbtf::$R" >> $PC
done


PUPPETLIB=$CODEDIR/puppet puppet $CODEDIR/puppet/local.pp
RET=$?

if [ $RET -gt 0 ]; then
    echo "Configuration of your environment by puppet failed! Please correct any"
    echo "problems it encountered and run this script again."
    exit 1
fi

echo "SBTF Bootstrap done. From now on, use 'sudo ./bin/sbtf-update.sh' to keep the environment up to date"
