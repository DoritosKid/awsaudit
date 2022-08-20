#!/bin/bash

CONFIG_FILE="$AWSAUDIT_WORKDIR/config/config.txt"

ACCOUNTS=""

while IFS= read -r line;
do
	if [[ $line == *"[profile"* ]] && [[ $line != *"#[profile"* ]] && [[ $line != *"default"* ]];
	then 
		if [[ $line != *"current_session"* ]] ;
		then
			PROFILE=${line:8}
			PROFILE_FORMATTED=${PROFILE::-1}

			ACCOUNTS+="${PROFILE_FORMATTED:1},"
		fi
	fi
done < $CONFIG_FILE

echo ${ACCOUNTS::-1}