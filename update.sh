#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

debList=$(realpath "debsIncludedInThisRepo")
upstreamRepo=Zagrios/bs-manager

# shellcheck disable=SC2120
h () {
    # if arguments, print them
    [ $# == 0 ] || echo "$*"

  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTION]...
  update $debList with debs this repo is publishing and push a commit
Available options:
  -h, --help       display this help and exit
  -n, --check      don't modify or push anything, just check if an update is required
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
TEMP=$(getopt -o hc --long help,check -n "$0" -- "$@")
#shellcheck disable=SC2181
if [ $? != 0 ] ; then
    die "something wrong with getopt"
fi
eval set -- "$TEMP"

check=false
while true ; do
    case "$1" in
        -h|--help) h ;;
        -c|--check) check=true; shift ;;
        --) shift ; break ;;
        *) die "issue parsing args, unexpected argument '$0'!" ;;
    esac
done

# list of updsream debs to deal with, newline separated
generateFileList () {
    repo=${1:?Must Provide Repo to generateFileList}
    releaseCount=${2:-2}
    gh release list -R "$repo" --exclude-drafts --exclude-pre-releases --limit "$releaseCount" --json tagName --jq '.[] | .tagName' | xargs -I{} gh release view '{}' -R "$repo" --json assets --jq '.assets[] | .url' | grep ".deb$"
}


newFiles=$(mktemp -t tmp.debGitRepoThing.XXXXXXXXXX,)
trap 'rm -- "$newFiles"' EXIT

generateFileList "$upstreamRepo" "$releaseCount" | sort > "$newFiles"

if cmp -s "$debList" "$newFiles" ; then
    echo "upstream unchagned from current, not doing anything"
    exit 0
fi

echo "deb list updated:"
cat "$debList"
echo new
cat "$newFiles"
diff "$debList" "$newFiles"


if [ "$check" = true ]; then
    exit 0
fi

cp "$newFiles" "$debList"
echo TODO update readme
git add README.md "$debList"

git commit -F- <<EOF
update deb list

run on $(date +"%Y-%m-%d %H:%M:%S %z")
TODO better message
EOF
git push
