#!/usr/bin/env bash

LOCK_SCREEN_AFTER=600 # seconds
SUSPEND_COMPUTER_AFTER=900 # seconds

swayidle -w timeout $LOCK_SCREEN_AFTER 'swaylock -f' \
            timeout $SUSPEND_COMPUTER_AFTER 'systemctl suspend' \
            before-sleep 'swaylock -f' &
