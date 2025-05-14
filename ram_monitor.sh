#!/bin/bash
# Default threshold (in percent)
THRESHOLD=60
MONITORING_PID=0
# Function to monitor RAM usage and alert if threshold is exceeded
start_monitoring() {
  zenity --info --title="RAM Monitor Started" --text="Monitoring started. You'll get alerts if RAM exceeds $THRESHOLD%." &
  (
    while true; do
      usage_percent=$(free | awk '/Mem:/ { printf("%.0f", $3/$2 * 100) }')
      if [ "$usage_percent" -ge "$THRESHOLD" ]; then
        notify-send "⚠️ High RAM Usage" "RAM usage is at ${usage_percent}%"
      fi
      sleep 5
    done
  ) &
  MONITORING_PID=$!
}
# Function to stop monitoring
stop_monitoring() {
  if [ "$MONITORING_PID" -ne 0 ]; then
    kill "$MONITORING_PID" 2>/dev/null
    MONITORING_PID=0
    zenity --info --title="RAM Monitor Stopped" --text="RAM monitoring has been stopped."
  else
    zenity --info --title="Not Running" --text="RAM monitoring is not currently running."
  fi
}
# Function to view RAM usage in a live-updating popup with close button
view_ram_usage() {
  (
    while true; do
      total=$(free | awk '/Mem:/ {printf("%.2f", $2/1024/1024)}')
      used=$(free | awk '/Mem:/ {printf("%.2f", $3/1024/1024)}')
      percent=$(free | awk '/Mem:/ {printf("%.0f", $3/$2*100)}')
      echo "# 🧠 RAM Usage: $used GB / $total GB ($percent%)"
      echo "$percent"
      sleep 1
    done
  ) |
  zenity --progress \
    --title="Live RAM Usage" \
    --text="Initializing RAM stats..." \
    --percentage=0 \
    --auto-close \
    --cancel-label="Close"
}
# Function to prompt user for threshold
set_threshold() {
  input=$(zenity --entry --title="Set RAM Alert Threshold" --text="Enter RAM usage threshold in % (default: 60):" --entry-text="$THRESHOLD")
  if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le 100 ]; then
    THRESHOLD=$input
    zenity --info --title="Threshold Set" --text="Alert threshold set to $THRESHOLD%."
  else
    zenity --error --title="Invalid Input" --text="Please enter a valid number between 1 and 100."
  fi
}
# Main menu loop
while true; do
  choice=$(zenity --list --title="RAM Monitor" \
    --column="Action" \
    "Start Monitoring" \
    "Stop Monitoring" \
    "View RAM Usage" \
    "Set Alert Threshold" \
    "Exit")
  case "$choice" in
    "Start Monitoring")
      start_monitoring
      ;;
    "Stop Monitoring")
      stop_monitoring
      ;;
    "View RAM Usage")
      view_ram_usage
      ;;
    "Set Alert Threshold")
      set_threshold
      ;;
    "Exit")
      stop_monitoring
      exit 0
      ;;
    *)
      break
      ;;
  esac
done
