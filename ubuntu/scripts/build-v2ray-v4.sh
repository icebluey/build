#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

/sbin/ldconfig

_install_go () {
    cd /tmp
    rm -fr /tmp/.dl.go.tmp
    mkdir /tmp/.dl.go.tmp
    cd /tmp/.dl.go.tmp
    # Latest version of go
    #_go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
    # go1.17.X
    _go_version="$(wget -qO- 'https://golang.org/dl/' | grep -i 'linux-amd64\.tar\.' | sed 's/"/\n/g' | grep -i 'linux-amd64\.tar\.' | cut -d/ -f3 | grep -i '\.gz$' | sed 's/go//g; s/.linux-amd64.tar.gz//g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | grep '^1\.17\.' | tail -n 1)"
    wget -q -c -t 0 -T 9 "https://dl.google.com/go/go${_go_version}.linux-amd64.tar.gz"
    rm -fr /usr/local/go
    sleep 1
    mkdir /usr/local/go
    tar -xf "go${_go_version}.linux-amd64.tar.gz" --strip-components=1 -C /usr/local/go/
    sleep 1
    cd /tmp
    rm -fr /tmp/.dl.go.tmp
}

_install_go

# Go programming language
export GOROOT='/usr/local/go'
export GOPATH="$GOROOT/home"
export GOTMPDIR='/tmp'
export GOBIN="$GOROOT/bin"
export PATH="$GOROOT/bin:$PATH"
alias go="$GOROOT/bin/go"
alias gofmt="$GOROOT/bin/gofmt"
rm -fr ~/.cache/go-build
echo
go version
echo

set -e

_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"

git clone --branch dev-v4main --recursive 'https://github.com/v2fly/v2ray-core.git' v2ray-core
sleep 1
cd v2ray-core
rm -fr .git 

###############################################################################

_build_date="$(date --utc +"%a %b %_d %T %Y UTC")"
sed "/build .*= /a\\\tbuilt    = \"Built on: ${_build_date}\"" -i core.go
sed '/serial.Concat("V2Ray "/a\\t\tbuilt,' -i core.go
head -n 40 core.go
echo

rm -fr /tmp/v2ray
rm -fr /tmp/v2ray*tar.*
mkdir -p /tmp/v2ray/etc/v2ray
mkdir -p /tmp/v2ray/usr/bin

cd main
CGO_ENABLED=0 go build -o /tmp/v2ray/usr/bin/v2ray -ldflags "-s -w" -trimpath
cd ../infra/control/main
CGO_ENABLED=0 go build -o /tmp/v2ray/usr/bin/v2ctl -tags confonly -ldflags "-s -w" -trimpath

echo
###############################################################################

cd /tmp/v2ray

echo '[Unit]
Description=V2Ray Service
After=network.target
Wants=network.target

[Service]
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting the following two lines, this service will run as user v2ray/v2ray.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
# User=v2ray
# Group=v2ray
Type=simple
PIDFile=/run/v2ray.pid
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/v2ray -config /etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target' > etc/v2ray/v2ray.service
sleep 1
chmod 0644 etc/v2ray/v2ray.service

echo '
cd "$(dirname "$0")"
/bin/rm -f /lib/systemd/system/v2ray.service
/bin/sleep 1
/usr/bin/install -v -c -m 0644 v2ray.service /lib/systemd/system/v2ray.service
/bin/systemctl daemon-reload >/dev/null 2>&1 || : 
' > etc/v2ray/.install.txt
sleep 1
chmod 0644 etc/v2ray/.install.txt
###############################################################################

_date="$(date -u +%Y%m%d)"
_version="$(./usr/bin/v2ray --version 2>&1 | grep '^V2Ray ' | awk '{print $2}')"
echo
sleep 2
tar -Jcvf /tmp/"v2ray_${_version}-${_date}-1_static.tar.xz" *
echo
sleep 2
cd /tmp
sha256sum "v2ray_${_version}-${_date}-1_static.tar.xz" > "v2ray_${_version}-${_date}-1_static.tar.xz".sha256

rm -fr /tmp/v2ray
rm -fr "${_tmp_dir}"
rm -fr /usr/local/go
rm -fr ~/.cache/go-build
sleep 2
echo
echo ' build v2ray done'
echo ' build v2ray done' >> /tmp/.done.txt
echo
exit

