#!/bin/bash -e

cd /opt/aws/bin/

/usr/bin/getent passwd ec2-instance-connect || /usr/sbin/useradd -r -M -s /sbin/nologin ec2-instance-connect
/usr/sbin/usermod -L ec2-instance-connect

eic_scripts=(
  eic_run_authorized_keys
  eic_parse_authorized_keys
  eic_curl_authorized_keys
  eic_harvest_hostkeys
)

for script_name in ${eic_scripts[@]}; do
  curl -sOLJ https://github.com/aws/aws-ec2-instance-connect-config/raw/master/src/bin/$script_name
  chmod a+x $script_name
done

/bin/sed -i "s%^ca_path=/etc/ssl/certs$%ca_path=/etc/ssl/certs/ca-bundle.crt%" /opt/aws/bin/eic_curl_authorized_keys

/opt/aws/bin/eic_harvest_hostkeys

/bin/sed -i "s/^#AuthorizedKeysCommand none$/AuthorizedKeysCommand \/opt\/aws\/bin\/eic_run_authorized_keys %u %f/" /etc/ssh/sshd_config
/bin/sed -i "s/^#AuthorizedKeysCommandUser nobody$/AuthorizedKeysCommandUser ec2-instance-connect/" /etc/ssh/sshd_config


if [ -d '/etc/systemd' ]; then
  /bin/systemctl restart sshd.service;
else
  /etc/init.d/sshd restart;
fi

