# DECISIONS

- **23:15 Project location**: `3D Objects/roblox-game/` as its own git repo. `.env` stays in `3D Objects/` (not inside the repo) and `tools/rbx.py` reads it from the parent, so the key can't be committed by accident.
- **23:15 Developer-product scope**: added `developer-product:read` + `write` to the existing key "clde" (not regenerated). Creator Hub showed an "Unrestricted Experience Access" warning. The key was already unrestricted before my edit; I didn't change that.
- **23:45 Concept**: "+1 Speed" escape run. See RESEARCH.md scoring (71 vs 58 for the runner-up). Theme is low-gravity space ("Comet Run") because Keyboard/Snow/Lava/Space/Jetpack variants already exist. Low gravity is the mechanical difference.
- **23:45 No paid randomness**: every purchase has a fixed, stated result. This avoids odds disclosure and the PolicyService alternative path entirely.
- **23:50 Map generated in code at server start** (MapBuilder from Config) instead of hand-built in Studio. It's deterministic, lives in git, is rebuilt by `rojo build`, and needs no GUI work. Trade-off: the edit-mode place looks empty.
- **23:50 Speed number vs WalkSpeed**: the displayed Speed stat grows without limit; WalkSpeed = 16 + 12·ln(1+Speed/5), capped at 140. Physics, camera and mobile controls stay sane.
- **23:50 Gate passability is client-side locally** (CanCollide false only in that player's simulation), but **the server validates every gate crossing** and teleports back anyone past a gate without the Speed. Exploiters can't skip.
