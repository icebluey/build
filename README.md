# build packages
## ubuntu 20.04
```
ln -svf bash /bin/sh && cd ubuntu/scripts && bash .build-all.sh 
```
```
#echo "proxy=http://192.168.10.1:1081" >> /etc/yum.conf
#export http_proxy="http://192.168.10.1:1081"
#export https_proxy="http://192.168.10.1:1081"

apt update -y -qqq ; apt install -y -qqq bash wget ca-certificates
wget -c -t 9 -T 9 "https://raw.githubusercontent.com/icebluey/build/master/.setup_env_ub2004" -O "/tmp/.setup_env_ub2004"
bash "/tmp/.setup_env_ub2004"
rm -f "/tmp/.setup_env_ub2004"

```
