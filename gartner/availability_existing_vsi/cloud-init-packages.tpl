#cloud-config
apt:
  conf: |
     APT {
         Get {
             Assume-Yes "true";
             Fix-Broken "true";
         }
     }
  primary:
    - arches: [default]
      uri:  http://mirrors.adn.networklayer.com/ubuntu
package-update: true
package_upgrade: true
packages:
 - python3
 - jq
 - fio
 - nginx
 - iperf
 - zlib1g-dev
 - libjpeg-dev
 - python3-pip