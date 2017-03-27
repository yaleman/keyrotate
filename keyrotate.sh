#!/bin/bash

# A pretty messy, but workable script for rotating ssh private keys on a server
# My ~/.ssh/config has "IdentityFile %h" in it, which means this might not work for you if yo don't have that.
# Keys are just called the hostname, and currently using ed25519 keys

# Usage:
# Run it from ~/.ssh/
# keyrotate.sh <hostname>

echo "This isn't working currently, binning."
exit

FIXHOST=$1

KEYTYPE="ed25519"

# check a host is set
if [ -z "$1" ]; then
	echo "Please set the host by running \"$0 <host>\""
	exit
fi

OLDDIR="./olddir"
NEWDIR="./newdir"

rm -rf {$OLDDIR,$NEWDIR}
mkdir -p {$OLDDIR,$NEWDIR}

OLDKEYFILE="$OLDDIR/$FIXHOST"
OLDPUBFILE="$OLDDIR/$FIXHOST.pub"

NEWKEYFILE="$NEWDIR/$FIXHOST-new"
NEWPUBFILE="$NEWDIR/$FIXHOST-new.pub"

echo "Rotating key on '$FIXHOST'"

if [ -f "$OLDKEYFILE" ]; then
	echo "Backing up the backup keys..derp?"
	mv "$OLDKEYFILE" "$OLDKEYFILE.$(date +%Y-%m-%d-%H%M).backup"
	mv "$OLDPUBFILE" "$OLDPUBFILE.$(date +%Y-%m-%d-%H%M).backup"
fi

# check for old keyfile
if [ -f "./$FIXHOST" ]; then
	echo "Old keyfile exists"
	# check for old public key
	if [ -f "./$FIXHOST.pub" ]; then
		echo "Old pubfile exists"
			# back up old files
			echo "Backing up old files"
			cp "./$FIXHOST" "$OLDKEYFILE"
			cp "./$FIXHOST.pub" "$OLDPUBFILE"

			# ensure we're not overwriting the new keys
			if [ -f "$NEWKEYFILE" ]; then
				echo "New key file $NEWKEYFILE already exists."
				exit
			fi
			if [ -f "$NEWPUBFILE" ]; then
				echo "New public key $NEWPUBFILE already exists."
				exit
			fi

			echo "Generating new keys..."
			ssh-keygen -t "$KEYTYPE" -f "$NEWKEYFILE" || exit
			echo "Done."

			echo "Copying the new key to the server..."
			ssh -i "$OLDKEYFILE" "$FIXHOST" "echo $(cat \"$NEWPUBFILE\") >> ~/.ssh/authorized_keys" || exit
			echo "Done."

			echo "Testing ssh to host..."
			# remember to move the old keyfiles out of the way to make sure it works
			mv "./$FIXHOST" "$OLDKEYFILE"
			mv "./$FIXHOST.pub" "$OLDPUBFILE"
			ssh -i "$NEWKEYFILE" "$FIXHOST" exit || exit
			echo "Done."

			echo "Removing old key..."
			ssh -i "$NEWKEYFILE" "$FIXHOST" "mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys.old; grep -v \"$(cat "$OLDPUBFILE")\" ~/.ssh/authorized_keys.old > ~/.ssh/authorized_keys" || exit
			echo "Done."

			echo "Moving new key to active key..."
			mv "$NEWKEYFILE" "./$FIXHOST"
			mv "$NEWPUBFILE" "./$FIXHOST.pub"
			echo "Done."

			echo "Testing login..."
			ssh -i "$FIXHOST" "$FIXHOST" exit || exit
			echo "Done."

			echo "Removing backup authorized_keys..."
			ssh -i "$FIXHOST" "$FIXHOST" "rm ~/.ssh/authorized_keys.old"
			echo "Done."

			echo "Removing old/newkey directories..."
			rm -rf ./{olddir,newdir}
			echo "Done."

			else
		echo "Couldn't find old public key file"
		exit
	fi
else
		echo "Couldn't find old private key file"
		exit
fi
