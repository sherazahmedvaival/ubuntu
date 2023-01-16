###########################################
# https://en.wikipedia.org/wiki/HAProxy
# 2.6 LTS	2022-05-31	2027-Q2 (LTS)
###########################################
sudo add-apt-repository ppa:vbernat/haproxy-2.6 -y
sudo apt update

sudo apt install haproxy -y

haproxy -vv
