#cloud-config
runcmd:
  - [ sh, -c, "pip3 install --no-cache --upgrade pip setuptools" ]
  - [ sh, -c, "pip3 install python-dateutil" ]
  - [ sh, -c, "pip3 install s3cmd" ]
  - [ sh, -c, "pip3 install fio-plot" ]
  - [ sh, -c, "/root/runFioTest.sh" ]
  - [ sh, -c, "/root/generatePlots.sh" ]
  - [ sh, -c, " s3cmd sync  /tmp/fio*  s3://cos-acadia-gartner/test/" ]
  - [ sh, -c, "touch /root/run_finished"]

output: {all: '| tee -a /var/log/cloud-init-output.log'}
final_message: "System boot (via cloud-init) is COMPLETE, after $UPTIME seconds. Finished at $TIMESTAMP"
