#!/bin/bash
#
# Ensures SBTF environments are up to date
#
# Usage: ./bin/sbtf-update.sh
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

PUPPETLIB=$CODEDIR/puppet puppet $CODEDIR/puppet/local.pp
RET=$?

if [ $RET -gt 0 ]; then
    echo "Configuration of your environment by puppet failed! Please correct any"
    echo "problems it encountered and run this script again."
    exit 1
fi

echo "OK"
