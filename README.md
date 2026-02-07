# Trash Talk Solitaire 🃏🔥

An iOS Klondike solitaire game with an AI commentator that roasts bad moves and celebrates good ones.

## Concept
"Oh, burying that King? Bold strategy, let's see how that works out..."

## Features
- Classic Klondike solitaire gameplay
- AI move analysis (good/bad/neutral)
- Witty commentary generation
- Text-to-speech roasts
- Sarcastic sports commentator personality

## Tech Stack
- SwiftUI (iOS 17+)
- AVSpeechSynthesizer (TTS)
- Local move analysis engine
- Optional: Groq API for dynamic commentary

## Architecture
- `SolitaireGame/` - Game logic (cards, moves, win detection)
- `Commentary/` - AI analysis + roast generation
- `Views/` - SwiftUI game interface
- `Audio/` - TTS and sound effects
