#!/usr/bin/env bash

(
set -e
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/base"
minecraftversion=$(cat "$workdir/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
spigotdecompiledir="$workdir/mc-dev/spigot"
nms="$spigotdecompiledir/net/minecraft/server"
cb="src/main/java/net/minecraft/server"
resources="src/main/resources"
gitcmd="git -c commit.gpgsign=false"

# https://stackoverflow.com/a/38595160
# https://stackoverflow.com/a/800644
if sed --version >/dev/null 2>&1; then
  strip_cr() {
    sed -i -- "s/\r//" "$@"
  }
else
  strip_cr () {
    sed -i "" "s/$(printf '\r')//" "$@"
  }
fi

patch=$(which patch 2>/dev/null)
if [ "x$patch" == "x" ]; then
    patch="$basedir/hctap.exe"
fi

echo "Applying CraftBukkit patches to NMS..."
cd "$workdir/Paper/CraftBukkit"
$gitcmd checkout -B patched HEAD >/dev/null 2>&1
rm -rf "$cb"
# create baseline NMS import so we can see diff of what CB changed
while IFS= read -r -d '' file
do
    patchFile="$file"
    file="$(echo "$file" | cut -d "/" -f2- | cut -d. -f1).java"
    mkdir -p "$(dirname $cb/"$file")"
    cp "$nms/$file" "$cb/$file"
done <   <(find nms-patches -type f -print0)
$gitcmd add --force src
$gitcmd commit -q -m "Minecraft $ $(date)" --author="Vanilla <auto@mated.null>"

# apply patches
while IFS= read -r -d '' file
do
    patchFile="$file"
    file="$(echo "$file" | cut -d "/" -f2- | cut -d. -f1).java"

    echo "Patching $file < $patchFile"
    set +e
    strip_cr "$nms/$file" > /dev/null
    set -e

    "$patch" -s -d src/main/java -p 1 < "$patchFile"
done <   <(find nms-patches -type f -print0)


$gitcmd add --force src
$gitcmd commit -q -m "CraftBukkit $ $(date)" --author="CraftBukkit <auto@mated.null>"
$gitcmd -c advice.detachedHead=false checkout -f HEAD~2
)
