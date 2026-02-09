#!/bin/bash
# Simple UI Drag Test using cliclick
# Uses fixed coordinates (adjust if needed)

set -e

echo "🎮 Simple UI Drag Test"
echo "======================"
echo ""
echo "Make sure the Simulator is in the foreground with the app running!"
echo "Starting in 3 seconds..."
sleep 3

# Fixed coordinates for iPhone 17 Pro Simulator
# Adjust these based on your screen resolution and Simulator position
# These assume Simulator window is at approximately (0, 45) with default size

# Approximate positions (you may need to adjust)
STOCK_X=50
STOCK_Y=230
WASTE_X=130
WASTE_Y=230

# Tableau columns (7 columns)
TAB_Y=420
col_x() {
    echo $((35 + $1 * 52))
}

echo ""
echo "Test 1: Draw 10 cards from stock"
for i in {1..10}; do
    cliclick c:$STOCK_X,$STOCK_Y
    sleep 0.3
done
echo "✓ Done"

echo ""
echo "Test 2: Drag from waste (5 times)"
for i in {1..5}; do
    COL=$((RANDOM % 7))
    DEST_X=$(col_x $COL)
    DEST_Y=$((TAB_Y + 50 + RANDOM % 100))
    echo "  Drag to column $COL"
    cliclick dd:$WASTE_X,$WASTE_Y du:$DEST_X,$DEST_Y
    sleep 0.5
done
echo "✓ Done"

echo ""
echo "Test 3: Drag between tableau columns (20 times)"
for i in {1..20}; do
    SRC_COL=$((RANDOM % 7))
    DEST_COL=$((RANDOM % 7))
    SRC_X=$(col_x $SRC_COL)
    SRC_Y=$((TAB_Y + RANDOM % 150))
    DEST_X=$(col_x $DEST_COL)
    DEST_Y=$((TAB_Y + RANDOM % 180))
    
    echo "  Drag col $SRC_COL -> col $DEST_COL"
    cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
    sleep 0.25
done
echo "✓ Done"

echo ""
echo "Test 4: Rapid stress test (100 random actions)"
for i in {1..100}; do
    ACTION=$((RANDOM % 3))
    case $ACTION in
        0)
            cliclick c:$STOCK_X,$STOCK_Y
            ;;
        1)
            X=$((30 + RANDOM % 350))
            Y=$((200 + RANDOM % 400))
            cliclick c:$X,$Y
            ;;
        2)
            SRC_X=$((30 + RANDOM % 350))
            SRC_Y=$((250 + RANDOM % 350))
            DEST_X=$((30 + RANDOM % 350))
            DEST_Y=$((200 + RANDOM % 400))
            cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
            ;;
    esac
    sleep 0.03
done
echo "✓ Done"

echo ""
echo "Test 5: New game + drags (5 games)"
NEW_X=45
NEW_Y=115
for game in {1..5}; do
    echo "  Game $game"
    cliclick c:$NEW_X,$NEW_Y
    sleep 0.5
    
    # Draw cards
    for j in {1..5}; do
        cliclick c:$STOCK_X,$STOCK_Y
        sleep 0.15
    done
    
    # Drags
    for j in {1..10}; do
        SRC_COL=$((RANDOM % 7))
        DEST_COL=$((RANDOM % 7))
        SRC_X=$(col_x $SRC_COL)
        SRC_Y=$((TAB_Y + 50 + RANDOM % 120))
        DEST_X=$(col_x $DEST_COL)
        DEST_Y=$((TAB_Y + RANDOM % 150))
        cliclick dd:$SRC_X,$SRC_Y du:$DEST_X,$DEST_Y
        sleep 0.1
    done
done
echo "✓ Done"

echo ""
echo "======================"
echo "✅ ALL TESTS COMPLETE"
echo ""
echo "Check Xcode console for 🚨 CARD COUNT ERROR messages"
