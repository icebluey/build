#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

export LD_LIBRARY_PATH=/usr/local/openssl-1.1.1/lib:$LD_LIBRARY_PATH

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
git clone "git://anongit.mindrot.org/openssh.git"
cd openssh
_ver=$(grep -i '#define SSH_VERSION' version.h | head -1 | awk '{print $NF}' | sed 's/"//g' | sed 's/OpenSSH_//g')
_port=$(grep -i '#define SSH_PORTABLE' version.h | head -1 | awk '{print $NF}' | sed 's/"//g')
_ssh_ver="${_ver}${_port}"
echo
echo "openssh version: ${_ssh_ver}"
echo
rm -fr /tmp/openssh*-systemd.patch
echo
printf '\x64\x69\x66\x66\x20\x2D\x2D\x67\x69\x74\x20\x61\x2F\x63\x6F\x6E\x66\x69\x67\x75\x72\x65\x2E\x61\x63\x20\x62\x2F\x63\x6F\x6E\x66\x69\x67\x75\x72\x65\x2E\x61\x63\x0A\x69\x6E\x64\x65\x78\x20\x33\x61\x31\x34\x63\x32\x61\x37\x2E\x2E\x39\x35\x65\x61\x31\x31\x33\x61\x20\x31\x30\x30\x36\x34\x34\x0A\x2D\x2D\x2D\x20\x61\x2F\x63\x6F\x6E\x66\x69\x67\x75\x72\x65\x2E\x61\x63\x0A\x2B\x2B\x2B\x20\x62\x2F\x63\x6F\x6E\x66\x69\x67\x75\x72\x65\x2E\x61\x63\x0A\x40\x40\x20\x2D\x34\x36\x39\x34\x2C\x36\x20\x2B\x34\x36\x39\x34\x2C\x32\x39\x20\x40\x40\x20\x41\x43\x5F\x41\x52\x47\x5F\x57\x49\x54\x48\x28\x5B\x6B\x65\x72\x62\x65\x72\x6F\x73\x35\x5D\x2C\x0A\x20\x41\x43\x5F\x53\x55\x42\x53\x54\x28\x5B\x47\x53\x53\x4C\x49\x42\x53\x5D\x29\x0A\x20\x41\x43\x5F\x53\x55\x42\x53\x54\x28\x5B\x4B\x35\x4C\x49\x42\x53\x5D\x29\x0A\x20\x0A\x2B\x23\x20\x43\x68\x65\x63\x6B\x20\x77\x68\x65\x74\x68\x65\x72\x20\x75\x73\x65\x72\x20\x77\x61\x6E\x74\x73\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x73\x75\x70\x70\x6F\x72\x74\x0A\x2B\x53\x59\x53\x54\x45\x4D\x44\x5F\x4D\x53\x47\x3D\x22\x6E\x6F\x22\x0A\x2B\x41\x43\x5F\x41\x52\x47\x5F\x57\x49\x54\x48\x28\x73\x79\x73\x74\x65\x6D\x64\x2C\x0A\x2B\x09\x5B\x20\x20\x2D\x2D\x77\x69\x74\x68\x2D\x73\x79\x73\x74\x65\x6D\x64\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x45\x6E\x61\x62\x6C\x65\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x73\x75\x70\x70\x6F\x72\x74\x5D\x2C\x0A\x2B\x09\x5B\x20\x69\x66\x20\x74\x65\x73\x74\x20\x22\x78\x24\x77\x69\x74\x68\x76\x61\x6C\x22\x20\x21\x3D\x20\x22\x78\x6E\x6F\x22\x20\x3B\x20\x74\x68\x65\x6E\x0A\x2B\x09\x09\x41\x43\x5F\x50\x41\x54\x48\x5F\x54\x4F\x4F\x4C\x28\x5B\x50\x4B\x47\x43\x4F\x4E\x46\x49\x47\x5D\x2C\x20\x5B\x70\x6B\x67\x2D\x63\x6F\x6E\x66\x69\x67\x5D\x2C\x20\x5B\x6E\x6F\x5D\x29\x0A\x2B\x09\x09\x69\x66\x20\x74\x65\x73\x74\x20\x22\x24\x50\x4B\x47\x43\x4F\x4E\x46\x49\x47\x22\x20\x21\x3D\x20\x22\x6E\x6F\x22\x3B\x20\x74\x68\x65\x6E\x0A\x2B\x09\x09\x09\x41\x43\x5F\x4D\x53\x47\x5F\x43\x48\x45\x43\x4B\x49\x4E\x47\x28\x5B\x66\x6F\x72\x20\x6C\x69\x62\x73\x79\x73\x74\x65\x6D\x64\x5D\x29\x0A\x2B\x09\x09\x09\x69\x66\x20\x24\x50\x4B\x47\x43\x4F\x4E\x46\x49\x47\x20\x2D\x2D\x65\x78\x69\x73\x74\x73\x20\x6C\x69\x62\x73\x79\x73\x74\x65\x6D\x64\x3B\x20\x74\x68\x65\x6E\x0A\x2B\x09\x09\x09\x09\x53\x59\x53\x54\x45\x4D\x44\x5F\x43\x46\x4C\x41\x47\x53\x3D\x60\x24\x50\x4B\x47\x43\x4F\x4E\x46\x49\x47\x20\x2D\x2D\x63\x66\x6C\x61\x67\x73\x20\x6C\x69\x62\x73\x79\x73\x74\x65\x6D\x64\x60\x0A\x2B\x09\x09\x09\x09\x53\x59\x53\x54\x45\x4D\x44\x5F\x4C\x49\x42\x53\x3D\x60\x24\x50\x4B\x47\x43\x4F\x4E\x46\x49\x47\x20\x2D\x2D\x6C\x69\x62\x73\x20\x6C\x69\x62\x73\x79\x73\x74\x65\x6D\x64\x60\x0A\x2B\x09\x09\x09\x09\x43\x50\x50\x46\x4C\x41\x47\x53\x3D\x22\x24\x43\x50\x50\x46\x4C\x41\x47\x53\x20\x24\x53\x59\x53\x54\x45\x4D\x44\x5F\x43\x46\x4C\x41\x47\x53\x22\x0A\x2B\x09\x09\x09\x09\x53\x53\x48\x44\x4C\x49\x42\x53\x3D\x22\x24\x53\x53\x48\x44\x4C\x49\x42\x53\x20\x24\x53\x59\x53\x54\x45\x4D\x44\x5F\x4C\x49\x42\x53\x22\x0A\x2B\x09\x09\x09\x09\x41\x43\x5F\x4D\x53\x47\x5F\x52\x45\x53\x55\x4C\x54\x28\x5B\x79\x65\x73\x5D\x29\x0A\x2B\x09\x09\x09\x09\x41\x43\x5F\x44\x45\x46\x49\x4E\x45\x28\x48\x41\x56\x45\x5F\x53\x59\x53\x54\x45\x4D\x44\x2C\x20\x31\x2C\x20\x5B\x44\x65\x66\x69\x6E\x65\x20\x69\x66\x20\x79\x6F\x75\x20\x77\x61\x6E\x74\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x73\x75\x70\x70\x6F\x72\x74\x2E\x5D\x29\x0A\x2B\x09\x09\x09\x09\x53\x59\x53\x54\x45\x4D\x44\x5F\x4D\x53\x47\x3D\x22\x79\x65\x73\x22\x0A\x2B\x09\x09\x09\x65\x6C\x73\x65\x0A\x2B\x09\x09\x09\x09\x41\x43\x5F\x4D\x53\x47\x5F\x52\x45\x53\x55\x4C\x54\x28\x5B\x6E\x6F\x5D\x29\x0A\x2B\x09\x09\x09\x66\x69\x0A\x2B\x09\x09\x66\x69\x0A\x2B\x09\x66\x69\x20\x5D\x0A\x2B\x29\x0A\x2B\x0A\x20\x23\x20\x4C\x6F\x6F\x6B\x69\x6E\x67\x20\x66\x6F\x72\x20\x70\x72\x6F\x67\x72\x61\x6D\x73\x2C\x20\x70\x61\x74\x68\x73\x20\x61\x6E\x64\x20\x66\x69\x6C\x65\x73\x0A\x20\x0A\x20\x50\x52\x49\x56\x53\x45\x50\x5F\x50\x41\x54\x48\x3D\x2F\x76\x61\x72\x2F\x65\x6D\x70\x74\x79\x0A\x40\x40\x20\x2D\x35\x35\x30\x37\x2C\x36\x20\x2B\x35\x35\x33\x30\x2C\x37\x20\x40\x40\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x6C\x69\x62\x6C\x64\x6E\x73\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x4C\x44\x4E\x53\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x53\x6F\x6C\x61\x72\x69\x73\x20\x70\x72\x6F\x63\x65\x73\x73\x20\x63\x6F\x6E\x74\x72\x61\x63\x74\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x53\x50\x43\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x53\x6F\x6C\x61\x72\x69\x73\x20\x70\x72\x6F\x6A\x65\x63\x74\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x53\x50\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x53\x6F\x6C\x61\x72\x69\x73\x20\x70\x72\x69\x76\x69\x6C\x65\x67\x65\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x53\x50\x50\x5F\x4D\x53\x47\x22\x0A\x2B\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x53\x59\x53\x54\x45\x4D\x44\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x49\x50\x20\x61\x64\x64\x72\x65\x73\x73\x20\x69\x6E\x20\x5C\x24\x44\x49\x53\x50\x4C\x41\x59\x20\x68\x61\x63\x6B\x3A\x20\x24\x44\x49\x53\x50\x4C\x41\x59\x5F\x48\x41\x43\x4B\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x54\x72\x61\x6E\x73\x6C\x61\x74\x65\x20\x76\x34\x20\x69\x6E\x20\x76\x36\x20\x68\x61\x63\x6B\x3A\x20\x24\x49\x50\x56\x34\x5F\x49\x4E\x36\x5F\x48\x41\x43\x4B\x5F\x4D\x53\x47\x22\x0A\x20\x65\x63\x68\x6F\x20\x22\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x42\x53\x44\x20\x41\x75\x74\x68\x20\x73\x75\x70\x70\x6F\x72\x74\x3A\x20\x24\x42\x53\x44\x5F\x41\x55\x54\x48\x5F\x4D\x53\x47\x22\x0A\x64\x69\x66\x66\x20\x2D\x2D\x67\x69\x74\x20\x61\x2F\x73\x73\x68\x64\x2E\x63\x20\x62\x2F\x73\x73\x68\x64\x2E\x63\x0A\x69\x6E\x64\x65\x78\x20\x61\x34\x66\x62\x62\x33\x38\x65\x2E\x2E\x32\x31\x30\x62\x63\x39\x30\x38\x20\x31\x30\x30\x36\x34\x34\x0A\x2D\x2D\x2D\x20\x61\x2F\x73\x73\x68\x64\x2E\x63\x0A\x2B\x2B\x2B\x20\x62\x2F\x73\x73\x68\x64\x2E\x63\x0A\x40\x40\x20\x2D\x38\x35\x2C\x36\x20\x2B\x38\x35\x2C\x31\x30\x20\x40\x40\x0A\x20\x23\x69\x6E\x63\x6C\x75\x64\x65\x20\x3C\x70\x72\x6F\x74\x2E\x68\x3E\x0A\x20\x23\x65\x6E\x64\x69\x66\x0A\x20\x0A\x2B\x23\x69\x66\x64\x65\x66\x20\x48\x41\x56\x45\x5F\x53\x59\x53\x54\x45\x4D\x44\x0A\x2B\x23\x69\x6E\x63\x6C\x75\x64\x65\x20\x3C\x73\x79\x73\x74\x65\x6D\x64\x2F\x73\x64\x2D\x64\x61\x65\x6D\x6F\x6E\x2E\x68\x3E\x0A\x2B\x23\x65\x6E\x64\x69\x66\x0A\x2B\x0A\x20\x23\x69\x6E\x63\x6C\x75\x64\x65\x20\x22\x78\x6D\x61\x6C\x6C\x6F\x63\x2E\x68\x22\x0A\x20\x23\x69\x6E\x63\x6C\x75\x64\x65\x20\x22\x73\x73\x68\x2E\x68\x22\x0A\x20\x23\x69\x6E\x63\x6C\x75\x64\x65\x20\x22\x73\x73\x68\x32\x2E\x68\x22\x0A\x40\x40\x20\x2D\x32\x30\x37\x30\x2C\x36\x20\x2B\x32\x30\x37\x34\x2C\x31\x31\x20\x40\x40\x20\x6D\x61\x69\x6E\x28\x69\x6E\x74\x20\x61\x63\x2C\x20\x63\x68\x61\x72\x20\x2A\x2A\x61\x76\x29\x0A\x20\x09\x09\x09\x7D\x0A\x20\x09\x09\x7D\x0A\x20\x0A\x2B\x23\x69\x66\x64\x65\x66\x20\x48\x41\x56\x45\x5F\x53\x59\x53\x54\x45\x4D\x44\x0A\x2B\x09\x09\x2F\x2A\x20\x53\x69\x67\x6E\x61\x6C\x20\x73\x79\x73\x74\x65\x6D\x64\x20\x74\x68\x61\x74\x20\x77\x65\x20\x61\x72\x65\x20\x72\x65\x61\x64\x79\x20\x74\x6F\x20\x61\x63\x63\x65\x70\x74\x20\x63\x6F\x6E\x6E\x65\x63\x74\x69\x6F\x6E\x73\x20\x2A\x2F\x0A\x2B\x09\x09\x73\x64\x5F\x6E\x6F\x74\x69\x66\x79\x28\x30\x2C\x20\x22\x52\x45\x41\x44\x59\x3D\x31\x22\x29\x3B\x0A\x2B\x23\x65\x6E\x64\x69\x66\x0A\x2B\x0A\x20\x09\x09\x2F\x2A\x20\x41\x63\x63\x65\x70\x74\x20\x61\x20\x63\x6F\x6E\x6E\x65\x63\x74\x69\x6F\x6E\x20\x61\x6E\x64\x20\x72\x65\x74\x75\x72\x6E\x20\x69\x6E\x20\x61\x20\x66\x6F\x72\x6B\x65\x64\x20\x63\x68\x69\x6C\x64\x20\x2A\x2F\x0A\x20\x09\x09\x73\x65\x72\x76\x65\x72\x5F\x61\x63\x63\x65\x70\x74\x5F\x6C\x6F\x6F\x70\x28\x26\x73\x6F\x63\x6B\x5F\x69\x6E\x2C\x20\x26\x73\x6F\x63\x6B\x5F\x6F\x75\x74\x2C\x0A\x20\x09\x09\x20\x20\x20\x20\x26\x6E\x65\x77\x73\x6F\x63\x6B\x2C\x20\x63\x6F\x6E\x66\x69\x67\x5F\x73\x29\x3B\x0A' | dd seek=$((0x0)) conv=notrunc bs=1 of=/tmp/openssh-7.4p1-systemd.patch
sleep 1
chmod 0644 /tmp/openssh-7.4p1-systemd.patch
echo
sleep 1
patch --verbose -p1 -N -i /tmp/openssh-7.4p1-systemd.patch
sleep 1
rm -fr /tmp/openssh-7.4p1-systemd.patch
echo
sleep 1
rm -fr .git
rm -fr autom4te.cache
rm -vf config.guess~
rm -vf config.sub~
rm -vf install-sh~
rm -vf configure.ac.orig
rm -vf sshd.c.orig
autoreconf -v -f -i
rm -fr autom4te.cache
rm -vf config.guess~
rm -vf config.sub~
rm -vf install-sh~
rm -vf configure.ac.orig
rm -vf sshd.c.orig
sleep 1

userdel -f -r ssh >/dev/null 2>&1 || : 
userdel -f -r sshd >/dev/null 2>&1 || : 
groupdel ssh >/dev/null 2>&1 || : 
groupdel sshd >/dev/null 2>&1 || : 
sleep 1
getent group sshd >/dev/null || groupadd -g 74 -r sshd || :
getent passwd sshd >/dev/null || \
useradd -c "Privilege-separated SSH" -u 74 -g sshd \
-s /usr/sbin/nologin -r -d /var/empty/sshd sshd 2> /dev/null || :

#sed "/^#UsePAM no/i# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several\n# problems." -i sshd_config
sed 's|^#UsePAM .*|UsePAM yes|g' -i sshd_config
sed '/^#PrintMotd .*/s|^#PrintMotd .*|\n# It is recommended to use pam_motd in /etc/pam.d/sshd instead of PrintMotd,\n# as it is more configurable and versatile than the built-in version.\nPrintMotd no\n|g' -i sshd_config
sed 's|^#SyslogFacility .*|SyslogFacility AUTHPRIV|' -i sshd_config
sed 's|^#PermitRootLogin .*|PermitRootLogin no|' -i sshd_config

./configure \
--prefix=/usr \
--sysconfdir=/etc/ssh \
--libexecdir=/usr/lib/openssh \
--with-pid-dir=/var/run \
--with-ssl-dir=/usr/local/openssl-1.1.1 \
--with-ssl-engine \
--with-pam \
--with-libedit=/usr \
--with-zlib \
--with-ipaddr-display \
--with-systemd \
--build=x86_64-linux-gnu \
--host=x86_64-linux-gnu

make all
rm -fr /tmp/openssh
make install DESTDIR=/tmp/openssh
install -v -c -m 0755 contrib/ssh-copy-id /tmp/openssh/usr/bin/
install -v -c -m 0644 contrib/ssh-copy-id.1 /tmp/openssh/usr/share/man/man1/

cd /tmp/openssh
install -m 0755 -d etc/ssh
install -m 0755 -d etc/pam.d
install -m 0755 -d usr/lib/systemd/system
install -m 0755 -d etc/systemd/system/sshd.service.d
install -m 0755 -d etc/sysconfig
install -m 0711 -d var/empty/sshd

sed -e 's|^#PubkeyAuthentication |PubkeyAuthentication |g' -e 's|^PubkeyAuthentication .*|PubkeyAuthentication yes|g' -i etc/ssh/sshd_config
sed -e 's|^#PermitEmptyPasswords |PermitEmptyPasswords |g' -e 's|^PermitEmptyPasswords .*|PermitEmptyPasswords no|g' -i etc/ssh/sshd_config
sed 's|^#PasswordAuthentication .*|#PasswordAuthentication no|g' -i etc/ssh/sshd_config
sed 's|^#KbdInteractiveAuthentication .*|#KbdInteractiveAuthentication no|g' -i etc/ssh/sshd_config
sed 's@^#HostKey /etc/ssh/ssh_host_@HostKey /etc/ssh/ssh_host_@g' -i etc/ssh/sshd_config
sed 's|^Ciphers |#Ciphers |g' -i etc/ssh/sshd_config
sed 's|^MACs |#MACs |g' -i etc/ssh/sshd_config
sed 's|^KexAlgorithms |#KexAlgorithms |g' -i etc/ssh/sshd_config
sed 's|^PubkeyAcceptedAlgorithms |#PubkeyAcceptedAlgorithms |g' -i etc/ssh/sshd_config
sed 's|^HostKeyAlgorithms |#HostKeyAlgorithms |g' -i etc/ssh/sshd_config
sed 's|^HostbasedAcceptedAlgorithms |#HostbasedAcceptedAlgorithms |g' -i etc/ssh/sshd_config
sleep 1
############################################################################
# Generating hardening options
rm -f etc/ssh/ssh-hardening-options.txt

echo "Ciphers $(./usr/bin/ssh -Q cipher | grep -iE '256.*gcm|gcm.*256|chacha' | paste -sd','),$(./usr/bin/ssh -Q cipher | grep -ivE 'gcm|chacha|cbc' | grep '256' | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt

echo "MACs $(./usr/bin/ssh -Q mac | grep -i 'hmac-sha[23]' | grep -E '256|512' | grep '[0-9]$' | sort -r | paste -sd','),$(./usr/bin/ssh -Q mac | grep -i 'hmac-sha[23]' | grep -E '256|512' | grep '\@' | sort -r | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt

echo "KexAlgorithms $(./usr/bin/ssh -Q kex | grep -iE '25519|448' | grep -iv '\@libssh' | sort -r | paste -sd','),$(./usr/bin/ssh -Q kex | grep -i 'ecdh-sha[23]-nistp5' | sort -r | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt

echo "PubkeyAcceptedAlgorithms $(./usr/bin/ssh -Q PubkeyAcceptedAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep -v '\@' | paste -sd','),$(./usr/bin/ssh -Q PubkeyAcceptedAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep '\@' | paste -sd','),$(./usr/bin/ssh -Q PubkeyAcceptedAlgorithms | grep -i 'rsa-' | grep -i 'sha[23]-512' | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt

echo "HostKeyAlgorithms $(./usr/bin/ssh -Q HostKeyAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep -v '\@' | paste -sd','),$(./usr/bin/ssh -Q HostKeyAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep '\@' | paste -sd','),$(./usr/bin/ssh -Q HostKeyAlgorithms | grep -i 'rsa-' | grep -i 'sha[23]-512' | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt

echo "HostbasedAcceptedAlgorithms $(./usr/bin/ssh -Q HostbasedAcceptedAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep -v '\@' | paste -sd','),$(./usr/bin/ssh -Q HostbasedAcceptedAlgorithms | grep -iE 'ed25519|ed448|sha[23].*nistp521' | grep '\@' | paste -sd','),$(./usr/bin/ssh -Q HostbasedAcceptedAlgorithms | grep -i 'rsa-' | grep -i 'sha[23]-512' | paste -sd',')" >> etc/ssh/ssh-hardening-options.txt
############################################################################

sleep 1
mv -f etc/ssh/moduli etc/ssh/moduli.orig
sleep 1
awk '$5 >= 3071' etc/ssh/moduli.orig > etc/ssh/moduli
sleep 1
chmod 0644 etc/ssh/moduli
sed 's|^Subsystem[ \t]*sftp|#&|g' -i etc/ssh/sshd_config
sleep 1
sed '/^#Subsystem.*sftp/aSubsystem\tsftp\tinternal-sftp' -i etc/ssh/sshd_config
sleep 1
cp -pf etc/ssh/sshd_config etc/ssh/sshd_config.default
ln -svf ssh usr/bin/slogin
find -L usr/share/man/ -type l -exec rm -f '{}' \;
find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
sleep 2
find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
sleep 2
find -L usr/share/man/ -type l -exec rm -f '{}' \;
find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/sbin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
find usr/lib/openssh/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[  ]*ELF.*, not stripped.*/\1/p' | xargs -I '{}' strip '{}'
echo
rm -f etc/pam.d/sshd
rm -f etc/pam.d/sshd.*
echo
printf '\x23\x20\x50\x41\x4D\x20\x63\x6F\x6E\x66\x69\x67\x75\x72\x61\x74\x69\x6F\x6E\x20\x66\x6F\x72\x20\x74\x68\x65\x20\x53\x65\x63\x75\x72\x65\x20\x53\x68\x65\x6C\x6C\x20\x73\x65\x72\x76\x69\x63\x65\x0A\x0A\x23\x20\x53\x74\x61\x6E\x64\x61\x72\x64\x20\x55\x6E\x2A\x78\x20\x61\x75\x74\x68\x65\x6E\x74\x69\x63\x61\x74\x69\x6F\x6E\x2E\x0A\x40\x69\x6E\x63\x6C\x75\x64\x65\x20\x63\x6F\x6D\x6D\x6F\x6E\x2D\x61\x75\x74\x68\x0A\x0A\x23\x20\x44\x69\x73\x61\x6C\x6C\x6F\x77\x20\x6E\x6F\x6E\x2D\x72\x6F\x6F\x74\x20\x6C\x6F\x67\x69\x6E\x73\x20\x77\x68\x65\x6E\x20\x2F\x65\x74\x63\x2F\x6E\x6F\x6C\x6F\x67\x69\x6E\x20\x65\x78\x69\x73\x74\x73\x2E\x0A\x61\x63\x63\x6F\x75\x6E\x74\x20\x20\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6E\x6F\x6C\x6F\x67\x69\x6E\x2E\x73\x6F\x0A\x0A\x23\x20\x55\x6E\x63\x6F\x6D\x6D\x65\x6E\x74\x20\x61\x6E\x64\x20\x65\x64\x69\x74\x20\x2F\x65\x74\x63\x2F\x73\x65\x63\x75\x72\x69\x74\x79\x2F\x61\x63\x63\x65\x73\x73\x2E\x63\x6F\x6E\x66\x20\x69\x66\x20\x79\x6F\x75\x20\x6E\x65\x65\x64\x20\x74\x6F\x20\x73\x65\x74\x20\x63\x6F\x6D\x70\x6C\x65\x78\x0A\x23\x20\x61\x63\x63\x65\x73\x73\x20\x6C\x69\x6D\x69\x74\x73\x20\x74\x68\x61\x74\x20\x61\x72\x65\x20\x68\x61\x72\x64\x20\x74\x6F\x20\x65\x78\x70\x72\x65\x73\x73\x20\x69\x6E\x20\x73\x73\x68\x64\x5F\x63\x6F\x6E\x66\x69\x67\x2E\x0A\x23\x20\x61\x63\x63\x6F\x75\x6E\x74\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x61\x63\x63\x65\x73\x73\x2E\x73\x6F\x0A\x0A\x23\x20\x53\x74\x61\x6E\x64\x61\x72\x64\x20\x55\x6E\x2A\x78\x20\x61\x75\x74\x68\x6F\x72\x69\x7A\x61\x74\x69\x6F\x6E\x2E\x0A\x40\x69\x6E\x63\x6C\x75\x64\x65\x20\x63\x6F\x6D\x6D\x6F\x6E\x2D\x61\x63\x63\x6F\x75\x6E\x74\x0A\x0A\x23\x20\x53\x45\x4C\x69\x6E\x75\x78\x20\x6E\x65\x65\x64\x73\x20\x74\x6F\x20\x62\x65\x20\x74\x68\x65\x20\x66\x69\x72\x73\x74\x20\x73\x65\x73\x73\x69\x6F\x6E\x20\x72\x75\x6C\x65\x2E\x20\x20\x54\x68\x69\x73\x20\x65\x6E\x73\x75\x72\x65\x73\x20\x74\x68\x61\x74\x20\x61\x6E\x79\x0A\x23\x20\x6C\x69\x6E\x67\x65\x72\x69\x6E\x67\x20\x63\x6F\x6E\x74\x65\x78\x74\x20\x68\x61\x73\x20\x62\x65\x65\x6E\x20\x63\x6C\x65\x61\x72\x65\x64\x2E\x20\x20\x57\x69\x74\x68\x6F\x75\x74\x20\x74\x68\x69\x73\x20\x69\x74\x20\x69\x73\x20\x70\x6F\x73\x73\x69\x62\x6C\x65\x20\x74\x68\x61\x74\x20\x61\x0A\x23\x20\x6D\x6F\x64\x75\x6C\x65\x20\x63\x6F\x75\x6C\x64\x20\x65\x78\x65\x63\x75\x74\x65\x20\x63\x6F\x64\x65\x20\x69\x6E\x20\x74\x68\x65\x20\x77\x72\x6F\x6E\x67\x20\x64\x6F\x6D\x61\x69\x6E\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x5B\x73\x75\x63\x63\x65\x73\x73\x3D\x6F\x6B\x20\x69\x67\x6E\x6F\x72\x65\x3D\x69\x67\x6E\x6F\x72\x65\x20\x6D\x6F\x64\x75\x6C\x65\x5F\x75\x6E\x6B\x6E\x6F\x77\x6E\x3D\x69\x67\x6E\x6F\x72\x65\x20\x64\x65\x66\x61\x75\x6C\x74\x3D\x62\x61\x64\x5D\x20\x20\x20\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x73\x65\x6C\x69\x6E\x75\x78\x2E\x73\x6F\x20\x63\x6C\x6F\x73\x65\x0A\x0A\x23\x20\x53\x65\x74\x20\x74\x68\x65\x20\x6C\x6F\x67\x69\x6E\x75\x69\x64\x20\x70\x72\x6F\x63\x65\x73\x73\x20\x61\x74\x74\x72\x69\x62\x75\x74\x65\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6C\x6F\x67\x69\x6E\x75\x69\x64\x2E\x73\x6F\x0A\x0A\x23\x20\x43\x72\x65\x61\x74\x65\x20\x61\x20\x6E\x65\x77\x20\x73\x65\x73\x73\x69\x6F\x6E\x20\x6B\x65\x79\x72\x69\x6E\x67\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x6F\x70\x74\x69\x6F\x6E\x61\x6C\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6B\x65\x79\x69\x6E\x69\x74\x2E\x73\x6F\x20\x66\x6F\x72\x63\x65\x20\x72\x65\x76\x6F\x6B\x65\x0A\x0A\x23\x20\x53\x74\x61\x6E\x64\x61\x72\x64\x20\x55\x6E\x2A\x78\x20\x73\x65\x73\x73\x69\x6F\x6E\x20\x73\x65\x74\x75\x70\x20\x61\x6E\x64\x20\x74\x65\x61\x72\x64\x6F\x77\x6E\x2E\x0A\x40\x69\x6E\x63\x6C\x75\x64\x65\x20\x63\x6F\x6D\x6D\x6F\x6E\x2D\x73\x65\x73\x73\x69\x6F\x6E\x0A\x0A\x23\x20\x50\x72\x69\x6E\x74\x20\x74\x68\x65\x20\x6D\x65\x73\x73\x61\x67\x65\x20\x6F\x66\x20\x74\x68\x65\x20\x64\x61\x79\x20\x75\x70\x6F\x6E\x20\x73\x75\x63\x63\x65\x73\x73\x66\x75\x6C\x20\x6C\x6F\x67\x69\x6E\x2E\x0A\x23\x20\x54\x68\x69\x73\x20\x69\x6E\x63\x6C\x75\x64\x65\x73\x20\x61\x20\x64\x79\x6E\x61\x6D\x69\x63\x61\x6C\x6C\x79\x20\x67\x65\x6E\x65\x72\x61\x74\x65\x64\x20\x70\x61\x72\x74\x20\x66\x72\x6F\x6D\x20\x2F\x72\x75\x6E\x2F\x6D\x6F\x74\x64\x2E\x64\x79\x6E\x61\x6D\x69\x63\x0A\x23\x20\x61\x6E\x64\x20\x61\x20\x73\x74\x61\x74\x69\x63\x20\x28\x61\x64\x6D\x69\x6E\x2D\x65\x64\x69\x74\x61\x62\x6C\x65\x29\x20\x70\x61\x72\x74\x20\x66\x72\x6F\x6D\x20\x2F\x65\x74\x63\x2F\x6D\x6F\x74\x64\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x6F\x70\x74\x69\x6F\x6E\x61\x6C\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6D\x6F\x74\x64\x2E\x73\x6F\x20\x20\x6D\x6F\x74\x64\x3D\x2F\x72\x75\x6E\x2F\x6D\x6F\x74\x64\x2E\x64\x79\x6E\x61\x6D\x69\x63\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x6F\x70\x74\x69\x6F\x6E\x61\x6C\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6D\x6F\x74\x64\x2E\x73\x6F\x20\x6E\x6F\x75\x70\x64\x61\x74\x65\x0A\x0A\x23\x20\x50\x72\x69\x6E\x74\x20\x74\x68\x65\x20\x73\x74\x61\x74\x75\x73\x20\x6F\x66\x20\x74\x68\x65\x20\x75\x73\x65\x72\x27\x73\x20\x6D\x61\x69\x6C\x62\x6F\x78\x20\x75\x70\x6F\x6E\x20\x73\x75\x63\x63\x65\x73\x73\x66\x75\x6C\x20\x6C\x6F\x67\x69\x6E\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x6F\x70\x74\x69\x6F\x6E\x61\x6C\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6D\x61\x69\x6C\x2E\x73\x6F\x20\x73\x74\x61\x6E\x64\x61\x72\x64\x20\x6E\x6F\x65\x6E\x76\x20\x23\x20\x5B\x31\x5D\x0A\x0A\x23\x20\x53\x65\x74\x20\x75\x70\x20\x75\x73\x65\x72\x20\x6C\x69\x6D\x69\x74\x73\x20\x66\x72\x6F\x6D\x20\x2F\x65\x74\x63\x2F\x73\x65\x63\x75\x72\x69\x74\x79\x2F\x6C\x69\x6D\x69\x74\x73\x2E\x63\x6F\x6E\x66\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x6C\x69\x6D\x69\x74\x73\x2E\x73\x6F\x0A\x0A\x23\x20\x52\x65\x61\x64\x20\x65\x6E\x76\x69\x72\x6F\x6E\x6D\x65\x6E\x74\x20\x76\x61\x72\x69\x61\x62\x6C\x65\x73\x20\x66\x72\x6F\x6D\x20\x2F\x65\x74\x63\x2F\x65\x6E\x76\x69\x72\x6F\x6E\x6D\x65\x6E\x74\x20\x61\x6E\x64\x0A\x23\x20\x2F\x65\x74\x63\x2F\x73\x65\x63\x75\x72\x69\x74\x79\x2F\x70\x61\x6D\x5F\x65\x6E\x76\x2E\x63\x6F\x6E\x66\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x65\x6E\x76\x2E\x73\x6F\x20\x23\x20\x5B\x31\x5D\x0A\x23\x20\x49\x6E\x20\x44\x65\x62\x69\x61\x6E\x20\x34\x2E\x30\x20\x28\x65\x74\x63\x68\x29\x2C\x20\x6C\x6F\x63\x61\x6C\x65\x2D\x72\x65\x6C\x61\x74\x65\x64\x20\x65\x6E\x76\x69\x72\x6F\x6E\x6D\x65\x6E\x74\x20\x76\x61\x72\x69\x61\x62\x6C\x65\x73\x20\x77\x65\x72\x65\x20\x6D\x6F\x76\x65\x64\x20\x74\x6F\x0A\x23\x20\x2F\x65\x74\x63\x2F\x64\x65\x66\x61\x75\x6C\x74\x2F\x6C\x6F\x63\x61\x6C\x65\x2C\x20\x73\x6F\x20\x72\x65\x61\x64\x20\x74\x68\x61\x74\x20\x61\x73\x20\x77\x65\x6C\x6C\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x20\x20\x20\x72\x65\x71\x75\x69\x72\x65\x64\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x65\x6E\x76\x2E\x73\x6F\x20\x75\x73\x65\x72\x5F\x72\x65\x61\x64\x65\x6E\x76\x3D\x31\x20\x65\x6E\x76\x66\x69\x6C\x65\x3D\x2F\x65\x74\x63\x2F\x64\x65\x66\x61\x75\x6C\x74\x2F\x6C\x6F\x63\x61\x6C\x65\x0A\x0A\x23\x20\x53\x45\x4C\x69\x6E\x75\x78\x20\x6E\x65\x65\x64\x73\x20\x74\x6F\x20\x69\x6E\x74\x65\x72\x76\x65\x6E\x65\x20\x61\x74\x20\x6C\x6F\x67\x69\x6E\x20\x74\x69\x6D\x65\x20\x74\x6F\x20\x65\x6E\x73\x75\x72\x65\x20\x74\x68\x61\x74\x20\x74\x68\x65\x20\x70\x72\x6F\x63\x65\x73\x73\x20\x73\x74\x61\x72\x74\x73\x0A\x23\x20\x69\x6E\x20\x74\x68\x65\x20\x70\x72\x6F\x70\x65\x72\x20\x64\x65\x66\x61\x75\x6C\x74\x20\x73\x65\x63\x75\x72\x69\x74\x79\x20\x63\x6F\x6E\x74\x65\x78\x74\x2E\x20\x20\x4F\x6E\x6C\x79\x20\x73\x65\x73\x73\x69\x6F\x6E\x73\x20\x77\x68\x69\x63\x68\x20\x61\x72\x65\x20\x69\x6E\x74\x65\x6E\x64\x65\x64\x0A\x23\x20\x74\x6F\x20\x72\x75\x6E\x20\x69\x6E\x20\x74\x68\x65\x20\x75\x73\x65\x72\x27\x73\x20\x63\x6F\x6E\x74\x65\x78\x74\x20\x73\x68\x6F\x75\x6C\x64\x20\x62\x65\x20\x72\x75\x6E\x20\x61\x66\x74\x65\x72\x20\x74\x68\x69\x73\x2E\x0A\x73\x65\x73\x73\x69\x6F\x6E\x20\x5B\x73\x75\x63\x63\x65\x73\x73\x3D\x6F\x6B\x20\x69\x67\x6E\x6F\x72\x65\x3D\x69\x67\x6E\x6F\x72\x65\x20\x6D\x6F\x64\x75\x6C\x65\x5F\x75\x6E\x6B\x6E\x6F\x77\x6E\x3D\x69\x67\x6E\x6F\x72\x65\x20\x64\x65\x66\x61\x75\x6C\x74\x3D\x62\x61\x64\x5D\x20\x20\x20\x20\x20\x20\x20\x20\x70\x61\x6D\x5F\x73\x65\x6C\x69\x6E\x75\x78\x2E\x73\x6F\x20\x6F\x70\x65\x6E\x0A\x0A\x23\x20\x53\x74\x61\x6E\x64\x61\x72\x64\x20\x55\x6E\x2A\x78\x20\x70\x61\x73\x73\x77\x6F\x72\x64\x20\x75\x70\x64\x61\x74\x69\x6E\x67\x2E\x0A\x40\x69\x6E\x63\x6C\x75\x64\x65\x20\x63\x6F\x6D\x6D\x6F\x6E\x2D\x70\x61\x73\x73\x77\x6F\x72\x64\x0A' | dd seek=$((0x0)) conv=notrunc bs=1 of=etc/pam.d/sshd
chmod 0644 etc/pam.d/sshd
rm -f usr/lib/systemd/system/ssh.service
rm -f usr/lib/systemd/system/sshd.service
sleep 1
echo '[Unit]
Description=OpenSSH server daemon
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/sshd
ExecStart=/usr/sbin/sshd -D $OPTIONS
ExecStartPost=/bin/sleep 0.1
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target' > usr/lib/systemd/system/sshd.service
chmod 0644 usr/lib/systemd/system/sshd.service
ln -svf sshd.service usr/lib/systemd/system/ssh.service

cp -pf usr/lib/systemd/system/sshd.service etc/ssh/

echo '
cd "$(dirname "$0")"
systemctl disable ssh >/dev/null 2>&1
systemctl disable sshd >/dev/null 2>&1
systemctl disable ssh.socket >/dev/null 2>&1
systemctl disable sshd-keygen.service >/dev/null 2>&1
systemctl disable ssh-agent.service >/dev/null 2>&1

userdel -f -r ssh >/dev/null 2>&1
userdel -f -r sshd >/dev/null 2>&1
groupdel ssh >/dev/null 2>&1
groupdel sshd >/dev/null 2>&1
sleep 1
getent group sshd >/dev/null || groupadd -g 74 -r sshd || :
getent passwd sshd >/dev/null || \
useradd -c "Privilege-separated SSH" -u 74 -g sshd \
-s /usr/sbin/nologin -r -d /var/empty/sshd sshd 2> /dev/null || :
sleep 1
install -m 0711 -d /var/empty/sshd

rm -fr /etc/ssh/ssh_host_*
/usr/bin/ssh-keygen -q -t rsa -b 5120 -E sha512 -f /etc/ssh/ssh_host_rsa_key -N "" -C ""
/usr/bin/ssh-keygen -q -t dsa -E sha512 -f /etc/ssh/ssh_host_dsa_key -N "" -C ""
/usr/bin/ssh-keygen -q -t ecdsa -b 521 -E sha512 -f /etc/ssh/ssh_host_ecdsa_key -N "" -C ""
/usr/bin/ssh-keygen -q -t ed25519 -E sha512 -f /etc/ssh/ssh_host_ed25519_key -N "" -C ""
rm -fr /lib/systemd/system/ssh.service
rm -fr /lib/systemd/system/sshd.service
sleep 1
install -v -c -m 0644 sshd.service /lib/systemd/system/
sleep 1
ln -svf sshd.service /lib/systemd/system/ssh.service
sleep 1
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/ssh/.install.txt

usr/bin/ssh-keygen -q -t rsa -b 5120 -E sha512 -f etc/ssh/ssh_host_rsa_key -N "" -C ""
usr/bin/ssh-keygen -q -t dsa -E sha512 -f etc/ssh/ssh_host_dsa_key -N "" -C ""
usr/bin/ssh-keygen -q -t ecdsa -b 521 -E sha512 -f etc/ssh/ssh_host_ecdsa_key -N "" -C ""
usr/bin/ssh-keygen -q -t ed25519 -E sha512 -f etc/ssh/ssh_host_ed25519_key -N "" -C ""

rm -fr var/run
rm -fr run
echo
sleep 2
tar -Jcvf /tmp/"openssh_${_ssh_ver}-1_amd64.tar.xz" *
echo
sleep 2

cd /tmp
rm -fr "${_tmp_dir}"
rm -fr /tmp/openssh
sleep 2
echo
echo ' build openssh done'
echo ' build openssh done' >> /tmp/.done.txt
echo
/sbin/ldconfig
exit

