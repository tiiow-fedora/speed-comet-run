# DECISIONS

- **23:15 Project location**: `3D Objects/roblox-game/` as its own git repo. `.env` stays in `3D Objects/` (not inside the repo) and `tools/rbx.py` reads it from the parent, so the key can't be committed by accident.
- **23:15 Developer-product scope**: added `developer-product:read` + `write` to the existing key "clde" (not regenerated). Creator Hub showed an "Unrestricted Experience Access" warning. The key was already unrestricted before my edit; I didn't change that.
- **23:45 Concept**: "+1 Speed" escape run. See RESEARCH.md scoring (71 vs 58 for the runner-up). Theme is low-gravity space ("Comet Run") because Keyboard/Snow/Lava/Space/Jetpack variants already exist. Low gravity is the mechanical difference.
- **23:45 No paid randomness**: every purchase has a fixed, stated result. This avoids odds disclosure and the PolicyService alternative path entirely.
- **23:50 Map generated in code at server start** (MapBuilder from Config) instead of hand-built in Studio. It's deterministic, lives in git, is rebuilt by `rojo build`, and needs no GUI work. Trade-off: the edit-mode place looks empty.
- **23:50 Speed number vs WalkSpeed**: the displayed Speed stat grows without limit; WalkSpeed = 16 + 12·ln(1+Speed/5), capped at 140. Physics, camera and mobile controls stay sane.
- **23:50 Gate passability is client-side locally** (CanCollide false only in that player's simulation), but **the server validates every gate crossing** and teleports back anyone past a gate without the Speed. Exploiters can't skip.
- **00:00 Restart-lap button**: added after a playtest showed early players would stall at gates with no Wins source (pads pay once per lap, and the lap only reset at the finish). The balance sim (`tools/balance_sim.py`) gives stage 4 at ~5 min and the finish at ~72 min free (~40 min with 2x Speed).
- **00:10 Leaderboard ranks TotalWins** (monotonic) rather than Speed, which resets on rebirth.
- **00:10 Slow-mode toggle** (WalkSpeed cap 45): at high Speed, auto-jumping overshoots islands. This gives skilled-jump control without nerfing the speed fantasy.
- **00:20 Publishing**: the Open Cloud publish returned `409 Conflict "Server is busy"` 4× while Studio had the Team Create session open. After closing Studio, the first retry succeeded (version 13). Note for the future: close Studio (end the Team Create session) before API publishing.
- **00:21 Max players 20**: typical for the +1-speed genre. The board is per-player, so crowding isn't an issue.
- **01:00 Welcome gift** (3x Speed for 2 min on first join): first-session hook. Gate 2 opens in about a minute for new players.
- **01:05 Server-wide toasts** on finish and rebirth: social proof and a co-play nudge.
- **01:10 Galaxy 2** (stages 11–15, zone "Event Horizon", +2 boots x64/x128): the report's #1 retention item, added as Config data only, since MapBuilder/gates/HUD/DevTest are driven by Config. Sim: stage 11 at ~82 min free (~52 min with 2x Speed). Stages 13–15 are multi-session goals.

## Follow-up run
- **01:26 PLAN_V2 ranking**: rough edges → first 60 s → perf basics → daily quests → Top Speed board → companions → thumbnails. There's no analytics data (0 visits), so the ranking comes from genre research and my own playtests.
- **01:30 Guide**: the beam turned into a screen-filling cone near its target. Replaced with a bobbing ⬇ marker over the target (red = locked gate, gold = go); the thin beam is shown only beyond 70 studs.
- **01:30 Tutorial step derived from server state** (Checkpoint/BestStage/Speed) instead of client events, so the hint can't get stuck on "gate is open" after the player has moved on.
- **01:44 Phone layout check uses screen height (<520 px)** as well as TouchEnabled/KeyboardEnabled. Studio's phone emulator reported a keyboard and put the grid at the desktop position.
- **01:45 Merge R1 + R2 into one release**: the run has an 80-turn budget, and each publish + live check costs ~6 turns. One full checklist pass (DevTest, 2-client server, phone, 10-min session) covers both.
- **01:45 Missing icons on two prompts**: all 5 product icons are "Approved" via the Assets API, so it's a Roblox thumbnail CDN delay. No change made.

## Follow-up run 3 (2026-10-04)
- **12:40 Priorities**: 0 visits means impressions → clicks (thumbnails/icon) and first-minute quality matter most. Retention systems mostly existed (daily, quests, friend boost, boards); I added only the missing visible pieces (streak strip, galaxy progress strip, next goal, weekly rotation).
- **12:42 Daytime "pastel cosmos" look** (Atmosphere + day sky) instead of a black night sky. The brief asks for bright, saturated and inviting; the black sky made the first view dark. Tuned twice: haze 1.2→0.35 and bloom threshold 1.8→2.6 after neon washed out to white.
- **12:42 Comet landmark uses Blender meshes** (CometHead/CometTail/SpawnArch via Open Cloud) and is warm-colored so it stands out against the blue sky.
- **12:42 Stage-1 gaps 6 studs** (were 8–10): in my playtest, holding jump dropped me into stage-1 gaps twice in 20 s.
- **12:42 Comet Shards** are validated by the server (position check, once per lap), reset with the existing lap path, and award Speed only, so there's no new economy or exploit surface.
- **12:42 Weekly events come from a schedule in Config indexed by UTC week**. They rotate every Monday with no new build. Studio can force one with ReplicatedStorage attribute `ForceEvent`.
- **12:42 Guide beam removed**: it still read as a yellow strip; the ⬇ marker is enough.
- **13:05 Thumbnails rendered from the real layout** (Config-driven Blender scene with the game's meshes), so every element exists in the game. 3 homepage thumbnails (within Roblox's 2–5 advice) + 1 icon.
- **13:06 No paid ads or promotion**: forbidden by the brief; listed as an owner decision.
- **13:07 Bash heredocs with emoji/apostrophes failed to parse twice** → switched to writing script files and running them.
