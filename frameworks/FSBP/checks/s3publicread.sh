#!/bin/bash

AWS_PROFILE=$1

CHECK_ID=9
TYPE="S3"
SEVERITY="4"
STATUS=""

S3_TOTAL=0
FAILS=""
S3_PUBLIC=0
S3_PRIVATE=0

CHECKED="$(aws s3api list-buckets --profile $AWS_PROFILE --query 'Buckets[].Name[]' --output text)"
S3_TOTAL=`echo "$CHECKED" | wc -w`

function checkS3ACLReadPolicy {
	BUCKETACL="$(aws s3api get-bucket-acl --profile $AWS_PROFILE --bucket $1 --output text)"

	BUCKETACL=`echo $BUCKETACL | xargs`

	if [[ $BUCKETACL == *"GRANTS READ GRANTEE Group http://acs.amazonaws.com/groups/global/AllUsers"* ]]; then
		((S3_PUBLIC+=1))
		if [[ $S3_PUBLIC == 1 ]]; then
			FAILS="${FAILS}$1"
		else
			FAILS="${FAILS}, $1"
		fi
	elif [[ $BUCKETACL == *"GRANTS READ GRANTEE Group http://acs.amazonaws.com/groups/global/AuthenticatedUsers"* ]]; then
		((S3_PUBLIC+=1))
		if [[ $S3_PUBLIC == 1 ]]; then
			FAILS="${FAILS}$1"
		else
			FAILS="${FAILS}, $1"
		fi
	else
		((S3_PRIVATE+=1))
	fi



}

function begin {

	if [[ $S3_TOTAL != 0 ]]; then
		for bucket in $CHECKED
		do
			checkS3ACLReadPolicy $bucket
	  	done
	else
		STATUS="SKIPPED"
	fi
	
  	if [[ $S3_PRIVATE == $S3_TOTAL ]]; then
		STATUS="PASSED"
	else
		STATUS="FAILED"
	fi
}


function performCheck {

	begin

	if [[ $STATUS == "FAILED" ]]; then

	echo "
CHECK:			Every S3 Bucket should prohibit public read access to resources.
SEVERITY:		HIGH
TYPE:			$TYPE
STATUS:			$STATUS
BUCKETS TOTAL:		$S3_TOTAL
CHECK PASSED FOR:	$S3_PRIVATE
CHECK FAILED FOR:  	$S3_PUBLIC
PUBLIC BUCKETS:		$FAILS
	
MITIGATION:		Update the ACL of every bucket mentioned to not allow public read access to bucket objects 
			for the bucket as a whole. No S3 bucket, unless intended otherwise, should allow its resources
			to be publically and globally readable to ensure the integrity and security of the data.
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





