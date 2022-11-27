#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"
gitcmd="git -c commit.gpgsign=false"

($gitcmd submodule update --init && cd "base/Paper" && $gitcmd submodule update --init && cd "$basedir" && ./scripts/remap.sh "$basedir" && ./scripts/decompile.sh "$basedir" && ./scripts/init.sh "$basedir" && ./scripts/applyPatches.sh "$basedir") || (
    echo "Failed to build PandaSpigot"
    exit 1
) || exit 1
if [ "$2" == "--jar" ]; then
    ./gradlew build && ./scripts/paperclip.sh "$basedir"
fi
) || exit 1
