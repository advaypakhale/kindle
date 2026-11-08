#!/bin/sh
# Copies books into /mnt/us/documents/<dir> on the Kindle over SSH.
# Usage: push-books.sh [-d dir] file...   (dir defaults to "inbox")
set -e
dir=inbox
[ "$1" = "-d" ] && { dir=$2; shift 2; }
[ $# -gt 0 ] || { echo "usage: $0 [-d dir] file..." >&2; exit 2; }
here=$(dirname "$0")
# The device has busybox tar, which reads plain ustar from stdin.
tar -cf - --transform='s|.*/||' "$@" |
	"$here/k.sh" "mkdir -p '/mnt/us/documents/$dir' && cd '/mnt/us/documents/$dir' && tar -xf - && sync"
