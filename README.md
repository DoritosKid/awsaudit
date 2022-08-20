AWS Audit CLI

  Usage: $name [command] [flag]

  Commands: 
    
    setup   -multi                                    Sets up the AWS CLI configuration for every profile
    setup   -single [profile] [account_id] [region]   Sets up the AWS CLI configuration for a specific profile
    backup                                            Backs up the current AWS CLI configuration
    restore                                           Restores the backed up AWS CLI configuration     

  Flags:

    -p      [profile]       AWS config profile to use for auditing
    -c      list            Gives a list of all available checks with their Ids
    -c      [check_Id]      Performs the check with the given Id
    -h                      Opens the help menu





Prerequisites:

1. Setup the AWS CLI
		- AWS CLI v2 is installed

2. Create the awsaudit IAM role in all necessary AWS accounts
		- An IAM role with the name "awsaudit" needs to be created
		- On creation, make sure to include the following role policies:
	    	a) ViewOnlyAccess
	    	b) IAMReadOnlyAccess
	    	c) SecurityAudit
	    - All of these are policies are maintained and provided by AWS
	    - Inlcude the following policy:
			  {
			    "Version": "2012-10-17",
			    "Statement": [
			        {
			            "Effect": "Allow",
			            "Principal": {
			                "AWS": "arn:aws:iam::<ORGANIZATION-ACCOUNT-ID>:root"
			            },
			            "Action": "sts:AssumeRole"
			        }
			    ]
				}
			- For a full audit with multi-account setup, make sure that every profile defined
				in your AWS CLI config can access the role in the AWS account

3. Creating the IAM policy for the technical user
		- An IAM policy needs to be created which is used by the technical user talked about in the next step
		- The name of this policy is insignificant, but it needs to look like this:
			{
				"Version": "2012-10-17",
				"Statement": [
				    {
				        "Sid": "",
				        "Effect": "Allow",
				        "Action": "sts:AssumeRole",
				        "Resource": "arn:aws:iam::\*:role/awsaudit"
				    }
				]
			}
		- Make sure that the policy is created in the organization account

4. Creating the technical IAM user in the desired AWS account
		- An IAM user with the name "awsaudit" needs to be created
		- For single account setups make sure to create the user in the desired account
		- For multi account setups make sure to create the user in the SSO account (organization account)
		- On creation, make sure to include the IAM policy created in the previous step
		- Also make sure that you create a user with the correct access type (via access key)

5. Updating the credentials file
		- Open the credentials.txt under awsaudit/config/credentials.txt
		- Put in the correct access info which we obtained from the technical user created prior
		- The updated file should look like this:
	    [audit-profile]
			aws_access_key_id = XXXXXXXXXXXXXXX
			aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Setup:

1. Back up your current AWS config and credentials, since they will be tampered with by the tool.
	 The backed up config can be found under awsaudit/config/backup
   "./awsaudit backup"

2. Run the setup to create the AWS config profiles, which allows the program to assume the identity
   of the technical user (via the credentials file) and switch into the awsaudit role on every account
   For multi a account setup use:
   "./awsaudit setup -multi"
   For a single account setup use:
   "./awsaudit setup -single <PROFILE-NAME> <ACCOUNT-ID> <REGION>"

Re-setup:

1. Restore the backed up config or manually delete the audit profile entries from the AWS config file
	 "./awsaudit restore"
2. Delete the previously backed up files from awsaudit/config/backup
3. Clear everything in awsaudit/config/config.txt so that it is an empty .txt file
4. Backup again
5. Run setup