#!/bin/bash
# ==================================================
# PCSX Simple Memory Card Manager (SAFE MODE)
# Focus: pcsx-card2.mcd
# ==================================================

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

DIALOG=/usr/bin/dialog
USER_PI="pi"
PSX_ROMS="/home/pi/RetroPie/roms/psx"

[ ! -x "$DIALOG" ] && exit 1

# =============================
# FIND USB
# =============================
find_usb() {
    for D in /media/* /media/*/*; do
        mountpoint -q "$D" && echo "$D" && return
    done
}
USB=$(find_usb)

# =============================
# SELECT GAME
# =============================
select_game() {
    MAP=/tmp/psx_game.map
    > "$MAP"
    MENU=()
    IDX=1

    for G in "$PSX_ROMS"/*; do
        [ -d "$G" ] || continue
        echo "$G" >> "$MAP"
        MENU+=("$IDX" "$(basename "$G")")
        ((IDX++))
    done

    [ "$IDX" -eq 1 ] && exit 0

    SEL=$(
        $DIALOG --stdout \
        --title "PCSX Memory Manager" \
        --menu "Select Game:" 18 60 10 \
        "${MENU[@]}"
    )

    [ -z "$SEL" ] && exit 0
    sed -n "${SEL}p" "$MAP"
}

# =============================
# BACKUP SLOT2
# =============================
backup_slot2() {
    DIR="$1"
    CARD="$DIR/pcsx-card2.mcd"

    [ ! -f "$CARD" ] && {
        $DIALOG --msgbox "No pcsx-card2.mcd found." 6 40
        return
    }

    mkdir -p "$DIR/backup"
	
    IDX=1
    while [ -f "$DIR/backup/pcsx-card2.mcd.$IDX" ]; do
        ((IDX++))
    done

    mv "$CARD" "$DIR/backup/pcsx-card2.mcd.$IDX"
    $DIALOG --msgbox "Backup created:\npcsx-card2.mcd.$IDX" 7 50
}

# =============================
# CREATE BLANK SLOT2
# =============================
create_blank_slot2() {
    DIR="$1"
    CARD="$DIR/pcsx-card2.mcd"

    [ -f "$CARD" ] && backup_slot2 "$DIR"

    sudo -u "$USER_PI" dd if=/dev/zero of="$CARD" bs=1k count=128 status=none
    $DIALOG --msgbox "New blank pcsx-card2.mcd created." 6 45
}

# =============================
# RESTORE FROM BACKUP
# =============================
restore_backup() {
    DIR="$1"
    BKDIR="$DIR/backup"

    [ ! -d "$BKDIR" ] && {
        $DIALOG --msgbox "No backup folder found." 6 40
        return
    }

    MAP=/tmp/backup.map
    > "$MAP"
    MENU=()
    IDX=1

    for B in "$BKDIR"/pcsx-card2.mcd.*; do
        [ -f "$B" ] || continue
        echo "$B" >> "$MAP"
        MENU+=("$IDX" "$(basename "$B")")
        ((IDX++))
    done

    [ "$IDX" -eq 1 ] && {
        $DIALOG --msgbox "No backups available." 6 40
        return
    }

    SEL=$(
        $DIALOG --stdout \
        --title "Restore Backup" \
        --menu "Select backup to restore:" 20 70 12 \
        "${MENU[@]}"
    )

    [ -z "$SEL" ] && return

    SELECTED=$(sed -n "${SEL}p" "$MAP")

    [ -f "$DIR/pcsx-card2.mcd" ] && backup_slot2 "$DIR"

    mv "$SELECTED" "$DIR/pcsx-card2.mcd"
    $DIALOG --msgbox "Backup restored as pcsx-card2.mcd" 6 45
}

# =============================
# MANAGE BACKUP
# =============================
manage_backups() {
    DIR="$1"
    BKDIR="$DIR/backup"

    [ ! -d "$BKDIR" ] && {
        $DIALOG --msgbox "No backup folder found." 6 40
        return
    }

    MAP=/tmp/backup_del.map
    > "$MAP"
    MENU=()
    IDX=1

    for B in "$BKDIR"/pcsx-card2.mcd.*; do
        [ -f "$B" ] || continue
        echo "$B" >> "$MAP"
        MENU+=("$IDX" "$(basename "$B")")
        ((IDX++))
    done

    [ "$IDX" -eq 1 ] && {
        $DIALOG --msgbox "No backups to manage." 6 40
        return
    }

    SEL=$(
        $DIALOG --stdout \
        --title "Manage Backups" \
        --menu "Select backup to delete:" 20 70 12 \
        "${MENU[@]}"
    )

    [ -z "$SEL" ] && return

    TARGET=$(sed -n "${SEL}p" "$MAP")

    $DIALOG --yesno \
        "Delete this backup?\n\n$(basename "$TARGET")" 9 60 || return

    rm -f "$TARGET"

    $DIALOG --msgbox "Backup deleted." 6 40
}

# =============================
# COPY TO USB
# =============================
copy_to_usb() {
    DIR="$1"
    GAME=$(basename "$DIR")
    CARD="$DIR/pcsx-card2.mcd"

    [ ! -f "$CARD" ] && {
        $DIALOG --msgbox "No pcsx-card2.mcd to copy." 6 40
        return
    }

    [ -z "$USB" ] && {
        $DIALOG --msgbox "USB not detected." 6 40
        return
    }

    DEST="$USB/${GAME}_pcsx-card2.mcd"

    if sudo -u "$USER_PI" cp "$CARD" "$DEST"; then
        $DIALOG --msgbox "Copied to USB:\n$(basename "$DEST")" 7 50
    else
        $DIALOG --msgbox "Copy FAILED.\nCheck USB permission or space." 7 55
    fi
}

# =============================
# RESTORE FROM USB
# =============================
restore_from_usb() {
    DIR="$1"
    GAME=$(basename "$DIR")

    [ -z "$USB" ] && {
        $DIALOG --msgbox "USB not detected." 6 40
        return
    }

    # cari file di USB yang cocok dengan game
    FILES=("$USB/${GAME}_pcsx-card2.mcd"*)
    [ ! -f "${FILES[0]}" ] && {
        $DIALOG --msgbox "No backup on USB for this game." 6 50
        return
    }

    MAP=/tmp/usb_restore.map
    > "$MAP"
    MENU=()
    IDX=1

    for F in "${FILES[@]}"; do
        [ -f "$F" ] || continue
        echo "$F" >> "$MAP"
        MENU+=("$IDX" "$(basename "$F")")
        ((IDX++))
    done

    SEL=$(
        $DIALOG --stdout \
        --title "Restore from USB" \
        --menu "Select backup to restore from USB:" 20 70 12 \
        "${MENU[@]}"
    )

    [ -z "$SEL" ] && return

    SELECTED=$(sed -n "${SEL}p" "$MAP")

    [ -f "$DIR/pcsx-card2.mcd" ] && backup_slot2 "$DIR"

    sudo -u "$USER_PI" cp "$SELECTED" "$DIR/pcsx-card2.mcd"

    $DIALOG --msgbox "Restored from USB:\n$(basename "$SELECTED")" 6 50
}

# =============================
# GAME MENU
# =============================
game_menu() {
    DIR="$1"
    GAME=$(basename "$DIR")

    while true; do
        CHOICE=$(
            $DIALOG --stdout \
            --title "Memory Manager - $GAME" \
            --menu "pcsx-card2.mcd actions:" 18 60 10 \
            1 "Backup current memory" \
            2 "Create new blank memory" \
            3 "Restore from backup" \
            4 "Manage backups (delete)" \
            5 "Copy current to USB" \
			6 "Restore from USB" \
            7 "Back"
        )

        case "$CHOICE" in
            1) backup_slot2 "$DIR" ;;
            2) create_blank_slot2 "$DIR" ;;
            3) restore_backup "$DIR" ;;
            4) manage_backups "$DIR" ;;
            5) copy_to_usb "$DIR" ;;
			6) restore_from_usb "$DIR" ;;
            *) break ;;
        esac
    done
}

# =============================
# MAIN
# =============================
while true; do
    GAME_DIR=$(select_game)
    [ -z "$GAME_DIR" ] && break
    game_menu "$GAME_DIR"
done

clear
exit 0
