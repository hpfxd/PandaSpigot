rootProject.name = "pandaspigot"

includeBuild("build-logic")

this.setupSubproject("pandaspigot-server", "PandaSpigot-Server")
this.setupSubproject("pandaspigot-api", "PandaSpigot-API")
this.setupSubproject("paperclip", "paperclip")

fun setupSubproject(name: String, dir: String) {
    include(":$name")
    project(":$name").projectDir = file(dir)
}
