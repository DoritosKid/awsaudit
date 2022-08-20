#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=6
TYPE="RDS"
SEVERITY="5"
STATUS=""

SNAPSHOT_TOTAL=0
FAILS=""
SNAPSHOT_PRIVATE=0
SNAPSHOT_PUBLIC=0

CHECKED="$(aws rds describe-db-snapshots --profile $AWS_PROFILE --query 'DBSnapshots[*].DBSnapshotIdentifier' --output text)"
SNAPSHOT_TOTAL=`echo "$CHECKED" | wc -w`

function checkPublicSnapshots {

	if [[ SNAPSHOT_TOTAL == 0 ]]; then
		STATUS="SKIPPED"
	else
		PUBLIC_SNAPSHOTS="$(aws rds describe-db-snapshots --profile $AWS_PROFILE --snapshot-type public \
		--query 'DBSnapshots[*].DBSnapshotIdentifier' --output text)"

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
CHECK:			Every manual or automated RDS snapshot should be set to private.
SEVERITY:		CRITICAL
TYPE:			$TYPE
STATUS:			$STATUS
SNAPSHOTS TOTAL:	$SNAPSHOT_TOTAL
CHECK PASSED FOR:	$SNAPSHOT_PRIVATE
CHECK FAILED FOR:  	$SNAPSHOT_PUBLIC
PUBLIC SNAPSHOTS:	$FAILS
	
MITIGATION:		All of the mentioned snapshots, if not intionally set to public, should be set to private.
				If snapshots are set to public, they propose an unintended risk of data exposure of their
				respective RDS instance, since they are able to be read from by anyone on AWS.
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





