#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

CC=gcc
export CC
CXX=g++
export CXX

/sbin/ldconfig

_strip_all_files() {
    rm -fr /tmp/strip.fs.tmp.sh
    if [[ -d usr/sbin ]]; then
        file usr/sbin/* | grep ' ELF ' | awk '{print $1}' | sed 's|:||g' | sort | uniq | sed 's|^|/usr/bin/strip |g' > /tmp/strip.fs.tmp.sh
    fi
    if [[ -d usr/bin ]]; then
        file usr/bin/* | grep ' ELF ' | awk '{print $1}' | sed 's|:||g' | sort | uniq | sed 's|^|/usr/bin/strip |g' >> /tmp/strip.fs.tmp.sh
    fi
    if [[ -d usr/lib/gnupg2 ]]; then
        file usr/lib/gnupg2/* | grep ' ELF ' | awk '{print $1}' | sed 's|:||g' | sort | uniq | sed 's|^|/usr/bin/strip |g' >> /tmp/strip.fs.tmp.sh
    fi
    sleep 1
    [ -f /tmp/strip.fs.tmp.sh ] && bash /tmp/strip.fs.tmp.sh
    sleep 1
    rm -f /tmp/strip.fs.tmp.sh

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
    find usr/ -type f -iname '*.la' -delete
}

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

for i in libgpg-error libassuan libksba npth ntbtls pinentry gpgme; do
    _tarname=$(wget -qO- https://gnupg.org/ftp/gcrypt/${i}/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)
    wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/${i}/${_tarname}"
done

_gnupg23_tarname="$(wget -qO- https://gnupg.org/ftp/gcrypt/gnupg/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | grep '^gnupg-2\.3' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/gnupg/${_gnupg23_tarname}"

#_gnupg22_tarname="$(wget -qO- https://gnupg.org/ftp/gcrypt/gnupg/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | grep '^gnupg-2\.2' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/gnupg/${_gnupg22_tarname}"

_libgcrypt110_tarname="$(wget -qO- https://gnupg.org/ftp/gcrypt/libgcrypt/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | grep '^libgcrypt-1\.10' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)"
wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/libgcrypt/${_libgcrypt110_tarname}"

#_libgcrypt19_tarname="$(wget -qO- https://gnupg.org/ftp/gcrypt/libgcrypt/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | grep '^libgcrypt-1\.9' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/libgcrypt/${_libgcrypt19_tarname}"

#_libgcrypt18_tarname="$(wget -qO- https://gnupg.org/ftp/gcrypt/libgcrypt/ | grep '\.tar\.bz2' | sed 's/href="/ /g' | sed 's/">/ /g' | sed 's/ /\n/g' | grep '^libgcrypt-1\.8' | sed -n '/\.tar\.bz2$/p' | sed -e '/-qt/d' | sort -V | uniq | tail -n 1)"
#wget -c -t 0 -T 9 "https://gnupg.org/ftp/gcrypt/libgcrypt/${_libgcrypt18_tarname}"

sleep 2
ls -1 *.tar* | xargs -I '{}' tar -xf '{}'
sleep 2
rm -f *.tar*

#libgpg-error-1.44
#libassuan-2.5.5
#libksba-1.6.0
#npth-1.6
#libgcrypt-1.9.4
#ntbtls-0.3.0
#pinentry-1.2.0
#gnupg-2.3.4
#gpgme-1.17.0

cd libgpg-error-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/libgpg-error
make install DESTDIR=/tmp/libgpg-error
cd /tmp/libgpg-error
install -m 0755 -d usr/include/x86_64-linux-gnu
mv -v -f usr/include/gpg-error.h usr/include/x86_64-linux-gnu/
mv -v -f usr/include/gpgrt.h usr/include/x86_64-linux-gnu/
ln -svf x86_64-linux-gnu/gpg-error.h usr/include/gpg-error.h
ln -svf x86_64-linux-gnu/gpgrt.h usr/include/gpgrt.h
_libgpg_error_ver="$(cat usr/lib/x86_64-linux-gnu/pkgconfig/gpg-error.pc | grep -i '^Version' | awk '{print $NF}' | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"libgpg-error_${_libgpg_error_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/libgpg-error
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr libgpg-error-*
cd libassuan-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/libassuan
make install DESTDIR=/tmp/libassuan
cd /tmp/libassuan
_libassuan_ver="$(cat usr/lib/x86_64-linux-gnu/pkgconfig/libassuan.pc | grep -i '^Version' | awk '{print $NF}' | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"libassuan-${_libassuan_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/libassuan
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr libassuan-*
cd libksba-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/libksba
make install DESTDIR=/tmp/libksba
cd /tmp/libksba
_libksba_ver="$(cat usr/lib/x86_64-linux-gnu/pkgconfig/ksba.pc | grep -i '^Version' | awk '{print $NF}' | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"libksba-${_libksba_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/libksba
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr libksba-*
cd npth-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/npth
make install DESTDIR=/tmp/npth
cd /tmp/npth
_npth_ver="$(usr/bin/npth-config --version | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"npth-${_npth_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/npth
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr npth-*
cd libgcrypt-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/libgcrypt
make install DESTDIR=/tmp/libgcrypt
cd /tmp/libgcrypt
_libgcrypt_ver="$(cat usr/lib/x86_64-linux-gnu/pkgconfig/libgcrypt.pc | grep -i '^Version' | awk '{print $NF}' | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"libgcrypt-${_libgcrypt_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/libgcrypt
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr libgcrypt-*
cd ntbtls-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --enable-shared --enable-static --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/ntbtls
make install DESTDIR=/tmp/ntbtls
cd /tmp/ntbtls
_ntbtls_ver="$(cat usr/lib/x86_64-linux-gnu/pkgconfig/ntbtls.pc | grep -i '^Version' | awk '{print $NF}' | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"ntbtls-${_ntbtls_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/ntbtls
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr ntbtls-*
cd pinentry-*
./configure --build=x86_64-linux-gnu --host=x86_64-linux-gnu --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
make all
rm -fr /tmp/pinentry
make install DESTDIR=/tmp/pinentry
cd /tmp/pinentry
_pinentry_ver="$(usr/bin/pinentry --version 2>&1 | grep -i '^pinentry.*[0-9]$' | awk '{print $NF}'  | tr -d '\n')"
_strip_all_files
echo
sleep 2
tar -Jcvf /tmp/"pinentry-${_pinentry_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/pinentry
/sbin/ldconfig

###############################################################################
cd "${_tmp_dir}"
rm -fr pinentry-*
cd gnupg-*
./configure \
--build=x86_64-linux-gnu \
--host=x86_64-linux-gnu \
--enable-gpg-is-gpg2 \
--enable-wks-tools \
--enable-g13 \
--enable-build-timestamp \
--enable-key-cache=10240 \
--prefix=/usr \
--libexecdir=/usr/lib/gnupg \
--libdir=/usr/lib/x86_64-linux-gnu \
--includedir=/usr/include \
--sysconfdir=/etc \
--localstatedir=/var \
--docdir=/usr/share/doc/gnupg2

make all
rm -fr /tmp/gnupg
make install DESTDIR=/tmp/gnupg
install -v -m 0755 -d /tmp/gnupg/usr/lib/systemd/user
cd doc/examples/systemd-user
for i in *.*; do
    install -v -c -m 0644 -D "$i" "/tmp/gnupg/usr/lib/systemd/user/$i"
done

cd /tmp/gnupg
install -m 0755 -d etc/gnupg
install -m 0755 -d usr/lib/x86_64-linux-gnu/gnupg

echo '# gpg2 ssh authenticate
[[ -d ~/.gnupg ]] || ( gpg2 --list-secret-keys >/dev/null 2>&1 || : )
gpgconf --launch gpg-agent >/dev/null 2>&1
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export GPG_TTY="$(tty)"
echo UPDATESTARTUPTTY | gpg-connect-agent >/dev/null 2>&1
# required for gpgv1
export GPG_AGENT_INFO="$(gpgconf --list-dirs agent-socket):0:1"    
# create sshcontrol file in ~/.gnupg/
[[ -f ~/.gnupg/sshcontrol ]] || ( ssh-add -L >/dev/null 2>&1 || : )
# "gpg: agent_genkey failed: Permission denied"
# "Key generation failed: Permission denied"
# fix Permission denied issues in root user
chown root:tty "$(tty)" >/dev/null 2>&1 || : ' > etc/gnupg/load_gpg-agent.sh

echo '#keyserver hkps://pgp.mit.edu
keyserver hkps://keyserver.ubuntu.com
expert
no-comments
no-emit-version
with-subkey-fingerprint
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
personal-cipher-preferences AES256 AES192 AES
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
cipher-algo AES256
digest-algo SHA512
cert-digest-algo SHA512
disable-cipher-algo 3DES
weak-digest SHA1
s2k-cipher-algo AES256
s2k-digest-algo SHA512
no-symkey-cache
charset utf-8
require-cross-certification
list-options show-uid-validity
verify-options show-uid-validity' > etc/gnupg/gpg.conf

echo '#pinentry-program /usr/bin/pinentry-curses
pinentry-timeout 300
default-cache-ttl 0
max-cache-ttl 0
enable-ssh-support' > etc/gnupg/gpg-agent.conf

echo '
cd "$(dirname "$0")"
rm -fr /etc/profile.d/load_gpg-agent.sh
sed -e '\''/\/etc\/gnupg\/load_gpg-agent.sh/d'\'' -i ~/.bashrc
sleep 1
install -c -m 0644 load_gpg-agent.sh /etc/profile.d/
echo '\''[[ -f /etc/gnupg/load_gpg-agent.sh ]] && source /etc/gnupg/load_gpg-agent.sh'\'' >> ~/.bashrc
' > etc/gnupg/.install.txt

chmod 0644 etc/gnupg/load_gpg-agent.sh
chmod 0644 etc/gnupg/gpg.conf
chmod 0644 etc/gnupg/gpg-agent.conf
chmod 0644 etc/gnupg/.install.txt

_gpg_ver="$(./usr/bin/gpg2 --version 2>&1 | grep -i '^gpg (GnuPG)' | awk '{print $3}')"
_strip_all_files
sleep 1
ln -svf gpg2.1.gz usr/share/man/man1/gpg.1.gz
ln -svf gpgv2.1.gz usr/share/man/man1/gpgv.1.gz
ln -svf gpg2 usr/bin/gpg
ln -svf gpgv2 usr/bin/gpgv
[ -f usr/sbin/gpg-zip ] && mv -f usr/sbin/gpg-zip usr/bin/
echo
sleep 2
tar -Jcvf /tmp/"gnupg-${_gpg_ver}-1_amd64.tar.xz" *
echo
sleep 2
ls -1 /tmp/*_amd64.tar.xz | xargs -I "{}" tar -xf "{}" -C /
cd /tmp
rm -fr /tmp/gnupg
/sbin/ldconfig

###############################################################################
cd /tmp
rm -fr "${_tmp_dir}"
sleep 2
echo
echo ' build gpg done'
echo ' build gpg done' >> /tmp/.done.txt
echo
/sbin/ldconfig
exit
###############################################################################
cd "${_tmp_dir}"
rm -fr gnupg-*
cd gpgme-*

