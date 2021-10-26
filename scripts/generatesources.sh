#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
initScript=$(dirname "$SOURCE")/init.sh
. "$initScript"


cd "$basedir"
paperVer=$(cat base/.upstream-state)

minecraftversion=$(cat "$basedir/base/Paper/BuildData/info.json" | grep minecraftVersion | cut -d '"' -f 4)
decompile="base/Paper/work/$minecraftversion/"

mkdir -p base/mc-dev/src/net/minecraft/server

cd base/mc-dev
if [ ! -d ".git" ]; then
    git init
fi

#cp $(sed 's/ /\\ /g' <<< $basedir)/$decompile/net/minecraft/server/*.java src/net/minecraft/server

for nmsFile in "$basedir/$decompile/net/minecraft/server/"*.java
do
    cp "$nmsFile" "src/net/minecraft/server"
done


base="$basedir/base/Paper/PaperSpigot-Server/src/main/java/net/minecraft/server"
cd "$basedir/base/mc-dev/src/net/minecraft/server/"
for file in $(/bin/ls "$base")
do
    if [ -f "$file" ]; then
        rm -f "$file"
    fi
done
cd "$basedir/base/mc-dev"
git add . -A
git commit . -m "mc-dev"
git tag -a "$paperVer" -m "$paperVer" 2>/dev/null
