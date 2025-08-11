# This script monitors D-Bus for notifications and logs them to files as JSON objects.
# It requires `jq` for safe JSON construction and must be run within a git repository.

# Function to write the collected notification data to a log file
write_log_file() {
  local app_name="$1" summary="$2" body="$3" app_icon="$4" image="$5" urgency="$6"

  if [[ -z "$summary" && -z "$app_name" ]]; then
    return
  fi

  local log_filename_base
  if [[ -n "$app_name" ]]; then
    log_filename_base="$app_name"
  elif [[ -n "$app_icon" ]]; then
    log_filename_base="$app_icon"
  else
    log_filename_base="unknown"
  fi

  local sanitized_filename
  sanitized_filename=$(echo "$log_filename_base" | sed 's#/#_#g' | sed 's/[^a-zA-Z0-9._-]/_/g')

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$repo_root" ]]; then
    # Cannot find repo root, do not log.
    return 1
  fi

  local log_dir="$repo_root/logs/notification"
  mkdir -p "$log_dir"

  local log_file="$log_dir/$sanitized_filename.log"

  current_time=$(date +%s%3N)

  jq -cn \
    --argjson notificationId null \
    --argjson actions "[]" \
    --arg appIcon "$app_icon" \
    --arg appName "$app_name" \
    --arg body "$body" \
    --arg image "$image" \
    --arg summary "$summary" \
    --argjson time "$current_time" \
    --arg urgency "${urgency:-1}" \
    '$ARGS.named' >> "$log_file"
}

# Main processing loop
dbus-monitor --session "interface='org.freedesktop.Notifications'" | while IFS= read -r line; do

  # A verbose method call to Notify is the trigger to start parsing a new notification.
  if [[ "$line" =~ "method call" && "$line" =~ "member=Notify" ]]; then

    # Read parameters sequentially from the lines following the method call
    read -r app_name_line
    app_name=$(echo "$app_name_line" | sed -n 's/^[[:space:]]*string "\(.*\)"/\1/p')

    read -r replaces_id_line

    read -r app_icon_line
    app_icon=$(echo "$app_icon_line" | sed -n 's/^[[:space:]]*string "\(.*\)"/\1/p')

    read -r summary_line
    summary=$(echo "$summary_line" | sed -n 's/^[[:space:]]*string "\(.*\)"/\1/p')

    read -r body_line
    body=$(echo "$body_line" | sed -n 's/^[[:space:]]*string "\(.*\)"/\1/p')

    # Consume the 'actions' array lines using grep for robust loop termination
    read -r line
    while IFS= read -r line && ! echo "$line" | grep -q -E "^\s*\]\s*$"; do
      : # Do nothing, just consume the line
    done

    # Parse the 'hints' array using grep for robust loop termination
    image=""
    urgency=""
    read -r line
    while IFS= read -r line && ! echo "$line" | grep -q -E "^\s*\]\s*$"; do
      if [[ "$line" =~ 'string "urgency"' ]]; then
        read -r value_line
        urgency=$(echo "$value_line" | sed -n 's/.*byte \([0-9]\+\).*/\1/p')
      elif [[ "$line" =~ 'string "image-path"' || "$line" =~ 'string "image_path"' ]]; then
        read -r value_line
        image=$(echo "$value_line" | sed -n 's/^[[:space:]]*string "\(.*\)"/\1/p')
      fi
    done

    # After parsing all data, call the function to write the log file
    write_log_file "$app_name" "$summary" "$body" "$app_icon" "$image" "$urgency"
  fi
done