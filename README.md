# PandaSpigot [![Build](https://img.shields.io/github/actions/workflow/status/hpfxd/PandaSpigot/build.yml?branch=master&label=Build)](https://github.com/hpfxd/PandaSpigot/actions/workflows/build.yml) [![Discord](https://img.shields.io/discord/1048733138655924274?label=Discord)](https://discord.gg/m6vCCX6Hvr) [![Servers](https://img.shields.io/bstats/servers/15154?label=Servers)](https://bstats.org/plugin/bukkit/PandaSpigot/15154)
Fork of Paper for 1.8.8 focused on improved performance and stability.

## Highlights
- **Backported API enhancements from newer versions**
    - ServerTickStartEvent & ServerTickEndEvent
    - PlayerChunkLoadEvent & PlayerChunkUnloadEvent
    - PlayerHandshakeEvent
    - EntityMoveEvent

- **Greatly improved network performance**
    - **Updating to Netty 4.1** offers the ability to use newer Java versions with epoll on Linux.
    - **Improved flush handling** to massively improve entity tracker performance.
    - **Support for Unix domain sockets** to avoid the overhead of TCP when using a proxy on the same machine.

- **More configuration options**, such as:
    - Customizable knockback
    - World and player data saving

See a full list of patches [here](./patches/).

## Using
You can download the latest pre-built server JAR by clicking the download button below.  
[![Download](https://custom-icon-badges.demolab.com/badge/-Download-blue?style=for-the-badge&logo=download&logoColor=white)](https://downloads.hpfxd.com/v2/projects/pandaspigot/versions/1.8.8/builds/latest/downloads/paperclip)

For support, please join our [Discord](https://discord.gg/m6vCCX6Hvr).

## API 
See our API patches [here](./patches/api/).  
[![Javadocs](https://repo.hpfxd.com/api/badge/latest/releases/com/hpfxd/pandaspigot/pandaspigot-api?name=Javadocs)](https://repo.hpfxd.com/javadoc/releases/com/hpfxd/pandaspigot/pandaspigot-api/1.8.8-R0.1-SNAPSHOT/raw/index.html)
<details>
<summary>Maven</summary>

```xml
<repositories>
    <repository>
        <id>hpfxd-repo</id>
        <url>https://repo.hpfxd.com/releases/</url>
    </repository>
</repositories>

<dependencies>
    <dependency>
        <groupId>com.hpfxd.pandaspigot</groupId>
        <artifactId>pandaspigot-api</artifactId>
        <version>1.8.8-R0.1-SNAPSHOT</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```
</details>

<details>
<summary>Gradle (kts)</summary>

```kotlin
repositories {
    mavenCentral()
    maven(url = "https://repo.hpfxd.com/releases/")
}

dependencies {
    compileOnly("com.hpfxd.pandaspigot:pandaspigot-api:1.8.8-R0.1-SNAPSHOT")
}
```
</details>

## Building
To compile PandaSpigot, you'll need:
- JDK 17 (required to run the decompiler)
- Git
- Bash

🧩 Although JDK 17 is required for building, the compiled JAR remains fully compatible with Java 8.

Building, patching, and compiling are all done through the main `panda` script.

PandaSpigot can be built by running `./panda jar`, and you will find the final Paperclip jar in `paperclip.jar`

### Panda Bash build script
The `panda` Bash script is the entry point for setup, patching, and builds.
Run it from a Bash-compatible shell on your platform. Run `./panda` without
arguments to print its command list.

Normal commands:

| Command | Description |
| --- | --- |
| `rb`, `rebuild` | Rebuild patches, can be called from anywhere. |
| `setup` | Remap, decompile, and patch Minecraft. Can be run from anywhere. |
| `p`, `patch` | Apply all patches to the project without building it. Can be run from anywhere. |
| `j`, `jar` | Apply all patches and build the project, `paperclip.jar` will be output. Can be run from anywhere. |
| `c`, `clean` | Removes all generated files, `PandaSpigot-API`, `PandaSpigot-Server`, and `work`. |
| `con`, `continue` | Shortcut command for running `git am --continue` or `git rebase --continue`. |

Commands that require `. ./panda install` first:

| Command | Description |
| --- | --- |
| `r`, `root` | Change directory to the root of the project. |
| `a`, `api` | Move to the `PandaSpigot-API` directory. |
| `s`, `server` | Move to the `PandaSpigot-Server` directory. |
| `e`, `edit` | Use to edit a specific patch, give it the argument `server` or `api` respectively to edit the correct project. Use the argument `continue` after the changes have been made to finish and rebuild patches. Can be called from anywhere. |
| `install` | Add an alias to `$RCPATH` to allow full functionality of this script. |

Install the default `panda` alias with:

```bash
. ./panda install
```

You can also provide a custom alias name:

```bash
. ./panda install example
```

`PandaSpigot-API` and `PandaSpigot-Server` are generated work trees created by
the build scripts. The patch creation process follows Paper's contributing guide,
which is linked below; `./panda rb` is the PandaSpigot command that saves those
work tree commits back into `patches/api` and `patches/server`.

### Patch workflow
PandaSpigot uses a patch-based workflow. Changes are committed once inside the
generated work tree, then committed again from the repository root after the
patch files are rebuilt.

Use this order:

1. Make your changes in `PandaSpigot-API` or `PandaSpigot-Server`.
2. Commit those changes inside that generated work tree.
3. Return to the repository root and run `./panda rb`.
4. Review the regenerated files in `patches/api` or `patches/server`.
5. Commit the regenerated patch files from the repository root.

Only push commits from the repository root. Do not push or pull from
`PandaSpigot-API` or `PandaSpigot-Server`; their commits are only used to create
patch files. Commit work tree changes before rebuilding or reapplying patches,
because those commands can reset the generated work trees.

## Contributing
You can mostly follow [Paper's contributing guide](https://github.com/PaperMC/Paper-archive/blob/ver/1.16.5/CONTRIBUTING.md), just remember:
- Multi-line changes start with `// PandaSpigot start` and end with `// PandaSpigot end`
- If the change isn't obvious, add a small explanation like this: `// PandaSpigot start - reason`
- One-line changes should have `// PandaSpigot` at the end of the line.
- Follow Java code style (aka. Oracle style), with some exceptions:
  - If you are modifying upstream files, keep your diff size minimal. Going over 80 characters per line is fine to make this happen.
  - When in doubt or the code around your change is in a clearly different style, use the same style as the surrounding code.

When contributing, please think about the side effects of any changes you write.
Plugin compatibility is important, and we wish to minimize any breakage.

Please do not open pull requests for features that you cannot justify the existence of,
and the added maintenance costs of that come along with them. If you are thinking of
adding a feature that may be controversial, please open an issue first!
