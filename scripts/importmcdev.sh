#!/usr/bin/env bash

(
set -e
nms="net/minecraft/server"
PS1="$"
basedir="$(cd "$1" && pwd -P)"
source "$basedir/scripts/functions.sh"
gitcmd="git -c commit.gpgsign=false"

workdir="$basedir/base"
minecraftversion=$(cat "$workdir/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
decompiledir="$workdir/mc-dev/forge"
# replace for now
decompiledir="$workdir/mc-dev/spigot"

find "$decompiledir/$nms" -name '*.java' -type f -exec cp -nt "$workdir/Paper/PaperSpigot-Server/src/main/java/$nms" {} +
cp -rt "$workdir/Paper/PaperSpigot-Server/src/main/resources" "$decompiledir/assets" "$decompiledir/yggdrasil_session_pubkey.der"

(
    cd "$workdir/Paper/PaperSpigot-Server/"
    lastlog=$($gitcmd log -1 --oneline)
    if [[ "$lastlog" = *"mc-dev Imports"* ]]; then
        $gitcmd reset --hard HEAD^
    fi
)

########################################################
########################################################
########################################################
#                   NMS IMPORTS
# Temporarily add new NMS dev imports here before you run paper patch
# but after you have paper rb'd your changes, remove the line from this file before committing.
# we do not need any lines added to this file for NMS

# import FileName

########################################################
########################################################
########################################################
set -e
cd "$workdir/Paper/PaperSpigot-Server/"
rm -rf nms-patches applyPatches.sh makePatches.sh README.md >/dev/null 2>&1
$gitcmd add --force . -A >/dev/null 2>&1
echo -e "mc-dev Imports" | $gitcmd commit . -q -F -
)
