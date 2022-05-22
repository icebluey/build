#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ

umask 022

_old_dir="$(pwd)"

set -e

if [[ "$#" == "0" ]]; then
    echo -e 'USAGE:\nbash '"$0"' --token TOKEN --user username --repo reponame --file filename\n'
    exit 1
fi

_token=""
while (( "$#" )); do
    case $1 in
        --token)
          _token="${2}"
          shift 2
          ;;
        --user)
          _username="${2}"
          shift 2
          ;;
        --repo)
          _reponame="${2}"
          shift 2
          ;;
        --file)
          _filename="${2}"
          shift 2
          ;;
        --help|-h|*)
          echo -e 'USAGE:\nbash '"$0"' --token TOKEN --user username --repo reponame --file filename\n'
          exit 1
    esac
done

cd /tmp
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
_github_release_ver="$(wget -qO- 'https://github.com/github-release/github-release/releases' | grep -i '/github-release/github-release/releases/download/.*/linux-amd64-github-release.bz2' | sed 's|"|\n|g' | grep -i '/github-release/github-release/releases/download/.*/linux-amd64-github-release.bz2' | sort -V | uniq | tail -n 1)"
wget -q -c -t 0 -T 9 "https://github.com/${_github_release_ver}"
bzip2 -d linux-amd64-github-release.bz2
rm -fr /usr/bin/github-release
sleep 1
install -c -m 0755 linux-amd64-github-release /usr/bin/github-release
sleep 1
strip /usr/bin/github-release
sleep 1
cd /tmp
rm -fr "${_tmp_dir}"

cd "${_old_dir}"
_datenow="$(date -u +%Y-%m-%d)"

GITHUB_TOKEN="${_token}" \
github-release release \
--user "${_username}" \
--repo "${_reponame}" \
--tag "v${_datenow}"

sleep 30

GITHUB_TOKEN="${_token}" \
github-release upload \
--user "${_username}" \
--repo "${_reponame}" \
--file "${_filename}" \
--name "${_filename}" \
--tag "v${_datenow}"

_token=""
echo
echo ' upload done'
echo
exit

