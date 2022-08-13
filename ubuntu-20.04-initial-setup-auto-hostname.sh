#!/bin/bash

sed -i -E 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i -E 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

swapoff -a; sed -i '/swap/d' /etc/fstab


export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname $(grep "`hostname -I | awk '{print $1}'`" /etc/hosts | awk '{print $2}')

echo 'PS1=$PS1"\[\e]0;`hostname`\a\]"' >> ~/.bashrc


apt update -y
apt upgrade -y
apt install -y apt-utils
apt install -y build-essential
apt install -y software-properties-common
apt install -y net-tools htop ncdu ca-certificates curl gnupg lsb-release nfs-common cachefilesd
apt-get autoremove -y
apt-get clean -y

apt update -y
apt install -y --install-recommends linux-generic-hwe-20.04

echo "tcp_bbr" > /etc/modules-load.d/bbr.conf

systemctl unmask systemd-timesyncd.service
systemctl enable systemd-timesyncd.service
systemctl start systemd-timesyncd.service

# check max limit
# cat /proc/sys/kernel/pid_max

cat <<EOF | tee -a /etc/security/limits.conf
root   soft    nofile  4194304
root   hard    nofile  4194304
root   soft    nproc   unlimited
root   hard    nproc   unlimited
root   soft    memlock unlimited
root   hard    memlock unlimite

*   soft    nofile  4194304
*   hard    nofile  4194304
*   soft    nproc   unlimited
*   hard    nproc   unlimited
*   soft    memlock unlimited
*   hard    memlock unlimite
EOF

cat /etc/security/limits.conf
cat <<EOF | sudo tee -a /etc/pam.d/common-session
session required pam_limits.so
EOF

cat /etc/pam.d/common-session
cat <<EOF | sudo tee -a /etc/systemd/system.conf
DefaultLimitNOFILE=infinity
DefaultLimitMEMLOCK=infinity
EOF

cat /etc/systemd/system.conf
cat > /etc/sysctl.d/01-tweaks.conf <<EOF
# BEGIN TWEAKS #
vm.swappiness = 0
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.core.somaxconn = 32768
net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_close = 10
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 30
net.netfilter.nf_conntrack_tcp_timeout_max_retrans = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 60
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_unacknowledged = 60
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.ip_local_port_range = 2000 65535
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_syn_backlog = 1024


EOF

ufw disable
apt install -y iptables iptables-persistent

WHITE_LIST_IPS="";
while read line; do
  if [[ "$line" == "127.0."* ]] || [[ -z "${line// }" ]]; then continue; fi;
  IP=$(echo "$line" | awk '{print $1}');
  if [[ ! -z "${WHITE_LIST_IPS// }" ]]; then WHITE_LIST_IPS="$WHITE_LIST_IPS\n"; fi;
  WHITE_LIST_IPS="$WHITE_LIST_IPS-A INPUT -s $IP -j ACCEPT";
done </etc/hosts

cat <<EOF | tee /etc/iptables/rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
EOF
echo -e "$WHITE_LIST_IPS" >> /etc/iptables/rules.v4
cat <<EOF | tee -a /etc/iptables/rules.v4
-A INPUT -s 127.0.0.0/16 -j ACCEPT
-A INPUT -s 192.168.0.0/16 -j ACCEPT
-A INPUT -s 10.233.0.0/16 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8448 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8448 -m state --state NEW -m recent --set --name ssh --mask 255.255.255.255 --rsource
-A INPUT -p tcp -m tcp --dport 8448 -m state --state NEW -m recent ! --rcheck --seconds 60 --hitcount 3 --name ssh --mask 255.255.255.255 --rsource -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -m conntrack --ctstate INVALID -j DROP
COMMIT
EOF

#iptables-restore < /etc/iptables/rules.v4

cat <<EOF | tee /etc/iptables/rules.v6
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p tcp -m tcp --dport 8448 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -m conntrack --ctstate INVALID -j DROP
COMMIT
EOF


cat >> /etc/ssh/sshd_config <<EOF
Port 8448
Protocol 2
MaxAuthTries 3
IgnoreRhosts yes
PermitEmptyPasswords no
PasswordAuthentication no
HostbasedAuthentication no
LogLevel INFO
AllowTcpForwarding yes
EOF

cat <<EOF | tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "5m",
    "max-file": "3"
  }
}
EOF

mkdir -p /data /data-media-cache /local-storage
chmod -R 0755 /data /data-media-cache /local-storage
chown -R 65534:65534 /data /data-media-cache /local-storage

rm .bash_history
history -c

echo "Setup Complete!"
