#!/bin/bash
if [ "$#" -lt 1 ]; then
  echo "Usage:"
  echo "$0 dal|wdc|..|syd tfvars_dir s3cmd_dir" >&2
  echo
  echo e.g. ./terraform.sh wdc . /var/lib/jenkins/s3cmd
  echo
  exit 1
fi

region_prefix=$1
tfvars_dir=$WORKDIR
s3cmd_dir=$WORKDIR

# some constants
bucket_name=$BUCKET_NAME
annotation="Pre GA"
version=1
hashkey=4cf9f522f799bf27cc8a1275e9505f469a4a795d

export TF_LOG="TRACE"
export TF_LOG_PATH="tf_apply_trace.log"

# take curent time for use with terraform
starttime=$(date -u +%s)

base_name=${region_prefix}-$starttime
tfstatefile="terraform.tfstate.d/${base_name}/terraform.tfstate"

tempfile_tfvars=/tmp/${region_prefix}-$starttime.tfvars
cp -v ${tfvars_dir}/${TERRAFORM_TFVARS} $tempfile_tfvars
chmod 600 $tempfile_tfvars

# load terraform variables from the temp file
while IFS= read -r line; do export $(echo $line | tr -d '"'); done < $tempfile_tfvars
s3cmd_cmd="/usr/bin/s3cmd -c ${s3cmd_dir}/s3cfg-us-geo"

cd /availability_single_zone
ls | grep logs
return_value=$?
if [ "$return_value" -ne 0 ]; then
    mkdir logs
fi
terraform workspace new $region_prefix-$starttime

terraform init

# get start date
year=$(date -u +%Y)
month=$(date -u +%m)
day=$(date -u +%d)
starttime=$(date -u +%s)

uuid=$starttime
newline="uuid=\"$starttime\""
sed -i "1s/.*/${newline}/" $tempfile_tfvars

TF_LOG_APPLY=logs/$uuid-apply.logs
echo "Writing results to $TF_LOG_APPLY, s3cmd=${s3cmd_cmd}, tempfile=${tempfile_tfvars}"
ls -l /tmp
return_value=$?
echo "now run terraform apply Exiting the script"
terraform apply -no-color -auto-approve -var-file=$tempfile_tfvars >$TF_LOG_APPLY 2>&1
return_value=$?

finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
    cp ${tfstatefile} logs
fi

# Create the measurement record
tempfile_provision=/tmp/$uuid-$REGION-provision.csv
echo $REGION,$service,$sku,$test_provision,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_provision


# wait for the Sentinel to finish the testruns
sleep $SLEEP_TIME

starttime=$(date -u +%s)

export TF_LOG_PATH="tf_destroy_trace.log"
TF_LOG_DESTROY=logs/$uuid-destroy.logs
terraform destroy -no-color -auto-approve -var-file=$tempfile_tfvars >$TF_LOG_DESTROY 2>&1
return_value=$?

finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
    cp ${tfstatefile} logs
fi
echo $UPLOAD_TO_COS
if [ "$UPLOAD_TO_COS" == "yes" ]; then
    # create the measurement record
    tempfile_terminate=/tmp/$uuid-$REGION-terminate.csv
    #echo $region,$service,$sku,$test_date,$test_terminate,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_terminate
    echo $REGION,$service,$sku,$test_terminate,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_terminate
    # upload the measurements to cos, terminate record first
    $s3cmd_cmd put $tempfile_terminate s3://$bucket_name/$REGION/$service/$sku/$year/$month/$day/$test_terminate/$uuid.csv
    $s3cmd_cmd put $TF_LOG_DESTROY s3://$bucket_name/$REGION/$service/$sku/$year/$month/$day/$test_terminate/$uuid.logs

    ## upload the provision record last
    $s3cmd_cmd put $tempfile_provision s3://$bucket_name/$REGION/$service/$sku/$year/$month/$day/$test_provision/$uuid.csv
    $s3cmd_cmd put $TF_LOG_APPLY s3://$bucket_name/$REGION/$service/$sku/$year/$month/$day/$test_provision/$uuid.logs
fi



# delete the temp files
rm -f $tempfile_terminate
rm -f $tempfile_provision
rm -f $tempfile_tfvars
rm -rf terraform.tfstate.d
