#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"

(
    cd "$basedir"
    ./gradlew paperclipJar
) || (
    echo "Failed to build Paperclip jar."
    exit 1
) || exit 1
cp -v "$basedir/paperclip/build/libs/paperclip-1.8.8-R0.1-SNAPSHOT.jar" "$basedir/paperclip.jar"

echo ""
echo ""
echo ""
echo "Build success!"
echo "Copied final jar to $(cd "$basedir" && pwd -P)/paperclip.jar"
) || exit 1
