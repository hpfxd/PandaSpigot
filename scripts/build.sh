#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"
gitcmd="git -c commit.gpgsign=false"

$gitcmd submodule update --init --recursive
cd "$basedir"

if [ "$2" == "--setup" ] || [ "$2" == "--jar" ]; then
    ./scripts/remap.sh "$basedir"
    ./scripts/decompile.sh "$basedir"
    ./scripts/init.sh "$basedir"
fi
    ./scripts/applyPatches.sh "$basedir" "$2"

if [ "$2" == "--jar" ]; then
    ./gradlew build && ./scripts/paperclip.sh "$basedir"
fi
) || exit 1
