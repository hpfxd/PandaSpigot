#!/usr/bin/env bash

cp ../../PandaSpigot-Server/build/libs/pandaspigot-1.8.8-R0.1-SNAPSHOT.jar ./Paperclip/pandaspigot-1.8.8.jar
cp ./work/1.8.8/1.8.8.jar ./Paperclip/minecraft_server.1.8.8.jar
cd ./Paperclip
sed -i -e 's/http:\/\/clojars/https:\/\/clojars/g' ./java8/pom.xml # Replace http repository with https
mvn clean package --batch-mode -Dmcver=1.8.8 "-Dpaperjar=../pandaspigot-1.8.8.jar" "-Dvanillajar=../minecraft_server.1.8.8.jar"
cd ..
cp ./Paperclip/assembly/target/paperclip*.jar ../../PandaSpigot-Server/build/libs/pandaspigot.jar

echo ""
echo ""
echo ""
echo "Build success!"
echo "Copied final jar to PandaSpigot-Server/build/libs/pandaspigot.jar"
