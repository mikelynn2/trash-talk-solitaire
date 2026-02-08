# Trash Talk Solitaire - Feature Roadmap

**Started:** Feb 7, 2026  
**App Store:** Submitted, awaiting review  
**GitHub:** https://github.com/mikelynn2/trash-talk-solitaire

---

## ✅ Shipped (v1.0)

- [x] Full Klondike solitaire engine
- [x] AI commentator with 80+ lines (roasts, praise, situational)
- [x] British grandmother TTS voice
- [x] Sound effects + haptics
- [x] Smooth card animations + 3D flip
- [x] Stats tracking (games, wins, streaks, best time)
- [x] Hints system with auto-clear
- [x] Epic win screen (confetti, sparkles, trophy)
- [x] Flick gestures + smart drop zones
- [x] Splash screen ("Mike loves Angie")

---

## 🚧 Phase 1: Quick Wins (v1.1)

### 1. Auto-Complete Fly Animation
- [ ] Cards swoosh to foundations one-by-one (0.15s delay each)
- [ ] Arc trajectory with scale-down during flight
- [ ] Landing "pop" effect + sound
- [ ] Grandma: "Finally, let me finish this for you..."
- [ ] Disable interaction during animation

### 2. Undo Snark Escalation
- [ ] Track undo count per game
- [ ] Escalating commentary:
  - 1-2: "Changed your mind, dear?"
  - 3-5: "Again? Commitment issues?"
  - 6+: "At this point, just start over..."
- [ ] Show undo count in stats

### 3. Draw 3 Mode
- [ ] Settings toggle: Draw 1 / Draw 3
- [ ] Fan 3 waste cards visually (offset stack)
- [ ] Only top card playable
- [ ] Persist preference in UserDefaults
- [ ] Grandma: "Oh, feeling brave today?"

---

## 🎯 Phase 2: Engagement (v1.2)

### 4. Vegas Scoring Mode
- [ ] Start at -$52, earn +$5 per foundation card
- [ ] Max payout: $260 - $52 = +$208
- [ ] Optional cumulative bankroll across games
- [ ] Show profit/loss on win screen
- [ ] Grandma comments on gambling habits

### 5. Achievements System
| Achievement | Requirement |
|-------------|-------------|
| Speed Demon | Win in under 2 minutes |
| Lightning Round | Win in under 60 seconds |
| Perfectionist | Win without undo |
| No Hints Needed | Win without hints |
| Streak Master | 5 game win streak |
| Unstoppable | 10 game win streak |
| Century Club | Play 100 games |
| Card Shark | Win 50 games |
| High Roller | Reach +$1000 (Vegas mode) |
| Grandma's Favorite | Win 10 games in one day |

- [ ] Achievement unlock animation + grandma praise
- [ ] Achievements gallery view
- [ ] Persist in UserDefaults

### 6. Themes
- [ ] Card back designs (classic, floral, geometric, dark mode)
- [ ] Table felt colors (green, blue, red, purple)
- [ ] Unlockable via achievements or purchase
- [ ] Preview in settings

---

## 🚀 Phase 3: Social (v1.3+)

### 7. Daily Challenge
- [ ] Same shuffled deck for all players (seeded by date)
- [ ] Global leaderboard (moves, time)
- [ ] "Challenge a friend" share link
- [ ] Special daily badge/streak
- [ ] Requires backend (CloudKit or Firebase)

### 8. Difficulty Analysis
- [ ] Score game difficulty post-win (easy/medium/hard/impossible)
- [ ] Track personal "clutch wins" (games you almost lost)
- [ ] Show difficulty in stats history
- [ ] "That was a tough one!" commentary

### 9. Multiplayer Race
- [ ] Real-time head-to-head (same deal)
- [ ] See opponent's progress bar
- [ ] First to complete wins
- [ ] Grandma trash talks opponent too
- [ ] Requires Game Center or custom backend

---

## 📋 Backlog (Nice to Have)

- [ ] Landscape mode support
- [ ] iPad optimized layout
- [ ] Apple Watch complication (current streak)
- [ ] Siri shortcuts ("Start a solitaire game")
- [ ] Widget showing stats
- [ ] Replay last game
- [ ] Colorblind accessibility (suit patterns)
- [ ] Left-handed mode (flip layout)
- [ ] Custom grandma voice pitch/speed
- [ ] More grandma personas (drill sergeant, valley girl, etc.)

---

## 🐛 Known Bugs

- [ ] Missing cards (50 instead of 52) — debug logging added, needs investigation
- [ ] Occasional card count drift during long sessions

---

## Build Priority (Next Up)

1. **Auto-Complete Fly Animation** — most visible polish
2. **Draw 3 Mode** — classic feature people expect
3. **Undo Snark Escalation** — quick win, more personality
4. **Vegas Scoring** — adds replayability
5. **Achievements** — long-term engagement

---

*Last updated: Feb 7, 2026*
