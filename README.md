=============================================================================
About
=============================================================================
ip-heartbeat is a simple shell script for automating keeping track of IP
addresses on machines with DHCP addresses.

It works by saving the client machine's `ifconfig` output to a remote server
on a set invertal (default is every 5 minutes). The ifconfig information is
saved remotely in a file equivalent to the path: <$IF_TARGET_DIR>/<hostname>.

=============================================================================
Usage
=============================================================================
Modify the values for the variables:
	IF_TARGET_DIR
	IF_TARGET_SSH
	IF_TARGET_SSH_IDENTITY

Optionally modify the variables:
	IF_LOG
	IF_LOG_LIMIT

Depending on server distribution/configuration this script will need root
permissions to access `ifconfig`. If this is the case, testing can be done
with `sudo`, but cron jobs should be added to the root user's crontab.

Once configured and tested, this should be run on a set interval through a
cron job. To see an example crontab entry pass the crontab argument:
```$ ./ip-heartbeat.sh crontab```

=============================================================================
License
=============================================================================
The code is released under four clause MIT License. See LICENSE.txt for both
the license and license commentary.
 
