#!/bin/bash

CONFIG_FILE=~/.aws/config
CREDENTIALS_FILE=~/.aws/credentials

if [ ! -z $(which aws) ]; then
	echo "[SUCCESS] AWS-CLI is installed!"
elif [ ! -z $(type -p aws) ]; then
	echo "[SUCCESS] AWS-CLI is installed!"
else
	echo "[ERROR] AWS-CLI was not found!"
	exit 1
fi

echo ""

if [ -f "$CONFIG_FILE" ] && [ -f "$CREDENTIALS_FILE" ]; then
  	echo "[SUCCESS] A working config and credentials file has been found!"
else
	echo "[ERROR] Config and/or credentials file could was not found in the default directory (~/.aws)"
	exit 1
fi