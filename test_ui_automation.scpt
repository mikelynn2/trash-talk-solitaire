-- UI Automation for Trash Talk Solitaire
-- Simulates drag gestures in the Simulator

on run
    tell application "Simulator"
        activate
        delay 1
    end tell
    
    tell application "System Events"
        tell process "Simulator"
            set frontmost to true
            
            -- Get the simulator window
            set simWindow to front window
            set winPos to position of simWindow
            set winSize to size of simWindow
            
            -- Calculate positions relative to window
            set winX to item 1 of winPos
            set winY to item 2 of winPos
            set winW to item 1 of winSize
            set winH to item 2 of winSize
            
            -- Stock pile position (approximate)
            set stockX to winX + (winW * 0.08)
            set stockY to winY + (winH * 0.22)
            
            -- Waste pile position
            set wasteX to winX + (winW * 0.22)
            set wasteY to winY + (winH * 0.22)
            
            -- Tableau area
            set tableauY to winY + (winH * 0.45)
            
            log "Starting UI drag tests..."
            log "Window position: " & winX & ", " & winY
            log "Window size: " & winW & " x " & winH
            
            -- Test 1: Draw cards from stock
            repeat 10 times
                click at {stockX, stockY}
                delay 0.3
            end repeat
            
            -- Test 2: Tap waste pile
            repeat 5 times
                click at {wasteX, wasteY}
                delay 0.3
            end repeat
            
            -- Test 3: Drag from waste to tableau
            repeat 5 times
                set destX to winX + (winW * (0.1 + (random number from 0 to 6) * 0.12))
                set destY to tableauY + (random number from 50 to 200)
                
                -- Perform drag
                set startPos to {wasteX, wasteY}
                set endPos to {destX, destY}
                
                -- Click and hold
                click at startPos
                delay 0.1
                
                -- Drag (using key down/up with mouse movement)
                set position of mouse to startPos
                delay 0.05
                key down {control down, shift down}
                set position of mouse to endPos
                delay 0.1
                key up {control down, shift down}
                
                delay 0.5
            end repeat
            
            -- Test 4: Random drags in tableau
            repeat 20 times
                set srcCol to random number from 0 to 6
                set destCol to random number from 0 to 6
                
                set srcX to winX + (winW * (0.08 + srcCol * 0.12))
                set srcY to tableauY + (random number from 20 to 150)
                
                set destX to winX + (winW * (0.08 + destCol * 0.12))
                set destY to tableauY + (random number from 20 to 200)
                
                -- Quick click-drag
                click at {srcX, srcY}
                delay 0.1
                
                delay 0.3
            end repeat
            
            log "UI tests complete!"
        end tell
    end tell
end run
