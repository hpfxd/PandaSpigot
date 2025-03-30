import io.sigpipe.jbsdiff.DefaultDiffSettings
import io.sigpipe.jbsdiff.Diff
import org.apache.commons.compress.compressors.CompressorStreamFactory
import java.nio.file.Files
import java.security.MessageDigest
import java.util.Properties

tasks {
    register<Jar>("paperclipJar") {
        outputs.upToDateWhen { false }
        dependsOn("shadowJar", ":pandaspigot-server:remap")

        from(zipTree((tasks["shadowJar"] as Jar).archiveFile.get()))

        manifest {
            from((tasks["jar"] as Jar).manifest)
        }

        rename { name ->
            if (name.endsWith("-LICENSE.txt")) {
                "META-INF/license/$name"
            } else {
                name
            }
        }

        doFirst {
            val inTask = project(":pandaspigot-server").tasks["remap"] as RemapTask
            val diffFile = temporaryDir.resolve("pandaspigot.patch")
            val propertiesFile = temporaryDir.resolve("patch.properties")

            val vanillaJar = project.rootProject.layout.projectDirectory.file("base/mc-dev/1.8.8.jar").asFile
            val newJar = inTask.outJarFile.get().asFile

            logger.info("Reading jars into memory")
            val vanillaBytes = Files.readAllBytes(vanillaJar.toPath())
            val patchedBytes = Files.readAllBytes(newJar.toPath())

            logger.info("Creating patch")
            diffFile.outputStream().use { Diff.diff(vanillaBytes, patchedBytes, it, DefaultDiffSettings(CompressorStreamFactory.XZ)) }

            val digest = MessageDigest.getInstance("SHA-256")
            val digestSha1 = MessageDigest.getInstance("SHA-1")

            logger.info("Hashing files")
            val vanillaHash = digest.digest(vanillaBytes)
            val patchedHash = digest.digest(patchedBytes)
            val vanillaSha1 = digestSha1.digest(vanillaBytes)

            val properties = Properties()
            properties.setProperty("originalHash", vanillaHash.toHex())
            properties.setProperty("patchedHash", patchedHash.toHex())
            properties.setProperty("patch", "pandaspigot.patch")
            properties.setProperty("sourceUrl", "https://launcher.mojang.com/v1/objects/${vanillaSha1.toHex().lowercase()}/server.jar")
            properties.setProperty("version", "1.8.8")

            logger.info("Writing properties file")
            propertiesFile.bufferedWriter().use { properties.store(it, null) }

            from(propertiesFile, diffFile)
        }
    }
}

fun ByteArray.toHex(): String {
    val sb = StringBuilder(this.size * 2)
    for (byte in this) {
        sb.append(String.format("%02X", byte.toInt() and 0xFF))
    }
    return sb.toString()
}
