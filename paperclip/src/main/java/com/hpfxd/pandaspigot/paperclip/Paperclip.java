/*
 * Paperclip - Paper Minecraft launcher
 *
 * Copyright (c) 2019 Kyle Wood (DemonWav)
 * https://github.com/PaperMC/Paperclip
 *
 * MIT License
 */

package com.hpfxd.pandaspigot.paperclip;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Reader;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.ReadableByteChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Locale;
import java.util.jar.JarInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import org.apache.commons.compress.compressors.CompressorException;
import io.sigpipe.jbsdiff.InvalidHeaderException;
import io.sigpipe.jbsdiff.Patch;

import static java.nio.file.StandardOpenOption.CREATE;
import static java.nio.file.StandardOpenOption.TRUNCATE_EXISTING;
import static java.nio.file.StandardOpenOption.WRITE;

public final class Paperclip {

    public static void main(final String[] args) {
        final Method mainMethod;
        {
            final Path paperJar = setupEnv();
            final String main = getMainClass(paperJar);
            mainMethod = getMainMethod(paperJar, main);
        }

        // By making sure there are no other variables in scope when we run mainMethod.invoke we allow the JVM to
        // GC any objects allocated during the downloading + patching process, minimizing paperclip's overhead as
        // much as possible
        try {
            mainMethod.invoke(null, new Object[] {args});
        } catch (final IllegalAccessException | InvocationTargetException e) {
            System.err.println("Error while running patched jar");
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static Path setupEnv() {
        final MessageDigest digest;
        try {
            digest = MessageDigest.getInstance("SHA-256");
        } catch (final NoSuchAlgorithmException e) {
            System.err.println("Could not create hashing instance");
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }

        final PatchData patchData;
        try (
            final InputStream defaultsInput = Paperclip.class.getResourceAsStream("/patch.properties");
            final Reader defaultsReader = new BufferedReader(new InputStreamReader(defaultsInput));
            final Reader optionalReader = getConfig()
        ) {
            patchData = PatchData.parse(defaultsReader, optionalReader);
        } catch (final IOException | IllegalArgumentException e) {
            if (e instanceof IOException) {
                System.err.println("Error reading patch file");
            } else {
                System.err.println("Invalid patch file");
            }
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }

        final Path paperJar = checkPaperJar(digest, patchData);

        // Exit if user has set `paperclip.patchonly` system property to `true`
        if (Boolean.getBoolean("paperclip.patchonly")) {
            System.exit(0);
        }

        // Install it to the local maven repository if `paperclip.install` is `true`
        if (Boolean.getBoolean("paperclip.install")) {
            mavenInstall(paperJar);
            System.exit(0);
        }

        return paperJar;
    }

    private static Path checkPaperJar(
        final MessageDigest digest,
        final PatchData patchData
    ) {
        final Path cache = Paths.get("cache");
        final Path paperJar = cache.resolve("patched_" + patchData.version + ".jar");

        if (!isJarInvalid(digest, paperJar, patchData.patchedHash)) {
            return paperJar;
        }

        final Path vanillaJar = checkVanillaJar(digest, patchData, cache);

        if (Files.exists(paperJar)) {
            try {
                Files.delete(paperJar);
            } catch (final IOException e) {
                System.err.println("Failed to delete invalid jar " + paperJar.toAbsolutePath());
                e.printStackTrace();
                System.exit(1);
            }
        }

        System.out.println("Patching vanilla jar...");
        final byte[] vanillaJarBytes;
        final byte[] patch;
        try {
            vanillaJarBytes = readBytes(vanillaJar);
            patch = readFully(patchData.patchFile.openStream());
        } catch (final IOException e) {
            System.err.println("Failed to read vanilla jar and patch file");
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }

        // Patch the jar to create the final jar to run
        try (
            final OutputStream jarOutput =
                new BufferedOutputStream(Files.newOutputStream(paperJar, CREATE, WRITE, TRUNCATE_EXISTING))
        ) {
            Patch.patch(vanillaJarBytes, patch, jarOutput);
        } catch (final CompressorException | InvalidHeaderException | IOException e) {
            System.err.println("Failed to patch vanilla jar");
            e.printStackTrace();
            System.exit(1);
        }

        // Only continue from here if the patched jar is correct
        if (isJarInvalid(digest, paperJar, patchData.patchedHash)) {
            System.err.println("Failed to patch vanilla jar, output patched jar is still not valid");
            System.exit(1);
        }

        return paperJar;
    }

    private static Path checkVanillaJar(
        final MessageDigest digest,
        final PatchData patchData,
        final Path cache
    ) {
        final Path vanillaJar = cache.resolve("mojang_" + patchData.version + ".jar");
        if (!isJarInvalid(digest, vanillaJar, patchData.originalHash)) {
            return vanillaJar;
        }

        System.out.println("Downloading vanilla jar...");
        try {
            if (!Files.isDirectory(cache)) {
                Files.createDirectories(cache);
            }
            Files.deleteIfExists(vanillaJar);
        } catch (final IOException e) {
            System.err.println("Failed to setup cache directory");
            e.printStackTrace();
            System.exit(1);
        }

        try (
            final ReadableByteChannel source = Channels.newChannel(patchData.originalUrl.openStream());
            final FileChannel fileChannel = FileChannel.open(vanillaJar, CREATE, WRITE, TRUNCATE_EXISTING)
        ) {
            fileChannel.transferFrom(source, 0, Long.MAX_VALUE);
        } catch (final IOException e) {
            System.err.println("Failed to download vanilla jar");
            e.printStackTrace();
            System.exit(1);
        }

        // Only continue from here if the downloaded jar is correct
        if (isJarInvalid(digest, vanillaJar, patchData.originalHash)) {
            System.err.println("Downloaded vanilla jar is not valid");
            System.exit(1);
        }

        return vanillaJar;
    }

    private static String getMainClass(final Path paperJar) {
        try (
            final InputStream is = new BufferedInputStream(Files.newInputStream(paperJar));
            final JarInputStream js = new JarInputStream(is)
        ) {
            return js.getManifest().getMainAttributes().getValue("Main-Class");
        } catch (final IOException e) {
            System.err.println("Error reading from patched jar");
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }
    }

    private static Method getMainMethod(final Path paperJar, final String mainClass) {
        Agent.addToClassPath(paperJar);
        try {
            final Class<?> cls = Class.forName(mainClass, true, ClassLoader.getSystemClassLoader());
            return cls.getMethod("main", String[].class);
        } catch (final NoSuchMethodException | ClassNotFoundException e) {
            System.err.println("Failed to find main method in patched jar");
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }
    }

    private static Path extractPom(Path paperJar) throws IOException {
        try (final ZipFile zipFile = new ZipFile(paperJar.toFile())) {
            Path pomPath = Paths.get("paper.xml");

            ZipEntry pomEntry = zipFile.getEntry("META-INF/maven/io.papermc.paper/paper/pom.xml");

            if (pomEntry == null) {
                pomEntry = zipFile.getEntry("META-INF/maven/com.destroystokyo.paper/paper/pom.xml");
            }
            if (pomEntry == null) {
                System.err.println("No Paper pom file could be found.");
                return null;
            }
            try (InputStream pom = zipFile.getInputStream(pomEntry)) {
                Files.copy(pom, pomPath, StandardCopyOption.REPLACE_EXISTING);
                pomPath.toFile().deleteOnExit();
            }

            return pomPath;
        }
    }

    private static void mavenInstall(Path paperJar) {
        // On Windows we need to use "mvn.cmd" instead of "mvn"
        final String mavenCommand = System.getProperty("os.name").toLowerCase(Locale.ENGLISH).contains("windows") ? "mvn.cmd" : "mvn";
        try {
            if (new ProcessBuilder(mavenCommand, "-version").start().waitFor() != 0) {
                // Error! It's either not on the path, or something went terribly wrong.
                System.err.println("Maven must be installed and on your PATH.");
                System.exit(1);
            }
        } catch (IOException | InterruptedException ex) {
            System.err.println("Maven must be installed and on your PATH.");
            ex.printStackTrace();
            System.exit(1);
        }

        try {
            Path pomPath = extractPom(paperJar);
            if (pomPath == null) {
                System.err.println("No Paper pom file could be found.");
                System.exit(1);
            }

            if (new ProcessBuilder(mavenCommand, "install:install-file", "-Dfile=" + paperJar, "-DpomFile=" + pomPath).start().waitFor() != 0) {
                // Error! Could not install the file.
                System.err.println("Could not install the Paper file.");
                return;
            }
        } catch (IOException | InterruptedException ex) {
            System.err.println("Could not install the Paper file.");
            ex.printStackTrace();
            return;
        }

        System.out.println("Installed jar into local maven repository.");
    }

    private static Reader getConfig() throws IOException {
        final Path customPatchInfo = Paths.get("paperclip.properties");
        if (Files.exists(customPatchInfo)) {
            return Files.newBufferedReader(customPatchInfo);
        } else {
            return null;
        }
    }

    private static byte[] readFully(final InputStream in) throws IOException {
        try {
            // In a test this was 12 ms quicker than a ByteBuffer
            // and for some reason that matters here.
            byte[] buffer = new byte[16 * 1024];
            int off = 0;
            int read;
            while ((read = in.read(buffer, off, buffer.length - off)) != -1) {
                off += read;
                if (off == buffer.length) {
                    buffer = Arrays.copyOf(buffer, buffer.length * 2);
                }
            }
            return Arrays.copyOfRange(buffer, 0, off);
        } finally {
            in.close();
        }
    }

    private static byte[] readBytes(final Path file) {
        try {
            return readFully(Files.newInputStream(file));
        } catch (final IOException e) {
            System.err.println("Failed to read all of the data from " + file.toAbsolutePath());
            e.printStackTrace();
            System.exit(1);
            throw new InternalError();
        }
    }

    private static boolean isJarInvalid(final MessageDigest digest, final Path jar, final byte[] hash) {
        if (Files.exists(jar)) {
            final byte[] jarBytes = readBytes(jar);
            return !Arrays.equals(hash, digest.digest(jarBytes));
        }
        return true;
    }
}
