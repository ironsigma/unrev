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

SCRIPT=unrev-ls
VERSION=1.0.0


# Args
ARCHIVE_FILE=${1:-}


# No archive file
if [ -z "$ARCHIVE_FILE" ]; then
    cat <<-USAGEMSG
$SCRIPT v$VERSION - List revisions in archive

Usage:
    $SCRIPT <archive>

USAGEMSG
    exit 1
fi

# padding for printf
pad_size=

# List archive content and extract the meta data
for meta in $(7z l "$ARCHIVE_FILE" \
    | grep "\(DIFF\|HEAD\)-R[-_.0-9]\+$" \
    | sed -e "s/^.\+\(DIFF\|HEAD\)-R//" -e "s/_/T/" -e "s/\./:/g" \
    | sort -rn)
do
    # get revision number
    rev=$(echo "$meta" | sed -e "s/^\([0-9]\+\).\+$/\1/")

    # get date time
    dt=$(echo "$meta" | sed -e "s/^[0-9]\+-//")

    # reformat date time
    timestamp=$(date --date="$dt" +"%a %b %d %H:%M.%S %Y")

    # save padding size
    if [ -z "$pad_size" ]; then
        pad_size=$((${#rev} + 1))
    fi

    # display revision and date time
    printf " \e[1;33m%${pad_size}s\e[0m %s\n" "r$rev" "$timestamp"
done

