#!/bin/bash

CONFIG_FILE=~/.aws/config
CREDENTIALS_FILE=~/.aws/credentials

cp $CONFIG_FILE $(dirname $(dirname $(readlink -f "$0")))/config/backup/config 
cp $CREDENTIALS_FILE $(dirname $(dirname $(readlink -f "$0")))/config/backup/credentials 

echo "[SUCCESS] Backed up the configuration successfully!"