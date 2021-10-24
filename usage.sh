#!/usr/bin/env bash

source logr.sh

logr new "text"
logr added "text"
logr item "text"
logr list "text-1" "text-2" "text-3"
logr link "https://github.com/bkahlert/logr"
logr link "https://example.com" "link-text"
logr file --line 300 --column 10 "logr.sh"
logr file --line 300 --column 10 "logr.sh" "link-text"
logr success "text"
logr info "text"
logr warn "text"
logr error "text"
logr fail "text"
logr task "text"
logr running "text"
logr task "text" -- sleep 2

headr "Usage"

logr info "Check out %s for instructive terminal session recording.\n" "$(logr -i link https://github.com/bkahlert/logr/ "github.com/bkahlert/logr")"
logr info "\
If you checked out the repository you can also find the
mentioned recordings in the %s directory." "$(logr -i file "docs")"
