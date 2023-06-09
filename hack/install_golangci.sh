#!/usr/bin/env bash

# This script is intended to be a convenience, to be called from the
# Makefile `.install.golangci-lint` target.  Any other usage is not recommended.

die() { echo "${1:-No error message given} (from $(basename $0))"; exit 1; }

[ -n "$VERSION" ] || die "\$VERSION is empty or undefined"

function install() {
    local retry=$1

    local msg="Installing golangci-lint v$VERSION into $BIN"
    if [[ $retry -ne 0 ]]; then
        msg+=" - retry #$retry"
    fi
    echo $msg

    curl -sSL --retry 5 https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s v$VERSION
}

# Undocumented behavior: golangci-lint installer requires $BINDIR in env,
# will default to ./bin but we can't rely on that.
export BINDIR="./bin"
BIN="$BINDIR/golangci-lint"
if [ ! -x "$BIN" ]; then
    # This flakes much too frequently with "crit unable to find v1.51.1"
    for retry in $(seq 0 5); do
	install $retry && exit 0
        sleep 5
    done
else
    # Prints its own file name as part of --version output
    $BIN --version | grep "$VERSION"
    if [ $? -eq 0 ]; then
        echo "Using existing $BINDIR/$($BIN --version)"
    else
        install
    fi
fi
