#!/bin/bash

AWS_ACCOUNTS=$1

CHECK_ID=2
TYPE="CloudTrail"
SEVERITY="4"
STATUS="FAILED"

TRAILS_TOTAL=0
ACCOUNTS_CHECKED=0
TRAILS_CHECKED=""


function getTrails {
	for ACCOUNT in $(echo $AWS_ACCOUNTS | sed "s/,/ /g")
	do
		ACCOUNTS_CHECKED=$((ACCOUNTS_CHECKED+=1))

		TRAILS="$(aws cloudtrail describe-trails --profile $ACCOUNT)"

		if [[ $TRAILS == *"Name"* ]]; then

			TRAILS_TOTAL=$((TRAILS_TOTAL+=1))

			TRAIL_NAME=`grep -oP ' "Name": "\K[^"]+' <<< "$TRAILS"`

			if [[ $TRAILS_TOTAL == 1 ]]; then
				TRAILS_CHECKED="${TRAILS_CHECKED}$TRAIL_NAME"
			else
				TRAILS_CHECKED="${TRAILS_CHECKED}, $TRAIL_NAME"
			fi

			TRAIL=$(echo $TRAILS | sed 's/"//g')

			if [[ $TRAIL == *"IsMultiRegionTrail: true"* ]]; then
				if [[ $TRAIL == *"IsOrganizationTrail: true"* ]]; then
					STATUS="PASSED"
				fi
			fi
		fi
  	done
}

function performCheck {

	getTrails

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			There should be at least one Trail enabled which is configured to be multi-regional.
				This Trail should also be organizational to cover logging across all accounts.
SEVERITY:		HIGH
TYPE:			$TYPE
STATUS:			$STATUS
ACCOUNTS CHECKED:	$ACCOUNTS_CHECKED
TRAILS TOTAL:	$TRAILS_TOTAL
TRAILS CHECKED  $TRAILS_CHECKED

MITIGATION:		One of the trails should enable the \"IsMultiRegional\" setting, so that every region is covered.
			If this multi-regional trail is also set as the organization trail via the \"IsOrganizationTrail\"
			setting, then a central logging mechanism which covers all accounts can be achieved.
			If CloudTrail is not used at all, it is extremely advisable to integrate the use of this service.
			CloudTrail enables the logging of API calls and allows users of AWS to keep these in check.  
" >> $RESULT_DIR

	fi
}

performCheck


if [[ $STATUS == "PASSED" ]]; then
	echo 0
else 
	echo $SEVERITY
fi





