#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

debList=$(realpath "$DIR/debsIncludedInThisRepo")
repoDir=$(realpath "$DIR/repo")

# shellcheck disable=SC2120
h () {
    # if arguments, print them
    [ $# == 0 ] || echo "$*"

  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTION]...
       $(basename "${BASH_SOURCE[0]}") --create
       $(basename "${BASH_SOURCE[0]}") --sign <--sign-from-key-id=SIGNING_KEY_NAME | --sign-from-key-file=key.gpg>
  do operations with debian repo in the dir repo
Available options:
  -h, --help                    display this help and exit
  -s, --sign                    sign the repo
      --sign-from-key-id=KEY_ID sign the repo with KEY_ID already in gpg
      --sign-from-file=KEY.gpg  sign the repo with a file non in GPG
  -c, --create                  create repo from deb list
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
TEMP=$(getopt -o hsc --long help,create,sign,sign-from-key-id:,sign-from-file: -n "$0" -- "$@")
#shellcheck disable=SC2181
if [ $? != 0 ] ; then
    die "something wrong with getopt"
fi
eval set -- "$TEMP"

keyid=
keyFile=
create=false
sign=false
while true ; do
    case "$1" in
        -h|--help) h ;;
        -s|--sign) sign=true; shift ;;
        --sign-from-key-id) keyid=$2; shift 2 ;;
        --sign-from-file) keyFile=$2; shift 2 ;;
        -c|--create) create=true; shift ;;
        --) shift ; break ;;
        *) die "issue parsing args, unexpected argument '$0'!" ;;
    esac
done


sign() {
    keyid=${1:?Must provide signing key to sign function}
    gpg --quiet --default-key "$keyid" -abs -o - "$repoDir/Release" > "$repoDir/Release.gpg"
    gpg --quiet --default-key "$keyid" --clearsign -o - "$repoDir/Release" > "$repoDir/InRelease"
}

create() {
    #rm -rf "$repoDir"
    #mkdir "$repoDir"
    cd "$repoDir"

    # download all the debs in newFileList
    < "$debList" xargs curl --parallel --location --remote-name-all --output-dir "$repoDir" --skip-existing
    echo "done downloading"

    dpkg-scanpackages --multiversion . > Packages
    gzip -k -f Packages

    apt-ftparchive release . > Release
}

if [[ "$sign" == true ]]; then
    if  [[ -z "$keyid" ]] && [[ -z "$keyFile" ]]; then
        h "need to pass in signing key file or id"
    fi

    if  [[ -n "$keyFile" ]]; then
        # key generation notes
        #export GNUPGHOME="$(mktemp -d)"
        #gpg --batch --passphrase '' --quick-gen-key foo@bar.tld rsa sign,encrypt never
        #gpg --armor --export foo@bar.tld > publickey.gpg
        #gpg --armor --export-secret-key foo@bar.tld > privatekey.gpg
        #rm -rf "$GNUPGHOME"
        GNUPGHOME="$(mktemp -d)"
        export GNUPGHOME
        trap 'rm -rf -- "$GNUPGHOME"' EXIT
        keyid=$(gpg --quiet --list-packets < "$keyFile" | awk '$1=="keyid:"{print$2}')
        gpg --quiet --batch --import "$keyFile"
    fi
    sign "$keyid"

elif [[ "$create" == true ]]; then
    create
else
    h "need to pick an operation"
fi
