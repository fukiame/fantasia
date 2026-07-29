#!/usr/bin/env bash

PS1="$"
basedir="$(pwd)"

function update {
    cd "$basedir/$1" || exit 1
    git fetch && git reset --hard "origin/$2"
    cd "$basedir/$1/.." || exit 1
    git add "$1"
}

update "$1" "$2"

# Update submodules
git submodule update --recursive
