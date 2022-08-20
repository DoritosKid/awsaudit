#!/bin/bash

function check1Desc {
	echo "CheckId:	1"
	echo "Description:	Every user with a console password should have MFA enabled."
	echo "Severity:	HIGH"
}

function check2Desc {
	echo "CheckId:	2"
	echo "Description:	There should be at least one Trail enabled, which is configured to be multi-regional."
	echo "Severity:	HIGH"
}

function check3Desc {
	echo "CheckId:	3"
	echo "Description:	No security groups should allow incoming traffic from 0.0.0.0/0 to Port 22."
	echo "Severity:	HIGH"
}

function check4Desc {
	echo "CheckId:	4"
	echo "Description:	No security groups should allow incoming traffic from 0.0.0.0/0 to Port 3389."
	echo "Severity:	HIGH"
}

function check5Desc {
	echo "CheckId:	5"
	echo "Description:	Every root storage of every RDS instance should be enycrypted."
	echo "Severity:	MEDIUM"
}

function check6Desc {
	echo "CheckId:	6"
	echo "Description:	Every manual or automated RDS snapshot should be set to private."
	echo "Severity:	CRITICAL"
}

function check7Desc {
	echo "CheckId:	7"
	echo "Description:	Every RDS instance should prohibit public access."
	echo "Severity:	CRITICAL"
}

function check8Desc {
	echo "CheckId:	8"
	echo "Description:	Every EBS snapshot owned by the account should be set to private, meaning it shouldn't be restorable by anyone."
	echo "Severity:	HIGH"
}

function check9Desc {
	echo "CheckId:	9"
	echo "Description:	Every S3 Bucket should prohibit public read access to resources."
	echo "Severity:	HIGH"
}

function check10Desc {
	echo "CheckId:	10"
	echo "Description:	Every S3 Bucket should prohibit public read access to resources."
	echo "Severity:	CRITICAL"
}

function check11Desc {
	echo "CheckId:	11"
	echo "Description:	Every S3 Bucket should at least be encrypted on the server-side."
	echo "Severity:	MEDIUM"
}

check1Desc
echo ""
check2Desc
echo ""
check3Desc
echo ""
check4Desc
echo ""
check5Desc
echo ""
check6Desc
echo ""
check7Desc
echo ""
check8Desc
echo ""
check9Desc
echo ""
check10Desc
echo ""
check11Desc
echo ""
