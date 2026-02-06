#!/bin/bash
# ==================================================
# Game Management Center
# ==================================================

# =============================
# ENV
# =============================
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
WHIPTAIL=/usr/bin/whiptail

BASE_DIR="/home/pi/RetroPie/scripts"

INSERT_SCRIPT="$BASE_DIR/insert_game_folder.sh"
COPY_SCRIPT="$BASE_DIR/copy_game_folder.sh"
DELETE_SCRIPT="$BASE_DIR/delete_game_folder.sh"
MEMORY_SCRIPT="$BASE_DIR/pcsx_memory_manager.sh"

GAME_LIST="/tmp/game_list.txt"
FREE_PERCENT=$(df / | awk 'NR==2 {print 100-$5}' | tr -d '%')

[ ! -x "$WHIPTAIL" ] && exit 1

# =============================
# FUNCTIONS
# =============================
get_free_space() {
    df -h / | awk 'NR==2 {print $4}'
}

get_total_games() {
    [ -f "$GAME_LIST" ] && wc -l < "$GAME_LIST" || echo 0
}

run_script() {
    SCRIPT="$1"
    MSG="$2"

    [ -x "$SCRIPT" ] || {
        $WHIPTAIL --msgbox "$MSG not found!" 8 45
        return
    }

    bash "$SCRIPT"
}

# =============================
# MAIN MENU LOOP
# =============================
while true; do

FREE_SPACE=$(get_free_space)
TOTAL_GAMES=$(get_total_games)

CHOICE=$(
$WHIPTAIL --title "🎮 Game Management Center" \
--menu "System Status

Free Storage : $FREE_SPACE ($FREE_PERCENT%)
Total Games : $TOTAL_GAMES

Select an action:" 22 70 10 \
1 "Insert Game from USB" \
2 "Copy Game to USB" \
3 "Delete Game" \
4 "PSX Memory Manager" \
5 "Exit" \
3>&1 1>&2 2>&3
)

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    1)
        run_script "$INSERT_SCRIPT" "Insert game script"
        ;;
    2)
        run_script "$COPY_SCRIPT" "Copy game script"
        ;;
    3)
        run_script "$DELETE_SCRIPT" "Delete game script"
        ;;
    4)
        run_script "$MEMORY_SCRIPT" "PSX Memory Manager"
        ;;
    5)
        break
        ;;
esac

done

exit 0
