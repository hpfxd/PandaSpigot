#!/usr/bin/env bash

# get base dir regardless of execution location
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SOURCE=$([[ "$SOURCE" = /* ]] && echo "$SOURCE" || echo "$PWD/${SOURCE#./}")
basedir=$(dirname "$SOURCE")

PS1="$"
workdir="$basedir/work"
minecraftversion="$(cat BuildData/info.json | grep minecraftVersion | cut -d '"' -f 4)"
decompiledir="$workdir/$minecraftversion"
nms="$decompiledir/net/minecraft/server"
cb=src/main/java/net/minecraft/server

patch="$(which patch 2>/dev/null)"
if [ "x$patch" == "x" ]; then
    patch="$basedir/hctap.exe"
fi

echo "Applying CraftBukkit patches to NMS..."
cd "$basedir/CraftBukkit"
git checkout -B patched HEAD >/dev/null 2>&1
rm -rf "$cb"
mkdir -p "$cb"
for file in $(ls nms-patches)
do
    patchFile="nms-patches/$file"
    file="$(echo $file | cut -d. -f1).java"

    echo "Patching $file < $patchFile"
    sed -i 's/\r//' "$nms/$file" > /dev/null

    cp "$nms/$file" "$cb/$file"
    "$patch" -s -d src/main/java/ "net/minecraft/server/$file" < "$patchFile"
done

git add src >/dev/null 2>&1
git commit -m "CraftBukkit $ $(date)" >/dev/null 2>&1
git checkout -f HEAD^ >/dev/null 2>&1
