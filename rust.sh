#!/usr/bin/env bash
# this should be executable with zsh or anything but sh
#
# I had RUST_IPFS_EXEC env variable point to this script
# and a symlink in the same directory to point to the `http` binary.
#
# This will leak http processes at least in some failure cases.

# fails the script when some command fails without any surrounding ifs or binary operations.
set -e

# pipefail allows portable-ish capturing of failing ./http "$@" (or failing
# tee) return code alternatives include PIPESTATUS[0] (only bash),
# pipestatus[0] (zsh). if failing `tee` needs to be processed otherwise, this
# can probably be done by redirecting all std{out,err} to file, then worrying
# about only the ./http "$@" return code with `||`.
set -o pipefail

trap 'on_killed $? $LINENO' EXIT
killed=false
retval=0

on_killed () {
	# this does not seem to useful in any seen case.
	if $killed; then
		# this never happens when the "leak" case happens
		echo "<<<< killed (retval: $1, lineno: $2) $$" | tee -a /tmp/rust.log >&2
	fi
	exit $retval
}

echo ">>>> new execution $$ with args: $@" | tee -a /tmp/rust.log >&2
killed=true
./http "$@" 2>&1 | tee -a /tmp/rust.log || retval=$?
killed=false
echo "<<<< exiting $$ with $retval" | tee -a /tmp/rust.log >&2
exit $retval
