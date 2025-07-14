#!/bin/bash

CACHE="/tmp/prayer_times.json"
TODAY=$(date +%d-%m-%Y)
NOW=$(date +%H:%M)

# Fetch prayer times if cache is old or missing
if [[ ! -f "$CACHE" ]] || [[ "$(jq -r '.data.date.readable' "$CACHE" 2>/dev/null)" != "$TODAY" ]]; then
    curl -s "https://api.aladhan.com/v1/timings/$TODAY?latitude=30.0444196&longitude=31.2357116&method=5" > "$CACHE"
fi

# Check if it's prayer time
for prayer in Fajr Dhuhr Asr Maghrib Isha; do
    time=$(jq -r ".data.timings.$prayer" "$CACHE" 2>/dev/null | cut -d: -f1-2)
    if [[ "$NOW" == "$time" ]]; then
        if [[ ! -f "/tmp/notified_$prayer" ]]; then
            notify-send "🕌 Prayer Time" "$prayer prayer is now! ($time)"
            touch "/tmp/notified_$prayer"
        fi
    fi
done

# Clean old notification files at midnight
[[ "$NOW" == "00:00" ]] && rm -f /tmp/notified_*
