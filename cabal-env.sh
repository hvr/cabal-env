#!/bin/bash

set -e

show_usage () {
    cat <<EOF
Usage: $0 [-n <env-name>] (-r | -l | [DEP]+)"

Creates GHC package environment named '<env-name>' (default = 'default')
containing the specified deps.

  -r deletes the specified environment

  -l lists available environments for current 'ghc'

Examples:

  $0 -n lens 'lens == 4.15.*' 'lens-aeson == 1.0.*' http-streams

  $0 unordered-containers QuickCheck quickcheck-instances

EOF
    exit 1
}

get_ghc_triplet () {
    GHC_TARGET=$(ghc --print-target-platform)
    GHC_VER=$(ghc --numeric-version)
    trip_pat="([^-]*)-([^-]*)-(.*)"

    [[ $GHC_TARGET =~ $trip_pat ]]

    TRIPLET="${BASH_REMATCH[1]}-${BASH_REMATCH[3]}-${GHC_VER}"

    ENVSDIR="${HOME}/.ghc/${TRIPLET}/environments/"
}

remove=false
list=false

envname="default"

while getopts lrn: flag; do
    case $flag in
        n) envname="$OPTARG"
           ;;

        r) remove=true
           ;;

        l) list=true
           ;;

        ?) show_usage
           ;;
    esac
done

shift $((OPTIND - 1))

if $list; then
    if [ $# -ge 1 ]; then
        show_usage
    fi

    get_ghc_triplet

    if [ -d "$ENVSDIR" ]; then
        echo "Environments available in $ENVSDIR:"
        echo
        cd "$ENVSDIR"
        find . -type f | sed 's,^[.][/],- ,'
    else
        echo "Environment folder $ENVSDIR does not exist"
    fi

    exit 0
fi

if $remove; then
    if [ $# -ge 1 ]; then
        show_usage
    fi

    get_ghc_triplet

    envfn="${ENVSDIR}${envname}"

    if [ -f "$envfn" ]; then
        echo "removing '$envfn'"
        rm "$envfn"
    else
        echo "Environemnt file '$envfn' doesn't exist; nothing to do"
    fi

    exit 0
fi

if [ $# -lt 1 ]; then
    show_usage
fi

echo "Using environment-name = '$envname'"

TMPDIR=$(mktemp -d)

pushd "$TMPDIR"

{
  cat <<EOF
name: z
version: 0
cabal-version:>=1.8
build-type: Simple

library
  build-depends: base
EOF

  for DEP in "$@";
  do
      echo "  build-depends: $DEP"
  done
} > z.cabal

cat > cabal.project <<EOF
packages: .
EOF

cabal new-build all

for ENVFN in .ghc.environment.*-*-*; do true; done

if [ -z "$ENVFN" ]; then
    echo "ERROR: no GHC environment file found. You need at least cabal 2.1 (or later) and GHC 8.0.2 (or later)."
    exit 1
fi

echo "Found '$ENVFN'"

TRIPLET=${ENVFN#.ghc.environment.}

echo "$TRIPLET"

ENVSDIR="${HOME}/.ghc/${TRIPLET}/environments/"

mkdir -v -p "${ENVSDIR}"

ENVSDIRFN="${ENVSDIR}${envname}"

cat "$ENVFN" | grep -v '^package-db dist-newstyle/' | grep -v '^package-id z-0-inplace' > "$ENVSDIRFN"

popd

rm -rf "$TMPDIR"

echo "Succesfully created '$ENVSDIRFN' pkg environment;"
echo "use 'ghci -package-env $envname' or 'GHC_ENVIRONMENT=$envname ghci' to select."
echo "(The 'default' package env is used by default. Try ':show packages' inside GHCi.)"
