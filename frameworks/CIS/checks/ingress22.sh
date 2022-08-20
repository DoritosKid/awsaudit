#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=3
TYPE="Security Groups"
SEVERITY="4"
STATUS=""

SG_TOTAL=0
FAILS=""
SG_PASSED=0
SG_FAILED=0

CHECKED="$(aws ec2 describe-security-groups --profile $AWS_PROFILE --query "SecurityGroups[*].[GroupId]" --output text )"
SG_TOTAL=`echo "$CHECKED" | wc -w`

function checkSSHPort {

	if [[ -z SG_TOTAL ]]; then
		STATUS="SKIPPED"
	else

		GROUP="$(aws ec2 describe-security-groups --profile $AWS_PROFILE --filters  \
		Name=ip-permission.from-port,Values=22 Name=ip-permission.to-port,Values=22 \
		Name=ip-permission.cidr,Values='0.0.0.0/0' --query "SecurityGroups[*].[GroupId]" --output text )"

		if [[ -z $GROUP ]]; then
			STATUS="PASSED"
		else
			STATUS="FAILED"
			SG_FAILED=`echo "$GROUP" | wc -w`

			for SG in $GROUP
			do
				if [[ -z $FAILS ]]; then
					FAILS="${FAILS}$SG"
				else
					FAILS="${FAILS}, $SG"
				fi
			done
		fi
	fi
}

function performCheck {

	checkSSHPort

	SG_PASSED=$((SG_TOTAL-SG_FAILED))

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			No security groups should allow incoming traffic from 0.0.0.0/0 to Port 22
SEVERITY:		HIGH
TYPE:			$TYPE
STATUS:			$STATUS
TOTAL GROUPS:		$SG_TOTAL
CHECK PASSED FOR:  	$SG_PASSED
CHECK FAILED FOR:  	$SG_FAILED
MISCONFIGURED SGs:	$FAILS
	
MITIGATION:		Every misconfigured security group needs to restrict the ingress for 0.0.0.0/0 on Port 22.
			Removing connectivity to remote console services like SSH reduces the risk of unauthorized remote access.
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




