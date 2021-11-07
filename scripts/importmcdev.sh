#!/usr/bin/env bash

(
set -e
nms="net/minecraft/server"
export MODLOG=""
PS1="$"
basedir="$(cd "$1" && pwd -P)"

workdir="$basedir/base/Paper/work"
minecraftversion=$(cat "$basedir/base/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
decompiledir="$workdir/$minecraftversion"
tmpresourcesdir="$decompiledir/resources"

# ensure temp resources dir exists
mkdir -p "$tmpresourcesdir"

export importedmcdev=""
function import {
    file="${1}.java"
    target="$basedir/base/Paper/PaperSpigot-Server/src/main/java/$nms/$file"
    base="$decompiledir/$nms/$file"

    if [[ ! -f "$target" ]]; then
        export importedmcdev="$importedmcdev $1"
        export MODLOG="$MODLOG  Imported $file from mc-dev\n";
        echo "Copying $base to $target"
        cp "$base" "$target"
    fi
}

function importResource {
    file="$1"
    target="$basedir/base/Paper/PaperSpigot-Server/src/main/resources/$file"

    # only continue if target doesn't exist
    if [[ ! -f "$target" ]]; then
        # extract the resource to temp directory
        cd "$tmpresourcesdir"
        jar xf "$decompiledir/$minecraftversion-mapped.jar" "$file"

        # make sure target directory exists
        targetdir=$(dirname "$target")
        mkdir -p "$targetdir/"

        base="$tmpresourcesdir/$file"

        # copy the resource to target
        export MODLOG="$MODLOG  Imported $file from mc-dev\n";
        echo "Copying $base to $target"
        cp -r "$base" "$target"
    fi
}

(
    cd "$basedir/base/Paper/PaperSpigot-Server/"
    lastlog=$(git log -1 --oneline)
    if [[ "$lastlog" = *"mc-dev Imports"* ]]; then
        git reset --hard HEAD^
    fi
)

# Import all Minecraft classes
for fullname in "$decompiledir/$nms"/*.java; do
    filename=$(basename -- "$fullname") # file name without path
    noext="${filename%.*}" # file name without extension
    import "$noext"
done

# Import resources

importResource "yggdrasil_session_pubkey.der" # yggdrasil public key
importResource "assets/minecraft/" # minecraft assets (translations)

cd "$basedir/base/Paper/PaperSpigot-Server/"
rm -rf nms-patches applyPatches.sh makePatches.sh >/dev/null 2>&1
git add . -A >/dev/null 2>&1
echo -e "mc-dev Imports\n\n$MODLOG" | git commit . -F -
)
