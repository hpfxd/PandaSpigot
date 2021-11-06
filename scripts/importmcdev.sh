#!/usr/bin/env bash

(
set -e
nms="net/minecraft/server"
export MODLOG=""
PS1="$"
basedir="$(cd "$1" && pwd -P)"

workdir="$basedir/base/Paper/work"
minecraftversion=$(cat "$basedir/base/Paper/BuildData/info.json"  | grep minecraftVersion | cut -d '"' -f 4)
decompiledir="$workdir/$minecraftversion"

export importedmcdev=""
function import {
    export importedmcdev="$importedmcdev $1"
    file="${1}.java"
    target="$basedir/base/Paper/PaperSpigot-Server/src/main/java/$nms/$file"
    base="$decompiledir/$nms/$file"

    if [[ ! -f "$target" ]]; then
        export MODLOG="$MODLOG  Imported $file from mc-dev\n";
        echo "Copying $base to $target"
        cp "$base" "$target"
    else
        echo "UN-NEEDED IMPORT: $file"
    fi
}

(
    cd "$basedir/base/Paper/PaperSpigot-Server/"
    lastlog=$(git log -1 --oneline)
    if [[ "$lastlog" = *"mc-dev Imports"* ]]; then
        git reset --hard HEAD^
    fi
)

import BlockBeacon
import ChunkCache
import ChunkCoordIntPair
import EntityTypes
import ItemFireworks
import PacketPlayInUseEntity
import PacketPlayOutEntityMetadata
import PacketPlayOutPlayerInfo
import PacketPlayOutScoreboardTeam
import PacketPlayOutNamedEntitySpawn
import PacketPlayOutSpawnEntityLiving
import PacketPlayOutAttachEntity
import PersistentScoreboard
import SlotResult
import StatisticList
import PacketPlayOutSpawnEntity
import ItemGoldenApple
import ItemPotion
import ServerPing
import WorldGenCaves
import WorldSettings
import BlockCarpet
import MerchantRecipeList
import Packet
import PacketPrepender
import PacketSplitter

cd "$basedir/base/Paper/PaperSpigot-Server/"
rm -rf nms-patches applyPatches.sh makePatches.sh >/dev/null 2>&1
git add . -A >/dev/null 2>&1
echo -e "mc-dev Imports\n\n$MODLOG" | git commit . -F -
)
