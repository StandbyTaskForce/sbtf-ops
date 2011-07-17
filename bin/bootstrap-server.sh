#!/bin/sh
#
# Bootstraps a new server.
#
# All this script does is send the production bootstrapping script through to
# the server, then executes it.
#
# Usage: bootstrap-server.sh <instance-ip> <role> [, role, ...]
# E.g.:  bootstrap-server.sh 184.106.94.194 web
#
# Author: Nigel McNie <nigel@mcnie.name>
#

INSTANCE=$1
shift
ROLES=$@
REMOTEUSER=ubuntu

echo "Bootstrapping $INSTANCE as $ROLES..."

sudo=''
if [ "$REMOTEUSER" != "root" ]; then
    sudo='sudo'
fi

SCRIPTPATH=$(dirname $(readlink -f $0))
# Dodgy hax to send the file and execute it in one go, so we don't have to ssh
# twice (and thus make the user enter the root pw twice)
( nc -l 12345 < bin/production-bootstrap.sh &
  cd $SCRIPTPATH/.. &&
  ssh -t -R12345:localhost:12345 $REMOTEUSER@$INSTANCE "$sudo apt-get install -qq -y netcat > /dev/null && nc localhost 12345 > production-bootstrap.sh && $sudo sh production-bootstrap.sh $ROLES" )

# This is an alternative way that also works, but the first thing the
# production-bootstrap script should do is remove the authorized_keys file for
# root if you do it this way.
#( cd $SCRIPTPATH/.. &&
#  ssh-copy-id $REMOTEUSER@$INSTANCE > /dev/null &&
#  tar cz bin/prod-bootstrap.sh | ssh $REMOTEUSER@$INSTANCE tar xz &&
#  ssh $REMOTEUSER@$INSTANCE sh bin/prod-bootstrap.sh $ROLES )
