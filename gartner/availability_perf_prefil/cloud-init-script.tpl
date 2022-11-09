#cloud-config

write_files:
  - path: "/root/runFioTest.sh"
    permissions: "0755"
    owner: "root"
    content: |
      #! /bin/bash
      /usr/local/bin/bench-fio -e ${FIO_ENGINE} --target ${TARGETS} --type device -o /root/results -m ${RW_MODE} --loops ${LOOPS} --iodepth ${IODEPTH} --numjobs ${JOBS} --runtime ${RUNTIME} --destructive --rwmixread ${RWMIX} -b ${BLOCK_SIZE}
      # Create plots Sample
      /usr/local/bin/fio-plot -i /root/results/vdd/16k  --source "Acadia Performance" -T "VDD Test 16k" -l -r randwrite -d 128  256  512  1024 -n 4 -o /root/results/randwrite-4.png
      /usr/local/bin/fio-plot -i /root/results/vdd/16k  --source "Acadia Performance" -T "VDD Test 16k" -l -r randread -d 128  256  512  1024 -n 4 -o /root/results/randread-4.png
      /usr/local/bin/fio-plot -i /root/results/vdd/16k  --source "Acadia Performance" -T "VDD Test 16k" -l -r randrw -d 128  256  512  1024 -n 4 -o /root/results/randread-4.png
      filename=fio-8TB_prefil_vol$(date +'%d-%m-%y:%R:%s').tar.gz
      echo $filename
      tar -zcvf /tmp/$filename /root/results/*
      touch /root/run_finished
  - path: "/root/generatePlots.sh"
    permissions: "0755"
    owner: "root"
    content: |
      #! /bin/bash
      myarray=(${RW_MODE})
      opt=""
      israndrw=""
      for i in "$${myarray[@]}"
      do
         echo "$i"
         if [ "$i" == "randrw" ]; then
             israndrw="randrw"
         else
             opt+=$i
             opt+=" "
          fi
      done

      for i in ${TARGETS}
      do
         for j in ${BLOCK_SIZE}
         do
            for k in ${JOBS}
            do
               for l in $${opt}
               do
                    diskname=$(echo $i | cut -d '/' -f 3)
                    echo "/usr/local/bin/fio-plot -i /root/results/$diskname/$j  --source \"Acadia Performance\" -T \"VDD Test 16k\" -l -r $l -d 128  256  512  1024 -n $k -o $j-$l-$k.png"
                    /usr/local/bin/fio-plot -i /root/results/$diskname/$j  --source "Acadia Performance" -T "VDD Test 16k" -l -r $l -d 128  256  512  1024 -n $k -o $j-$l-$k.png
               done
            done
         done
      done

      if [ "$$opt" != "" ]; then
          exit 0
      fi

      for i in ${TARGETS}; do
         for j in ${BLOCK_SIZE}; do
            for k in ${JOBS}; do
               diskname=$(echo $i | cut -d '/' -f 3)
               for l in `ls -d /root/results/$diskname/rand*`; do
                 name=$(basename $l)
                 for m in read write; do
                    echo "/usr/local/bin/fio-plot -i $l/$j  --source \"Acadia Performance\" -T \"VDD Test 16k\" -l -r randrw -f $m -d 128  256  512  1024 -n $k -o /root/results/$j-$name-$k-$m.png"
                   /usr/local/bin/fio-plot -i $l/$j  --source "Acadia Performance" -T "VDD Test 16k" -l -r randrw -f $m  -d 128  256  512  1024 -n $k -o /root/results/$j-$name-$k-$m.png
                 done
               done
            done
         done
      done

  - path: "/root/.s3cfg"
    permissions: "0755"
    owner: "root"
    content: |
      [default]
      access_key = ${COS_ACCESS_KEY}
      access_token = ${COS_SECRET_KEY}
      add_encoding_exts =
      add_headers =
      bucket_location = US
      ca_certs_file =
      cache_file =
      check_ssl_certificate = True
      check_ssl_hostname = True
      cloudfront_host = cloudfront.amazonaws.com
      connection_max_age = 5
      connection_pooling = True
      content_disposition =
      content_type =
      default_mime_type = binary/octet-stream
      delay_updates = False
      delete_after = False
      delete_after_fetch = False
      delete_removed = False
      dry_run = False
      enable_multipart = True
      encoding = UTF-8
      encrypt = False
      expiry_date =
      expiry_days =
      expiry_prefix =
      follow_symlinks = False
      force = False
      get_continue = False
      gpg_command = /usr/bin/gpg
      gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
      gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
      gpg_passphrase = ausgen
      guess_mime_type = True
      host_base = ${COS_END_POINT}
      host_bucket = %(bucket)s.${COS_END_POINT}
      human_readable_sizes = False
      invalidate_default_index_on_cf = False
      invalidate_default_index_root_on_cf = True
      invalidate_on_cf = False
      kms_key =
      limit = -1
      limitrate = 0
      list_allow_unordered = False
      list_md5 = False
      log_target_prefix =
      long_listing = False
      max_delete = -1
      mime_type =
      multipart_chunk_size_mb = 15
      multipart_copy_chunk_size_mb = 1024
      multipart_max_chunks = 10000
      preserve_attrs = True
      progress_meter = True
      proxy_host =
      proxy_port = 0
      public_url_use_https = False
      put_continue = False
      recursive = False
      recv_chunk = 65536
      reduced_redundancy = False
      restore_days = 1
      restore_priority = Standard
      secret_key = ${COS_SECRET_KEY}
      send_chunk = 65536
      server_side_encryption = False
      signature_v2 = False
      signurl_use_https = False
      simpledb_host = sdb.amazonaws.com
      skip_existing = False
      socket_timeout = 300
      ssl_client_cert_file =
      ssl_client_key_file =
      stats = False
      stop_on_error = False
      storage_class =
      throttle_max = 100
      upload_id =
      urlencoding_mode = normal
      use_http_expect = False
      use_https = True
      use_mime_magic = True
      verbosity = WARNING
      website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
      website_error =
      website_index = index.html