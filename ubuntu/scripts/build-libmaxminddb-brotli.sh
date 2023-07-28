#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

_strip_all_files() {
    find usr/ -type f -iname '*.la' -delete
    if [[ -d usr/sbin ]]; then
        file usr/sbin/* | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' /usr/bin/strip '{}'
    fi
    if [[ -d usr/bin ]]; then
        file usr/bin/* | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' /usr/bin/strip '{}'
    fi
    if [[ -d usr/lib/x86_64-linux-gnu ]]; then
        find usr/lib/x86_64-linux-gnu/ -iname 'lib*.so*' -type f -exec /usr/bin/strip "{}" \;
        find usr/lib/x86_64-linux-gnu/ -iname '*.so' -type f -exec /usr/bin/strip "{}" \;
    fi
    if [[ -d usr/share/man ]]; then
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
        find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
        sleep 2
        find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
        sleep 2
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
    fi
}

CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -e

cd /tmp
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
git clone --recursive 'https://github.com/maxmind/libmaxminddb.git' libmaxminddb
git clone --recursive 'https://github.com/google/brotli.git' brotli

cd libmaxminddb
rm -fr .git
rm -f ltmain.sh
./bootstrap
rm -fr autom4te.cache
./configure \
--build=x86_64-linux-gnu --host=x86_64-linux-gnu \
--enable-shared --enable-static \
--prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/libmaxminddb
make install DESTDIR=/tmp/libmaxminddb
cd /tmp/libmaxminddb
_maxminddb_ver=$(grep -i '#define PACKAGE_VERSION' usr/include/maxminddb.h | cut -d'"' -f2)
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"libmaxminddb_${_maxminddb_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/libmaxminddb_*_amd64.tar.xz | xargs -I '{}' tar -xf '{}' -C /
cd /tmp
rm -fr /tmp/libmaxminddb
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr libmaxminddb
cd brotli
rm -fr .git
if [[ -f bootstrap ]]; then
    ./bootstrap
    rm -fr autom4te.cache
    LDFLAGS='' ; LDFLAGS="${_ORIG_LDFLAGS}"' -Wl,-rpath,\$$ORIGIN' ; export LDFLAGS
    ./configure \
    --build=x86_64-linux-gnu --host=x86_64-linux-gnu \
    --enable-shared --disable-static \
    --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
    make all
    rm -fr /tmp/brotli
    make install DESTDIR=/tmp/brotli
else
    LDFLAGS='' ; LDFLAGS="${_ORIG_LDFLAGS}"' -Wl,-rpath,\$ORIGIN' ; export LDFLAGS
    cmake \
    -S "." \
    -B "build" \
    -DCMAKE_BUILD_TYPE='Release' \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_PREFIX:PATH=/usr \
    -DINCLUDE_INSTALL_DIR:PATH=/usr/include \
    -DLIB_INSTALL_DIR:PATH=/usr/lib/x86_64-linux-gnu \
    -DSYSCONF_INSTALL_DIR:PATH=/etc \
    -DSHARE_INSTALL_PREFIX:PATH=/usr/share \
    -DLIB_SUFFIX=64 \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DCMAKE_INSTALL_SO_NO_EXE:INTERNAL=0
    cmake --build "build"  --verbose
    rm -fr /tmp/brotli
    DESTDIR="/tmp/brotli" cmake --install "build"
fi
cd /tmp/brotli
_brotli_ver=$(LD_LIBRARY_PATH=usr/lib/x86_64-linux-gnu ./usr/bin/brotli --version 2>&1 | grep -i '^brotli' | awk '{print $2}')
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"brotli_${_brotli_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/brotli_*_amd64.tar.xz | xargs -I '{}' tar -xf '{}' -C /
cd /tmp
rm -fr /tmp/brotli
/sbin/ldconfig

###############################################################################
cd /tmp
rm -fr "${_tmp_dir}"
sleep 2
echo
echo ' build libmaxminddb and brotli done'
echo ' build libmaxminddb and brotli done' >> /tmp/.done.txt
echo
/sbin/ldconfig
exit

