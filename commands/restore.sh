#!/bin/bash

CONFIG_FILE=~/.aws/config
CREDENTIALS_FILE=~/.aws/credentials

if [ "$(ls -A "$(dirname $(dirname $(readlink -f "$0")))/config/backup")" ]; then
	cp $(dirname $(dirname $(readlink -f "$0")))/config/backup/config $CONFIG_FILE
	cp $(dirname $(dirname $(readlink -f "$0")))/config/backup/credentials $CREDENTIALS_FILE

	echo "[SUCCESS] Restored the backed up configuration successfully!"
else
	echo "[ERROR]: Could not find credentials to restore in $(dirname $(dirname $(readlink -f "$0")))/config/backup!"
	echo "[ERROR]: Please back up a configuration prior to restoring!"
	exit 1
fi

