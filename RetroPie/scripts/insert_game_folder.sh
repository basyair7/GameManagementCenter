#!/bin/bash
# insert_game_folder.sh
# USB Game Import (DIALOG VERSION)

# =============================
# CONFIG
# =============================
DIALOG=/usr/bin/dialog
USB_ROOT="/media"
SOURCE="RetroPieOS"
TARGET="/home/pi/RetroPie/roms"
MIN_FREE=5
USER_PI="pi"

command -v "$DIALOG" >/dev/null 2>&1 || exit 1

# =============================
# SAFE USB UNMOUNT FUNCTION
# =============================
safe_unmount() {
    MOUNT_DIR="$1"

    DEV=$(lsblk -o MOUNTPOINT,NAME -nr | awk -v m="$MOUNT_DIR" '$1==m {print "/dev/"$2}')
    [ -z "$DEV" ] && return 0

    sync
    sleep 2

    if command -v udisksctl >/dev/null 2>&1; then
        udisksctl unmount -b "$DEV" --no-user-interaction >/dev/null 2>&1
    else
        umount "$DEV" >/dev/null 2>&1
    fi
}

# =============================
# CHECK READ-ONLY
# =============================
check_ro() {
    MOUNT_DIR="$1"

    if mount | grep " $MOUNT_DIR " | grep -q "(ro,"; then
        $DIALOG --clear --backtitle "Game Management Center" \
        --title "Insert New Game" \
        --msgbox "USB flash drive is READ-ONLY.

Possible causes:
• Unsafe removal
• File system error

Please run fsck or reformat the USB." 13 60
        return 1
    fi
    return 0
}

# =============================
# SYSTEM FOLDERS
# =============================
SYSTEMS=(
  amstradcpc atari800 atari2600 atari5200 atari7800 atarilynx
  channelf coleco fba fds gamegear gb gba gbc
  mastersystem megadrive msx n64 neogeo nes
  ngp ngpc pcengine psp psx sega32x segacd
  sg-1000 snes vectrex zxspectrum
)

declare -A SYSTEMS_WITH_SUBDIRS=(
  ["arcade"]="mame2003"
  ["mame-libretro"]="mame2003"
)

MAME_SUBDIRS=(cfg ctrlr diff hi memcard nvram)

# =============================
# STORAGE CHECK
# =============================
FREE=$(df / | awk 'NR==2 {print 100-$5}' | tr -d '%')
if [ "$FREE" -le "$MIN_FREE" ]; then
    $DIALOG --clear --title "Insert New Game" \
    --msgbox "Free storage too low: ${FREE}%" 7 45
    clear
    exit 0
fi

# =============================
# USB DETECTION
# =============================
USB_FOUND=""
for DIR in /media/* /media/*/*; do
    mountpoint -q "$DIR" || continue
    USB_FOUND="$DIR"
    break
done

if [ -z "$USB_FOUND" ]; then
    $DIALOG --clear --title "Insert New Game" \
    --msgbox "USB flash drive not detected." 7 45
    clear
    exit 0
fi

check_ro "$USB_FOUND" || exit 1

RETROPIE_USB="$USB_FOUND/$SOURCE"

# =============================
# CREATE STRUCTURE IF NEEDED
# =============================
if [ ! -d "$RETROPIE_USB" ]; then
    mkdir -p "$RETROPIE_USB"

    for SYS in "${SYSTEMS[@]}"; do
        mkdir -p "$RETROPIE_USB/$SYS"
    done

    for SYS in "${!SYSTEMS_WITH_SUBDIRS[@]}"; do
        for DIR in "${MAME_SUBDIRS[@]}"; do
            mkdir -p "$RETROPIE_USB/$SYS/${SYSTEMS_WITH_SUBDIRS[$SYS]}/$DIR"
        done
    done

    $DIALOG --clear --backtitle "Game Management Center" \
    --title "USB Structure Created" \
    --msgbox "RetroPieOS folder created on USB.

Copy ROMs into:
RetroPieOS/<system>/" 10 60

    safe_unmount "$USB_FOUND"
    clear
    exit 0
fi

# =============================
# STOP EMULATIONSTATION
# =============================
ES_WAS_RUNNING=0
if pgrep emulationstation >/dev/null; then
    ES_WAS_RUNNING=1
    sudo systemctl stop emulationstation
    sleep 1
fi

# =============================
# COUNT TASKS
# =============================
TOTAL=0
for SYS in "$RETROPIE_USB"/*; do
    [ -d "$SYS" ] && TOTAL=$((TOTAL + $(find "$SYS" -mindepth 1 -maxdepth 1 -type d | wc -l)))
done
[ "$TOTAL" -eq 0 ] && TOTAL=1
COUNT=0

# =============================
# COPY PROCESS
# =============================
(
for SYS in "$RETROPIE_USB"/*; do
    [ -d "$SYS" ] || continue

    SYS_NAME=$(basename "$SYS")
    DEST_SYS="$TARGET/$SYS_NAME"
    [ -d "$DEST_SYS" ] || continue

    for GAME in "$SYS"/*; do
        [ -d "$GAME" ] || continue

        GAME_NAME=$(basename "$GAME")
        DEST="$DEST_SYS/$GAME_NAME"

        if [ -d "$DEST" ]; then
            STATUS="Skipped"
        else
            cp -r "$GAME" "$DEST"
            STATUS="Imported"
        fi

        COUNT=$((COUNT + 1))
        PERCENT=$((COUNT * 100 / TOTAL))

        echo "$PERCENT"
        echo "XXX"
        echo "Importing games from USB...

⚠ DO NOT remove USB
⚠ DO NOT power off system

Progress : $COUNT / $TOTAL games
--------------------------------
$STATUS : $SYS_NAME / $GAME_NAME"
        echo "XXX"

    done
done
) | $DIALOG --clear \
    --backtitle "Game Management Center" \
    --title "Import Progress" \
    --gauge "Preparing import..." 15 70 0

# =============================
# FINISH
# =============================
sync
sleep 2
safe_unmount "$USB_FOUND"

[ "$ES_WAS_RUNNING" -eq 1 ] && sudo systemctl start emulationstation

$DIALOG --clear --backtitle "Game Management Center" \
--title "Import Completed" \
--msgbox "Game import completed successfully.

USB safely unmounted.
You may now remove the device." 10 60

clear
exit 0
