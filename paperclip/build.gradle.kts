plugins {
    id("pandaspigot.conventions")
    id("paperclip")
    id("com.github.johnrengelman.shadow") version "7.1.2"
}

dependencies {
    implementation("io.sigpipe:jbsdiff:1.0")
}

sourceSets {
    create("java9")
}

tasks {
    jar {
        archiveClassifier.set("original")
        manifest {
            val agentClass = "com.hpfxd.pandaspigot.paperclip.Agent"
            attributes(
                "Main-Class" to "com.hpfxd.pandaspigot.paperclip.Paperclip",
                "Multi-Release" to true,
                "Launcher-Agent-Class" to agentClass,
                "Premain-Class" to agentClass,
            )
        }

        into("META-INF/versions/9") {
            from(sourceSets["java9"].output)
        }
    }

    shadowJar {
        val prefix = "com.hpfxd.pandaspigot.paperclip.libs"
        arrayOf("org.apache", "org.tukaani", "io.sigpipe").forEach { pack ->
            relocate(pack, "$prefix.$pack")
        }
    }
}
