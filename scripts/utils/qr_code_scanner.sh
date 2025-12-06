FILE=$(mktemp --suffix=.png)
grim -g "$(slurp)" "$FILE"

if [ $? -eq 0 ]; then
    QR_CODE_DATA=$(zbarimg -q --raw "$FILE")

    if [ -n "$QR_CODE_DATA" ]; then
        echo "$QR_CODE_DATA" | wl-copy
        notify-send "QR Code Scanned" "$QR_CODE_DATA"
    else
        notify-send "QR Code Scanned" "No QR code found or could not be decoded."
    fi
else
    notify-send "QR Code Scanner" "Screen capture cancelled."
fi

rm "$FILE"