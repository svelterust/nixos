#!/usr/bin/env bash

LOCK_SCREEN_AFTER=60 # seconds
SUSPEND_COMPUTER_AFTER=180 # seconds

swayidle -w timeout $LOCK_SCREEN_AFTER 'swaylock -f -c 000000' \
            timeout $SUSPEND_COMPUTER_AFTER 'systemctl suspend' \
            before-sleep 'swaylock -f -c 000000' &
