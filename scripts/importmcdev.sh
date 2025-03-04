#!/usr/bin/env bash

(
set -e
nms="net/minecraft/server"
PS1="$"
basedir="$(cd "$1" && pwd -P)"
source "$basedir/scripts/functions.sh"
gitcmd="git -c commit.gpgsign=false"

workdir="$basedir/base"
minecraftversion=$(cat "$workdir/Paper/BuildData/info.json" | grep minecraftVersion | cut -d '"' -f 4)
decompiledir="$workdir/mc-dev/spigot"

find "$decompiledir/$nms" -type f -name "*.java" | while read file; do
    filename=$(basename "$file")
    target="$workdir/Paper/PaperSpigot-Server/src/main/java/$nms/$filename"

    if [[ ! -f "$target" ]]; then
        cp "$file" "$target"
    fi
done

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
set -e
cd "$workdir/Paper/PaperSpigot-Server/"
rm -rf nms-patches applyPatches.sh makePatches.sh README.md >/dev/null 2>&1
$gitcmd add --force . -A >/dev/null 2>&1
echo -e "mc-dev Imports" | $gitcmd commit . -q -F -
)
