#!/bin/bash

# Shows the current AeroSpace binding mode in the bar.
# Called from aerospace.toml next to every 'mode ...' command.
#   mode.sh M   main
#   mode.sh S   service
#   mode.sh W   ws (go to workspace)
#   mode.sh V   move (send window to workspace)

case "$1" in
  S) sketchybar --set mode label="S" label.color=0xffffb454 ;;
  W) sketchybar --set mode label="W" label.color=0xff6fd3ff ;;
  V) sketchybar --set mode label="V" label.color=0xffff7ab8 ;;
  *) sketchybar --set mode label="M" label.color=0x80ffffff ;;
esac
