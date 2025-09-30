#!/bin/bash

echo "Ranking Arch Linux mirrors..."
TMPFILE="$(mktemp)"
sudo true # Prompt for password once
rate-mirrors --save="$TMPFILE" arch --max-delay=43200 \
  && sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup \
  && sudo mv "$TMPFILE" /etc/pacman.d/mirrorlist
echo "Arch Linux mirrors ranked."

echo "Ranking Chaotic-AUR mirrors..."
TMPFILE="$(mktemp)"
rate-mirrors --save="$TMPFILE" chaotic-aur --max-delay=43200 \
  && sudo mv /etc/pacman.d/chaotic-mirrorlist /etc/pacman.d/chaotic-mirrorlist-backup \
  && sudo mv "$TMPFILE" /etc/pacman.d/chaotic-mirrorlist
echo "Chaotic-AUR mirrors ranked."

if grep -q "ID=cachyos" /etc/os-release; then
  echo "Ranking CachyOS mirrors..."
  TMPFILE="$(mktemp)"
  rate-mirrors --save="$TMPFILE" cachyos --max-delay=43200 \
    && sudo mv /etc/pacman.d/cachyos-mirrorlist /etc/pacman.d/cachyos-mirrorlist-backup \
    && sudo mv "$TMPFILE" /etc/pacman.d/cachyos-mirrorlist
  echo "CachyOS mirrors ranked."
fi

echo "All mirror lists updated."

