#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

apt update -y -qqq
# build keepalived
apt install -y libsystemd-dev libipset-dev iptables libsnmp-dev libmnl-dev libnftnl-dev libnl-3-dev libnl-genl-3-dev libnfnetlink-dev
apt install -y ipset iptables

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

_ssl_ver="$(wget -qO- 'https://www.openssl.org/source/' | grep '1.1.1' | sed 's/">/ /g' | sed 's/<\/a>/ /g' | awk '{print $3}' | grep '\.tar.gz' | sed -e 's|openssl-||g' -e 's|\.tar.*||g' | sort -V | tail -n 1)"
_keepalived_ver="$(wget -qO- 'https://www.keepalived.org/download.html' | grep -i 'keepalived-[1-9].*\.tar' | sed -e 's|"|\n|g' -e 's|/|\n|g' | grep -i '^keepalived-[1-9].*\.tar' | sed -e 's|keepalived-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://www.openssl.org/source/openssl-${_ssl_ver}.tar.gz"
wget -c -t 0 -T 9 "https://www.keepalived.org/software/keepalived-${_keepalived_ver}.tar.gz"

sleep 1
tar -xf "openssl-${_ssl_ver}.tar.gz"
tar -xf "keepalived-${_keepalived_ver}.tar.gz"
sleep 1
rm -vf "openssl-${_ssl_ver}.tar.gz"
rm -vf "keepalived-${_keepalived_ver}.tar.gz"
sleep 1

cd "openssl-${_ssl_ver}"
./Configure \
--prefix=/usr \
--libdir=/usr/lib/x86_64-linux-gnu \
--openssldir=/etc/ssl \
zlib enable-tls1_3 threads shared \
enable-camellia enable-seed enable-rfc3779 enable-sctp \
enable-cms enable-md2 enable-rc5 \
no-mdc2 no-ec2m \
no-sm2 no-sm3 no-sm4 \
enable-ec_nistp_64_gcc_128 \
linux-x86_64 \
'-DDEVRANDOM="\"/dev/urandom\""'

sleep 1
#sed 's@engines-1.1@engines@g' -i Makefile
sleep 1
make all
rm -fr /tmp/openssl
sleep 2
make DESTDIR=/tmp/openssl install_sw
sleep 2
cd ..
rm -fr "openssl-${_ssl_ver}"
find /tmp/openssl/usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find /tmp/openssl/usr/lib/x86_64-linux-gnu/ -type f -iname '*.so*' -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sleep 2
cp -a /tmp/openssl/usr/include/openssl /usr/include/
rm -f /usr/include/x86_64-linux-gnu/openssl/opensslconf.h
cp -a /tmp/openssl/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/
cp -a /tmp/openssl/usr/bin/* /usr/bin/
mkdir -p /usr/include/x86_64-linux-gnu/openssl
install -c -m 0644 /usr/include/openssl/opensslconf.h /usr/include/x86_64-linux-gnu/openssl/

/sbin/ldconfig

cd "keepalived-${_keepalived_ver}"
./configure \
LDFLAGS="-Wl,-rpath,/usr/lib/x86_64-linux-gnu/keepalived/private" \
--build=x86_64-linux-gnu \
--host=x86_64-linux-gnu \
--prefix=/usr \
--sysconfdir=/etc \
--enable-snmp \
--enable-snmp-rfc \
--enable-nftables \
--disable-iptables \
--with-init=systemd

make all
rm -fr /tmp/keepalived
sleep 2
make DESTDIR=/tmp/keepalived install
sleep 2
cd ..
rm -fr "keepalived-${_keepalived_ver}"

cd /tmp/keepalived
mkdir -p var/log/keepalived
mkdir -p usr/libexec/keepalived
[[ -f etc/keepalived/keepalived.conf ]] && mv -f etc/keepalived/keepalived.conf etc/keepalived/keepalived.conf.default
mv -f etc/keepalived/samples usr/share/doc/keepalived/
mkdir -p usr/lib/x86_64-linux-gnu/keepalived/private
cp -a /tmp/openssl/usr/lib/x86_64-linux-gnu/lib*.so* usr/lib/x86_64-linux-gnu/keepalived/private/
strip usr/sbin/keepalived
find -L usr/share/man/ -type l -exec rm -f '{}' \;
find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
sleep 2
find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
sleep 2
find -L usr/share/man/ -type l -exec rm -f '{}' \;

echo '[Unit]
Description=LVS and VRRP High Availability Monitor
After=network-online.target syslog.target
Wants=network-online.target

[Service]
Type=notify
NotifyAccess=all
PIDFile=/run/keepalived.pid
KillMode=process
EnvironmentFile=-/etc/sysconfig/keepalived
ExecStart=/usr/sbin/keepalived --dont-fork $KEEPALIVED_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target' > etc/keepalived/keepalived.service
sleep 1
chmod 0644 etc/keepalived/keepalived.service
echo '
cd "$(dirname "$0")"
systemctl daemon-reload >/dev/null 2>&1 || : 
rm -f /lib/systemd/system/keepalived.service
sleep 1
install -v -c -m 0644 keepalived.service /lib/systemd/system/
systemctl daemon-reload >/dev/null 2>&1 || : 
## log to file
#touch /var/log/keepalived/keepalived.log
#echo "local0.* /var/log/keepalived/keepalived.log" > /etc/rsyslog.d/keepalived.conf
#sleep 1
#chmod 0644 /etc/rsyslog.d/keepalived.conf
#systemctl restart rsyslog.service >/dev/null 2>&1 || : 
' > etc/keepalived/.install.txt
sleep 1
chmod 0644 etc/keepalived/.install.txt

echo
sleep 2
tar -Jcvf /tmp/"keepalived-${_keepalived_ver}-1_amd64.tar.xz" *
echo
sleep 2

cd /tmp
rm -fr /tmp/openssl /tmp/keepalived
rm -fr "${_tmp_dir}"
echo
echo ' build keepalived done'
echo ' build keepalived done' >> /tmp/.done.txt
echo
/sbin/ldconfig
exit

