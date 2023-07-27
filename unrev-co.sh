#!/usr/bin/env bash
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
#...set -o xtrace

#
# Author: Juan D Frias <juandfrias@gmail.com>
# Created: Jul 25, 2023
# Updated: Jul 26, 2023
# Copyright: CC BY-NC-SA <https://creativecommons.org/licenses/by-nc-sa/4.0/>
#

SCRIPT=unrev-co
VERSION=1.0.0


# Check arg count
if [ $# -lt 2 ]; then
    cat <<-USAGEMSG
$SCRIPT v$VERSION - Check-out revision from archive

Usage:
    $SCRIPT [--stdout] <archive> <rev num> [.ext]

USAGEMSG
    exit 1
fi

# look for stdout flag
STDOUT=false
if [ "$1" = "--stdout" ]; then
    STDOUT=true
    shift
fi

# check archive file exists
ARCHIVE_FILE="$1"
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "Archive file \"$ARCHIVE_FILE\" does not exist"
    exit 1
fi

# check revision number is valid
REV_ARG="$2"
REVISION_NUM=$(echo "$2" | sed -e "s/[^0-9]//g")
if [[ "$REVISION_NUM" = "" || $REVISION_NUM -le 0 ]]; then
    echo "Invalid revision number \"$REV_ARG\""
    exit 1
fi

# extension suffix to use
EXT_SUFFIX="${3:-}"

# Get the head revision number
head_rev=$(7z l -i"!HEAD-R*" "$ARCHIVE_FILE" \
    | grep "HEAD-R[-_.0-9]\+$" \
    | sed -e "s/^.\+HEAD-R\([0-9]\+\)-.\+$/\1/")

# check if revision number is out of bounds
if [ $REVISION_NUM -gt $head_rev ]; then
    echo "Revision number \"$REV_ARG\" not found in archive"
    exit 1
fi

# create temp file template
template=$(basename "$ARCHIVE_FILE")
template="unrev-${template%%.*}-R$REVISION_NUM-XXXXXXXX$EXT_SUFFIX"

# create a temp file and extract the head revision
base_file=$(mktemp -t "$template")
7z e -i"!HEAD-R$head_rev-*" -so "$ARCHIVE_FILE" >> "$base_file"

# apply each remaning revisions until we're done
rev=$((head_rev - 1))
while [ $rev -ge $REVISION_NUM ]; do
    7z e -i"!DIFF-R$rev-*" -so "$ARCHIVE_FILE" | patch -s -i- "$base_file"
    rev=$((rev - 1))
done

# display file content?
if [ "$STDOUT" = "true" ]; then
    cat "$base_file"
    rm "$base_file"

else
    # just display file name
    echo "$base_file"
fi

