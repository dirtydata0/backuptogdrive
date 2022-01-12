#!/bin/bash

set -o errexit

BACKUP_LIST="./backup_dirs.txt"
do_stuff () {
	while IFS= read -r LINE
	do
		echo "$LINE"
		NUMPARAMETERS=`echo "$LINE" | awk -F '[\t,]' '{print NF-1}'`
		if [ $NUMPARAMETERS -eq 0 ]; then
			FULLDIR="`echo "$LINE"`"
		else
			FULLDIR="`echo "$LINE" | cut -d',' -f1`"
		fi
		echo "$FULLDIR"
		BASEDIR="`echo "$FULLDIR" | sed -E -n "s_/(home|mnt)/(david|pool/|fastpool/)__p"`"
		echo "Backing up $FULLDIR to google:$BASEDIR"
		if [ $NUMPARAMETERS -eq 0 ]; then
			rclone copy -P --user-agent D8jRTyaa0POq "$FULLDIR" "google:$BASEDIR"
		else
			COUNT=0
			PARAMETERS="--exclude="
			while [ $COUNT -lt $NUMPARAMETERS ]
			do
				COUNT=$(($COUNT + 1))
				PARAMETERNUM=$(($COUNT + 1))
				PARAMETER="`echo $LINE | cut -d',' -f$PARAMETERNUM`"
				if [ $COUNT -eq $NUMPARAMETERS ]; then
					PARAMETERS="$PARAMETERS'$PARAMETER'"
				else
					PARAMETERS="$PARAMETERS'$PARAMETER' --exclude="
				fi
			done
			rclone move -P --user-agent D8jRTyaa0POq "$FULLDIR" "google:$BASEDIR" "$PARAMETERS"
		fi
	done < "$BACKUP_LIST"
}

LOCKFILE="/tmp/`basename $0`.lock"
if [ ! -e "$LOCKFILE" ]; then
	trap "rm -f $LOCKFILE; exit" INT TERM EXIT
	touch $LOCKFILE
	do_stuff
	rm $LOCKFILE
	trap - INT TERM EXIT
else
	echo "$0 already running"
fi
