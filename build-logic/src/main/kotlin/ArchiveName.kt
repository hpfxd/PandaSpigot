import org.gradle.api.tasks.bundling.AbstractArchiveTask

/*
 * Included from https://github.com/typst-io/gradle-specialsource
 * Original project licensed under Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0
 */
data class ArchiveName(
    val baseName: String,
    val appendix: String,
    val version: String,
    val classifier: String,
    val extension: String
) {
    fun toFileName(): String =
        listOf(
            baseName,
            appendix,
            version,
            classifier
        ).filter {
            it.isNotEmpty()
        }.joinToString("-") + if (extension.isNotEmpty()) {
            ".${extension}"
        } else ""

    companion object {
        @JvmStatic
        fun jar(name: String, version: String, classifier: String): ArchiveName =
            ArchiveName(name, "", version, classifier, "jar")

        @JvmStatic
        fun simpleJar(name: String, version: String): ArchiveName =
            jar(name, version, "")

        fun archiveNameFromTask(x: AbstractArchiveTask): ArchiveName =
            ArchiveName(
                x.archiveBaseName.orNull ?: "",
                x.archiveAppendix.orNull ?: "",
                x.archiveVersion.orNull ?: "",
                x.archiveClassifier.orNull ?: "",
                x.archiveExtension.orNull ?: ""
            )
    }
}
