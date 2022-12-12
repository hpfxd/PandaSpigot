#!/usr/bin/env bash

(
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/base"
source "$basedir/scripts/functions.sh"
gitcmd="git -c commit.gpgsign=false -c core.safecrlf=false"

echo "Rebuilding patch files from current fork state..."
nofilter="0"
if [ "$2" == "nofilter" ] || [ "$2" == "noclean" ]; then
    nofilter="1"
fi
function cleanupPatches {
    cd "$1"
    for patch in *.patch; do
        echo "  $patch"
        diffs=$($gitcmd diff --staged "$patch" | grep --color=none -E "^(\+|-)" | grep --color=none -Ev "(--- a|\+\+\+ b|^.index)")

        if [ "x$diffs" == "x" ] ; then
            $gitcmd reset HEAD "$patch" >/dev/null
            $gitcmd checkout -- "$patch" >/dev/null
        fi
    done
}

function savePatches {
    what=$1
    what_name=$(basename "$what")
    target=$2
    patch_folder=$3
    echo "Formatting patches for $what..."

    cd "$basedir/$patch_folder/"
    if [ -d "$basedir/$target/.git/rebase-apply" ]; then
        # in middle of a rebase, be smarter
        echo "REBASE DETECTED - PARTIAL SAVE"
        last=$(cat "$basedir/$target/.git/rebase-apply/last")
        next=$(cat "$basedir/$target/.git/rebase-apply/next")
        orderedfiles=$(find . -name "*.patch" | sort)
        for i in $(seq -f "%04g" 1 1 $last)
        do
            if [ $i -lt $next ]; then
                rm $(echo "$orderedfiles{@}" | sed -n "${i}p")
            fi
        done
    else
        rm -rf *.patch
    fi

    cd "$basedir/$target"

    $gitcmd format-patch --zero-commit --full-index --no-signature --no-stat -N -o "$basedir/$patch_folder/" upstream/upstream >/dev/null
    cd "$basedir"
    $gitcmd add --force -A "$basedir/$patch_folder"
    if [ "$nofilter" == "0" ]; then
        cleanupPatches "$basedir/$patch_folder"
    fi
    echo "Patches saved for $what to $patch_folder/"
}

savePatches "$workdir/Paper/PaperSpigot-API" "PandaSpigot-API" "patches/api"
if [ -f "$basedir/PandaSpigot-API/.git/patch-apply-failed" ]; then
    echo "$(color 1 31)[[[ WARNING ]]] $(color 1 33)- Not saving PandaSpigot-Server as it appears PandaSpigot-API did not apply clean.$(colorend)"
    echo "$(color 1 33)If this is a mistake, delete $(color 1 34)PandaSpigot-API/.git/patch-apply-failed$(color 1 33) and run rebuild again.$(colorend)"
    echo "$(color 1 33)Otherwise, rerun ./panda patch to have a clean PandaSpigot-API apply so the latest PandaSpigot-Server can build.$(colorend)"
else
    savePatches "$workdir/Paper/PaperSpigot-Server" "PandaSpigot-Server" "patches/server"
fi
) || exit 1
