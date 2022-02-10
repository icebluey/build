# build packages
## ubuntu 20.04
```
ln -svf bash /bin/sh && cd ubuntu/scripts && bash .build-all.sh 
```
```

apt update -y -qqq ; apt install -y -qqq bash wget ca-certificates
wget -c -t 9 -T 9 "https://raw.githubusercontent.com/icebluey/build/master/.setup_env_ub2004" -O "/tmp/.setup_env_ub2004"
bash "/tmp/.setup_env_ub2004"

```
