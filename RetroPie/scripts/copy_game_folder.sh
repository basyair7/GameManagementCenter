#!/bin/bash
# copy_game_folder.sh
# Copy selected game folder from RetroPie to USB flash drive

# =============================
# ENV
# =============================
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
WHIPTAIL=/usr/bin/whiptail
USER_PI="pi"
ROMS="/home/pi/RetroPie/roms"
USB_ROOT="/media"
USB_FOLDER="RetroPieOS"

[ ! -x "$WHIPTAIL" ] && exit 1

TMP_LIST="/tmp/game_list.txt"

# =============================
# FIND USB DEVICE
# =============================
USB_FOUND=""
for DIR in /media/* /media/*/*; do
    mountpoint -q "$DIR" || continue
    USB_FOUND="$DIR"
    break
done

if [ -z "$USB_FOUND" ]; then
    $WHIPTAIL --title "Copy Game" --msgbox "USB flash drive not detected." 8 50
    exit 1
fi

# =============================
# ENSURE RetroPieOS FOLDER
# =============================
USB_PATH="$USB_FOUND/$USB_FOLDER"

if [ ! -d "$USB_PATH" ]; then
    CHOICE=$(
    $WHIPTAIL --title "Copy Game to USB" \
    --menu "RetroPieOS folder not found on USB.\nChoose destination:" 15 65 6 \
    1 "Create RetroPieOS folder (recommended)" \
    2 "Use USB root directly" \
    3 "Cancel" \
    3>&1 1>&2 2>&3
    )

    case "$CHOICE" in
        1)
            mkdir -p "$USB_PATH"
            ;;
        2)
            USB_PATH="$USB_FOUND"
            ;;
        *)
            exit 0
            ;;
    esac
fi

# =============================
# MAIN LOOP
# =============================
while true; do
    # =============================
    # BUILD GAME LIST
    # =============================
    > "$TMP_LIST"

    for SYSTEM in "$ROMS"/*; do
        [ ! -d "$SYSTEM" ] && continue
        SYS_NAME=$(basename "$SYSTEM")

        [[ "$SYS_NAME" == "bios" ]] && continue
        [[ "$SYS_NAME" == "ports" ]] && continue

        for ITEM in "$SYSTEM"/*; do
            [ ! -e "$ITEM" ] && continue

            NAME=$(basename "$ITEM")

            if [ -d "$ITEM" ]; then
                TYPE="FOLDER"
            elif [ -L "$ITEM" ]; then
                TYPE="SYMLINK"
            else
                TYPE="FILE"
            fi

            echo "$SYS_NAME|$NAME|$TYPE|$ITEM" >> "$TMP_LIST"
        done
    done

    TOTAL=$(wc -l < "$TMP_LIST")
    if [ "$TOTAL" -eq 0 ]; then
        $WHIPTAIL --msgbox "No games found." 8 40
        exit 0
    fi

    # =============================
    # BUILD MENU
    # =============================
    MENU_ITEMS=()
    INDEX=1

    while IFS='|' read -r SYS NAME TYPE GAME_PATH; do
        MENU_ITEMS+=("$INDEX" "$SYS / $NAME ($TYPE)")
        INDEX=$((INDEX + 1))
    done < "$TMP_LIST"

    # =============================
    # SELECT ITEM
    # =============================
    CHOICE=$(
    $WHIPTAIL --title "Copy Game to USB" \
      --menu "Select a game or folder to copy:" 20 75 12 \
      "${MENU_ITEMS[@]}" \
      3>&1 1>&2 2>&3
    )

    [ -z "$CHOICE" ] && break

    LINE=$(sed -n "${CHOICE}p" "$TMP_LIST")
    IFS='|' read -r SYS NAME TYPE GAME_PATH <<< "$LINE"

    DEST_DIR="$USB_PATH/$SYS/$NAME"

    # =============================
    # CONFIRM
    # =============================
    $WHIPTAIL --yesno \
"System : $SYS
Name   : $NAME
Type   : $TYPE

Destination:
$DEST_DIR

Copy this item to USB?" 15 65
    [ $? -ne 0 ] && continue

    mkdir -p "$USB_PATH/$SYS"

    # =============================
    # COPY WITH PROGRESS
    # =============================
    {
        if [ -d "$GAME_PATH" ]; then
            TOTAL_FILES=$(find "$GAME_PATH" -type f | wc -l)
            COUNT=0
            mkdir -p "$DEST_DIR"

            find "$GAME_PATH" -type f | while read -r FILE; do
                REL_PATH="${FILE#$GAME_PATH/}"
                mkdir -p "$(dirname "$DEST_DIR/$REL_PATH")"
                cp -f "$FILE" "$DEST_DIR/$REL_PATH"
                COUNT=$((COUNT + 1))
                PERCENT=$((COUNT * 100 / TOTAL_FILES))
                echo $PERCENT
                echo "# Copying: $REL_PATH"
            done
        else
            cp -f "$GAME_PATH" "$USB_PATH/$SYS/"
            echo 100
            echo "# Copied file: $NAME"
        fi
    } | $WHIPTAIL --gauge "Copying files to USB...

⚠ DO NOT remove the USB flash drive
⚠ DO NOT power off the system" 13 65 0

    sync
    sleep 1

    $WHIPTAIL --msgbox "Copied successfully to:\n$DEST_DIR" 9 60

    # =============================
    # ASK CONTINUE
    # =============================
    $WHIPTAIL --yesno "Copy another game?" 8 40
    [ $? -ne 0 ] && break
done

# =============================
# SAFE UNMOUNT
# =============================
sync
sleep 2
if command -v udisksctl >/dev/null 2>&1; then
    DEV=$(lsblk -o MOUNTPOINT,NAME -nr | awk -v m="$USB_FOUND" '$1==m {print "/dev/"$2}')
    [ -n "$DEV" ] && udisksctl unmount -b "$DEV" --no-user-interaction >/dev/null 2>&1
else
    umount "$USB_FOUND" >/dev/null 2>&1
fi

$WHIPTAIL --title "Copy Game" --msgbox "Copy process finished.

USB safely unmounted.
You may now remove the flash drive." 11 60

exit 0
