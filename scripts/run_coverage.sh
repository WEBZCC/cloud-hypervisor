#!/usr/bin/env bash

set -x

# shellcheck source=/dev/null
source "$HOME"/.cargo/env

PROJECT_DIR="/cloud-hypervisor"
TARGET_DIR="$PROJECT_DIR/target"

pushd $PROJECT_DIR || exit

export BUILD_TARGET=${BUILD_TARGET-$(uname -m)-unknown-linux-gnu}

# GLIBC > 2.31
GRCOV_RELEASE_URL="https://github.com/mozilla/grcov/releases/download/v0.8.19/grcov-$BUILD_TARGET.tar.bz2"
wget --quiet "$GRCOV_RELEASE_URL" || exit 1
tar -xjf "grcov-$BUILD_TARGET.tar.bz2"

rustup component add llvm-tools-preview

export_lcov() {
    rm "coverage.info"

    ./grcov "$(find . -name 'ch-*.profraw' -print)" -s . \
        --ignore "tests/*" \
        --ignore "test_infra/*" \
        --ignore "performance-metrics/*" \
        --binary-path "$TARGET_DIR/$BUILD_TARGET/release/" \
        --branch --ignore-not-existing -t lcov \
        -o "coverage.info"

    find . -type f -name 'ch-*.profraw' -exec rm {} \;
}

# Generate HTML report
export_html() {
    OUTPUT_DIR="$TARGET_DIR/coverage"
    rm -rf $OUTPUT_DIR
    ./grcov "$(find . -name 'ch-*.profraw' -print)" -s . \
        --ignore "tests/*" \
        --ignore "test_infra/*" \
        --ignore "performance-metrics/*" \
        --binary-path "$TARGET_DIR/$BUILD_TARGET/release/" \
        --branch --ignore-not-existing -t html \
        -o $OUTPUT_DIR
    find . -type f -name 'ch-*.profraw' -exec rm {} \;
}

# $1 is now a command name. Check if it is a valid command and, if so,
# run it.
#
declare -f "export_$1" >/dev/null
code=$?
[[ $code == 0 ]] || echo "Unknown command: $1. Only support \"lcov\" and \"html\". Change to default command: html"
type=${1-html}

func=export_$type
shift

$func "$@"

popd || exit 1