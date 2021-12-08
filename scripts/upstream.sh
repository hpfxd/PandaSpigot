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

if [[ "$1" == up* ]]; then
    (
        cd "$basedir/base/Paper/"
        git fetch && git reset --hard origin/master
        cd ../
        git add Paper
    )
fi
log_info "Setting up build environment"
git submodule update --init --recursive
log_info "Preparing upstream..."
paperVer=$(gethead base/Paper)

cd "$basedir"
cp -f scripts/baseremap.sh base/Paper/remap.sh
cp -f scripts/basedecompile.sh base/Paper/decompile.sh
cp -f scripts/baseinit.sh base/Paper/init.sh
cp -f scripts/basenewApplyPatches.sh base/Paper/newApplyPatches.sh

cd "$basedir/base/Paper/"

git submodule update --init && ./remap.sh && ./decompile.sh && ./init.sh && ./newApplyPatches.sh

cd "PaperSpigot-Server"
mcVer=$(mvn -o org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=minecraft_version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }')

basedir
. scripts/importmcdev.sh
scripts/generatesources.sh
minecraftversion=$(cat "$basedir/base/Paper/BuildData/info.json" | grep minecraftVersion | cut -d '"' -f 4)

cd base/Paper/

version=$(echo -e "Paper: $paperVer\nmc-dev:$importedmcdev")
tag="${minecraftversion}-${mcVer}-$(echo -e $version | sha1sum | awk '{print $1}')"

function tag {
(
    cd "$1"
    if [ "$2" == "1" ]; then
        git tag -d "$tag" 2>/dev/null
    fi
    echo -e "$(date)\n\n$version" | git tag -a "$tag" -F - 2>/dev/null
)
}

forcetag=0
upstreamState=$(cat "$basedir/base/.upstream-state")
if [ "$upstreamState" != "$tag" ]; then
    forcetag=1
fi

tag PaperSpigot-API $forcetag
tag PaperSpigot-Server $forcetag

echo "$tag" > "$basedir/base/.upstream-state"

log_info "Build environment prepared. Run './panda apply' to apply patches."
