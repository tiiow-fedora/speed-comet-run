# Live check of v30 (release v2), 2026-10-04 02:02–02:04
- Joined via roblox://placeId=111550268150564. Server log: `02:01:46 [CometRun] server ready, 15 stages, track length 7614, map parts 1171`, no errors (`run2/v30_live_prompt_sequence_done.jpg`).
- Core loop: W+Space through stage 1, guide marker + JUMP sign visible, pad progress counted (pads quest 2/80); QUESTS button + panel with 3 daily quests (Restart 5x / Play 25 min / 80 pads) (`run2/v30_live_quests.jpg`).
- All purchases prompted from the server console sequence and closed without buying:
  Speed Burst 25 ✅ icon, Skip Stage 29 ✅ icon, 3x Speed Potion 39 ✅ icon, 750 Wins 49 ✅ icon, 5,000 Wins 149 ✅ icon,
  2x Speed / 2x Wins / VIP passes ✅ ("You already own this item. Your account has not been charged."; owner owns them).
  Console: `02:03:26 -- V30 PROMPT SEQUENCE DONE`.
- Previous features still present: Top Runners board, Store/Boots/Rebirth/Daily/Restart, Invite/Slow/Music, HUD.
- Not fixed in this run: Wins pad sparkle particles + bloom form a large yellow glow cone when the camera is near a pad (root cause found 02:03; fix not released, see report).
