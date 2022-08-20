#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=11
TYPE="S3"
SEVERITY="3"
STATUS=""

S3_TOTAL=0
FAILS=""
S3_PASSED=0
S3_FAILED=0

CHECKED="$(aws s3api list-buckets --profile $AWS_PROFILE --query 'Buckets[].Name[]' --output text)"
S3_TOTAL=`echo "$CHECKED" | wc -w`

function checkS3Encryption {
	ENCRYPTION="$(aws s3api get-bucket-encryption --profile $AWS_PROFILE --bucket $1 --output json 2> /dev/null)"

	if [[ ! -z $ENCRYPTION ]]; then
		((S3_PASSED+=1))
	else
		((S3_FAILED+=1))
		if [[ -z $FAILS ]]; then
				FAILS="${FAILS}$1"
			else
				FAILS="${FAILS}, $1"
		fi
	fi
}

function begin {

	if [[ $S3_TOTAL != 0 ]]; then
		for bucket in $CHECKED
		do
			checkS3Encryption $bucket
	  	done
	else
		STATUS="SKIPPED"
	fi
	
  	if [[ $S3_PASSED == $S3_TOTAL ]]; then
		STATUS="PASSED"
	else
		STATUS="FAILED"
	fi
}


function performCheck {

	begin

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			Every S3 Bucket should at least be encrypted on the server-side.
SEVERITY:		MEDIUM
TYPE:			$TYPE
STATUS:			$STATUS
BUCKETS TOTAL:		$S3_TOTAL
CHECK PASSED FOR:	$S3_PASSED
CHECK FAILED FOR:  	$S3_FAILED
UNENCRYPTED BUCKETS:		$FAILS
	
MITIGATION:		Activate a form of server-side encryption for every bucket mentioned. AWS supports server-side
			encryption via AES-256 or AWS-KMS, the latter being harder to configurate initially but providing
			even more security.

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





