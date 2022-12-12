/*
 * Paperclip - Paper Minecraft launcher
 *
 * Copyright (c) 2019 Kyle Wood (DemonWav)
 * https://github.com/PaperMC/Paperclip
 *
 * MIT License
 */

package com.hpfxd.pandaspigot.paperclip;

import java.io.IOException;
import java.lang.instrument.Instrumentation;
import java.nio.file.Path;
import java.util.jar.JarFile;

public final class Agent {

    private static Instrumentation inst = null;

    public static void premain(final String agentArgs, final Instrumentation inst) {
        Agent.inst = inst;
    }

    public static void agentmain(final String agentArgs, final Instrumentation inst) {
        Agent.inst = inst;
    }

    @SuppressWarnings("unused") // This class replaces the Agent class in the java8 module when run on Java9+
    static void addToClassPath(final Path paperJar) {
        if (inst == null) {
            System.err.println("Unable to retrieve Instrumentation API to add Paper jar to classpath. If you're " +
                "running paperclip without -jar then you also need to include the -javaagent:<paperclip_jar> JVM " +
                "command line option.");
            System.exit(1);
            return;
        }
        try {
            inst.appendToSystemClassLoaderSearch(new JarFile(paperJar.toFile()));
            inst = null;
        } catch (final IOException e) {
            System.err.println("Failed to add Paper jar to ClassPath");
            e.printStackTrace();
            System.exit(1);
        }
    }
}
