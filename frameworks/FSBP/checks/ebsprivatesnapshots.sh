#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=8
TYPE="EBS"
SEVERITY="4"
STATUS=""

SNAPSHOT_TOTAL=0
FAILS=""
SNAPSHOT_PASSED=0
SNAPSHOT_FAILED=0

OWNER_ID="$(aws sts get-caller-identity --profile $AWS_PROFILE --query Account --output text)"
CHECKED="$(aws ec2 describe-snapshots --profile $AWS_PROFILE --owner-ids $OWNER_ID \
	--query 'Snapshots[].SnapshotId[]' --output text)"

SNAPSHOT_TOTAL=`echo "$CHECKED" | wc -w`

function checkPublicSnapshots {

	if [[ SNAPSHOT_TOTAL == 0 ]]; then
		STATUS="SKIPPED"
	else
		PUBLIC_SNAPSHOTS="$(aws ec2 describe-snapshots --profile $AWS_PROFILE --owner-ids $OWNER_ID \
		--restorable-by-user-ids all --query 'Snapshots[].SnapshotId[]' --output text)"

		if [[ -z $PUBLIC_SNAPSHOTS ]]; then
			STATUS="PASSED"
			SNAPSHOT_PRIVATE=$SNAPSHOT_TOTAL
		else
			STATUS="FAILED"
			for SNAPSHOT in $PUBLIC_SNAPSHOTS
			do
				((SNAPSHOT_PUBLIC+=1))
				if [[ $SNAPSHOT_PUBLIC == 1 ]]; then
					FAILS="${FAILS}$SNAPSHOT"
				else
					FAILS="${FAILS}, $SNAPSHOT"
				fi
			done
		fi
	fi
}


function performCheck {

	checkPublicSnapshots

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			Every EBS snapshot owned by the account should be set to private, meaning it shouldn't
				be restorable by anyone.
SEVERITY:		CRITICAL
TYPE:			$TYPE
STATUS:			$STATUS
SNAPSHOTS TOTAL:	$SNAPSHOT_TOTAL
CHECK PASSED FOR:	$SNAPSHOT_PRIVATE
CHECK FAILED FOR:  	$SNAPSHOT_PUBLIC
PUBLIC SNAPSHOTS:	$FAILS
	
MITIGATION:		Every public snapshot mentioned should only allow select Account IDs to form a new EBS volume
				on the basis of the respective snapshot. As snapshots contain highly sensitive data they should
				never be public by default, only if intended.
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





