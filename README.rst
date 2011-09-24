SBTF Ops
========

Scripts and puppet configuration to set up and configure a server to run
Ushahidi (though the puppet could be expanded to run anything).

The goal is that you can run one command::

    ./bin/bootstrap-server.sh [ip/hostname of server] ushahidi

And it will install and configure an Ushahidi on that server, using the best
configuration possible, including handling monitoring and other such
maintenance issues.

If the puppet config is changed, you can simply run one command on the server
to grab and apply it::

    sbtf@server:~/sbtf$ sudo ./bin/sbtf-update.sh

Thus, with minimal effort, anyone can run a highly optimised, sensibly
configured Ushahidi - and more importantly, keep up to date with any
improvements over time.

Server Requirements
-------------------

The config expects to be run on a server running Ubuntu Lucid, which was chosen
due to being the most recent LTS release. It'll probably run against newer
Ubuntus and also probably against Debian. Patches welcome.

In particular, the config has been tested against Amazon EC2 instances, however
it was ported from a project running on Rackspace, so it may run fine there
too. If you have your own pristine Lucid machine, there's no reason why it
wouldn't be a suitable host - again, patches welcome.

Legal
-----

This project is released into the public domain.

Attribution would be nice, a link to http://github.com/StandbyTaskForce/sbtf-ops is fine.

Principal Author: Nigel McNie <nigel@mcnie.name>

Initial config donated by Shoptime Software: http://www.shoptime.co.nz/
