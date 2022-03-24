#!/bin/bash

sed -i -E 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i -E 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

swapoff -a; sed -i '/swap/d' /etc/fstab


export DEBIAN_FRONTEND=noninteractive

apt update -y
apt upgrade -y
apt install -y apt-utils
apt install -y build-essential
apt install -y software-properties-common
apt install -y net-tools htop ncdu ca-certificates curl gnupg lsb-release nfs-common cachefilesd
apt-get autoremove -y
apt-get clean -y

systemctl unmask systemd-timesyncd.service
systemctl enable systemd-timesyncd.service
systemctl start systemd-timesyncd.service


cat <<EOF | tee -a /etc/security/limits.conf
root   soft    nofile  2097152
root   hard    nofile  2097152
root   soft    nproc   unlimited
root   hard    nproc   unlimited
root   soft    memlock unlimited
root   hard    memlock unlimite

*   soft    nofile  2097152
*   hard    nofile  2097152
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
vm.swappiness=0
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1

net.netfilter.nf_conntrack_max = 1048576
net.nf_conntrack_max = 1048576
net.core.somaxconn = 32768
kernel.msgmax = 65536
kernel.msgmnb = 65536
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15


###
### TUNING NETWORK PERFORMANCE ###
###
# For high-bandwidth low-latency networks, use 'htcp' congestion control

# Do a 'modprobe tcp_htcp' first
net.ipv4.tcp_congestion_control = htcp

# For servers with tcp-heavy workloads, enable 'fq' queue management scheduler (kernel > 3.12)
net.core.default_qdisc = fq

# Turn on the tcp_window_scaling
net.ipv4.tcp_window_scaling = 1

# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
net.core.rmem_default = 262144
net.core.rmem_max = 16777216

# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# Increase number of incoming connections
net.core.somaxconn = 32768

# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 16384
net.core.dev_weight = 64

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 65535

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks

net.ipv4.tcp_max_tw_buckets = 1440000

# try to reuse time-wait connections, but don't recycle them (recycle can break clients behind NAT)
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1

# Limit number of orphans, each orphan can eat up to 16M (max wmem) of unswappable memory
net.ipv4.tcp_max_orphans = 16384
net.ipv4.tcp_orphan_retries = 0

# Increase the maximum memory used to reassemble IP fragments
net.ipv4.ipfrag_high_thresh = 512000
net.ipv4.ipfrag_low_thresh = 446464

# don't cache ssthresh from previous connection
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1

# Increase size of RPC datagram queue length
net.unix.max_dgram_qlen = 50

# Don't allow the arp table to become bigger than this
net.ipv4.neigh.default.gc_thresh3 = 2048

# Tell the gc when to become aggressive with arp table cleaning.
# Adjust this based on size of the LAN. 1024 is suitable for most /24 networks
net.ipv4.neigh.default.gc_thresh2 = 1024

# Adjust where the gc will leave arp table alone - set to 32.
net.ipv4.neigh.default.gc_thresh1 = 32

# Adjust to arp table gc to clean-up more often
net.ipv4.neigh.default.gc_interval = 30

# Increase TCP queue length
net.ipv4.neigh.default.proxy_qlen = 96
net.ipv4.neigh.default.unres_qlen = 6

# Enable Explicit Congestion Notification (RFC 3168), disable it if it doesn't work for you
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_reordering = 3

# How many times to retry killing an alive TCP connection
net.ipv4.tcp_retries2 = 15
net.ipv4.tcp_retries1 = 3

# Avoid falling back to slow start after a connection goes idle
# keeps our cwnd large with the keep alive connections (kernel > 3.6)
net.ipv4.tcp_slow_start_after_idle = 0

# Allow the TCP fastopen flag to be used, beware some firewalls do not like TFO! (kernel > 3.7)
net.ipv4.tcp_fastopen = 3

# This will enusre that immediatly subsequent connections use the new values
net.ipv4.route.flush = 1
net.ipv6.route.flush = 1

net.ipv4.ip_local_port_range = 15000 65000
# END TWEAKS #
EOF

cat /etc/sysctl.d/01-tweaks.conf
sysctl -p
sysctl -p /etc/sysctl.d/01-tweaks.conf
sysctl net.ipv4.ip_local_port_range

ufw disable
apt install -y iptables iptables-persistent

cat > /etc/iptables/rules.v4 <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
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
iptables-restore < /etc/iptables/rules.v4


cat >> /etc/ssh/sshd_config <<EOF
Port 8448
Protocol 2
MaxAuthTries 6
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

history -c

echo "Setup Complete!"
echo "You must reboot the server for the changes to take effect"
echo "shutdown -r now"
