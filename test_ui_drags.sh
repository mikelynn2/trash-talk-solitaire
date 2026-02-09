#!/bin/bash
# UI Drag Test Script using cliclick
# Simulates actual mouse drags on the Simulator

set -e

DEVICE="iPhone 17 Pro"
BUNDLE="com.tinroofai.trashtalksolitaire"

echo "🎮 Starting UI Drag Test with cliclick"
echo "======================================="

# Terminate and relaunch app
echo "Launching app..."
xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
sleep 0.5
xcrun simctl launch "$DEVICE" "$BUNDLE"
sleep 2

# Bring Simulator to front
osascript -e 'tell application "Simulator" to activate'
sleep 1

# Get Simulator window position using AppleScript
WINDOW_INFO=$(osascript -e '
tell application "System Events"
    tell process "Simulator"
        set frontmost to true
        set w to front window
        set p to position of w
        set s to size of w
        return (item 1 of p) & "," & (item 2 of p) & "," & (item 1 of s) & "," & (item 2 of s)
    end tell
end tell
')

IFS=',' read -r WIN_X WIN_Y WIN_W WIN_H <<< "$WINDOW_INFO"
echo "Simulator window: position ($WIN_X, $WIN_Y), size ($WIN_W x $WIN_H)"

# Calculate key positions (iPhone 17 Pro in Simulator)
# The simulator has a frame around the device
FRAME_TOP=60
FRAME_SIDE=0

# Device screen area within window
DEV_X=$((WIN_X + FRAME_SIDE))
DEV_Y=$((WIN_Y + FRAME_TOP))
DEV_W=$((WIN_W - FRAME_SIDE * 2))
DEV_H=$((WIN_H - FRAME_TOP - 20))

echo "Device area: ($DEV_X, $DEV_Y), size ($DEV_W x $DEV_H)"

# Key positions (as percentage of device area)
stock_x() { echo $((DEV_X + DEV_W * 8 / 100)); }
stock_y() { echo $((DEV_Y + DEV_H * 18 / 100)); }
waste_x() { echo $((DEV_X + DEV_W * 22 / 100)); }
waste_y() { echo $((DEV_Y + DEV_H * 18 / 100)); }
tableau_y() { echo $((DEV_Y + DEV_H * 35 / 100)); }
tableau_col_x() { echo $((DEV_X + DEV_W * (7 + $1 * 13) / 100)); }

echo ""
echo "Test 1: Draw cards from stock (10 taps)"
STOCK_X=$(stock_x)
STOCK_Y=$(stock_y)
for i in {1..10}; do
    cliclick c:$STOCK_X,$STOCK_Y
    sleep 0.3
done
echo "✓ Stock taps complete"

echo ""
echo "Test 2: Tap and drag from waste"
WASTE_X=$(waste_x)
WASTE_Y=$(waste_y)
for i in {1..5}; do
    # Drag from waste to a random tableau column
    COL=$((RANDOM % 7))
    DEST_X=$(tableau_col_x $COL)
    DEST_Y=$(($(tableau_y) + 50 + RANDOM % 150))
    
    echo "  Dragging waste to column $COL ($WASTE_X,$WASTE_Y -> $DEST_X,$DEST_Y)"
    cliclick dd:$WASTE_X,$WASTE_Y du:$DEST_X,$DEST_Y
    sleep 0.5
done
echo "✓ Waste drags complete"

echo ""
echo "Test 3: Drag between tableau columns"
TAB_Y=$(tableau_y)
for i in {1..20}; do
    SRC_COL=$((RANDOM % 7))
    DEST_COL=$((RANDOM % 7))
    
    SRC_X=$(tableau_col_x $SRC_COL)
    SRC_Y=$((TAB_Y + 30 + RANDOM % 200))
    
    DEST_X=$(tableau_col_x $DEST_COL)
    DEST_Y=$((TAB_Y + RANDOM % 250))
    
    echo "  Drag: col $SRC_COL -> col $DEST_COL"
    cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
    sleep 0.3
done
echo "✓ Tableau drags complete"

echo ""
echo "Test 4: Flick gestures (fast swipes)"
for i in {1..10}; do
    COL=$((RANDOM % 7))
    SRC_X=$(tableau_col_x $COL)
    SRC_Y=$((TAB_Y + 100))
    
    # Flick up (toward foundations)
    DEST_X=$SRC_X
    DEST_Y=$((DEV_Y + DEV_H * 18 / 100))
    
    echo "  Flick up from col $COL"
    # Quick drag = flick
    cliclick dd:$SRC_X,$SRC_Y m:$DEST_X,$DEST_Y du:$DEST_X,$DEST_Y w:50
    sleep 0.3
done
echo "✓ Flick gestures complete"

echo ""
echo "Test 5: Rapid random interactions (stress test)"
for i in {1..50}; do
    ACTION=$((RANDOM % 4))
    
    case $ACTION in
        0)
            # Tap stock
            cliclick c:$STOCK_X,$STOCK_Y
            ;;
        1)
            # Tap random position
            X=$((DEV_X + RANDOM % DEV_W))
            Y=$((DEV_Y + DEV_H * 25 / 100 + RANDOM % (DEV_H * 60 / 100)))
            cliclick c:$X,$Y
            ;;
        2)
            # Random drag
            SRC_X=$((DEV_X + RANDOM % DEV_W))
            SRC_Y=$((DEV_Y + DEV_H * 30 / 100 + RANDOM % (DEV_H * 50 / 100)))
            DEST_X=$((DEV_X + RANDOM % DEV_W))
            DEST_Y=$((DEV_Y + DEV_H * 15 / 100 + RANDOM % (DEV_H * 65 / 100)))
            cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
            ;;
        3)
            # Double tap
            X=$((DEV_X + RANDOM % DEV_W))
            Y=$((DEV_Y + DEV_H * 30 / 100 + RANDOM % (DEV_H * 50 / 100)))
            cliclick dc:$X,$Y
            ;;
    esac
    
    sleep 0.05
done
echo "✓ Stress test complete"

echo ""
echo "Test 6: New game + more drags (repeat 5x)"
for game in {1..5}; do
    echo "  Game $game..."
    # Tap "New" button (top left area)
    NEW_X=$((DEV_X + DEV_W * 8 / 100))
    NEW_Y=$((DEV_Y + DEV_H * 8 / 100))
    cliclick c:$NEW_X,$NEW_Y
    sleep 0.5
    
    # Draw some cards
    for j in {1..5}; do
        cliclick c:$STOCK_X,$STOCK_Y
        sleep 0.2
    done
    
    # Do some drags
    for j in {1..10}; do
        SRC_COL=$((RANDOM % 7))
        DEST_COL=$((RANDOM % 7))
        SRC_X=$(tableau_col_x $SRC_COL)
        SRC_Y=$((TAB_Y + 50 + RANDOM % 150))
        DEST_X=$(tableau_col_x $DEST_COL)
        DEST_Y=$((TAB_Y + RANDOM % 200))
        cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
        sleep 0.15
    done
done
echo "✓ Multi-game test complete"

echo ""
echo "======================================="
echo "✅ ALL UI TESTS COMPLETE"
echo ""
echo "Check the Xcode console output for:"
echo "  🚨 CARD COUNT ERROR messages"
echo "  ⚠️ Any unexpected behavior"
echo ""
echo "If you see card count errors, the logs will show"
echo "exactly which drag operation caused the issue."
