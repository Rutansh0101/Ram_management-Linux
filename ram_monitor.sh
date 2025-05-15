#!/bin/bash

THRESHOLD=60
MONITORING_PID=0
THRESHOLDS_FILE="thresholds.txt"
touch "$THRESHOLDS_FILE"

# 🧠 Start Monitoring
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

# ❌ Stop Monitoring
stop_monitoring() {
  if [ "$MONITORING_PID" -ne 0 ]; then
    kill "$MONITORING_PID" 2>/dev/null
    MONITORING_PID=0
    zenity --info --title="RAM Monitor Stopped" --text="RAM monitoring has been stopped."
  else
    zenity --info --title="Not Running" --text="RAM monitoring is not currently running."
  fi
}

# 📊 Live RAM Usage Viewer
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

# 🔧 Set Single Threshold
set_threshold() {
  input=$(zenity --entry --title="Set RAM Alert Threshold" --text="Enter RAM usage threshold in % (default: 60):" --entry-text="$THRESHOLD")
  if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le 100 ]; then
    THRESHOLD=$input
    zenity --info --title="Threshold Set" --text="Alert threshold set to $THRESHOLD%."
  else
    zenity --error --title="Invalid Input" --text="Please enter a valid number between 1 and 100."
  fi
}

# 🧩 CRUD Threshold Profiles
manage_thresholds() {
  while true; do
    action=$(zenity --list --title="Manage RAM Thresholds" \
      --column="Action" \
      "Create New Threshold" \
      "View All Thresholds" \
      "Update Existing Threshold" \
      "Delete Threshold" \
      "Back")

    case "$action" in
      "Create New Threshold")
        name=$(zenity --entry --title="New Threshold" --text="Enter profile name (e.g., Low, Medium, High):")
        value=$(zenity --entry --title="Threshold Value" --text="Enter threshold percentage (1-100):")
        if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 100 ]; then
          if grep -q "^$name=" "$THRESHOLDS_FILE"; then
            zenity --error --text="Profile '$name' already exists."
          else
            echo "$name=$value" >> "$THRESHOLDS_FILE"
            zenity --info --text="Profile '$name' created with threshold $value%."
          fi
        else
          zenity --error --text="Invalid value. Enter a number between 1 and 100."
        fi
        ;;

      "View All Thresholds")
        zenity --text-info --title="Saved Thresholds" --filename="$THRESHOLDS_FILE" --width=300 --height=200
        ;;

      "Update Existing Threshold")
        selection=$(cut -d= -f1 "$THRESHOLDS_FILE" | zenity --list --title="Select Profile to Update" --column="Profiles")
        if [ -n "$selection" ]; then
          new_value=$(zenity --entry --title="Update Threshold" --text="Enter new threshold for '$selection':")
          if [[ "$new_value" =~ ^[0-9]+$ ]] && [ "$new_value" -ge 1 ] && [ "$new_value" -le 100 ]; then
            sed -i "s/^$selection=.*/$selection=$new_value/" "$THRESHOLDS_FILE"
            zenity --info --text="Profile '$selection' updated to $new_value%."
          else
            zenity --error --text="Invalid value. Enter a number between 1 and 100."
          fi
        fi
        ;;

      "Delete Threshold")
        selection=$(cut -d= -f1 "$THRESHOLDS_FILE" | zenity --list --title="Select Profile to Delete" --column="Profiles")
        if [ -n "$selection" ]; then
          sed -i "/^$selection=/d" "$THRESHOLDS_FILE"
          zenity --info --text="Profile '$selection' deleted."
        fi
        ;;

      "Back")
        break
        ;;
    esac
  done
}

# 🎯 Set Threshold from Profile
select_threshold_profile() {
  choice=$(cut -d= -f1 "$THRESHOLDS_FILE" | zenity --list --title="Select Alert Profile" --column="Profiles")
  if [ -n "$choice" ]; then
    THRESHOLD=$(grep "^$choice=" "$THRESHOLDS_FILE" | cut -d= -f2)
    zenity --info --text="Selected '$choice' profile. Threshold set to $THRESHOLD%."
  fi
}

# 📋 Main Menu Loop
while true; do
  choice=$(zenity --list --title="RAM Monitor" \
    --column="Action" \
    "Start Monitoring" \
    "Stop Monitoring" \
    "View RAM Usage" \
    "Set Alert Threshold" \
    "Manage Threshold Profiles" \
    "Use Saved Threshold Profile" \
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
    "Manage Threshold Profiles")
      manage_thresholds
      ;;
    "Use Saved Threshold Profile")
      select_threshold_profile
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
