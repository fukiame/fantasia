#!/usr/bin/env bash

(
PS1="$"
basedir="$(pwd -P)"
echo "Rebuilding patch files from current fork state..."
git config core.safecrlf false

function cleanupPatches {
    cd "$1" || exit 1
    for patch in *.patch; do
        echo "$patch"
        gitver=$(tail -n 2 "$patch" | grep -ve "^$" | tail -n 1)
        diffs=$(git diff --staged "$patch" | grep -E "^(\+|-)" | grep -Ev "(From [a-z0-9]{32,}|--- a|\+\+\+ b|.index)")

        testver=$(echo "$diffs" | tail -n 2 | grep -ve "^$" | tail -n 1 | grep "$gitver")
        if [ "$testver" != "" ]; then
            diffs=$(echo "$diffs" | sed 'N;$!P;$!D;$d')
        fi

        if [ "$diffs" == "" ] ; then
            git reset HEAD "$patch" >/dev/null
            git checkout -- "$patch" >/dev/null
        fi
    done
}

function savePatches {
    what=$1
    target=$2
    echo "Formatting patches for $what..."

    cd "$basedir/patches/" || exit 1
    if [ -d "$basedir/$target/.git/rebase-apply" ]; then
        # in middle of a rebase, be smarter
        echo "REBASE DETECTED - PARTIAL SAVE"
        last=$(cat "$basedir/$target/.git/rebase-apply/last")
        next=$(cat "$basedir/$target/.git/rebase-apply/next")
        for i in $(seq -f "%04g" 1 1 "$last")
        do
            if [ "$i" -lt "$next" ]; then
                rm "${i}"-*.patch
            fi
        done
    else
        rm -rf ./*.patch
    fi

    cd "$basedir/$target" || exit 1

    git format-patch --zero-commit --no-stat -N -o "$basedir/patches/" upstream/upstream >/dev/null
    cd "$basedir" || exit 1
    git add -A "$basedir/patches"
    cleanupPatches "$basedir/patches"
    echo "  Patches saved for $what to patches/"
}

savePatches "$1" "$2"
)
