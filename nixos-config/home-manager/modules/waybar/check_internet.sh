#!/usr/bin/env bash

OFFLINE_COUNTER_FILE=/tmp/waybar_internet_offline_counter
LAST_STATE_FILE=/tmp/waybar_internet_last_state

# Initialize files if they don't exist
[ -f $OFFLINE_COUNTER_FILE ] || echo 0 > $OFFLINE_COUNTER_FILE
[ -f $LAST_STATE_FILE ] || echo "online" > $LAST_STATE_FILE

LAST_STATE=$(cat $LAST_STATE_FILE)

if timeout 2s ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
  # Online
  echo 0 > $OFFLINE_COUNTER_FILE
  if [ "$LAST_STATE" = "offline" ]; then
    # We just came back online
    notify-send "Internet Connection Restored"
    echo "online" > $LAST_STATE_FILE
  fi
  echo '{"text":"","class":"online"}'
else
  # Offline
  COUNTER=$(cat $OFFLINE_COUNTER_FILE)
  COUNTER=$((COUNTER + 1))
  echo $COUNTER > $OFFLINE_COUNTER_FILE

  # The interval is 5 seconds. 3 * 5 = 15 seconds.
  # We notify on the 3rd consecutive failure.
  if [ $COUNTER -eq 3 ]; then
    notify-send -u critical "Internet Connection Lost" "Connection has been down for 15 seconds."
    echo "offline" > $LAST_STATE_FILE
  fi
  echo '{"text":"󰖪","class":"offline"}'
fi
