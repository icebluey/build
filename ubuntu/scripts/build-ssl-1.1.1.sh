#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

CC=gcc
export CC
CXX=g++
export CXX
LDFLAGS="-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,/usr/local/openssl-1.1.1/lib"
export LDFLAGS

/sbin/ldconfig

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

latest_targz=$(wget -qO- 'https://www.openssl.org/source/' | grep '1.1.1' | sed 's/">/ /g' | sed 's/<\/a>/ /g' | awk '{print $3}' | grep '.tar.gz' | head -n 1)
wget -c -t 0 -T 9 "https://www.openssl.org/source/${latest_targz}"
echo
sleep 2
tar -xf "${latest_targz}"
sleep 2
rm -fr ${latest_targz}
cd openssl-1.1.1*

#sed '/define X509_CERT_FILE .*OPENSSLDIR "/s|"/cert.pem"|"/certs/ca-certificates.crt"|g' -i include/internal/cryptlib.h
sed '/install_docs:/s| install_html_docs||g' -i Configurations/unix-Makefile.tmpl
sleep 1
HASHBANGPERL=/usr/bin/perl
./Configure \
--prefix=/usr/local/openssl-1.1.1 \
--openssldir=/usr/local/openssl-1.1.1/etc/pki/tls \
zlib enable-tls1_3 threads shared \
enable-camellia enable-seed enable-rfc3779 enable-sctp enable-cms enable-md2 \
enable-rc5 \
no-mdc2 no-ec2m \
no-sm2 no-sm3 no-sm4 \
enable-ec_nistp_64_gcc_128 linux-x86_64 '-DDEVRANDOM="\"/dev/urandom\""' 

sed 's@engines-1.1@engines@g' -i Makefile
make all -j1 
for i in libcrypto.pc libssl.pc openssl.pc ; do
  sed -i '/^Libs.private:/{s/-L[^ ]* //;s/-Wl[^ ]* //}' $i
done
rm -fr /tmp/openssl
sleep 1
install -m 0755 -d /tmp/openssl
make DESTDIR=/tmp/openssl install

cd /tmp/openssl
rm -fr usr/local/openssl-1.1.1/etc/pki/tls/certs
rm -fr usr/local/openssl-1.1.1/share/doc
strip usr/local/openssl-1.1.1/bin/openssl
strip usr/local/openssl-1.1.1/lib/libssl.so.1.1
strip usr/local/openssl-1.1.1/lib/libcrypto.so.1.1
strip usr/local/openssl-1.1.1/lib/engines/*.so
ln -svf /etc/ssl/certs usr/local/openssl-1.1.1/etc/pki/tls/certs
ln -svf certs/ca-certificates.crt usr/local/openssl-1.1.1/etc/pki/tls/cert.pem

echo '
cd "$(dirname "$0")"
rm -f /etc/ld.so.conf.d/openssl-1.1.1.conf
sleep 1
echo "/usr/local/openssl-1.1.1/lib" > /etc/ld.so.conf.d/openssl-1.1.1.conf
[ -f bin/openssl ] && \
(rm -f /usr/bin/openssl ; sleep 1 ; install -v -c -m 0755 bin/openssl /usr/bin/openssl)
/sbin/ldconfig
' > usr/local/openssl-1.1.1/.install.txt

find -L usr/local/openssl-1.1.1/share/man/ -type l -exec rm -f '{}' \;
sleep 2
find usr/local/openssl-1.1.1/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
sleep 2
find -L usr/local/openssl-1.1.1/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
sleep 2
find -L usr/local/openssl-1.1.1/share/man/ -type l -exec rm -f '{}' \;

_ver="$(cat usr/local/openssl-1.1.1/include/openssl/opensslv.h | grep -i '# define OPENSSL_VERSION_TEXT' | sed 's/ /\n/g' | grep -i '^1\.1\.1')"
echo
echo "${_ver}"
echo
sleep 2
tar -Jcvf /tmp/"openssl_${_ver}-1_amd64.tar.xz" *
echo
sleep 2
cd /tmp
sha256sum "openssl_${_ver}-1_amd64.tar.xz" > "openssl_${_ver}-1_amd64.tar.xz".sha256

cd /tmp
rm -fr "${_tmp_dir}"
rm -fr /tmp/openssl
/sbin/ldconfig
sleep 2
echo
echo ' build openssl 1.1.1 done'
echo ' build openssl 1.1.1 done' >> /tmp/.done.txt
echo
exit

