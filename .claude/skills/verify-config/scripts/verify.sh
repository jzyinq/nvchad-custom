#!/usr/bin/env bash
# Start nvim with a real UI (inside tmux) on each FILE and print a state report.
# A UI is required: NvChad loads LSP, gitsigns, etc. on "User FilePost", which only
# fires after UIEnter, so plain --headless misses most of the config.
#
# Usage: verify.sh [-a NVIM_APPNAME] [-n NVIM_BIN] [-w WAIT_MS] FILE...
# Exit:  0 = all reports clean, 1 = a report has errors or missing highlighting
set -u
here=$(cd "$(dirname "$0")" && pwd)
appname=${NVIM_APPNAME:-nvim} bin=nvim wait=6000
while getopts "a:n:w:" o; do
  case $o in a) appname=$OPTARG ;; n) bin=$OPTARG ;; w) wait=$OPTARG ;; *) exit 2 ;; esac
done
shift $((OPTIND - 1))
[ $# -gt 0 ] || { echo "usage: $0 [-a appname] [-n nvim] [-w ms] FILE..." >&2; exit 2; }
command -v tmux >/dev/null || { echo "tmux is required" >&2; exit 2; }

out_dir=$(mktemp -d) rc=0
trap 'rm -rf "$out_dir"' EXIT
for f in "$@"; do
  file=$(realpath "$f") out="$out_dir/$(basename "$f").txt" sess="nvim-verify-$$-$RANDOM"
  tmux new-session -d -s "$sess" -x 200 -y 50 \
    "cd '$(dirname "$file")' && BOOT_OUT='$out' BOOT_WAIT=$wait NVIM_APPNAME='$appname' '$bin' -c 'luafile $here/boot_check.lua' '$file'"
  for _ in $(seq 1 $(((wait / 500) + 20))); do [ -f "$out" ] && break; sleep 0.5; done
  tmux kill-session -t "$sess" 2>/dev/null
  echo "===== $f"
  if [ -f "$out" ]; then cat "$out"; grep -q '^FAIL' "$out" && rc=1; else echo "FAIL: no report (nvim hung or crashed)"; rc=1; fi
done
exit $rc
