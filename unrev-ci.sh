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

SCRIPT=unrev-ci
VERSION=1.0.0


# Options
DIFF_CHECK=true
if [ "${1:-}" = "--skip-diff-check" ]; then
    DIFF_CHECK=false
    shift
fi

# Arguments
BASE_FILE="${1:-}"
ARCHIVE_FILE="${2:-}"


# No base file
if [ -z "$BASE_FILE" ]; then
    cat <<-USAGEMSG
$SCRIPT v$VERSION - Add a new revision to archive

Usage:
    $SCRIPT [--skip-diff-check] <file> [archive]

Options:
    --skip-diff-check   Skip "no changes" check, fastter but may result
                        in empty diffs checked into the archive.
USAGEMSG
    exit 1
fi


# Check for archive file
if [ -z "$ARCHIVE_FILE" ]; then
    ARCHIVE_FILE="$BASE_FILE,v.7z"
fi


# get current time stamp
DATE_TIME=$(date "+%Y-%m-%d_%H.%M.%S")

# 7z compression options
CMD_7Z_OPTIONS="-myx=9 -mx=9 -m0=PPMd:mem1g:o32"

# Next revison number to use
NEXT_REV=1

# if archive is present add new diff
if [ -f "$ARCHIVE_FILE" ]; then

    # check for differences before checking-in
    if [ "$DIFF_CHECK" = "true" ]; then

        # extract head to stdout and check for changes
        CHANGES=$(7z x -so -i"!HEAD-R*" "$ARCHIVE_FILE" \
            | diff -q "$BASE_FILE" -) || true

        # if no changes, we're done
        if [ "$CHANGES" = "" ]; then
            echo "No changes found, skipping check-in"
            exit 1
        fi

    fi

    # get the head meta data
    HEAD_META=$(7z l -i"!HEAD-R*" "$ARCHIVE_FILE" \
        | grep "HEAD-R[-_.0-9]\+$" | sed -e "s/^.*HEAD-R//")

    # get the head time stamp
    LAST_TS=$(echo "$HEAD_META" | sed -e "s/^[0-9]\+-//")

    # get the last revision number
    LAST_REV=$(echo "$HEAD_META" | sed -e "s/^\([0-9]\+\).\+$/\1/")

    # update the next revision number
    NEXT_REV=$(( LAST_REV + 1 ))

    # generate diff and store it in archive
    7z x -so -i"!HEAD-R*" "$ARCHIVE_FILE" \
        | diff -du "$BASE_FILE" - \
        | 7z a $CMD_7Z_OPTIONS "$ARCHIVE_FILE" -si"DIFF-R$LAST_REV-$LAST_TS" > /dev/null || true

    # delete previous head
    7z d -i"!HEAD-R*" "$ARCHIVE_FILE" > /dev/null

fi


# Store new head into archive
cat "$BASE_FILE" \
    | 7z a $CMD_7Z_OPTIONS "$ARCHIVE_FILE" -si"HEAD-R$NEXT_REV-$DATE_TIME" > /dev/null

# Display revision number
echo "revision: $NEXT_REV"

