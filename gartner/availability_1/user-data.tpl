#!/bin/bash -x
touch /root/abc
sleep 100
apt-get update -y
apt-get install -y stress-ng
apt-get install -y python-dateutil
apt-get install -y git
cd /root
git
git clone https://github.com/s3tools/s3cmd.git

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

# some time delay before starting
sleep 20

# custom config with netplan, must use with a image with netplan installed
# sleep 15
# myhost=$(hostname)
# myip=$(hostname -I)
# echo "$myip $myhost" >> /etc/hosts
# ifname=$(ip a |awk ' $1 ~ /:/ { printf "%s,%s,", $2, $(NF-4);getline;printf "%s,", $2;getline; print $2 }' |grep -v  "lo:"| awk -F':' '{print $1}')
# ipaddr=$(ip a | awk '{print $2 }' | grep 10. | awk -F'/' '{print $1}')
# gateway=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
# sed -i "s/IFNAME/$ifname/g" /etc/netplan/availability.yaml
# sed -i "s/IPADDR/$ipaddr/g" /etc/netplan/availability.yaml
# sed -i "s/GATEWAY/$gateway/g" /etc/netplan/availability.yaml
# netplan generate
# netplan apply
# sleep 10

annotation="Pre GA"
version=1
hashkey=4cf9f522f799bf27cc8a1275e9505f469a4a795d

year=$(date -u "+%Y" -d @$uuid)
month=$(date -u "+%m" -d @$uuid)
day=$(date -u "+%d" -d @$uuid)
starttime=$(date -u +%s)

# run the data test
stress-ng --matrix 1 -t 10s
return_value=$?

# find the finish time
finishtime=$(date -u +%s)
let elapsedtime=$finishtime-$starttime

# convert the startime to utc string
test_date=$(date -u "+%Y-%m-%d %H:%M:%S" -d @$starttime)Z

# construct the mesaurement record
msecs=$(date -u +%6N)
filename=${uuid}-${zone}-$msecs.csv
echo $region,$service,$sku,$test_date,$test_data,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation,$version,$hashkey > /tmp/$filename

$s3cmd_cmd put /tmp/$filename s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename
return_value=$?
if [ "$return_value" -ne 0 ]; then
    sleep 10
    $s3cmd_cmd put /tmp/$filename s3://$bucket_name/$region/$service/$sku/$year/$month/$day/$test_data/$filename
fi

touch /tmp/DONE
