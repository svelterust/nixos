#!/usr/bin/env bash

# Find git repositories in /home/odd and let user select with walker
selected=$(for dir in /home/odd/*/ /etc/nixos/; do
    [ -d "$dir/.git" ] && echo "$dir"
done | walker -d)

# Open selected directory in zed if something was selected
[ -n "$selected" ] && zeditor -n "$selected"
