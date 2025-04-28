#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"
gitcmd="git -c commit.gpgsign=false"

($gitcmd submodule update --init --recursive && ./scripts/remap.sh "$basedir" && ./scripts/decompile.sh "$basedir" && ./scripts/init.sh "$basedir" && ./scripts/applyPatches.sh "$basedir" "$2") || (
    echo "PandaSpigot setup stage failed"
    exit 1
) || exit 1

if [ "$2" == "--jar" ]; then
    ./gradlew build && ./scripts/paperclip.sh "$basedir"
fi
) || exit 1
