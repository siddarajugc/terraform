#!/bin/bash
if [ "$#" -lt 1 ]; then
  echo "Usage:"
  echo "$0 dal|wdc|..|syd tfvars_dir s3cmd_dir" >&2
  echo
  echo e.g. ./terraform.sh wdc . /var/lib/jenkins/s3cmd
  echo
  exit 1
fi

# get start date
year=$(date -u +%Y)
month=$(date -u +%m)
day=$(date -u +%d)
starttime=$(date -u +%s)

uuid=$starttime

cd /availability_prefil_volume
ls | grep logs
return_value=$?
if [ "$return_value" -ne 0 ]; then
    mkdir logs
fi

region_prefix=$1
tfvars_dir=$WORKDIR


tempfile_tfvars="logs/${region_prefix}-$starttime.tfvars"
TF_LOG_APPLY="logs/$uuid-apply.logs"
TF_OUTPUT_FILE="logs/output.json"
TF_LOG_DESTROY="logs/$uuid-destroy.logs"
#TF_VOLUME_ID="logs/volumes_id.logs"

cp -v ${tfvars_dir}/terraform_${region_prefix}.tfvars $tempfile_tfvars
chmod 600 $tempfile_tfvars

# load terraform variables from the temp file

while IFS= read -r line; do export $(echo $line | tr -d '"'); done < "$tempfile_tfvars"
terraform workspace new $region_prefix-$starttime

terraform init

terraform apply -auto-approve -no-color -var-file=$tempfile_tfvars 2>>$TF_LOG_APPLY 1>>$TF_LOG_APPLY
terraform output -json > $TF_OUTPUT_FILE
#cat $TF_OUTPUT_FILE | jq '.volume_ID.value[].id' > $TF_VOLUME_ID
echo "Terraform tfvars file: $tempfile_tfvars"
echo "Terraform log file: $TF_LOG_APPLY"
echo "terraform apply -auto-approve -no-color -var-file=$tempfile_tfvars"
echo "terraform destroy -auto-approve -no-color -var-file=$tempfile_tfvars"

return_value=$?
if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
    cp ${tfstatefile} logs
fi

terraform state rm ibm_is_volume.acadia_prefil_volume
echo "removed terraform resources"

export TF_LOG_PATH="tf_destroy_trace.log"
terraform destroy -no-color -auto-approve -var-file=$tempfile_tfvars 2>>$TF_LOG_DESTROY 1>>$TF_LOG_DESTROY
return_value=$?

finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

if [ "$return_value" -ne 0 ]; then
    mv $TF_LOG_PATH logs
    cp ${tfstatefile} logs
fi
echo "destroyed resources"

# delete the temp files
rm -f $tempfile_tfvars

