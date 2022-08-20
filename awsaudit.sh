#!/bin/bash

set -e
export AWSAUDIT_WORKDIR=$(cd $(dirname $0) && pwd)
export RESULT_DIR="$AWSAUDIT_WORKDIR/results/report.txt"

function help {
  name=${0##*/}
  echo "

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
  "
  exit 1
}

AWS_PROFILE=""
CHECK_ID=""


FINAL_SCORE=0
FULL_AUDIT=""
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0
CRITICAL_FAILS=0
HIGH_FAILS=0
MEDIUM_FAILS=0

CLOUDTRAIL_CHECKED=false



function printStatus {
  SCORE=$1
  ID=$2

  CHECKS_TOTAL=$((CHECKS_TOTAL+=1))

  if [[ $SCORE == -1 || $SCORE == 0 ]]; then

    echo "[INFO] Passed Check #$ID"
    echo ""
    ((CHECKS_PASSED+=1))
  else
    echo "[INFO] Failed Check #$ID"
    echo ""
    ((CHECKS_FAILED+=1))
  fi
}

function check1 {
  echo "[INFO] Checking for missing MFA..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/CIS/checks/mfa.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no human IAM users were found"
  elif [[ $SCORE > 0 ]]; then
    ((HIGH_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 1
}

function check2 {

  #This check needs to be done only once as not every account needs to have a multi-regional trail
  if [[ $CLOUDTRAIL_CHECKED == false ]]; then
    echo "[INFO] Checking for multiregional CloudTrail..."

    SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/CIS/checks/cloudtrail.sh $1`

    if [[ $SCORE > 0 ]]; then
      ((HIGH_FAILS+=1))
      ((FINAL_SCORE += SCORE))
    fi

    CLOUDTRAIL_CHECKED=true

    printStatus $SCORE 2
  fi
}

function check3 {
  echo "[INFO] Checking security groups for misconfigured ingress on Port 22..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/CIS/checks/ingress22.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no security groups were found"
  elif [[ $SCORE > 0 ]]; then
    ((HIGH_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 3
}

function check4 {
  echo "[INFO] Checking security groups for misconfigured ingress on Port 3389..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/CIS/checks/ingress3389.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no security groups were found"
  elif [[ $SCORE > 0 ]]; then
    ((HIGH_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 4
}

function check5 {
  echo "[INFO] Checking RDS instances for storage encryption..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/rdsencryption.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no RDS instances were found"
  elif [[ $SCORE > 0 ]]; then
    ((MEDIUM_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 5
}

function check6 {
  echo "[INFO] Checking RDS instances for public snapshots..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/rdsprivatesnapshots.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no RDS snapshots were found"
  elif [[ $SCORE > 0 ]]; then
    ((CRITICAL_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 6
}

function check7 {
  echo "[INFO] Checking RDS instances for public access..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/rdsprivateaccess.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no RDS instances were found"
  elif [[ $SCORE > 0 ]]; then
    ((CRITICAL_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 7
}

function check8 {
  echo "[INFO] Checking EBS volumes for public snapshots..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/ebsprivatesnapshots.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no EBS snapshots were found"
  elif [[ $SCORE > 0 ]]; then
    ((HIGH_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 8
}

function check9 {
  echo "[INFO] Checking S3 buckets for public read access..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/s3publicread.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no S3 buckets were found"
  elif [[ $SCORE > 0 ]]; then
    ((HIGH_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 9
}

function check10 {
  echo "[INFO] Checking S3 buckets for public write access..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/s3publicwrite.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no S3 buckets were found"
  elif [[ $SCORE > 0 ]]; then
    ((CRITICAL_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 10
}

function check11 {
  echo "[INFO] Checking S3 buckets for storage encryption..."

  SCORE=`bash $AWSAUDIT_WORKDIR/frameworks/FSBP/checks/s3encryption.sh $1`

  if [[ $SCORE == -1 ]]; then
    echo "[INFO] Skipped checking, because no S3 buckets were found"
  elif [[ $SCORE > 0 ]]; then
    ((MEDIUM_FAILS+=1))
    ((FINAL_SCORE += SCORE))
  fi

  printStatus $SCORE 11
}

function checkSingleProfile {
  
  if [[ ! -z $CHECK_ID ]]; then
  echo "-------------------------OVERVIEW: ${AWS_PROFILE::-6}-------------------------" >> $RESULT_DIR
  echo ""

    echo "[INFO] Beginning Check #${CHECK_ID: -1} for ${AWS_PROFILE::-6}..."

    CHECK=$CHECK_ID
    $CHECK $AWS_PROFILE

    echo "[SUCCESS] Finished the selected Check"
    echo ""
    
  else
  echo "-------------------------OVERVIEW: ${1::-6}-------------------------" >> $RESULT_DIR
  echo ""

    echo "[INFO] Beginning Checks for ${1::-6}..."

    check1 $1
    check2 $AWS_ACCOUNTS
    check3 $1
    check4 $1
    check5 $1
    check6 $1
    check7 $1
    check8 $1
    check9 $1
    check10 $1
    check11 $1

    echo "[SUCCESS] Finished the selected Checks"
    echo ""
  fi
}

function checkAllProfiles {
  FULL_AUDIT=true
  for PROFILE in $(echo $AWS_ACCOUNTS | sed "s/,/ /g")
  do
    checkSingleProfile $PROFILE
  done
}

function performAudit {

  if [[ -f $RESULT_DIR ]]; then
    rm $RESULT_DIR
  fi

  if [[ $AWS_ACCOUNTS == *","* ]] && [ -z "$AWS_PROFILE" ]; then
    checkAllProfiles

    if [[ $FULL_AUDIT == true ]]; then
      echo "[SUCCESS] Finished auditing with the following verdict:"
      echo ""
      echo "NUMBER OF CHECKS: $CHECKS_TOTAL"
      echo "CHECKS PASSED:    $CHECKS_PASSED"
      echo "CHECKS FAILED:    $CHECKS_FAILED"
      echo ""
      echo "CRITICAL RISK FAILS: $CRITICAL_FAILS"
      echo "HIGH RISK FAILS:          $HIGH_FAILS"
      echo "MEDIUM RISK FAILS:        $MEDIUM_FAILS"
      echo ""

      #This is important, so that the full verdict is also part of the report
      echo "Finished auditing with the following verdict:" >> $RESULT_DIR
      echo "" >> $RESULT_DIR
      echo "NUMBER OF CHECKS: $CHECKS_TOTAL" >> $RESULT_DIR
      echo "CHECKS PASSED:    $CHECKS_PASSED" >> $RESULT_DIR
      echo "CHECKS FAILED:    $CHECKS_FAILED" >> $RESULT_DIR
      echo "" >> $RESULT_DIR
      echo "CRITICAL RISK FAILS: $CRITICAL_FAILS" >> $RESULT_DIR
      echo "HIGH RISK FAILS:          $HIGH_FAILS" >> $RESULT_DIR
      echo "MEDIUM RISK FAILS:        $MEDIUM_FAILS" >> $RESULT_DIR
      echo "" >> $RESULT_DIR


      NUMBER_OF_ACCOUNTS=`echo $(echo $AWS_ACCOUNTS | sed "s/,/ /g") | wc -w`

      if [[ $FINAL_SCORE -gt $((3*NUMBER_OF_ACCOUNTS)) ]]; then
        echo "OVERALL VERDICT:  HIGH SECURITY RISK"
        echo "OVERALL VERDICT:  HIGH SECURITY RISK" >> $RESULT_DIR
      elif [[ $FINAL_SCORE -gt $((2*NUMBER_OF_ACCOUNTS)) ]]; then
        echo "OVERALL VERDICT:  MEDIUM SECURITY RISK"
        echo "OVERALL VERDICT:  MEDIUM SECURITY RISK" >> $RESULT_DIR
      elif [[ $FINAL_SCORE -lt $((1*NUMBER_OF_ACCOUNTS)) ]]; then
        if [[ $CRITICAL_FAILS -gt 0 ]]; then
          echo "OVERALL VERDICT:  MEDIUM SECURITY RISK"
          echo "OVERALL VERDICT:  MEDIUM SECURITY RISK" >> $RESULT_DIR
        else 
          echo "OVERALL VERDICT:  LOW SECURITY RISK"
          echo "OVERALL VERDICT:  LOW SECURITY RISK" >> $RESULT_DIR
        fi
      fi
    fi
  else
    checkSingleProfile $AWS_PROFILE
  fi

  echo ""
  echo "A detailed view on every failed check can be found in the report.txt file"
}

echo $AWS_ACCOUNTS

#Handling Flags
while getopts "p:c:" option;
do
  case "$option" in
    p) 
      if [[ $OPTARG == *$AWS_ACCOUNTS* ]]; then
        AWS_PROFILE="$OPTARG-audit"
      else 
        echo "[ERROR] Given profile could not be found, please make sure it was included in the setup"
        exit
      fi
      ;;
    c)
      if [[ $OPTARG == "list" ]]; then
        bash $AWSAUDIT_WORKDIR/common/getChecks.sh
        exit 
      elif (( $OPTARG > 0 && $OPTARG <= 11)); then
          CHECK_ID="check$OPTARG"
      else 
          echo "[ERROR] Check with the given Id could not be found"
          exit
      fi
      ;;  
    *)
      help
      ;;  
  esac
done

shift $((OPTIND-1))

#Handling Commands
case "$1" in
  setup)
    case "$2" in
      -single)
        echo "Setting up single-account configuration for" $3 $4 $5
        bash $AWSAUDIT_WORKDIR/commands/setup.sh $2 $3 $4 $5 
        exit
        ;;
      -multi)
        echo "Setting up multi-account configuration..."
        bash $AWSAUDIT_WORKDIR/commands/setup.sh $2
        exit
        ;;
      *)
        help
        ;;
    esac
    ;;
  backup)
    echo "Backing up configuration..."
    bash $AWSAUDIT_WORKDIR/commands/backup.sh
    exit
    ;;
  restore)
    echo "Restoring configuration..."
    bash $AWSAUDIT_WORKDIR/commands/restore.sh
    exit
    ;;
esac

AWS_ACCOUNTS=$(bash $AWSAUDIT_WORKDIR/common/getAccountsFromConfig.sh)

performAudit 2> /dev/null