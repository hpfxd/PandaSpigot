/*
 * Paperclip - Paper Minecraft launcher
 *
 * Copyright (c) 2019 Kyle Wood (DemonWav)
 * https://github.com/PaperMC/Paperclip
 *
 * MIT License
 */

package com.hpfxd.pandaspigot.paperclip;

import java.lang.instrument.Instrumentation;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Path;

public final class Agent {
    public static void premain(final String agentArgs, final Instrumentation inst) {
        // noop - if this is called on Java 8 we just ignore it
    }

    static void addToClassPath(final Path paperJar) {
        final ClassLoader loader = ClassLoader.getSystemClassLoader();
        if (!(loader instanceof URLClassLoader)) {
            throw new RuntimeException("System ClassLoader is not URLClassLoader");
        }
        try {
            final Method addURL = getAddMethod(loader);
            if (addURL == null) {
                System.err.println("Unable to find method to add Paper jar to System ClassLoader");
                System.exit(1);
            }
            addURL.setAccessible(true);
            addURL.invoke(loader, paperJar.toUri().toURL());
        } catch (final IllegalAccessException | InvocationTargetException | MalformedURLException e) {
            System.err.println("Unable to add Paper Jar to System ClassLoader");
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static Method getAddMethod(final Object o) {
        Class<?> clazz = o.getClass();
        Method m = null;
        while (m == null) {
            try {
                m = clazz.getDeclaredMethod("addURL", URL.class);
            } catch (final NoSuchMethodException ignored) {
                clazz = clazz.getSuperclass();
                if (clazz == null) {
                    return null;
                }
            }
        }
        return m;
    }
}
