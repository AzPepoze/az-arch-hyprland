#!/bin/bash

#-------------------------------------------------------
# Basic Logging Function (Fallback if helpers.sh is not found)
#-------------------------------------------------------
# This makes the script more self-contained.
# If your existing helpers.sh provides better logging,
# ensure it's sourced correctly.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"

if [ -f "$HELPER_SCRIPT" ]; then
    source "$HELPER_SCRIPT"
else
    echo "Error: Helper script not found at $HELPER_SCRIPT"
    exit 1
fi


#-------------------------------------------------------
# Prerequisite Check
#-------------------------------------------------------
if ! command -v inotifywait &>/dev/null; then
     _log ERROR "inotify-tools is not installed. Please install it to use this script."
     _log INFO "On Arch Linux, you can install it with: sudo pacman -S inotify-tools"
     exit 1
fi

if ! command -v rclone &>/dev/null; then
    _log ERROR "rclone is not installed. Please install it to use this script."
    exit 1
fi

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
WATCH_DIR="$HOME/GoogleDrive" # Ensure this path is correct and exists
REMOTE_NAME="gdrive:"         # Ensure this matches your rclone remote name
REMOTE_CHECK_INTERVAL=60      # Seconds to wait for file changes before performing a scheduled sync
SCRIPT_NAME=$(basename "$0")
LOCK_FILE="/tmp/${SCRIPT_NAME%.*}.lock" # Unique lock file for this script

#-------------------------------------------------------
# Functions
#-------------------------------------------------------
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        # Lock file exists. Check if the process that created it is still running.
        local old_pid
        old_pid=$(cat "$LOCK_FILE")
        if [ -n "$old_pid" ] && ps -p "$old_pid" > /dev/null; then
            _log WARN "Another sync process is already running (PID: $old_pid). Lock file: $LOCK_FILE. Skipping this sync cycle."
            return 1 # Failed to acquire lock
        else
            _log WARN "Stale lock file found for non-running process (PID: $old_pid). Removing it."
            rm -f "$LOCK_FILE"
        fi
    fi

    # Attempt to acquire a lock using noclobber.
    # This prevents race conditions if two scripts start at almost the same time.
    if ( set -o noclobber; echo "$" > "$LOCK_FILE") 2> /dev/null; then
        _log INFO "Lock acquired: $LOCK_FILE"
        # Ensure lock is released on exit, interrupt, or termination
        trap 'rm -f "$LOCK_FILE"; exit $?' INT TERM EXIT
        return 0 # Success
    else
        # This case is unlikely if the stale lock removal works, but it's a good safeguard
        # against race conditions where another process creates the lock just after our check.
        local current_pid
        current_pid=$(cat "$LOCK_FILE")
        _log WARN "Another sync process (PID: $current_pid) appears to have just started. Skipping this sync cycle."
        return 1 # Failed to acquire lock
    fi
}

release_lock() {
    rm -f "$LOCK_FILE"
    _log INFO "Lock released: $LOCK_FILE"
    # Remove trap after successful completion to prevent it from running on normal exit
    trap - INT TERM EXIT
}

run_bisync() {
    local resync_flag=$1 # Expecting '--resync' or an empty string

    # Check if WATCH_DIR exists before attempting sync
    if [ ! -d "$WATCH_DIR" ]; then
        _log ERROR "Watch directory '${WATCH_DIR}' does not exist. Please create it or correct the path. Exiting."
        exit 1
    fi

    if [ "$resync_flag" == "--resync" ]; then
        _log INFO "Starting rclone bisync with --resync flag..."
        _log WARN "This will establish a new sync baseline. Files may be overwritten based on the newest version."
    else
        _log INFO "Starting rclone bisync process..."
    fi

    # Create a temporary file to capture the output, and show it to the user with tee
    local output_file
    output_file=$(mktemp)

    # Run rclone, redirecting output to both the terminal and the temp file
    rclone bisync "$WATCH_DIR" "$REMOTE_NAME" \
        --transfers=24 \
        --checkers=48 \
        --drive-chunk-size=64M \
        --fast-list \
        --progress \
        --drive-acknowledge-abuse \
        --exclude "node_modules/**" \
        $resync_flag 2>&1 | tee "$output_file"

    # Get the exit code from rclone, not tee
    local rclone_exit_code=${PIPESTATUS[0]}

    if [ $rclone_exit_code -ne 0 ]; then
        _log ERROR "rclone bisync failed. Check the output above for details."

        # Check for stale lock file
        if grep -q "prior lock file found" "$output_file"; then
            _log WARN "Stale bisync lock file detected. Attempting to remove it..."
            # Extract lock file path from the error message
            lock_file_path=$(grep "prior lock file found" "$output_file" | sed -n 's/.*prior lock file found: \(.*\)/\1/p' | head -n 1)
            if [ -n "$lock_file_path" ]; then
                _log INFO "Attempting to delete lock file: $lock_file_path"
                rclone deletefile "$lock_file_path"
                local delete_exit_code=$?
                if [ $delete_exit_code -eq 0 ]; then
                    _log SUCCESS "Lock file removed. Retrying bisync..."
                    rm "$output_file"
                    run_bisync "$resync_flag" # Retry with the same flags
                    return $?
                else
                    _log ERROR "Failed to remove lock file (rclone exit code: $delete_exit_code). Please remove it manually and restart."
                    rm "$output_file"
                    return 1
                fi
            else
                _log ERROR "Could not extract lock file path from rclone output. Please check the logs and remove it manually."
                rm "$output_file"
                return 1
            fi
        fi

        # Only attempt auto-resync if we weren't already doing one (to prevent loops)
        if [ "$resync_flag" != "--resync" ] && grep -q "Must run --resync to recover" "$output_file"; then
            _log WARN "Critical bisync error detected. Attempting automatic --resync..."
            rm "$output_file" # Clean up before recursive call
            run_bisync "--resync"
            return $?
        fi

        rm "$output_file" # Clean up the temp file
        return 1
    fi

    rm "$output_file" # Clean up the temp file
    _log SUCCESS "Bisync completed successfully."
    return 0
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
RESYNC_ARG=""
if [ "$1" == "--resync" ]; then
    RESYNC_ARG="--resync"
    _log WARN "Running in --resync mode as requested by command line argument."
fi

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
_log INFO "Performing initial sync on startup..."
if acquire_lock; then
    run_bisync "$RESYNC_ARG"
    release_lock
fi

# Exit after resync if called with the flag
if [ "$RESYNC_ARG" == "--resync" ]; then
    _log INFO "Initial resync complete. Exiting script. Run without --resync to start watching."
    exit 0
fi

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
    _log INFO "Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

    # It's crucial that WATCH_DIR exists before inotifywait runs.
    if [ ! -d "$WATCH_DIR" ]; then
        _log ERROR "Watch directory '${WATCH_DIR}' does not exist for inotifywait. Exiting."
        exit 1
    fi

    # Start watching. -q suppresses non-error output from inotifywait
    inotifywait -r -q -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR"
    exit_code=$?

    case $exit_code in
        0)
            _log INFO "Local file change detected. Starting rclone bisync..."
            ;;
        1)
            _log WARN "Watched directory may have been deleted or is inaccessible. Triggering sync."
            ;;
        2)
            _log INFO "Timeout reached. Starting scheduled bisync to check for remote changes..."
            ;;
        *)
            _log WARN "inotifywait exited with unexpected code ${exit_code}. Triggering sync anyway."
            ;;
    esac

    # Attempt to acquire lock and run sync
    if acquire_lock; then
        run_bisync "" # Always run normal bisync in the loop
        release_lock
    fi

    _log INFO "Sync finished. Resuming watch."
done