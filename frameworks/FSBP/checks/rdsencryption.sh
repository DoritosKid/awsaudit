#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=5
TYPE="RDS"
SEVERITY="3"
STATUS=""

RDS_TOTAL=0
FAILS=""
RDS_PASSED=0
RDS_FAILED=0

CHECKED="$(aws rds describe-db-instances --profile $AWS_PROFILE --query 'DBInstances[].DBInstanceIdentifier[]' --output text)"
RDS_TOTAL=`echo "$CHECKED" | wc -w`

function checkRDSEncryption {
	PASS="$(aws rds describe-db-instances --profile $AWS_PROFILE --db-instance-identifier $1 \
	--query "*[].{StorageEncrypted:StorageEncrypted}" --output text)"

	if [[ $PASS == "True" ]]; then
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
			checkRDSEncryption $instance
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
CHECK:			Every root storage of every RDS instance should be enycrypted.
SEVERITY:		MEDIUM
TYPE:			$TYPE
STATUS:			$STATUS
INSTANCE TOTAL:		$RDS_TOTAL
CHECK PASSED FOR:	$RDS_PASSED
CHECK FAILED FOR:  	$RDS_FAILED
UNENCRYPTED RDS:	$FAILS
	
MITIGATION:		Manually turn on the encryption for every RDS instance mentioned. This allows for the instance
			itself, its snapshots, backups and read replicas to be encrypted as well, which greatly mitigates
			security risks for sensitive data.
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





