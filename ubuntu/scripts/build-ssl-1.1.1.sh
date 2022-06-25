#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

CC=gcc
export CC
CXX=g++
export CXX

/sbin/ldconfig


_install_fido2 () {
    set -e
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _libfido2_ver="$(wget -qO- 'https://developers.yubico.com/libfido2/Releases/' | grep -i 'a href="libfido2-.*\.tar' | sed 's|"|\n|g' | grep -iv '\.sig' | grep -i '^libfido2' | sed -e 's|libfido2-||g' -e 's|\.tar.*||g' | sort -V | uniq | tail -n 1)"
    wget -q -c -t 9 -T 9 "https://developers.yubico.com/libfido2/Releases/libfido2-${_libfido2_ver}.tar.gz"
    sleep 1
    tar -xf "libfido2-${_libfido2_ver}.tar.gz"
    sleep 1
    rm -f libfido*.tar*
    cd "libfido2-${_libfido2_ver}"
    PKG_CONFIG_PATH=/usr/local/openssl-1.1.1/lib/pkgconfig \
    cmake -S . -B build -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE:STRING='Debug' \
    -DCMAKE_INSTALL_SO_NO_EXE=0 -DUSE_PCSC=ON \
    -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu
    /usr/bin/cmake --build "build"  --verbose
    rm -f /usr/lib/x86_64-linux-gnu/libfido2.*
    rm -f /usr/include/fido.h
    rm -fr /usr/include/fido
    /usr/bin/cmake --install "build"
    sleep 1
    strip /usr/lib/x86_64-linux-gnu/libfido2.so.*.*
    cd /tmp
    rm -fr "${_tmp_dir}"
    /sbin/ldconfig >/dev/null 2>&1
}
_install_fido2

LDFLAGS="-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -Wl,-rpath,/usr/local/openssl-1.1.1/lib -Wl,-rpath,/usr/lib/x86_64-linux-gnu/openssh/private"
export LDFLAGS

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
install -m 0755 -d usr/lib/x86_64-linux-gnu/openssh/private
rm -fr usr/local/openssl-1.1.1/etc/pki/tls/certs
rm -fr usr/local/openssl-1.1.1/share/doc
strip usr/local/openssl-1.1.1/bin/openssl
strip usr/local/openssl-1.1.1/lib/libssl.so.1.1
strip usr/local/openssl-1.1.1/lib/libcrypto.so.1.1
strip usr/local/openssl-1.1.1/lib/engines/*.so
ln -svf /etc/ssl/certs usr/local/openssl-1.1.1/etc/pki/tls/certs
ln -svf certs/ca-certificates.crt usr/local/openssl-1.1.1/etc/pki/tls/cert.pem
cp -af /usr/lib/x86_64-linux-gnu/libfido2.so* usr/lib/x86_64-linux-gnu/openssh/private/

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

