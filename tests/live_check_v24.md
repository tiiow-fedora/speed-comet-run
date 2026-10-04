# Live check of v24 (follow-up run step 1.3), 2026-10-04 01:21–01:25
- Joined via `roblox://placeId=111550268150564`; server log: `[CometRun] server ready, 15 stages, track length 7614`, no errors.
- Core loop: W+Space for 5 s → crossed stage-1 gaps, pad paid "+10 Wins!" (2x Wins pass), gate 2 opened (`run2/v24_live_coreloop.jpg`).
- Purchases, prompted from the server developer console (owner-only) and closed without buying:
  - Speed Burst 25 ✅, Skip Stage 29 ✅, 3x Speed Potion 39 ✅, 750 Wins 49 ✅, 5,000 Wins 149 ✅ (Roblox "Buy item" dialog with correct name/price)
  - 2x Speed / 2x Wins / VIP passes ✅ prompted; Roblox shows "You already own this item. Your account has not been charged." (the creator owns their passes)
  - Console: `PROMPT SEQUENCE DONE`, no errors.
- Rough edges seen: guide beam renders as a huge yellow cone when the target is near the camera; 750/5,000 Wins prompts show no icon.
