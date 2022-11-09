#cloud-config
runcmd:
  - [ sh, -c, "echo deb http://archive.ubuntu.com/ubuntu/ bionic main restricted $ deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted $ deb http://archive.ubuntu.com/ubuntu/ bionic universe $ deb http://archive.ubuntu.com/ubuntu/ bionic-updates universe $ deb http://archive.ubuntu.com/ubuntu/ bionic multiverse $ deb http://archive.ubuntu.com/ubuntu/ bionic-updates multiverse $ deb http://archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse $ deb http://security.ubuntu.com/ubuntu/ bionic-security main restricted $ deb http://security.ubuntu.com/ubuntu/ bionic-security universe $ deb http://security.ubuntu.com/ubuntu/ bionic-security multiverse | tr '$' '\n' > /etc/apt/sources.list" ]
  - [ sh, -c, "apt update"]
  - [ sh, -c, "apt install python3-pip"]
  - [ sh, -c, "pip3 install --no-cache --upgrade pip setuptools" ]
  - [ sh, -c, "pip3 install python-dateutil" ]
  - [ sh, -c, "sudo apt-get install fio"]
  - [ sh, -c, "pip3 install s3cmd" ]
  - [ sh, -c, "pip3 install fio-plot" ]
  - [ sh, -c, "/root/runFioTest.sh" ]
  - [ sh, -c, "/root/generatePlots.sh" ]
  - [ sh, -c, " s3cmd sync  /tmp/fio*  s3://cos-acadia-gartner/test/" ]
  - [ sh, -c, "touch /root/run_finished"]

output: {all: '| tee -a /var/log/cloud-init-output.log'}
final_message: "System boot (via cloud-init) is COMPLETE, after $UPTIME seconds. Finished at $TIMESTAMP"
