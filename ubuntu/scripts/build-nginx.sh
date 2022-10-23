#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

/sbin/ldconfig

rm -fr /tmp/*el7.x86_64.tar.xz
rm -fr /tmp/*amd64.tar.xz

rm -fr /tmp/bintar
rm -fr /tmp/buildall.tmp

mkdir -p /tmp/buildall.tmp/build
mkdir -p /tmp/buildall.tmp/src
mkdir /tmp/bintar

getent group nginx >/dev/null || groupadd -r nginx
getent passwd nginx >/dev/null || useradd -r -d /var/lib/nginx -g nginx -s /usr/sbin/nologin -c "Nginx web server" nginx

sleep 5

getent group nginx
getent passwd nginx

cp -vfr nginx-build-2*{xz,gz,bz2} /tmp/buildall.tmp/src/ 2>/dev/null

set -e

cd /tmp/buildall.tmp/build

ls -1 ../src/* | xargs --no-run-if-empty -I "{}" tar -xf "{}"
##################################################

cd build-nginx/nginx/

/bin/ls -la --color 

CFLAGS='-O2 -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fstack-protector-strong -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection'
export CFLAGS
CXXFLAGS='-O2 -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fstack-protector-strong -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection'
export CXXFLAGS

LDFLAGS='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now'
export LDFLAGS
CC=gcc
export CC
CXX=g++
export CXX

##############################################################################

_vmajor=4
_vminor=7
_vpatch=2

_longver=$(printf "%1d%03d%03d" ${_vmajor} ${_vminor} ${_vpatch})
_fullver="$(echo \"${_vmajor}\.${_vminor}\.${_vpatch}\")"

sed "s@#define nginx_version.*@#define nginx_version      ${_longver}@g" -i src/core/nginx.h
sed "s@#define NGINX_VERSION.*@#define NGINX_VERSION      ${_fullver}@g" -i src/core/nginx.h

sed 's@"nginx/"@"gws-v"@g' -i src/core/nginx.h
sed 's@Server: nginx@Server: gws@g' -i src/http/ngx_http_header_filter_module.c
sed 's@<hr><center>nginx</center>@<hr><center>gws</center>@g' -i src/http/ngx_http_special_response.c

##############################################################################

sed 's@\./config --prefix=$ngx_prefix@& no-rc2 no-rc4 no-rc5 no-sm2 no-sm3 no-sm4 enable-tls1_3@g' -i auto/lib/openssl/make

sleep 1
cat auto/lib/openssl/make

_http_module_args="$(./auto/configure --help | grep -i '\--with-http' | awk '{print $1}' | sed 's/^[ ]*//g' | sed 's/[ ]*$//g' | grep -v '=' | sort -u | uniq | grep -iv 'geoip' | paste -sd' ')"
_stream_module_args="$(./auto/configure --help | grep -i '\--with-stream' | awk '{print $1}' | sed 's/^[ ]*//g' | sed 's/[ ]*$//g' | grep -v '=' | sort -u | uniq | grep -iv 'geoip' | paste -sd' ')"
sleep 2
sed '/define X509_CERT_FILE .*OPENSSLDIR "/s|"/cert.pem"|"/certs/ca-certificates.crt"|g' -i ../openssl/include/internal/cryptlib.h
./auto/configure \
--build=x86_64-linux-gnu \
--prefix=/usr/share/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/x86_64-linux-gnu/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
--http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
--http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
--http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
--pid-path=/run/nginx.pid \
--lock-path=/run/lock/subsys/nginx \
--user=nginx \
--group=nginx \
${_http_module_args} \
${_stream_module_args} \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-poll_module \
--with-select_module \
--with-threads \
--with-pcre-jit \
--with-pcre=../pcre2 \
--with-zlib=../zlib \
--with-openssl=../openssl \
--add-module=../modules/ngx_http_brotli_module \
--add-module=../modules/ngx_http_cache_purge_module \
--add-module=../modules/ngx_http_echo_module \
--add-module=../modules/ngx_http_geoip2_module \
--add-module=../modules/ngx_http_headers_more_filter_module \
--add-module=../modules/ngx_http_memc_module \
--add-module=../modules/ngx_http_redis2_module \
--add-module=../modules/ngx_http_substitutions_filter_module \
--add-module=../modules/ngx_http_naxsi_module/naxsi_src \
--add-module=../modules/ngx_pagespeed \
--add-module=../modules/ngx_rtmp_module \
--with-ld-opt='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now'

make -j1

rm -fr /tmp/nginx
sleep 1
mkdir /tmp/nginx
sleep 2
make install DESTDIR=/tmp/nginx

install -m 0755 -d /tmp/nginx/var/www/html
install -m 0755 -d /tmp/nginx/var/lib/nginx/tmp
install -m 0755 -d /tmp/nginx/usr/lib/x86_64-linux-gnu/nginx/modules

#install -m 0755 -d /tmp/nginx/usr/lib/systemd/system

install -m 0755 -d /tmp/nginx/etc/sysconfig
install -m 0755 -d /tmp/nginx/etc/systemd/system/nginx.service.d
install -m 0755 -d /tmp/nginx/etc/logrotate.d

cp -fr /tmp/nginx/usr/local/* /tmp/nginx/usr/
sleep 2
rm -fr /tmp/nginx/usr/local

install -m 0755 -d /tmp/nginx/etc/nginx/conf.d
install -m 0755 -d /tmp/nginx/etc/nginx/geoip

install -m 0700 -d /tmp/nginx/var/log/nginx

chown -R nginx:nginx /tmp/nginx/var/www/html
chown -R nginx:nginx /tmp/nginx/var/lib/nginx

##############################################################################

##############################################################################

echo '# Configuration file for the nginx service.

NGINX=/usr/sbin/nginx
CONFFILE=/etc/nginx/nginx.conf' > /tmp/nginx/etc/sysconfig/nginx

##############################################################################

printf '\x2F\x76\x61\x72\x2F\x6C\x6F\x67\x2F\x6E\x67\x69\x6E\x78\x2F\x2A\x6C\x6F\x67\x20\x7B\x0A\x20\x20\x20\x20\x63\x72\x65\x61\x74\x65\x20\x30\x36\x34\x34\x20\x72\x6F\x6F\x74\x20\x72\x6F\x6F\x74\x0A\x20\x20\x20\x20\x64\x61\x69\x6C\x79\x0A\x20\x20\x20\x20\x72\x6F\x74\x61\x74\x65\x20\x35\x32\x0A\x20\x20\x20\x20\x6D\x69\x73\x73\x69\x6E\x67\x6F\x6B\x0A\x20\x20\x20\x20\x6E\x6F\x74\x69\x66\x65\x6D\x70\x74\x79\x0A\x20\x20\x20\x20\x63\x6F\x6D\x70\x72\x65\x73\x73\x0A\x20\x20\x20\x20\x73\x68\x61\x72\x65\x64\x73\x63\x72\x69\x70\x74\x73\x0A\x20\x20\x20\x20\x70\x6F\x73\x74\x72\x6F\x74\x61\x74\x65\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x62\x69\x6E\x2F\x6B\x69\x6C\x6C\x20\x2D\x55\x53\x52\x31\x20\x60\x63\x61\x74\x20\x2F\x72\x75\x6E\x2F\x6E\x67\x69\x6E\x78\x2E\x70\x69\x64\x20\x32\x3E\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x60\x20\x32\x3E\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x7C\x7C\x20\x74\x72\x75\x65\x0A\x20\x20\x20\x20\x65\x6E\x64\x73\x63\x72\x69\x70\x74\x0A\x20\x20\x20\x20\x70\x6F\x73\x74\x72\x6F\x74\x61\x74\x65\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x2F\x75\x73\x72\x2F\x73\x62\x69\x6E\x2F\x6E\x67\x69\x6E\x78\x20\x2D\x73\x20\x72\x65\x6C\x6F\x61\x64\x20\x3E\x2F\x64\x65\x76\x2F\x6E\x75\x6C\x6C\x20\x32\x3E\x26\x31\x20\x7C\x7C\x20\x74\x72\x75\x65\x0A\x20\x20\x20\x20\x65\x6E\x64\x73\x63\x72\x69\x70\x74\x0A\x7D\x0A\x0A' | dd seek=$((0x0)) conv=notrunc bs=1 of=/tmp/nginx/etc/logrotate.d/nginx
chmod 0644 /tmp/nginx/etc/logrotate.d/nginx

##############################################################################

sed 's/nginx\/$nginx_version/gws/g' -i /tmp/nginx/etc/nginx/fastcgi.conf
sed 's/nginx\/$nginx_version/gws/g' -i /tmp/nginx/etc/nginx/fastcgi_params

sed 's/nginx\/$nginx_version/gws/g' -i /tmp/nginx/etc/nginx/fastcgi.conf.default
sed 's/nginx\/$nginx_version/gws/g' -i /tmp/nginx/etc/nginx/fastcgi_params.default

sed 's@#user .* nobody;@user  nginx;@g' -i /tmp/nginx/etc/nginx/nginx.conf
sed 's@#user .* nobody;@user  nginx;@g' -i /tmp/nginx/etc/nginx/nginx.conf.default

sed 's@#pid .*nginx.pid;@pid  /run/nginx.pid;@g' -i /tmp/nginx/etc/nginx/nginx.conf
sed 's@#pid .*nginx.pid;@pid  /run/nginx.pid;@g' -i /tmp/nginx/etc/nginx/nginx.conf.default

sed '/ root .* html;/s@html;@/var/www/html;@g' -i /tmp/nginx/etc/nginx/nginx.conf
sed '/ root .* html;/s@html;@/var/www/html;@g' -i /tmp/nginx/etc/nginx/nginx.conf.default

sleep 2
rm -fr /tmp/nginx/etc/nginx/nginx.conf

cd /tmp/nginx

find /tmp/nginx -type f -name .packlist -exec rm -vf '{}' \;
find /tmp/nginx -type f -name perllocal.pod -exec rm -vf '{}' \;
find /tmp/nginx -type f -empty -exec rm -vf '{}' \;
find /tmp/nginx -type f -iname '*.so' -exec chmod -v 0755 '{}' \;

rm -fr run
rm -fr var/run
[ -d usr/man ] && mv -f usr/man usr/share/

rm -fr /tmp/geoip2
mkdir /tmp/geoip2
ls -1 /tmp/buildall.tmp/build/build-nginx/geoip2/*.tar.* | xargs -I "{}" tar -xf "{}" -C /tmp/geoip2/
find /tmp/geoip2/ -type f -iname '*.mmdb' -exec /bin/cp -vf '{}' /tmp/nginx/etc/nginx/geoip/ \;
sleep 5
chmod 0644 /tmp/nginx/etc/nginx/geoip/*.mmdb
rm -fr /tmp/geoip2

strip usr/sbin/nginx
find usr/lib/x86_64-linux-gnu/ -type f -iname '*.so*' -exec strip '{}' \;

###############################################################################

echo '[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
ExecStartPre=/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecStartPost=/bin/sleep 0.1
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target' > etc/nginx/nginx.service

echo '
systemctl daemon-reload >/dev/null 2>&1 || : 
systemctl stop nginx.service >/dev/null 2>&1 || : 
systemctl disable nginx.service >/dev/null 2>&1 || : 
userdel -f -r nginx >/dev/null 2>&1 || : 
groupdel nginx >/dev/null 2>&1 || : 
rm -f /usr/sbin/nginx
rm -f /lib/systemd/system/nginx.service
rm -fr /usr/share/nginx
rm -f /usr/share/man/man3/nginx.3*
rm -fr /etc/systemd/system/nginx.service.d
rm -f /etc/logrotate.d/nginx
rm -f /etc/sysconfig/nginx
rm -f /etc/nginx/scgi_params.default
rm -f /etc/nginx/fastcgi.conf
rm -f /etc/nginx/fastcgi_params
rm -f /etc/nginx/koi-win
rm -f /etc/nginx/uwsgi_params
rm -f /etc/nginx/nginx.conf.default
rm -f /etc/nginx/mime.types.default
rm -f /etc/nginx/uwsgi_params.default
rm -f /etc/nginx/win-utf
rm -f /etc/nginx/koi-utf
rm -f /etc/nginx/fastcgi_params.default
rm -f /etc/nginx/mime.types
rm -f /etc/nginx/fastcgi.conf.default
rm -f /etc/nginx/scgi_params
rm -fr /etc/nginx/geoip
rm -fr /etc/nginx/conf.d
rm -fr /var/lib/nginx
rm -fr /var/log/nginx
rm -fr /usr/lib/x86_64-linux-gnu/nginx
rm -fr /usr/lib/x86_64-linux-gnu/perl/5.30.0/auto/nginx
rm -f /usr/lib/x86_64-linux-gnu/perl/5.30.0/nginx.pm
rm -f /etc/nginx/nginx.service
systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/nginx/.del.txt

echo '
cd "$(dirname "$0")"
systemctl daemon-reload >/dev/null 2>&1 || : 
getent group nginx > /dev/null || groupadd -r nginx
getent passwd nginx > /dev/null || useradd -r -d /var/lib/nginx -g nginx -s /usr/sbin/nologin -c "Nginx web server" nginx
rm -f /lib/systemd/system/nginx.service
install -v -c -m 0644 nginx.service /lib/systemd/system/
chown -R nginx:nginx /var/www/html
chown -R nginx:nginx /var/lib/nginx
systemctl daemon-reload >/dev/null 2>&1 || : 
sleep 1
systemctl enable nginx.service >/dev/null 2>&1 || : 
' > etc/nginx/.install.txt

chmod 0644 etc/nginx/nginx.service
chmod 0644 etc/nginx/.del.txt
chmod 0644 etc/nginx/.install.txt

###############################################################################

echo
sleep 2
tar -Jcvf /tmp/gws_"${_vmajor}.${_vminor}.${_vpatch}"-1_amd64.tar.xz *
echo
sleep 2

mv /tmp/*amd64.tar.xz /tmp/bintar/
cd /tmp/buildall.tmp/build
rm -fr /tmp/nginx

###############################################################################

cd /tmp/bintar

sha256sum *tar.xz > sha256sums.txt

cd /tmp
rm -fr /tmp/buildall.tmp
sleep 2
echo
echo ' build nginx done'
echo ' build nginx done' >> /tmp/.done.txt
echo
/sbin/ldconfig
exit

