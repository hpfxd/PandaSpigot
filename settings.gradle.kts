rootProject.name = "pandaspigot"

this.setupSubproject("pandaspigot-server", "PandaSpigot-Server")
this.setupSubproject("pandaspigot-api", "PandaSpigot-API")

fun setupSubproject(name: String, dir: String) {
    include(":$name")
    project(":$name").projectDir = file(dir)
}
