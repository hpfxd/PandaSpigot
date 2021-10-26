#!/usr/bin/env bash

cd ./Paperclip
git fetch origin master
git reset --hard 2d4c7b3
cd ..
cp ../../PandaSpigot-Server/build/libs/pandaspigot-1.8.8-R0.1-SNAPSHOT.jar ./Paperclip/pandaspigot-1.8.8.jar
cp ./work/1.8.8/1.8.8.jar ./Paperclip/minecraft_server.1.8.8.jar
cd ./Paperclip
mvn -Dmcver=1.8.8 -Dvanillajar=../minecraft_server.1.8.8.jar -Dpaperjar=../pandaspigot-1.8.8.jar clean package
cd ..
cp ./Paperclip/assembly/target/paperclip-1.8.8.jar ../../PandaSpigot-Server/build/libs/pandaspigot.jar

echo ""
echo ""
echo ""
echo "Build success!"
echo "Copied final jar to PandaSpigot-Server/build/libs/pandaspigot.jar"
