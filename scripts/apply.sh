#!/usr/bin/env bash
# get base dir regardless of execution location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
initScript=$(dirname "$SOURCE")/init.sh
. "$initScript"
PS1="$"

paperVer=$(cat base/.upstream-state)
log_info "Applying PandaSpigot patches"
function applyPatch {
    what=$1
    what_name=$(dirname "$what")
    target=$2
    branch=$3
    patch_folder=$4

    cd "$basedir/$what"
    git fetch --all
    git branch -f upstream "$branch" >/dev/null 2>&1

    cd "$basedir"
    if [ ! -d  "$basedir/$target" ]; then
        mkdir "$basedir/$target"
        cd "$basedir/$target"
        git init
        cd "$basedir"
    fi
    cd "$basedir/$target"
    echo "Resetting $target to $what_name..."
    git remote rm upstream > /dev/null 2>&1
    git remote add upstream "$basedir/$what" >/dev/null 2>&1
    git checkout master 2>/dev/null || git checkout -b master
    git fetch upstream >/dev/null 2>&1
    git reset --hard upstream/upstream
    echo "  Applying patches to $target..."
    git am --abort >/dev/null 2>&1
    for patchFile in "$basedir/patches/$patch_folder/"*.patch
    do
        git am --3way --ignore-whitespace "$patchFile"
    done
    #git am --3way --ignore-whitespace "$basedir/patches/$patch_folder/*.patch"
    if [ "$?" != "0" ]; then
        echo "  Something did not apply cleanly to $target."
        echo "  Please review above details and finish the apply then"
        echo "  save the changes with rebuildPatches.sh"
        exit 1
    else
        echo "  Patches applied cleanly to $target"
    fi
}

log_info "Applying PandaSpigot API patches"
applyPatch base/Paper/PaperSpigot-API PandaSpigot-API HEAD api
log_info "Applying PandaSpigot server patches"
applyPatch base/Paper/PaperSpigot-Server PandaSpigot-Server HEAD server

log_info "Patches successfully applied."
