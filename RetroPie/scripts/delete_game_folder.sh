#!/bin/bash
#delete_folder_game.sh

# =============================
# ENV FIX
# =============================
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
WHIPTAIL=/usr/bin/whiptail
USER_PI="pi"

ROMS="/home/pi/RetroPie/roms"
TMP_LIST="/tmp/game_list.txt"

[ ! -x "$WHIPTAIL" ] && exit 1

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
    $WHIPTAIL --title "Delete Game" \
      --menu "Select a game or folder to delete:" 20 75 12 \
      "${MENU_ITEMS[@]}" \
      3>&1 1>&2 2>&3
    )

    # Cancel / ESC → keluar
    [ -z "$CHOICE" ] && break

    LINE=$(sed -n "${CHOICE}p" "$TMP_LIST")
    IFS='|' read -r SYS NAME TYPE GAME_PATH <<< "$LINE"

    # =============================
    # CONFIRM
    # =============================
    $WHIPTAIL --yesno \
"System : $SYS
Name   : $NAME
Type   : $TYPE

⚠ THIS CANNOT BE UNDONE ⚠
Delete this item?" 15 60

    [ $? -ne 0 ] && continue

    # =============================
    # DELETE
    # =============================
    if [ "$TYPE" = "FOLDER" ]; then
        sudo -u "$USER_PI" rm -rf -- "$GAME_PATH"
    else
        sudo -u "$USER_PI" rm -f -- "$GAME_PATH"
    fi

    # Remove gamelist cache
    GAMELIST="$ROMS/$SYS/gamelist.xml"
    [ -f "$GAMELIST" ] && sudo -u "$USER_PI" rm -f "$GAMELIST"

    $WHIPTAIL --msgbox "Deleted successfully." 8 40

done

exit 0
