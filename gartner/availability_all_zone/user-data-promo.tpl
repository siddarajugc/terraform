#!/bin/bash -x
touch /root/abc
sleep 20
apt-get update -y
apt-get install -y fio
#apt-get install -y stress-ng
apt-get install  python-is-python3
apt-get install -y python3-dateutil
apt-get install -y git
cd /root
git clone https://github.com/s3tools/s3cmd.git
return_value=$?
if [ "$return_value" -ne 0 ]; then
    sleep 10
    git clone https://github.com/s3tools/s3cmd.git
fi

touch /tmp/STARTED

#define variables for any child bash shells
cat <<- EOF > /tmp/variables.sh
#!/bin/bash
region=${region}
zone=${zone}
group=${group}
ordinal=${ordinal}
sku=${sku}
service=${service}
test_provision=${test_provision}
test_terminate=${test_terminate}
test_data=${test_data}
destination=${destination}
uuid=${uuid}
access_key=${access_key}
secret_key=${secret_key}
EOF

source /tmp/variables.sh

s3cmd_dir=/root/s3cmd
# s3cmd_cmd="$s3cmd_dir/s3cmd -c $s3cmd_dir/s3cfg-${region}"
s3cmd_cmd="$s3cmd_dir/s3cmd -c $s3cmd_dir/s3cfg-us-geo"

bucket_name="cos-acadia-gartner"

# cat <<- EOF > $s3cmd_dir/s3cfg-$region
cat <<- EOF > $s3cmd_dir/s3cfg-us-geo
access_key = ${access_key}
check_ssl_certificate = True
check_ssl_hostname = True
connection_pooling = True
default_mime_type = binary/octet-stream
enable_multipart = True
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = ausgen
guess_mime_type = True
host_base = ${destination}
host_bucket = %(bucket)s.${destination}
multipart_chunk_size_mb = 15
multipart_copy_chunk_size_mb = 1024
multipart_max_chunks = 10000
preserve_attrs = True
progress_meter = True
public_url_use_https = False
put_continue = False
recursive = False
recv_chunk = 65536
restore_days = 1
restore_priority = Standard
secret_key = $secret_key
send_chunk = 65536
signature_v2 = False
signurl_use_https = False
skip_existing = False
socket_timeout = 300
throttle_max = 100
urlencoding_mode = normal
use_https = True
use_mime_magic = True
EOF

annotation="Pre GA"
version=1
hashkey=4cf9f522f799bf27cc8a1275e9505f469a4a795d

year=$(date -u "+%Y" -d @$uuid)
month=$(date -u "+%m" -d @$uuid)
day=$(date -u "+%d" -d @$uuid)
starttime=$(date -u +%s)

sleep 10
echo "user-data-int.tpl"
#run fio on data volume
mkdir outputs
lsblk > ~/outputs/lsblk.txt
cat ~/outputs/lsblk.txt
for a in {randrw,}
 do
  printf "Starting $a"
  for bs in {4k,}
   do
    for iodpth in {1,}
     do
     for njobs in {1,4,8}
      do
      printf "=============="
      #modify output file names accordingly
      fio --filename=/dev/vdd --direct=1 --rw=$a --rwmixread=70 --rwmixwrite=30 --bs=$bs --iodepth=$iodpth --numjobs=$njobs --runtime=300 --time_based --group_reporting --name=throughput-test-job --eta-newline=1 --ioengine=posixaio --output-format=json,normal > ~/outputs/$a-1TB_custumIOPs_vol_$bs-bs_$iodpth-iodepth_$njobs-numjobs.json
      grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print "CPU Usage : " usage "%"}'
      free -t | awk 'NR == 2 {printf("Current Memory Utilization is : %.2f%\n"), $3/$2*100}' > ~/outputs/$a_2_10_vols_$i_bs_$j_iodepth.txt
      head -16 ~/outputs/$a_1TB_10IOPs_vol_$bs_bs_$iodpth_iodepth_$njobs_numjobs.json
      echo "done with $bs Block & $iodpth iodepth & $njobs numjobs"
      printf "==============\n==============\n\n"
     done
   done
  done
 filename=fio-$a-1TB_custumIOPs_vol_$(date +'%d-%m-%y:%R').tar.gz
 cp /var/log/cloud-init-output.log ~/outputs/
 tar -zcvf /tmp/$filename ./outputs/
 $s3cmd_cmd put /tmp/$filename s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename
 rm ./outputs/*json ./outputs/*txt
 printf "done with $a\n\n\n\n"
 done


# find the finish time
finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

# convert the startime to utc string
test_date=$(date -u "+%Y-%m-%d %H:%M:%S" -d @$starttime)Z

# construct the mesaurement record
msecs=$(date -u +%6N)
filename=${uuid}-${zone}-$msecs.csv
fio_result=${uuid}-${zone}-fio_output.json
echo $region,$service,$sku,$test_date,$test_data,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > /tmp/$filename

$s3cmd_cmd put /tmp/$filename s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename
return_value=$?
if [ "$return_value" -ne 0 ]; then
    sleep 10
    $s3cmd_cmd put /tmp/$filename s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename
fi

touch /tmp/DONE
filename_cloudinit_log=${uuid}-${zone}-cloudinit.log
$s3cmd_cmd put /var/log/cloud-init-output.log s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename_cloudinit_log
