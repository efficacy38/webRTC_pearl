#!/bin/bash
# sudo snap install lxd
# sudo lxd init --auto

set -x 
lxc profile create macvlan
# change macvlan's parent to the real one
perl -i -pe "s/parent: .*$/parent: $(ip route show to 0.0.0.0/0 | awk '{print $5}' | head -1)/g" macvlan_profile.txt
lxc profile edit macvlan < ./macvlan_profile.txt

for name in jerry; do # branko chofinn angela phoebe angela henry edger solomon; do
    lxc rm -f $name
    lxc profile create $name
    lxc profile edit $name <<-EOF
    config:
      security.nesting: "true"
      security.privileged: "true"
      security.syscalls.intercept.mknod: "true"
      security.syscalls.intercept.setxattr: "true"

      user.user-data: |
        #cloud-config
        ssh_pwauth: True
        users:
          - default
          - name: ${name}
            gecos: ${name}
            primary_group: ${name}
            groups: [ ${name}, sudo ]
            sudo: ALL=(ALL) NOPASSWD:ALL
            lock_passwd: False
            shell: /bin/bash
            plain_text_passwd: 'test'
        apt:
          sources:
            source1:
              source: deb [arch=amd64] https://download.docker.com/linux/ubuntu \$RELEASE stable
              keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
              # keyserver: https://download.docker.com/linux/ubuntu/gpg
          packages:
            - docker-ce
            - docker-ce-cli
            - containerd.io
        runcmd:
          - ['ls']
          - "cp /run/systemd/resolve/resolv.conf /etc/resolv.conf"
          - "systemctl stop systemd-resolved.service"
          - "cp /run/systemd/resolve/resolv.conf /etc/resolv.conf"
          - "systemctl disable systemd-resolved.service"
          - apt-get install -y docker-compose
EOF

    lxc launch ubuntu:20.04 -p default -p $name -p macvlan $name
done

