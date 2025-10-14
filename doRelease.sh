#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

debList=$(realpath "debsIncludedInThisRepo")

# shellcheck disable=SC2120
h () {
    # if arguments, print them
    [ $# == 0 ] || echo "$*"

  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTION]... SIGNING-PRIVATE-KEY.gpg
  do a new release from $debList and push to latest github release
Available options:
  -h, --help       display this help and exit
  -n, --dry-run    don't update release, only print and mess with the local tmp release dir
EOF

    # if args, exit 1 else exit 0
    [ $# == 0 ] || exit 1
    exit 0
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    echo "$msg"
    exit "$code"
}

# getopt short options go together, long options have commas
TEMP=$(getopt -o hn --long help,dry-run -n "$0" -- "$@")
#shellcheck disable=SC2181
if [ $? != 0 ] ; then
    die "something wrong with getopt"
fi
eval set -- "$TEMP"

dry=false
while true ; do
    case "$1" in
        -h|--help) h ;;
        -n|--dry-run) dry=true; shift ;;
        --) shift ; break ;;
        *) die "issue parsing args, unexpected argument '$0'!" ;;
    esac
done
privateKey=${1:-}
if [[ ! -f "$privateKey" ]]; then
    h "need to pass in gpg signing key name"
fi

rm -rf release
mkdir release
cd release

# download all the debs in newFileList
< "$debList" xargs -n1 -P5 -- wcurl --curl-options="--create-dirs --silent"

# Packages & Packages.gz
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages




# key generation notes
#export GNUPGHOME="$(mktemp -d)"
#gpg --batch --passphrase '' --quick-gen-key foo@bar.tld rsa sign,encrypt never
#gpg --armor --export foo@bar.tld > publickey.gpg # put in repo, is signign key probably
#gpg --armor --export-secret-key foo@bar.tld > privatekey.gpg
#rm -rf "$GNUPGHOME"
export GNUPGHOME="$(mktemp -d)"
trap 'rm -rf -- "$GNUPGHOME"' EXIT
keyid=$(gpg --list-packets < "$privateKey" | awk '$1=="keyid:"{print$2}')
gpg --batch --import "$privateKey"



# Release, Release.gpg & InRelease
apt-ftparchive release . > Release
gpg --default-key "$keyid" -abs -o - Release > Release.gpg
gpg --default-key "$keyid" --clearsign -o - Release > InRelease

if [ "$dry" = true ]; then
    exit 0
fi

tag=latest
release=latest
repoKeyName=bs-manager

git tag -f "$tag" -m \
"bs-manager apt repo

to setup this apt repo:
\`\`\`
curl -fsSL https://raw.githubusercontent.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/refs/heads/main/$repoKeyName.gpg | sudo gpg --dearmor -o /usr/share/keyrings/$repoKeyName.gpg
cat | sudo tee /etc/apt/sources.list.d/bs-manager.sources << EOF
Suites: /
Types: deb
Uris: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/download/latest
Signed-By: /usr/share/keyrings/$repoKeyName.gpg
EOF
\`\`\`


Date: $(date --iso=s)
SHA: $(git rev-parse --short HEAD)"

echo "pushing new tag $tag"
git push origin --quiet --force "$tag"


echo "delete everything out of the release $release"
gh release view "$release" --json assets --jq '.assets[] | .name' | xargs --no-run-if-empty -n1 gh release delete-asset "$release"
echo "update the release to point to the updated tag"
gh release edit "$release" -n "$(git tag -l --format='%(body)' "$tag")" -t "$(git tag -l --format='%(subject)' "$tag")"
echo "upload new assets"
gh release upload "$release" ./*
