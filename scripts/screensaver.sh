#!/usr/bin/env bash

LOCK_SCREEN_AFTER=180 # seconds
SUSPEND_COMPUTER_AFTER=300 # seconds

swayidle -w timeout $LOCK_SCREEN_AFTER 'swaylock -f' \
            timeout $SUSPEND_COMPUTER_AFTER 'systemctl suspend' \
            before-sleep 'swaylock -f' &
