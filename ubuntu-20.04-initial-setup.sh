#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

ORIGINAL_USER=$(who am i | awk '{print $1}')

mkdir ~/.ssh
touch ~/.ssh/authorized_keys
chmod go-w ~/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

cat /home/ubuntu/.ssh/authorized_keys | tee ~/.ssh/authorized_keys
cat /home/ubuntu/.bashrc | tee ~/.bashrc

cat <<EOF | tee /home/ubuntu/.vimrc
set number
syntax on
EOF
cat /home/ubuntu/.vimrc | tee ~/.vimrc

# Version 2
wget -O ~/.bashrc_fancy_prompt_v2.sh https://raw.githubusercontent.com/sherazahmedvaival/ubuntu/main/.bashrc_fancy_prompt_v2.sh
chmod +x ~/.bashrc_fancy_prompt_v2.sh
echo "source ~/.bashrc_fancy_prompt_v2.sh" >> ~/.bashrc
source ~/.bashrc_fancy_prompt_v2.sh

swapoff -a; sed -i '/swap/d' /etc/fstab

apt update -y
apt upgrade -y
apt install -y apt-utils
apt install -y build-essential
apt install -y software-properties-common
apt install -y net-tools htop ncdu ca-certificates curl gnupg lsb-release nfs-common cachefilesd rename acl p7zip-full p7zip-rar net-tools
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
root   hard    memlock unlimited

*   soft    nofile  4194304
*   hard    nofile  4194304
*   soft    nproc   unlimited
*   hard    nproc   unlimited
*   soft    memlock unlimited
*   hard    memlock unlimited
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
vm.max_map_count = 262144
overcommit_memory = 1
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


#############################################

cat <<EOF | tee /etc/rc.local
#!/bin/bash  
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
exit 0 
EOF
cat /etc/rc.local
chmod +x /etc/rc.local

cat <<EOF | tee /etc/systemd/system/rc-local.service
[Unit]  
 Description=/etc/rc.local Compatibility  
 ConditionPathExists=/etc/rc.local  

[Service]  
 Type=forking  
 ExecStart=/etc/rc.local start  
 TimeoutSec=0  
 StandardOutput=tty  
 RemainAfterExit=yes  
 SysVStartPriority=99  

[Install]  
 WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/rc-local.service
cat /etc/systemd/system/rc-local.service

systemctl daemon-reload
systemctl enable rc-local

#############################################
ufw disable
apt install -y iptables iptables-persistent

WHITE_LIST_IPS="";
while read line; do
  if [[ "$line" != "127.0."* ]] && [[ "$line" == [0-9]* ]]; then
  	IP=$(echo "$line" | awk '{print $1}');
  	if [[ ! -z "${WHITE_LIST_IPS// }" ]]; then WHITE_LIST_IPS="$WHITE_LIST_IPS\n"; fi;
  	WHITE_LIST_IPS="$WHITE_LIST_IPS-A INPUT -s $IP -j ACCEPT";
  fi;
done </etc/hosts

cat <<EOF | tee /etc/iptables/rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
EOF
echo -e "$WHITE_LIST_IPS" >> /etc/iptables/rules.v4
cat <<EOF | tee -a /etc/iptables/rules.v4
-A INPUT -s 10.0.0.0/8 -j ACCEPT
-A INPUT -s 172.16.0.0/12 -j ACCEPT
-A INPUT -s 192.168.0.0/16 -j ACCEPT
-A INPUT -s 127.0.0.0/16 -j ACCEPT
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



cat <<EOF | tee /etc/ssh/sshd_config.d/99-override.conf
ListenAddress 0.0.0.0
Port 8448
Protocol 2
ClientAliveInterval 3600
MaxAuthTries 3
IgnoreRhosts yes
PermitEmptyPasswords no
PasswordAuthentication no
HostbasedAuthentication no
RhostsRSAAuthentication no

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin without-password
StrictModes yes

UsePAM yes

AuthenticationMethods publickey
PubkeyAuthentication yes
RSAAuthentication yes



AllowTcpForwarding yes
TCPKeepAlive no
PasswordAuthentication no
ChallengeResponseAuthentication no

X11Forwarding yes
X11DisplayOffset 10
PrintMotd yes
PrintLastLog yes
TCPKeepAlive yes

# Enable PFS ciphersuites.
Ciphers aes256-ctr
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


#systemctl disable systemd-resolved
#systemctl stop systemd-resolved
#
#rm -f /etc/resolv.conf
#cat <<EOF | tee /etc/resolv.conf
#nameserver 8.8.8.8
#nameserver 8.8.4.4
#EOF

# Enable NFS CacheFiles
sed -i 's/#RUN=yes/RUN=yes/g' /etc/default/cachefilesd
systemd enable cachefilesd.service

# Conformation
cat /proc/fs/nfsfs/servers
cat /proc/fs/nfsfs/volumes


echo "Setup Complete!"

