#!/bin/bash

CONFIG_FILE=~/.aws/config
CREDENTIALS_FILE=~/.aws/credentials
IAM_ROLE="awsaudit"

MODE=$1
PROFILE=$2
ACCOUNT_ID=$3
REGION=$4

CONFIG_DIR="$AWSAUDIT_WORKDIR/config"

function checkPrerequisites {
	bash $(dirname $(dirname $(readlink -f "$0")))/common/checkCLI.sh
}

function pushNewConfig {

	echo >> $CONFIG_FILE
	echo >> $CONFIG_FILE

  while IFS= read -r line;
		do
		echo $line >> $CONFIG_FILE
	done < $CONFIG_DIR/config.txt

	echo "[SUCCESS] Setup configuration successfully!"
}

function pushNewCredentials {

	echo >> $CONFIG_FILE
	echo >> $CONFIG_FILE

  while IFS= read -r line || [ -n "$line" ];
		do
		echo $line >> $CREDENTIALS_FILE
	done < $CONFIG_DIR/credentials.txt

	echo "[SUCCESS] Setup credentials successfully!"
}

function clearConfig {

	if [ -f "$CONFIG_DIR/config.txt" ] ; then
  	rm "$CONFIG_DIR/config.txt"
	fi
}

function restoreBackup {
	bash $(dirname "${BASH_SOURCE[0]}")/restore.sh
}

function createBackup {
	bash $(dirname "${BASH_SOURCE[0]}")/backup.sh
}

function singleSetup {

	restoreBackup
	clearConfig
	checkPrerequisites

	echo "[profile $PROFILE]" >> $CONFIG_DIR/config.txt
	echo "role_arn = arn:aws:iam::$ACCOUNT_ID:role/awsaudit" >> $CONFIG_DIR/config.txt
	echo "source_profile = awsaudit" >> $CONFIG_DIR/config.txt
	echo "region = $REGION" >> $CONFIG_DIR/config.txt
	echo "output = json" >> $CONFIG_DIR/config.txt

	pushNewConfig
	pushNewCredentials
}

function multiSetup {

	restoreBackup
	clearConfig
	checkPrerequisites

	while IFS= read -r line;
	do
		if [[ $line != *"#"* ]]; then
			echo $line >> $CONFIG_DIR/config.txt
		fi
	done < $CONFIG_FILE

  #Sets the role and source profile accordingly
	while IFS= read -r line;
	do
		if [[ $line == *"role_arn"* ]];
		then 
			ROLE_TO_REPLACE="${line#*/}"
			sed -i "s/$ROLE_TO_REPLACE/$IAM_ROLE/g" $CONFIG_DIR/config.txt
		fi
		if [[ $line == *"source_profile"* ]];
		then 
			SOURCE_TO_REPLACE="${line#*=}"
			sed -i "s/$SOURCE_TO_REPLACE/ awsaudit/g" $CONFIG_DIR/config.txt
		fi 
	done < $CONFIG_DIR/config.txt

	#Deletes the MFA information, as well as giving the profiles a unique name
	sed -i "s/]/TOBEREPLACED/g" $CONFIG_DIR/config.txt
	sed -i "s/TOBEREPLACED/-audit]/g" $CONFIG_DIR/config.txt
	sed -i "/mfa_serial/d" $CONFIG_DIR/config.txt

	pushNewConfig
	pushNewCredentials
}

if [[ $1 == "-single" ]]; then
	singleSetup $PROFILE $ACCOUNT_ID $REGION
fi

if [[ $1 == "-multi" ]]; then
	multiSetup
fi

echo "[SUCCESS] Setup has been completed successfully!"