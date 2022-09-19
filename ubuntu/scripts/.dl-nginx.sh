#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

umask 022

cd "$(dirname "$0")"

CURRTIME="$(date --utc +%Y%m%d)"
_CURRENT_DIR="$(pwd)"

cd /tmp

set -e

rm -fr /tmp/tip.tar*
rm -fr /tmp/nginx.tm*
mkdir -p /tmp/nginx.tmp/build-nginx/modules

wget -c -t 0 -T 9 -O /tmp/tip.tar.gz 'https://hg.nginx.org/nginx/archive/tip.tar.gz'
sleep 2
tar -xf /tmp/tip.tar.gz -C /tmp/nginx.tmp/build-nginx/
sleep 2
mv -v /tmp/nginx.tmp/build-nginx/nginx-* /tmp/nginx.tmp/build-nginx/nginx
rm -f /tmp/tip.tar*

mkdir -p /tmp/nginx.tmp/build-nginx/geoip2
cd /tmp/nginx.tmp/build-nginx/geoip2
_license_key='uzrU0s2GJt6I'
for _edition_id in GeoLite2-ASN GeoLite2-Country GeoLite2-City; do
    wget -c -t 0 -T 9 -O "${_edition_id}.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=${_edition_id}&license_key=${_license_key}&suffix=tar.gz"
done

cd /tmp/nginx.tmp/build-nginx/

# Zlib
_zlib_ver="$(wget -qO- 'https://www.zlib.net/' | grep -i 'HREF="zlib-[0-9].*\.tar\.' | sed 's|"|\n|g' | grep '^zlib-' | grep -ivE 'alpha|beta|rc' | sed -e 's|zlib-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
wget -c -t 9 -T 9 "https://zlib.net/zlib-${_zlib_ver}.tar.xz"
tar -xf  zlib-*.tar.xz
sleep 2
rm -fr zlib-*.tar*
mv -v zlib-* zlib

# PCRE
#_pcre_ver="$(wget -qO- 'https://sourceforge.net/projects/pcre/files/pcre/' | grep -i 'href="/projects/pcre/files/pcre/[1-9]' | sed 's|"|\n|g' | grep -i '^/projects/pcre/files/pcre/' | sed 's|.*pcre/||g' | sed 's|/.*||g' | sort -V | uniq | tail -n 1)"
#wget -c "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/${_pcre_ver}/pcre-${_pcre_ver}.tar.bz2"
#tar -xf "pcre-${_pcre_ver}.tar.bz2"
#sleep 2
#rm -fr pcre-*.tar*
#mv -v pcre-* pcre

# PCRE2
_pcre2_ver="$(wget -qO- 'https://github.com/PCRE2Project/pcre2/releases' | grep -i 'pcre2-[0-9]' | grep -i 'href="/PCRE2Project/pcre2/releases/tag/pcre2-[0-9]' | sed 's|"|\n|g' | grep '^/PCRE2Project/pcre2/releases/tag/pcre2-[0-9]' | sed 's|.*pcre2-||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
wget -c -t 9 -T 9 "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${_pcre2_ver}/pcre2-${_pcre2_ver}.tar.bz2"
tar -xf pcre2-${_pcre2_ver}.tar.*
sleep 2
rm -f pcre2-*.tar*
mv -v pcre2-* pcre2

# OpenSSL 1.1.1
latest_targz=$(wget -qO- 'https://www.openssl.org/source/' | grep '1.1.1' | sed 's/">/ /g' | sed 's/<\/a>/ /g' | awk '{print $3}' | grep '.tar.gz' | head -n 1)
wget -c -t 0 -T 9 "https://www.openssl.org/source/${latest_targz}"
tar -xf ${latest_targz}
sleep 2
rm -fr openssl-*.tar*
mv -v openssl-* openssl

cd modules
###############################################################################

git clone "https://github.com/nbs-system/naxsi.git" \
ngx_http_naxsi_module

git clone "https://github.com/nginx-modules/ngx_cache_purge.git" \
ngx_http_cache_purge_module

git clone "https://github.com/arut/nginx-rtmp-module.git" \
ngx_rtmp_module

git clone "https://github.com/leev/ngx_http_geoip2_module.git" \
ngx_http_geoip2_module

git clone "https://github.com/openresty/headers-more-nginx-module.git" \
ngx_http_headers_more_filter_module

git clone "https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git" \
ngx_http_substitutions_filter_module
    
git clone --recursive "https://github.com/eustas/ngx_brotli.git" \
ngx_http_brotli_module

git clone "https://github.com/apache/incubator-pagespeed-ngx.git" \
ngx_pagespeed
wget -c "https://dl.google.com/dl/page-speed/psol/1.13.35.2-x64.tar.gz" -O psol.tar.gz
tar -xf psol.tar.gz -C ngx_pagespeed/
sleep 2
rm -fr psol.tar.gz

###############################################################################

git clone "https://github.com/openresty/redis2-nginx-module.git" \
ngx_http_redis2_module

git clone "https://github.com/openresty/memc-nginx-module.git" \
ngx_http_memc_module

git clone "https://github.com/openresty/echo-nginx-module.git" \
ngx_http_echo_module

###############################################################################
cd ..

cd /tmp/nginx.tmp

sleep 5
tar -zcf nginx-build-${CURRTIME}.tar.gz build-nginx
sleep 2
sha256sum nginx-build-${CURRTIME}.tar.gz > nginx-build-${CURRTIME}.tar.gz.sha256
sleep 2
cp -pf nginx-build-${CURRTIME}.tar.gz* "${_CURRENT_DIR}"/
sleep 2

echo
echo ' download nginx done '
echo
cd /tmp
rm -fr /tmp/nginx.tmp
exit

