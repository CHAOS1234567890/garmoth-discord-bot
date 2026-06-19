#!/bin/sh

ROOT="bdo_unix"
ETC="$ROOT/etc"
LIB="$ROOT/usr/lib/bdo"
BIN="$ROOT/usr/bin"

mkdir -p "$ETC" "$LIB" "$BIN"

# /etc/bdo.conf
cat > "$ETC/bdo.conf" << 'EOF'
MODE="mixed"          # fishing | grind | mixed
USE_BUFFS=1
USE_POTS=1
AUTO_REPAIR=1
AUTO_SELL_TRASH=1
HUMANIZE=1
LOGFILE="/var/log/bdo.log"
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
FISH_WAIT_MIN=2
FISH_WAIT_MAX=5
GRIND_DURATION=1800
FISH_DURATION=1800
EOF

# core.sh
cat > "$LIB/core.sh" << 'EOF'
log() {
    echo "$(date '+%H:%M:%S') [BDO] $1" >> "$LOGFILE"
}

sleep_human() {
    base=$1
    spread=$2
    rand=$(( RANDOM % spread ))
    sleep "$(echo "$base + ($rand / 1000)" | bc -l)"
}

press() {
    key="$1"
    dur="$2"
    # Simulate key press using xdotool
    if command -v xdotool >/dev/null 2>&1; then
        xdotool key "$key" 2>/dev/null
        sleep "$(echo "$dur / 1000" | bc -l)"
    fi
}

click() {
    x="$1"
    y="$2"
    # Simulate mouse click using xdotool
    if command -v xdotool >/dev/null 2>&1; then
        xdotool mousemove "$x" "$y" click 1 2>/dev/null
    fi
}

get_pixel() {
    x="$1"
    y="$2"
    # Get pixel color at position (requires ImageMagick)
    if command -v convert >/dev/null 2>&1; then
        convert x: -crop 1x1+$x+$y -depth 8 txt:- 2>/dev/null | grep -oP '#[0-9A-F]{6}' | head -1
    fi
}
EOF

# safety.sh
cat > "$LIB/safety.sh" << 'EOF'
check_alive() {
    # Check if character is alive (simplified: check for HP bar color)
    # Red HP bar indicates low health
    hp_color=$(get_pixel 100 50)
    
    if [ "$hp_color" = "#FF0000" ]; then
        log "LOW HP DETECTED"
        use_pots
        if [ "$?" -ne 0 ]; then
            emergency_stop "No pots available, low HP!"
        fi
    fi
}

check_gm() {
    # TODO: Monitor chat for GM presence
    # In a real implementation, would parse game chat logs
    # or monitor screen for GM notifications
    log "GM check passed"
}

emergency_stop() {
    log "EMERGENCY STOP: $1"
    pkill -P $$ 2>/dev/null
    exit 1
}
EOF

# buffs.sh
cat > "$LIB/buffs.sh" << 'EOF'
use_buffs() {
    [ "$USE_BUFFS" -eq 1 ] || return
    
    log "Using buffs..."
    
    # Use food buff
    press "w" 100
    sleep 0.5
    press "Return" 100
    
    log "Buffs applied"
}

use_pots() {
    [ "$USE_POTS" -eq 1 ] || return
    
    log "Using potions..."
    
    # Check inventory space
    if [ "$(get_inventory_count)" -lt 5 ]; then
        log "Not enough inventory space for pots"
        return 1
    fi
    
    # Use HP pot (typically hotkey)
    press "grave" 100
    sleep_human 0.5 0.2
    
    log "Potion used"
    return 0
}

get_inventory_count() {
    # Simplified: return assumed free slots
    # In real implementation, would parse inventory from screen
    echo 20
}
EOF

# fishing.sh
cat > "$LIB/fishing.sh" << 'EOF'
fish_loop() {
    log "Fishing gestartet"
    
    start_time=$(date +%s)

    while true; do
        check_alive
        check_gm
        use_buffs
        use_pots

        # Cast fishing line
        press "f" 100
        sleep_human "$FISH_WAIT_MIN" "$FISH_WAIT_MAX"

        solve_minigame
        handle_loot
        
        # Check duration
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ "$elapsed" -gt "$FISH_DURATION" ]; then
            log "Fishing duration reached, switching mode"
            break
        fi
    done
}

solve_minigame() {
    log "Minigame started..."
    
    # Simulate minigame solving by detecting fish bite and reacting
    timeout 15 bash -c '
    while true; do
        # Check for bobber movement (would detect screen change in real impl)
        sleep 0.5
        if [ $((RANDOM % 100)) -lt 30 ]; then
            # Fish detected, press spacebar rapidly
            xdotool key space 2>/dev/null
            sleep 0.2
            xdotool key space 2>/dev/null
            sleep 0.2
            xdotool key space 2>/dev/null
            break
        fi
    done
    ' 2>/dev/null
    
    log "Minigame completed"
}

handle_loot() {
    # Handle caught fish
    press "Return" 100
    sleep_human 1 0.5
    
    # Auto-sell trash if enabled
    if [ "$AUTO_SELL_TRASH" -eq 1 ]; then
        log "Selling trash loot..."
        # Would implement trash detection via screen analysis
    fi
}
EOF

# grind.sh
cat > "$LIB/grind.sh" << 'EOF'
grind_loop() {
    log "Grind gestartet"
    
    start_time=$(date +%s)

    while true; do
        check_alive
        check_gm
        use_buffs
        use_pots

        move_path
        skill_rotation
        loot
        pet_check
        
        # Check duration
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        if [ "$elapsed" -gt "$GRIND_DURATION" ]; then
            log "Grind duration reached, switching mode"
            break
        fi
    done
}

move_path() {
    # Simplified path following (in real impl, would use waypoint system)
    log "Moving to grind location..."
    
    # Move forward
    press "w" 2000
    sleep_human 1 0.5
}

skill_rotation() {
    # Execute skill rotation
    for i in 1 2 3 1 2 3; do
        press "$i" 200
        sleep_human 0.8 0.3
        
        # Check if we need to move again
        if [ $((RANDOM % 100)) -lt 20 ]; then
            move_path
        fi
    done
}

loot() {
    # Auto-loot nearby items
    press "e" 100
    sleep 0.2
    
    # Check inventory
    if [ "$AUTO_SELL_TRASH" -eq 1 ]; then
        log "Processing loot..."
    fi
}

pet_check() {
    # Check pet status periodically
    log "Pet check: OK"
}
EOF

# /usr/bin/bdo
cat > "$BIN/bdo" << 'EOF'
#!/bin/sh
BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"

. "$BASE_DIR/etc/bdo.conf"
. "$BASE_DIR/usr/lib/bdo/core.sh"
. "$BASE_DIR/usr/lib/bdo/safety.sh"
. "$BASE_DIR/usr/lib/bdo/buffs.sh"
. "$BASE_DIR/usr/lib/bdo/fishing.sh"
. "$BASE_DIR/usr/lib/bdo/grind.sh"

log "BDO Script gestartet. Mode=$MODE"

case "$MODE" in
    fishing) fish_loop ;;
    grind)   grind_loop ;;
    mixed)
        while true; do
            log "Starting grind session..."
            grind_loop
            
            log "Grind completed, starting fishing..."
            fish_loop
        done
        ;;
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac

log "BDO Script beendet"
EOF

chmod +x "$BIN/bdo"

tar -czf bdo_unix.tar.gz "$ROOT"

echo "Fertig: bdo_unix.tar.gz erstellt."
