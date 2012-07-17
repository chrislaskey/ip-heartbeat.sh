#!/bin/bash
# =============================================================================
# About
# =============================================================================
# ip-heartbeat is a simple shell script for automating keeping track of IP
# addresses on machines with DHCP addresses.
#
# It works by saving the client machine's `ifconfig` output to a remote server
# on a set invertal (default is every 5 minutes). The ifconfig information is
# saved remotely in a file equivalent to the path: <$IF_TARGET_DIR>/<hostname>.
#
# @author: Chris Laskey
# @source: http://chrislaskey.com
# @version: 1.2.0
# @updated: 2012.07.17
#
# =============================================================================
# Usage
# =============================================================================
# Modify the values for the variables:
# 	IF_TARGET_DIR
# 	IF_TARGET_SSH
# 	IF_TARGET_SSH_IDENTITY
#
# Optionally modify the variables:
# 	IF_LOG
# 	IF_LOG_LIMIT
#
# Depending on server distribution/configuration this script will need root
# permissions to access `ifconfig`. If this is the case, testing can be done
# with `sudo`, but cron jobs should be added to the root user's crontab.
#
# Once configured and tested, this should be run on a set interval through a
# cron job. To see an example crontab entry pass the crontab argument:
# ```$ ./ip-heartbeat.sh crontab```
#
# =============================================================================
# License
# =============================================================================
# The code is released under four clause MIT License. See LICENSE.txt for both
# the license and license commentary.

# =============================================================================
# Set PATH
# =============================================================================
# Since cron jobs do not use a login shell, which usually loads the
# PATH from .bashrc and .bash_profile, we need to specify PATH here.
PATH=/usr/sbin:/usr/bin:/sbin:/bin

# =============================================================================
# Set variables
# =============================================================================
# Be sure to use absolute paths as the user executing the script may not be
# the current user. If you prefer relative paths for portability, use
# `readlink` to expand a relative path to an absolute:
#	IF_TARGET_SSH_IDENTITY=`readlink -f ~/.ssh/file`
IF_LOG="`pwd`/ip-heartbeat.log"
IF_LOG_LIMIT=1000

if [[ -f "${IF_LOG}" ]]; then
	# Truncate log if it contains more lines than the log limit
	`tail -n "${IF_LOG_LIMIT}" "${IF_LOG}" > tempfile`
	`cat tempfile > ${IF_LOG}`
	`rm tempfile`
fi

IF_TARGET_DIR='~/example/path/'
if [[ '~/example/path' == "${IF_TARGET_DIR}" ]]; then
	echo 'Error executing: Target directory not set. See the Usage section of this script for more information.'
	exit 121
fi

IF_TARGET_SSH='user@example.com'
if [[ 'user@example.com' == "${IF_TARGET_SSH}" ]]; then
	echo 'Error executing: Target SSH not set. See the Usage section of this script for more information.'
	exit 122
fi

IF_TARGET_SSH_IDENTITY='/example/identity/file/path'
if [[ ! -f "${IF_TARGET_SSH_IDENTITY}" ]]; then
	echo 'Error executing: Could not find SSH Identity File'
	exit 123
fi

# =============================================================================
# Functions
# =============================================================================
help_message () { 
	echo "Error, invalid argument."
	echo "Valid arguments for ${0} are: crontab"
} 

print_crontab () { 
	echo "Insert the following using \`crontab -e \`"
	echo "*/5 * * * * `readlink -f ${0}` >> ${IF_LOG} 2>&1"
} 

# =============================================================================
# Check for passed arguments
# =============================================================================
if [[ "$1" ]]; then
	if [[ ! "$1" =~ (crontab) ]]; then
		help_message
		exit 120
	fi
	if [[ "$1" == crontab ]]; then
		print_crontab
		exit 0
	fi
fi

# =============================================================================
# Create target file
# =============================================================================
IF_TARGET_FILE=`hostname --fqdn`
if [[ $? != 0 ]]; then
	echo 'Error executing: $ hostname --fqdn'
	exit 124
fi

# =============================================================================
# Get current ifconfig
# =============================================================================
IF_CONFIG=`date +%c`$'\n'$'\n'`ifconfig`
if [[ $? != 0 ]]; then
	echo 'Error executing: $ ifconfig'
	exit 125
fi

# =============================================================================
# Save to local file
# =============================================================================
`echo "${IF_CONFIG}" > "${IF_TARGET_FILE}"`
if [[ $? != 0 ]]; then
	echo 'Error executing: $ echo "${IF_CONFIG}" > "${IF_TARGET_FILE}"'
	exit 126
fi

# =============================================================================
# Create remote target directory with ssh
# =============================================================================
`ssh -i "${IF_TARGET_SSH_IDENTITY}" "${IF_TARGET_SSH}" ""/bin/mkdir -p "${IF_TARGET_DIR}"""`
if [[ $? != 0 ]]; then
	echo "Error executing: $ ssh -i "${IF_TARGET_SSH_IDENTITY}" "${IF_TARGET_SSH}" ""/bin/mkdir -p "${IF_TARGET_DIR}""""
	exit 127
fi

# =============================================================================
# scp local file to remote server
# =============================================================================
`scp -i "${IF_TARGET_SSH_IDENTITY}" "${IF_TARGET_FILE}" "${IF_TARGET_SSH}":"${IF_TARGET_DIR}"`
if [[ $? != 0 ]]; then
	echo 'Error executing: $ scp -i "${IF_TARGET_SSH_IDENTITY}" "${IF_TARGET_FILE}" "${IF_TARGET_SSH}":"${IF_TARGET_DIR}"'
	exit 128
fi

# =============================================================================
# Remove local file
# =============================================================================
`rm "${IF_TARGET_FILE}"`
if [[ $? != 0 ]]; then
	echo 'Error executing: $ rm "${IF_TARGET_FILE}"'
	exit 129
fi

# =============================================================================
# Success
# =============================================================================
# Add a success message for the log file. Keep log file to 1000 entries.
echo `date` ' Successful call to ip-heartbeat.sh'
