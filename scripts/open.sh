#!/usr/bin/env bash

# Find git repositories in /home/odd and let user select with walker
selected=$(for dir in /home/odd/*/; do
    [ -d "$dir/.git" ] && echo "$dir"
done | walker -d)

# Open selected directory in zed if something was selected
if [ -n "$selected" ]; then
    zed "$selected"
fi
