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
