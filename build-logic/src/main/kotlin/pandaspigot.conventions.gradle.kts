plugins {
    java
    `java-library`
}

repositories {
    mavenCentral()

    maven(url = "https://oss.sonatype.org/content/groups/public")
    maven(url = "https://hub.spigotmc.org/nexus/content/groups/public")
}

group = "com.hpfxd.pandaspigot"
version = "1.8.8-R0.1-SNAPSHOT"

tasks {
    withType<JavaCompile>().configureEach {
        options.encoding = "UTF-8"
        options.release = 8
    }

    java {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}
