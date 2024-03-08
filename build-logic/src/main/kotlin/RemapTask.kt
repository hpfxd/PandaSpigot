import net.md_5.specialsource.AccessMap
import net.md_5.specialsource.Jar
import net.md_5.specialsource.JarMapping
import net.md_5.specialsource.JarRemapper
import net.md_5.specialsource.RemapperProcessor
import net.md_5.specialsource.provider.JarProvider
import org.gradle.api.DefaultTask
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.SkipWhenEmpty
import org.gradle.api.tasks.TaskAction

/*
 * Included from https://github.com/typst-io/gradle-specialsource - modified to add support for specifying an access
 * transformer to pass to SpecialSource. Original project licensed under Apache 2.0 - https://www.apache.org/licenses/LICENSE-2.0
 */
/**
 * Java bytecode remap task.
 *
 * This task uses and following [md-5's SpecialSource.](https://github.com/md-5/specialsource)
 *
 * Command-line arguments: [SpecialSource.java](https://github.com/md-5/SpecialSource/blob/master/src/main/java/net/md_5/specialsource/SpecialSource.java#L63)
 *
 * @author typst-io
 */
abstract class RemapTask : DefaultTask() {
    /**
     * Inputs a source jar file as `RegularFile`. Mandatory.
     *
     * Corresponding cmd-line args:
     *
     * ```-i ${inJarFile}```
     */
    @get:InputFile
    @get:SkipWhenEmpty
    abstract val inJarFile: RegularFileProperty

    /**
     * Inputs a destination dir. Mandatory.
     */
    @get:OutputFile
    abstract val outJarFile: RegularFileProperty

    /**
     * Input a mapping file as `RegularFile`. Mandatory.
     *
     * Corresponding cmd-line args:
     *
     * ```-srg-in ${mappingFile}```
     */
    @get:InputFile
    abstract val mappingFile: RegularFileProperty

    /**
     * Input an access transformer file as `RegularFile`.
     *
     * Corresponding cmd-line args:
     *
     * ```-access-transformer ${accessTransformer}```
     */
    @get:InputFile
    @get:Optional
    abstract val accessTransformerFile: RegularFileProperty

    /**
     * Input whether reverse or not. Defaults to `false`.
     *
     * Corresponding cmd-line args:
     *
     * ```-reverse```
     */
    @get:Input
    @get:Optional
    abstract val reverse: Property<Boolean>

    @TaskAction
    fun remap() {
        val mapping = JarMapping()
        val rev = reverse.getOrElse(false)

        val mappingPath = mappingFile.asFile.get().absolutePath
        mapping.loadMappings(mappingPath, rev, false, null, null)

        val accessMapper = accessTransformerFile.orNull?.let {
            val access = AccessMap()
            access.loadAccessTransformer(it.asFile)
            RemapperProcessor(null, mapping, access)
        }

        val jarMap = JarRemapper(null, mapping, accessMapper)
        Jar.init(inJarFile.asFile.get()).use { jar ->
            mapping.setFallbackInheritanceProvider(JarProvider(jar))
            jarMap.remapJar(jar, outJarFile.get().asFile)
        }
    }
}
