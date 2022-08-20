#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=1
TYPE="IAM"
SEVERITY="4"
STATUS=""

HUMAN_USERS=""
FAILS=""
HAS_MFA=0
MISSING_MFA=0

function checkIfUserIsHuman {
	HUMANS="$(aws iam get-login-profile --profile $AWS_PROFILE --user-name $1 2> /dev/null)"

	if [[ ! -z $HUMANS ]]; then
		HUMAN_USER=`grep -oP ' "UserName": "\K[^"]+' <<< "$HUMANS"`	
		HUMAN_USERS="${HUMAN_USERS} $HUMAN_USER"
	fi
}

function getUsers {
	USERS="$(aws iam list-users --profile $AWS_PROFILE --query 'Users[].UserName' --output text)"
	USER_TOTAL=`echo "$USERS" | wc -w`

	for USER in $USERS 
	do
		checkIfUserIsHuman $USER
  	done
}

function checkMFADevices {
	if [[ ! -z $HUMAN_USERS ]]; then

		for USER in $HUMAN_USERS 
		do
			MFA_DEVICES="$(aws iam list-mfa-devices --profile $AWS_PROFILE --user-name $USER)"
			
			if [[ $MFA_DEVICES == *$USER* ]]; then
				((HAS_MFA+=1))
				STATUS="PASSED"

			else
				((MISSING_MFA+=1))
				if [[ $MISSING_MFA == 1 ]]; then
					FAILS="${FAILS}$USER"
				else
					FAILS="${FAILS}, $USER"
				fi
				STATUS="FAILED"
			fi
  		done

	else
		STATUS="SKIPPED"
	fi
}

function performCheck {

	getUsers
	checkMFADevices	

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			Every user with a console password should have MFA enabled.
SEVERITY:		HIGH
TYPE:			$TYPE
STATUS:			$STATUS
CHECK PASSED FOR:	$HAS_MFA
CHECK FAILED FOR:	$MISSING_MFA
USERS WITHOUT MFA:	$FAILS

MITIGATION:		Every of the above users should enable MFA, either with virtual MFA or (more secure) hardware MFA.
			This adds another layer of protection on all authentication processes and is easy to implement and maintain.
			It is also a good security practice to enforce MFA for every new user at their first sign in. 
" >> $RESULT_DIR
	
	fi
}

performCheck


if [[ $STATUS == "SKIPPED" ]]; then
	echo -1
elif [[ $STATUS == "PASSED" ]]; then
	echo 0
else 
	echo $SEVERITY
fi





