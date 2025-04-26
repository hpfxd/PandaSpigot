#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"
gitcmd="git -c commit.gpgsign=false"

if [ "$2" == "--jar" ] && [ "$3" == "--fast" ]; then
    echo "Skipping PandaSpigot setup because --jar and --fast are specified."
else
    ($gitcmd submodule update --init --recursive && ./scripts/remap.sh "$basedir" && ./scripts/decompile.sh "$basedir" && ./scripts/init.sh "$basedir" && ./scripts/applyPatches.sh "$basedir" "$2") || (
        echo "PandaSpigot setup failed"
        exit 1
    ) || exit 1
fi

if [ "$2" == "--jar" ]; then
    ./gradlew build && ./scripts/paperclip.sh "$basedir"
fi
) || exit 1
