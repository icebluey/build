#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

apt update -y -qqq
# build nettle for gnutls
apt install -y libgmp-dev
# build gnutls for chrony
apt install -y libp11-kit-dev libidn2-dev
# build chrony
apt install -y libseccomp-dev libcap-dev libedit-dev

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

_build_nettle () {

CC=gcc
export CC
CXX=g++
export CXX
LDFLAGS="-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,/usr/lib/x86_64-linux-gnu/chrony/private"
export LDFLAGS
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
_nettle_ver=$(wget -qO- 'https://ftp.gnu.org/gnu/nettle/' | grep -i 'a href="nettle.*\.tar' | sed 's/"/\n/g' | grep -i '^nettle-.*tar.gz$' | sed -e 's|nettle-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)
wget -c -t 0 -T 9 "https://ftp.gnu.org/gnu/nettle/nettle-${_nettle_ver}.tar.gz"
sleep 2
tar -xf "nettle-${_nettle_ver}.tar.gz"
sleep 2
rm -f "nettle-${_nettle_ver}.tar.gz"
cd "nettle-${_nettle_ver}"

./configure \
--build=x86_64-linux-gnu --host=x86_64-linux-gnu \
--prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu \
--includedir=/usr/include --sysconfdir=/etc \
--enable-shared --enable-static --enable-fat

make all
rm -fr /tmp/nettle
make install DESTDIR=/tmp/nettle

cd /tmp/nettle
if [[ -d usr/share/man ]]; then
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
    find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
    sleep 2
    find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
    sleep 2
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
fi
find usr/lib/x86_64-linux-gnu/ -type f -iname '*.so.*' -exec chmod 0755 '{}' \;
sleep 2
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/lib/x86_64-linux-gnu/ -type f -iname 'lib*.so.*' -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sed 's|http://|https://|g' -i usr/lib/x86_64-linux-gnu/pkgconfig/*.pc

sleep 1
mkdir -p usr/lib/x86_64-linux-gnu/chrony/private
sleep 1
cp -a usr/lib/x86_64-linux-gnu/*.so* usr/lib/x86_64-linux-gnu/chrony/private/

echo
sleep 2
tar -Jcvf /tmp/"nettle_${_nettle_ver}-1_amd64.tar.xz" *
echo
sleep 2
tar -xf /tmp/"nettle_${_nettle_ver}-1_amd64.tar.xz" -C /
/sbin/ldconfig
rm -fr /tmp/nettle

cd /tmp
rm -fr "${_tmp_dir}"
/sbin/ldconfig
sleep 2
echo
echo ' done'
echo

}

_build_gnutls () {

CC=gcc
export CC
CXX=g++
export CXX
LDFLAGS="-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,/usr/lib/x86_64-linux-gnu/chrony/private"
export LDFLAGS
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
_gnutls_ver="$(wget -qO- 'https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/' | grep -i 'a href="gnutls.*\.tar' | sed 's/"/\n/g' | grep -i '^gnutls-.*tar.xz$' | sed -e 's|gnutls-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-${_gnutls_ver}.tar.xz"
sleep 2
tar -xf "gnutls-${_gnutls_ver}.tar.xz"
sleep 2
rm -f "gnutls-${_gnutls_ver}.tar.xz"
cd "gnutls-${_gnutls_ver}"

./configure \
--build=x86_64-linux-gnu \
--host=x86_64-linux-gnu \
--enable-shared \
--enable-threads=posix \
--enable-sha1-support \
--enable-ssl3-support \
--enable-fips140-mode \
--disable-openssl-compatibility \
--with-included-unistring \
--with-included-libtasn1 \
--prefix=/usr \
--libdir=/usr/lib/x86_64-linux-gnu \
--includedir=/usr/include \
--sysconfdir=/etc

make all
rm -fr /tmp/gnutls
make install DESTDIR=/tmp/gnutls

cd /tmp/gnutls
if [[ -d usr/share/man ]]; then
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
    find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
    sleep 2
    find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
    sleep 2
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
fi
find usr/lib/x86_64-linux-gnu/ -type f -iname '*.so.*' -exec chmod 0755 '{}' \;
sleep 2
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/lib/x86_64-linux-gnu/ -type f -iname 'lib*.so.*' -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
sed 's|http://|https://|g' -i usr/lib/x86_64-linux-gnu/pkgconfig/*.pc
sleep 1
mkdir -p usr/lib/x86_64-linux-gnu/chrony/private
sleep 1
cp -a usr/lib/x86_64-linux-gnu/*.so* usr/lib/x86_64-linux-gnu/chrony/private/
echo
sleep 2
tar -Jcvf /tmp/"gnutls_${_gnutls_ver}-1_amd64.tar.xz" *
echo
sleep 2
tar -xf /tmp/"gnutls_${_gnutls_ver}-1_amd64.tar.xz" -C /
/sbin/ldconfig
rm -fr /tmp/gnutls

cd /tmp
rm -fr "${_tmp_dir}"
/sbin/ldconfig
sleep 2
echo
echo ' done'
echo

}

_build_chrony () {

CC=gcc
export CC
CXX=g++
export CXX
LDFLAGS="-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,/usr/lib/x86_64-linux-gnu/chrony/private"
export LDFLAGS
/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
_chrony_ver=$(wget -qO- 'https://download.tuxfamily.org/chrony/' | grep -ivE 'pre[1-9]|alpha|beta' | grep -i 'a href="chrony-.*\.tar' | sed 's|"|\n|g' | grep -i '^chrony-.*\.tar' | sed -e 's|chrony-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)
wget -c -t 0 -T 9 "https://download.tuxfamily.org/chrony/chrony-${_chrony_ver}.tar.gz"
sleep 2
tar -xf "chrony-${_chrony_ver}.tar.gz"
sleep 2
rm -f "chrony-${_chrony_ver}.tar.gz"
cd "chrony-${_chrony_ver}"

./configure \
--prefix=/usr \
--mandir=/usr/share/man \
--sysconfdir=/etc/chrony \
--chronyrundir=/run/chrony \
--docdir=/usr/share/doc \
--enable-scfilter \
--enable-ntp-signd \
--enable-debug \
--with-ntp-era=$(date -d '1970-01-01 00:00:00+00:00' +'%s') \
--with-hwclockfile=/etc/adjtime \
--with-pidfile=/run/chrony/chronyd.pid

make all
rm -fr /tmp/chrony
make install DESTDIR=/tmp/chrony
mkdir -p /tmp/chrony/etc/logrotate.d
cd examples
install -v -c -m 0644 chrony.conf.example2 /tmp/chrony/etc/chrony/chrony.conf
install -v -c -m 0640 chrony.keys.example /tmp/chrony/etc/chrony/chrony.keys
install -v -c -m 0644 chrony.logrotate /tmp/chrony/etc/logrotate.d/chrony
install -v -c -m 0644 chrony-wait.service /tmp/chrony/etc/chrony/chrony-wait.service
install -v -c -m 0644 chronyd.service /tmp/chrony/etc/chrony/chronyd.service

cd /tmp/chrony
rm -fr var/run
install -m 0755 -d etc/sysconfig
install -m 0755 -d usr/libexec/chrony
if [[ -d usr/share/man ]]; then
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
    find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
    sleep 2
    find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
    sleep 2
    find -L usr/share/man/ -type l -exec rm -f '{}' \;
fi
sleep 2
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/sbin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'

sleep 1
mkdir -p usr/lib/x86_64-linux-gnu/chrony
sleep 1
cp -a /usr/lib/x86_64-linux-gnu/chrony/private usr/lib/x86_64-linux-gnu/chrony/

sed -e 's|#\(driftfile\)|\1|' \
-e 's|#\(rtcsync\)|\1|' \
-e 's|#\(keyfile\)|\1|' \
-e 's|#\(leapsectz\)|\1|' \
-e 's|#\(logdir\)|\1|' \
-e 's|#\(authselectmode\)|\1|' \
-e 's|#\(ntsdumpdir\)|\1|' \
-i etc/chrony/chrony.conf

sed 's|/etc/chrony\.|/etc/chrony/chrony\.|g' -i etc/chrony/chrony.conf
sed 's/^pool /#pool /g' -i etc/chrony/chrony.conf
sed 's/^allow /#allow /g' -i etc/chrony/chrony.conf
sed 's/^server/#server/g' -i etc/chrony/chrony.conf
sed '3a\\nserver time.cloudflare.com iburst nts\nserver nts.ntp.se iburst nts\nserver nts.sth1.ntp.se iburst nts\nserver nts.sth2.ntp.se iburst nts\n#server time1.google.com iburst\n#server time2.google.com iburst\n#server time3.google.com iburst\n#server time4.google.com iburst' -i etc/chrony/chrony.conf
sed '/^After=/aAfter=dnscrypt-proxy.service network-online.target' -i etc/chrony/chronyd.service
sed '/^ExecStart=/iExecStartPre=/usr/libexec/chrony/resolve-ntp-servers.sh' -i etc/chrony/chronyd.service

mkdir -p usr/lib/systemd/ntp-units.d
echo 'chronyd.service' > usr/lib/systemd/ntp-units.d/50-chronyd.list
echo 'chronyd.service' > usr/lib/systemd/ntp-units.d/50-chrony.list
sleep 1
chmod 0644 usr/lib/systemd/ntp-units.d/50-chrony*list

echo '# Command-line options for chronyd
OPTIONS=""' > etc/sysconfig/chronyd
sleep 1
chmod 0644 etc/sysconfig/chronyd

echo '#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='\''UTC'\''; export TZ

_ntpservers=(
'\''time.cloudflare.com'\''
'\''nts.ntp.se'\''
'\''nts.sth1.ntp.se'\''
'\''nts.sth2.ntp.se'\''
)
if [[ -f /usr/bin/dig ]]; then
    sleep 1
    for server in "${_ntpservers[@]}"; do
        /usr/bin/dig \
        +timeout=1 +tries=1 \
        "${server}" AAAA \
        >/dev/null 2>&1 & 
    done
    sleep 2
    for server in "${_ntpservers[@]}"; do
        /usr/bin/dig \
        +timeout=1 +tries=1 \
        "${server}" A \
        >/dev/null 2>&1 & 
    done
    sleep 2
fi
_ntpservers='\'''\''
exit 0
' > usr/libexec/chrony/resolve-ntp-servers.sh
sleep 1
chmod 0755 usr/libexec/chrony/resolve-ntp-servers.sh

echo '
cd "$(dirname "$0")"
/bin/systemctl stop chronyd >/dev/null 2>&1 || : 
/bin/systemctl stop chrony >/dev/null 2>&1 || : 
/bin/systemctl disable chronyd >/dev/null 2>&1 || : 
/bin/systemctl disable chrony >/dev/null 2>&1 || : 
rm -fr /lib/systemd/system/chrony.service
rm -fr /lib/systemd/system/chronyd.service
rm -fr /lib/systemd/system/chrony-wait.service
rm -fr /run/chrony
rm -f /etc/init.d/chrony
rm -fr /var/lib/chrony/*
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
sleep 1
install -v -c -m 0644 chronyd.service /lib/systemd/system/
install -v -c -m 0644 chrony-wait.service /lib/systemd/system/
ln -svf chronyd.service /lib/systemd/system/chrony.service
mkdir -p /var/log/chrony
mkdir -p /var/lib/chrony
touch /var/lib/chrony/{drift,rtc}
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/chrony/.install.txt

echo
sleep 2
tar -Jcvf /tmp/"chrony_${_chrony_ver}-1_amd64.tar.xz" *
echo
sleep 2
tar -xf /tmp/"chrony_${_chrony_ver}-1_amd64.tar.xz" -C /
/sbin/ldconfig
rm -fr /tmp/chrony

cd /tmp
rm -fr "${_tmp_dir}"
/sbin/ldconfig
sleep 2
echo
echo ' done'
echo

}

cd /tmp
rm -fr /usr/lib/x86_64-linux-gnu/chrony/private
_build_nettle
_build_gnutls
_build_chrony

rm -f /tmp/nettle*.tar*
rm -f /tmp/gnutls*.tar*

/sbin/ldconfig
sleep 2
echo
echo ' build chrony done'
echo ' build chrony done' >> /tmp/.done.txt
echo
exit

