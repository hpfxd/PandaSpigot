#!/bin/sh
set -ue

# Check if an application is on the PATH.
# If it is not, return with non-zero.
_is_dep_available() {
	command -v "$1" >/dev/null || (echo "\`$1\` ${2:-command was not found in the path and is a required dependency}"; return 1)
}

if [ -z "${1:-}" ]; then
    # No specific dependency was found; let's just check for all required ones.
    _is_dep_available git
    _is_dep_available patch
    _is_dep_available curl

    _is_dep_available javac "was not found; you can download the JDK from https://adoptium.net/ or via your package manager"
    _is_dep_available jar "was not found; you can download the JDK from https://adoptium.net/ or via your package manager"
else
    # Require all dependencies provided.
    for dep in $@; do
        _is_dep_available "$dep"
    done
fi

# vim: set ff=unix autoindent ts=4 sw=4 tw=0 et :
