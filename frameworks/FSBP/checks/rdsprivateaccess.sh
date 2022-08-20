#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=7
TYPE="RDS"
SEVERITY="5"
STATUS=""

RDS_TOTAL=0
FAILS=""
RDS_PASSED=0
RDS_FAILED=0

CHECKED="$(aws rds describe-db-instances --profile $AWS_PROFILE --query 'DBInstances[].DBInstanceIdentifier[]' --output text)"
RDS_TOTAL=`echo "$CHECKED" | wc -w`

function checkRDSPublicAccess {
	PASS="$(aws rds describe-db-instances --profile $AWS_PROFILE --db-instance-identifier $1 \
	--query "*[].{PubliclyAccessible:PubliclyAccessible}" --output text)"

	if [[ $PASS == "False" ]]; then
		((RDS_PASSED+=1))
	else
		((RDS_FAILED+=1))
		if [[ -z $FAILS ]]; then
				FAILS="${FAILS}$1"
			else
				FAILS="${FAILS}, $1"
		fi
	fi

}

function begin {

	if [[ $RDS_TOTAL != 0 ]]; then
		for instance in $CHECKED
		do
			checkRDSPublicAccess $instance
	  	done
	else
		STATUS="SKIPPED"
	fi
	
  	if [[ $RDS_PASSED == $RDS_TOTAL ]]; then
		STATUS="PASSED"
	else
		STATUS="FAILED"
	fi
}

function performCheck {

	begin

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			Every RDS instance should prohibit public access.
SEVERITY:		CRITICAL
TYPE:			$TYPE
STATUS:			$STATUS
INSTANCE TOTAL:	$RDS_TOTAL
CHECK PASSED FOR:	$RDS_PASSED
CHECK FAILED FOR:  	$RDS_FAILED
PUBLIC RDS:	$FAILS
	
MITIGATION:		Set access for every RDS instance mentioned to private, unless intended otherwise. This prevents
			potentially malicious traffic to the database instance.
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





