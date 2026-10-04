# FINDINGS V3 (2026-10-04 12:36–12:40, live place v30)

## Analytics (Creator Hub, read 12:37) — baseline for the next run
| Metric | Value |
|---|---|
| Visits | **0** |
| Concurrent players | 0 |
| Play-through rate / first-session length / D1 retention | "--", "No data for selected period" |
| Revenue | none |
| Audience reach | "Ages 16+ and trusted friends" |

The game has been public ~10.5 h with **zero visits**. There is no player data at all, so no conclusions about engagement can be drawn. The most likely cause is discovery, not gameplay: a brand-new experience with limited reach (16+ only) and no traffic source gets no impressions. Better thumbnails/icon and a brighter first impression are the levers available without spending money; recommendation exposure itself can't be forced. **Next run: compare against these zeros.**

## New-player playtest (live v30, owner account, timed from window open)
| t | What happened | Problem |
|---|---|---|
| 0–4 s | Window → in game; HUD with 9 buttons + 3 chips + a two-line hint | Busy UI; hint is 20+ words ("The gate is open! Run through, press SPACE to jump the gaps, and step on the pad") |
| 8 s | Spawn view: dark grey-purple floor, black sky, dim planets | **Dark, low-contrast first view**; nothing exciting in sight except the gate frame |
| 8–16 s | Guide beam draws a **wide yellow strip** from the character's feet along the floor | Looks like a glitch |
| ~20 s | First Wins pad: "+10 Wins!" | First reward is fine timing-wise, but the pad shows a **big yellow glow cone** (sparkle particles + bloom) |
| 20–32 s | Holding Space while running → **fell into a stage-1 gap twice** ("Whoops! Back to your checkpoint") | Early gaps punish the most natural input; low gravity makes the overshoot worse |
| 32 s | Reached Mars; strong orange/yellow neon rails | Mars reads better than the Moon start |

Time to understand the goal: about 10 s (the bar "Gate 1 ⚡25" and the gate are clear). Main confusion and boredom risks: dark start, 250 studs of empty floor before the first gate, a long hint, falls, and nothing to collect on the way.

## Carried over (skipped / unverified / cut in earlier runs)
Pad glow (known, unfixed); companions (cut); thumbnails stale (cut); game-pass first purchase untestable for the owner; friend boost / Invite / VIP tag untested; cross-server session lock untested; Experience Detail Page thumbnail unconfirmed; reach limited to 16+; console disabled; quest top-end rewards unbalanced; balance only simulated.
