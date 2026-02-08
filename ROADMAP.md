# Trash Talk Solitaire - Feature Roadmap

## Phase 1: Core Features ✅ → 🚧

### 1. Auto-Complete with Fly Animation 🚧
- [ ] Detect when all cards face-up and stock empty
- [ ] Show "Auto" button (already exists)
- [ ] Animate cards flying to foundations one by one
- [ ] Satisfying swoosh animation + sound
- [ ] Grandma commentary: "Finally, let me finish this for you..."

### 2. Hints System
- [ ] Add "Hint" button to top bar
- [ ] Find valid moves (prioritize: foundation > tableau)
- [ ] Highlight source card with glow/pulse
- [ ] Highlight destination with outline
- [ ] Grandma reluctantly helps: "Oh, fine... try THAT one."
- [ ] Cooldown or limit hints per game

### 3. Draw 3 Mode
- [ ] Add setting toggle: Draw 1 / Draw 3
- [ ] Modify drawFromStock() to draw 3 cards
- [ ] Fan the 3 waste cards visually
- [ ] Only top card playable
- [ ] Persist preference in UserDefaults

### 4. Stats Tracking
- [ ] Create StatsManager with UserDefaults persistence
- [ ] Track: games played, games won, win %, best time, current streak, longest streak
- [ ] Stats view in settings sheet
- [ ] Reset stats option
- [ ] Update stats on game end

### 5. More Commentary (50+ lines)
- [ ] Add 20+ new roasts
- [ ] Add 20+ new praises
- [ ] Add situational comments (long game, fast win, many undos, etc.)
- [ ] Add hint-related comments
- [ ] Add streak-related comments

## Phase 2: Polish

### 6. Card Fly Animation
- [ ] On double-tap to foundation, animate card flying
- [ ] Arc trajectory (not straight line)
- [ ] Scale down slightly during flight
- [ ] Landing "pop" effect
- [ ] Sound effect on landing

### 7. Haptic Improvements
- [ ] Light haptic on card pickup
- [ ] Medium haptic on valid drop
- [ ] Error haptic on invalid move attempt
- [ ] Success haptic on foundation placement
- [ ] Heavy haptic on win

## Phase 3: Engagement

### 8. Achievements System
- [ ] Define achievements:
  - "Speed Demon" - Win in under 2 minutes
  - "Lightning Round" - Win in under 60 seconds
  - "Perfectionist" - Win without undo
  - "Streak Master" - 5 game win streak
  - "Unstoppable" - 10 game win streak
  - "Century Club" - Play 100 games
  - "Card Shark" - Win 50 games
  - "No Hints Needed" - Win without hints
  - "Grandma's Favorite" - Win 10 games in a day
- [ ] Achievement unlock animation + notification
- [ ] Achievements view in settings
- [ ] Persist in UserDefaults

---

## Build Order
1. Stats tracking (foundation for achievements)
2. More commentary lines (quick win)
3. Haptic improvements (quick win)
4. Card fly animation
5. Auto-complete with animation
6. Hints system
7. Draw 3 mode
8. Achievements

## Status
- Started: Feb 7, 2026
- Current: Building...
