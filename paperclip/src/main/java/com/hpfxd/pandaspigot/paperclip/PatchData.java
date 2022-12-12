/*
 * Paperclip - Paper Minecraft launcher
 *
 * Copyright (c) 2019 Kyle Wood (DemonWav)
 * https://github.com/PaperMC/Paperclip
 *
 * MIT License
 */

package com.hpfxd.pandaspigot.paperclip;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Properties;

final class PatchData {
    final URL patchFile;
    final URL originalUrl;
    final byte[] originalHash;
    final byte[] patchedHash;
    final String version;

    private PatchData(final Properties prop) {
        final String patch = prop.getProperty("patch");
        // First try and parse the patch as a uri
        URL patchFile = PatchData.class.getResource("/" + patch);
        {
            final File tempFile = new File(patch);
            if (tempFile.exists()) {
                try {
                    patchFile = tempFile.toURI().toURL();
                } catch (final MalformedURLException ignored) {}
            }
        }
        if (patchFile == null) {
            throw new IllegalArgumentException("Couldn't find " + patch);
        }
        this.patchFile = patchFile;
        try {
            this.originalUrl = new URL(prop.getProperty("sourceUrl"));
        } catch (final MalformedURLException e) {
            throw new IllegalArgumentException("Invalid URL", e);
        }
        this.originalHash = fromHex(prop.getProperty("originalHash"));
        this.patchedHash = fromHex(prop.getProperty("patchedHash"));
        this.version = prop.getProperty("version");
    }

    static PatchData parse(final Reader defaults, final Reader optional) throws IOException {
        try {
            final Properties defaultProps = new Properties();
            defaultProps.load(defaults);
            final Properties props = new Properties(defaultProps);
            if (optional != null) {
                props.load(optional);
            }
            return new PatchData(props);
        } catch (final IOException e) {
            throw e;
        } catch (final Exception e) {
            throw new IllegalArgumentException("Invalid properties file", e);
        }
    }

    private static byte[] fromHex(final String s) {
        if (s.length() % 2 != 0) {
            throw new IllegalArgumentException("Hex " + s + " must be divisible by two");
        }
        final byte[] bytes = new byte[s.length() / 2];
        for (int i = 0; i < bytes.length; i++) {
            final char left = s.charAt(i * 2);
            final char right = s.charAt(i * 2 + 1);
            final byte b = (byte) ((getValue(left) << 4) | (getValue(right) & 0xF));
            bytes[i] = b;
        }
        return bytes;
    }

    private static int getValue(final char c) {
        int i = Character.digit(c, 16);
        if (i < 0) {
            throw new IllegalArgumentException("Invalid hex char: " + c);
        }
        return i;
    }
}
