#!/bin/bash

# Cycles a workspace through 4 layouts: 1 -> 2 -> 3 -> 4 -> 1
#   1: one tile, full screen (accordion, one window visible at a time)
#   2: left | right
#   3: left top, left bottom | right
#   4: 2x2 grid
# Windows fill the tiles in tree order. Extra windows stack (accordion) in the
# last tile. With fewer windows than tiles, the layout uses as many as exist.
#
# Usage: layout-cycle.sh [mode]
#   Works on the focused workspace; mode defaults to the next in the cycle.

export PATH="/opt/homebrew/bin:$PATH"

ws=$(aerospace list-workspaces --focused)
state_dir=~/.local/state/aerospace-layout
mkdir -p "$state_dir"

if [ -n "$1" ]; then
  mode=$1
else
  prev=$(cat "$state_dir/$ws" 2>/dev/null || echo 0)
  mode=$((prev % 4 + 1))
fi
echo "$mode" > "$state_dir/$ws"

orig=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)

# Flatten first so the tree order below is plain left-to-right.
aerospace flatten-workspace-tree --workspace "$ws"

# list-windows is not in tree order, so walk the tree by dfs index instead.
count=$(aerospace list-windows --workspace "$ws" --format '%{window-layout}' | grep -vc '^floating$')
ids=()
i=0
while [ "$i" -lt "$count" ]; do
  aerospace focus --dfs-index "$i" >/dev/null 2>&1 || break
  ids+=("$(aerospace list-windows --focused --format '%{window-id}')")
  i=$((i + 1))
done
n=${#ids[@]}
[ "$n" -eq 0 ] && exit 0

# Put the given windows (2 or more, adjacent in the root) into one accordion.
# The order of the last windows can swap, which is fine.
group() {
  local first=$1 second=$2
  shift 2
  aerospace join-with --window-id "$first" right
  for id in "$@"; do
    aerospace move --window-id "$id" left
  done
  aerospace layout --window-id "$first" accordion
}

tiles=$mode
[ "$mode" -eq 1 ] && tiles=1
[ "$n" -lt "$tiles" ] && tiles=$n

# aerospace prints a notice when the root is already in the requested layout.
if [ "$tiles" -eq 1 ]; then
  aerospace layout --workspace "$ws" --root h_accordion >/dev/null 2>&1
else
  aerospace layout --workspace "$ws" --root h_tiles >/dev/null 2>&1
  # Build from the right so earlier windows keep their positions.
  case "$tiles" in
    2)
      [ "$n" -gt 2 ] && group "${ids[@]:1}"
      ;;
    3)
      [ "$n" -gt 3 ] && group "${ids[@]:2}"
      aerospace join-with --window-id "${ids[0]}" right
      ;;
    4)
      [ "$n" -gt 4 ] && group "${ids[@]:3}"
      aerospace join-with --window-id "${ids[2]}" right
      aerospace join-with --window-id "${ids[0]}" right
      ;;
  esac
  aerospace balance-sizes --workspace "$ws"
fi

[ -n "$orig" ] && aerospace focus --window-id "$orig"
