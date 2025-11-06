rootProject.name = "pandaspigot"

includeBuild("build-logic")

fun setupSubproject(name: String, dir: String) {
    include(":$name")
    project(":$name").projectDir = file(dir)
}

setupSubproject("pandaspigot-server", "PandaSpigot-Server")
setupSubproject("pandaspigot-api", "PandaSpigot-API")
setupSubproject("paperclip", "paperclip")
