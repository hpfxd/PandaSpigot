plugins {
    `kotlin-dsl`
}

repositories {
    mavenCentral()
    gradlePluginPortal()
}

dependencies {
    implementation("io.sigpipe:jbsdiff:1.0")
    implementation("net.md-5:SpecialSource:1.11.3")
}
