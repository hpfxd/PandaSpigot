#!/usr/bin/env bash
sourceBase=$(dirname "$SOURCE")/../
cd "${basedir:-$sourceBase}"

basedir="$(pwd -P)"

log_info() {
    echo -e "\033[32m---\033[0m $1"
}

log_warning() {
    echo -e "\033[33m!!!\033[0m $1"
}

log_error() {
    echo -e "\033[31m###\033[0m $1"
}

function cleanupPatches {
    cd "$1"
    for patch in *.patch; do
        gitver=$(tail -n 2 $patch | grep -ve "^$" | tail -n 1)
        diffs=$(git diff --staged $patch | grep -E "^(\+|\-)" | grep -Ev "(From [a-z0-9]{32,}|\-\-\- a|\+\+\+ b|.index|Date\: )")

        testver=$(echo "$diffs" | tail -n 2 | grep -ve "^$" | tail -n 1 | grep "$gitver")
        if [ "x$testver" != "x" ]; then
            diffs=$(echo "$diffs" | tail -n +3)
        fi

        if [ "x$diffs" == "x" ] ; then
            git reset HEAD $patch >/dev/null
            git checkout -- $patch >/dev/null
        fi
    done
}

function basedir {
    cd "$basedir"
}

function gethead {
    (
        cd "$1"
        git log -1 --oneline
    )
}
