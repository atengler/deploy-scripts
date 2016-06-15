#!/bin/bash -e

USAGE="Usage: $0 --path|-P path/to/formula-dir [--build|-B]\n\nExamples:\n $0 --path ./salt-formula-mysql/ --build\n Generate FORMULA file and build SPM package\n $0 --path ./salt-formula-mysql/\n Generate FORMULA file"

if [ "$#" -lt 1 ]; then
  echo -e "$USAGE"
  exit 1
fi

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -P|--path)
        FORMULA_DIR="$2"
        shift
        ;;
        -B|--build)
        BUILD=true
        ;;
        -H|--help)
        echo -e "$USAGE"
        exit 0
        ;;
    esac
    shift
done

if [ -z $FORMULA_DIR ]; then
   echo -e "$USAGE"
   exit 1
fi

if [ ! -d $FORMULA_DIR ]; then
  echo "Directory $FORMULA_DIR does not exist"
  exit 1
fi

NAME="$(grep name: $FORMULA_DIR/metadata.yml | head -1 | cut -d : -f 2 | grep -Eo '[a-z0-9\-]*')"

declare -a SUPPORTED_OS=("Arch" "Debian" "Gentoo" "MacOS" "RedHat")

for S_OS in "${SUPPORTED_OS[@]}"; do
    if [[ $(grep $S_OS $FORMULA_DIR/$NAME/map.jinja) ]]; then
        if [ -z "$OS" ]; then
            OS="$S_OS"
        else
            OS="$OS, $S_OS"
        fi
    fi
done

VERSION=$(date +%Y%m)

if [ -f $FORMULA_DIR/FORMULA ]; then
    CURRENT_VERSION=$(grep version: $FORMULA_DIR/FORMULA | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')
    if [ "$CURRENT_VERSION" == "$VERSION" ]; then
        RELEASE=$(grep release: $FORMULA_DIR/FORMULA | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')
        ((RELEASE++))
    else
        RELEASE=1
    fi
else
    RELEASE=1
fi

if [ -f $FORMULA_DIR/debian/control ]; then
    SUMMARY=$(grep Description: $FORMULA_DIR/debian/control | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')
    DESCRIPTION=$(grep -A 1 Description: $FORMULA_DIR/debian/control | tail -1 | sed -e 's/^[[:space:]]*//')
else
    SUMMARY="Formula for installing and configuring $NAME"
    DESCRIPTION=$SUMMARY
fi

cat << EOF > $FORMULA_DIR/FORMULA
name: $NAME
os: $OS
os_family: $OS
version: $VERSION
release: $RELEASE
summary: $SUMMARY
description: $DESCRIPTION
top_level_dir: $NAME
EOF

echo "FORMULA file generated at $(echo $FORMULA_DIR/FORMULA | sed -e 's@//@/@')"

if [[ $BUILD ]]; then
    if [[ $(which spm) ]]; then
        echo "Running SPM package build ..."
        spm build $FORMULA_DIR
    else
        echo "SPM command not available, aborting package build ..."      
    fi
fi

