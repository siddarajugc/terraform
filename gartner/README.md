# Gartner Availability Test Setup

Scripts used for Gartner Availability testing.

Since 1/15, scripts are no longer pulled from github in the test runs due to frequent connect failures to github from the jenkins server vm. In stead same set of files are copied to local dir on the test server vm.




# Terraform Setup

A dedicated account is used to setup resources like vpc, subnet, ssh key and public gateways. These are pre-created per MZR and the id's are put into matching terraform_region.tfvars files which are placed on the host where Jenkins server is running.


## Resources to pre-create

These can be created e.g. using ibmcloud cli.

```bash
For each MZR:
1 vpc
3 subnets for each zone, e.g. using /20
1 public gateway per subnet
1 ssh key
```



## terraform_region.tfvars

e.g.

```bash
ls -l /home/perf/gartner/availability_1
-rw-rw---- 1 jenkins perf    845 Feb  4 13:53 terraform_dal.tfvars
-rw-rw---- 1 jenkins perf    879 Jan 31 10:22 terraform_fra.tfvars
-rw-rw---- 1 jenkins perf    879 Jan 31 10:21 terraform_lon.tfvars
-rw-rw---- 1 jenkins perf    883 Jan 29 13:44 terraform_osa.tfvars
-rw-rw---- 1 jenkins perf    883 Jan 31 10:23 terraform_par.tfvars
-rw-rw---- 1 jenkins perf    883 Jan 29 13:43 terraform_syd.tfvars
-rw-rw---- 1 jenkins perf    883 Jan 29 13:42 terraform_tok.tfvars
-rw-rw---- 1 jenkins perf    887 Feb  3 00:33 terraform_wdc.tfvars
```



## Custom image

Basically two tools are needed on the image, stress-ng and s3cmd. To install these, following commands were run inside user-data.tpl initially using the stock debian image but to reduce time and also reduce possible install errors, a custom debian10 image was created with these pre-installed.

```bash
apt-get -y update
apt-get -y install stress-ng
apt-get -y install python-dateutil
apt-get -y install git
cd /root
git clone https://github.com/s3tools/s3cmd
```





# COS Data Structure

One single bucket is created in us-geo and accessed by all vm's using public hostname.

HMAC credentials, access and secret key are used to access the bucket, these keys are put into a file with minimum standard s3cmd settings, see the s3cfg-sample for reference.

For the file directory structure, refer to the Gartner requirements specifications, https://ibm.ent.box.com/folder/129913971047?s=e51w15hzkxbqik6jo30u26isz8wn1yj0





# Sync'ing data in COS to a local host

At the end of every test run, below sync job is run to download latest files to local host, s3cmd is used to sync data.

```bash
data_path=eu-gb/cpu/cx2-2x4/2021/01/30/
local_dir=/home/perf/gartner/avail_data/
cd $local_dir
s3cmd -c s3cfg-sample -v sync --acl-private --no-preserve s3:///availabilityres/$data_path $local_dir$data_path
```

This is not part of the Gartner requirements, this is just for internal use and for browsing data. This step may be broken out and run on a separate host or implement a different mechanism to view data on COS.





# Parsing and creating a local data repository

This is a python script and runs something like this at the very end of the Jenkins job.

```bash
export TESTNAME=cpu
export PROFILE=cx2-2x4
export ES_URI=http://localhost:9201
export ES_INDEX=gartner
export ES_TYPE=cpu_test

STDOUT=logs/cpu_dataupload_${REGION}.log
cd $WORKSPACE/availability_1
./data_uploader.py -s $SCHEDULE -m $REGION -r $REGION_NAME -t $TESTNAME -p $PROFILE 2>>$STDOUT 1>>$STDOUT
```

This too is not part of the Gartner requirement, this is for internal use and used to populate a database with data on COS to create charts for viewing. This step may also be broken out and run on a different host.