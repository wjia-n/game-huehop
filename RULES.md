# Hue Hop — RULES.md
_Authoritative rules. If the implementation conflicts with this document, fix the implementation._

## 1. Objective
Bounce a ball upward through as many gates as possible. Each gate is a
full-width bar with a circular hole, painted in one of the game's colors.
Pass through the hole **only when the ball's color matches the gate's color**.

## 2. Setup
- Ball starts resting on a start platform at the bottom of the screen, painted
  in the current theme's floor color, with a random starting color.
- 8 gates are pre-spawned above the start; more spawn as the camera rises.
- Score Attack: 90-second timer, 3 lives. Endless: one life, no timer.

## 3. Turn order
Single-player, real-time. There are no turns: the ball falls under gravity
continuously; every tap is a hop impulse; horizontal drags steer the ball.

## 4. Legal moves
- **Tap** anywhere: hop impulse (sets upward velocity). Legal only while
  playing.
- **Drag** horizontally (or vertically — x is used): steers the ball's x
  position, clamped to the screen with a 24px margin.
- **Grab a swapper orb**: touch it (44px radius) to change the ball's color
  to the orb's color. Orbs always show a color different from the ball's
  current color.

## 5. Illegal moves
- Tapping while paused, during the OOF/splat beat, on the idle card, or on
  the game-over panel does nothing (invalid feedback may play).
- Dragging while not playing does nothing.

## 6. Captures
N/A — no capturing in Hue Hop.

## 7. Special rules
- **Gate crossing** is evaluated when the ball moves upward through a gate's
  y-plane (`prevY > gate.y && ballY <= gate.y`).
  - Success: ball inside the hole (distance from hole center < hole radius)
    AND ball color == gate color → +1 score, combo +1, celebration burst,
    "+1"/"PERFECT +1" popup, ding sound.
  - Failure: ball outside the hole ("Missed the hole!") or color mismatch
    ("Wrong color!") → OOF/splat (see §8).
- **Combo**: consecutive successful gates. Every 5th consecutive success
  awards +2 bonus points and a "COMBO xN!" popup with a fanfare.
- **Swapper orbs** appear in every second gate gap. Picking one up swaps the
  ball color and shows a "SWAP!" popup.
- **Drifting gates** (Zippy/Wild): hole x oscillates sinusoidally around its
  base position. Hole position is a pure function of sim time (deterministic).
- **Score Attack**: 3 lives. A failure with lives remaining triggers the OOF
  beat: 0.9s pause, lose one life, combo resets, ball respawns at 25% of the
  screen height with a fresh random color. When the timer hits 0, the run
  ends ("Time's up!") and the score is recorded.
- **Endless**: any failure is a terminal splat: 1.2s splat beat, then game
  over.
- **Speed ramp**: gravity and hop impulse scale slightly with score
  (endless mode ramps difficulty as you climb).

## 8. Scoring
- +1 per correctly passed gate.
- +2 bonus every 5th consecutive perfect gate (combo).
- Best score is stored per (mode, difficulty): `best_<mode>_<difficulty>`.
- A run that beats the stored best is a NEW BEST (fanfare + record).

## 9. Winning conditions
Hue Hop is a score-attack arcade game: there is no final win state.
In Score Attack, surviving the full 90 seconds with a high score is the goal;
a NEW BEST is the victory moment (fanfare + review prompt).

## 10. Draw conditions
N/A.

## 11. AI strategy
N/A — single-player arcade, no opponents.

## 12. Edge cases
- Ball falls below the screen → treated as a gate failure ("You fell!").
- Two gates can never occupy the same y: spacing is fixed per difficulty.
- Orb positions are clamped inside the screen; orb color never equals the
  ball's current color at spawn.
- App backgrounding pauses the run (engine phase → paused); music pauses
  and resumes on return.
- If the sim timer ever dies (stale > 3s), the watchdog restarts it; if an
  OOF/splat one-shot dies, the watchdog completes the transition. No stuck
  states are possible by construction.
- Pause menu: Resume / Restart / Quit. Restart begins a fresh run; Quit
  returns to the menu.

## 13. Test cases
1. Tap → ball hops, boing sound, particle puff. ✓
2. Drag → ball steers horizontally, clamped at edges. ✓
3. Pass matching gate through hole → +1, popup, ding, gate dims. ✓
4. Pass gate with wrong color → splat beat → (Endless) game over panel;
   (Attack, lives left) OOF → respawn, lives −1. ✓
5. Miss hole entirely → same failure path as wrong color. ✓
6. Grab orb → ball color swaps, "SWAP!" popup, sparkle. ✓
7. 5 consecutive perfect gates → +2 combo bonus, fanfare, "COMBO x5!". ✓
8. Score Attack: timer counts down, last 5 seconds tick, at 0 → "Time's up!"
   panel with final score. ✓
9. New best → fanfare + "NEW BEST!" + review prompt (graceful off-Play). ✓
10. Pause → sim freezes; Resume continues; Restart resets score; Quit → menu. ✓
11. Wild difficulty locked without PRO (menu shows lock, tap explains). ✓
12. PRO themes/balls/gates locked without PRO; purchase (when Play Console
    products exist) unlocks and persists. ✓
