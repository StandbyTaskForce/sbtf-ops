#!/bin/bash
#
# Bootstraps a new server.
#
# All this script does is send the production bootstrapping script through to
# the server, then executes it.
#
# Usage: bootstrap-server.sh <instance-ip> [<ssh-options>]
# E.g.:  bootstrap-server.sh 184.106.94.194 -i ~/.ssh/sbtfaws.pem
#
# Author: Nigel McNie <nigel@mcnie.name>
#

INSTANCE=$1
shift
SSH_OPTS=$@
REMOTEUSER=root

echo "Bootstrapping $INSTANCE..."

sudo=''
if [ "$REMOTEUSER" != "root" ]; then
    sudo='sudo'
fi

if [[ ! $INSTANCE =~ .*@.* ]]; then
    INSTANCE="$REMOTEUSER@$INSTANCE"
fi


exit_cleanly () {
    nc_pid=`netstat -ntlp 2>/dev/null | grep 12345.*nc | awk '{print $7}' | cut -f 1 -d '/'`
    if [ -n "$nc_pid" ]; then
        kill $nc_pid;
    fi

    exit 0
}

trap exit_cleanly SIGINT SIGTERM

SCRIPTPATH=$(dirname $(readlink -f $0))
# Dodgy hax to send the file and execute it in one go, so we don't have to ssh
# twice (and thus make the user enter the root pw twice)
( nc -l 12345 < scripts/production-bootstrap.sh &
  cd $SCRIPTPATH/.. &&
  LANG=C ssh -t -R12345:localhost:12345 $INSTANCE $SSH_OPTS "$sudo apt-get install -qq -y netcat > /dev/null && nc localhost 12345 > production-bootstrap.sh && $sudo sh production-bootstrap.sh $ROLES" )

# This is an alternative way that also works, but the first thing the
# production-bootstrap script should do is remove the authorized_keys file for
# root if you do it this way.
#( cd $SCRIPTPATH/.. &&
#  ssh-copy-id $REMOTEUSER@$INSTANCE > /dev/null &&
#  tar cz bin/prod-bootstrap.sh | ssh $REMOTEUSER@$INSTANCE tar xz &&
#  ssh $REMOTEUSER@$INSTANCE sh bin/prod-bootstrap.sh $ROLES )

exit_cleanly
