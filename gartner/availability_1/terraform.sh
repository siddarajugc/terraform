#!/bin/bash
if [ "$#" -lt 3 ]; then
  echo "Usage:"
  echo "$0 dal|wdc|..|syd tfvars_dir s3cmd_dir" >&2
  echo
  echo e.g. ./terraform.sh wdc . /var/lib/jenkins/s3cmd
  echo
  exit 1
fi

export IBMCLOUD_RESOURCE_MANAGEMENT_API_ENDPOINT=https://resource-controller.test.cloud.ibm.com
export IBMCLOUD_IAM_API_ENDPOINT=https://iam.test.cloud.ibm.com
export IBMCLOUD_RESOURCE_CONTROLLER_API_ENDPOINT=https://resource-controller.test.cloud.ibm.com
export IBMCLOUD_GT_API_ENDPOINT="https://tags.global-search-tagging.test.cloud.ibm.com"
export IBMCLOUD_RESOURCE_CATALOG_API_ENDPOINT="https://globalcatalog.test.cloud.ibm.com"
export IBMCLOUD_IAM_API_ENDPOINT="https://iam.test.cloud.ibm.com"
export IBMCLOUD_IS_NG_API_ENDPOINT="https://us-south-genesis-dal-dev98-etcd.iaasdev.cloud.ibm.com/v1"

region_prefix=$1
tfvars_dir=$2
s3cmd_dir=$3

# some constants
bucket_name="cos-acadia-gartner"
annotation="Pre GA"
version=1
hashkey=4cf9f522f799bf27cc8a1275e9505f469a4a795d

export TF_LOG="TRACE"
export TF_LOG_PATH="tf_apply_trace.log"

# take curent time for use with terraform
starttime=$(date -u +%s)
tempfile_tfvars=/tmp/${region_prefix}-$starttime.tfvars
cp -v ${tfvars_dir}/terraform_${region_prefix}.tfvars $tempfile_tfvars
chmod 600 $tempfile_tfvars

# load terraform variables from the temp file
while IFS= read -r line; do export $(echo $line | tr -d '"'); done < $tempfile_tfvars
s3cmd_cmd="${s3cmd_dir}/s3cmd/s3cmd -c ${s3cmd_dir}/s3cfg-us-geo"

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
terraform apply -auto-approve -var-file=$tempfile_tfvars 2>>$TF_LOG_APPLY 1>>$TF_LOG_APPLY
return_value=$?


finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
fi

# convert the startime to utc string
#test_date=$(date -u "+%Y-%m-%d %H:%M:%S" -d @$starttime)Z

# Create the measurement record
tempfile_provision=/tmp/$uuid-$region-provision.csv
echo $region,$service,$sku,$test_provision,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_provision
#echo $region,$service,$sku,$test_date,$test_provision,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_provision

# wait for the Sentinel to finish the testruns
sleep 200

starttime=$(date -u +%s)

export TF_LOG_PATH="tf_destroy_trace.log"
TF_LOG_DESTROY=logs/$uuid-destroy.logs
terraform destroy -auto-approve -var-file=$tempfile_tfvars 2>>$TF_LOG_DESTROY 1>>$TF_LOG_DESTROY
return_value=$?

finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
fi

# convert the startime to utc string
#test_date=$(date -u "+%Y-%m-%d %H:%M:%S" -d @$starttime)Z


# create the measurement record
tempfile_terminate=/tmp/$uuid-$region-terminate.csv
#echo $region,$service,$sku,$test_date,$test_terminate,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_terminate
echo $region,$service,$sku,$test_terminate,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > $tempfile_terminate
# upload the measurements to cos, terminate record first
$s3cmd_cmd put $tempfile_terminate s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_terminate/$uuid.csv
$s3cmd_cmd put $TF_LOG_DESTROY s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_terminate/$uuid.logs
#
## upload the provision record last
$s3cmd_cmd put $tempfile_provision s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_provision/$uuid.csv
$s3cmd_cmd put $TF_LOG_APPLY s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_provision/$uuid.logs

# delete the temp files
rm -f $tempfile_terminate
rm -f $tempfile_provision
rm -f $tempfile_tfvars
