#!/usr/bin/env bash

source logr.sh

declare -r URL='https://github.com/bkahlert/logr/'
declare -r LABEL=${URL#*://}

headr "Usage"

logr info "Check out %s for instructive terminal session recording.\n" "$(logr -i link "$URL" "$LABEL")"
logr info "\
If you checked out the repository you can also find the
mentioned recordings in the %s directory." "$(logr -i file "docs")"
echo
prompt4 Y/n "Do you want to open $LABEL?"
open "$URL"
