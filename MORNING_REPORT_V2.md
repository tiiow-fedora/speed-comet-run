# MORNING REPORT V2: follow-up run

**Live game:** https://www.roblox.com/games/111550268150564/, **place version 30** (Public). Run: 2026-10-04 01:20 → ~02:06.
**Rollback point:** `backup/last-known-good.rbxl` is a byte-for-byte copy of the file uploaded as v30 (sha256 prefix `6b1f0634ca717bc5`, `backup/manifest.json`), git tag `live-v30`. The previous good build is tag `live-v24`.

I stopped early because of the run's 80-turn budget, not the 6-hour clock. Each Studio test + publish + live-check cycle costs about 10–15 turns, so I shipped one well-tested release (R1+R2 merged) instead of risking an untested third.

## What changed in the live game
All of this shipped in **v30** (previous live: v24):
1. **Guide marker:** a bobbing ⬇ arrow over the next gate (red = locked) or pad (gold). The thin guide beam now shows only when the target is more than 70 studs away.
2. **Tutorial hints follow real progress** (checkpoint / best stage / Speed), so they can't get stuck on "the gate is open". Hints now say how to jump: "press SPACE" on keyboard, "tap ⬆" on touch.
3. **First-join intro:** a 3-second camera fly-down of the track with the welcome-gift toast.
4. **"⬆ JUMP! ⬆" floor signs** before the first crater gap of stages 1 and 2.
5. **Daily quests:** 3 per UTC day, one from each tier (e.g. step on 15/40/80 pads, play 10/25 minutes, restart 5 laps, reach the FINISH). Progress is counted only by the server. Wins rewards scale with your best stage. Quest panel with progress bars, a red dot on 📜 QUESTS when something is claimable, and a "Quest complete" toast.
6. **⚡ TOP SPEED board** (new OrderedDataStore `CometRun_TopSpeed_v1`, using a new `BestSpeed` save field) beside the existing Top Runners board.
7. **Performance:** all non-colliding map and decor parts (including the 700+ Blender rocks and crystals) now have CanTouch and CanQuery off; the map is 1,171 parts. The HUD boost row is updated in place instead of being rebuilt every second.
8. **Phone layout detection** also checks screen height (< 520 px), since Studio's phone emulator reports a keyboard.

**Save data:** the DataStore name and existing fields are unchanged. New fields (`BestSpeed`, `QuestDay`, `Quests`) are filled with defaults for old saves by the existing `reconcile()` path, which is tested with a v1-format sample save. Purchases, passes and prices are unchanged.

## What I verified and how
| Check | Evidence |
|---|---|
| API key re-test this run | `STATUS.md` "Step 1": all read endpoints 200; create endpoints 400-validation (auth OK) |
| Analytics | Creator Hub overview: 0 visits, no retention/revenue data. **Too little data to conclude anything**, so none drawn. |
| Live v24 before changes | core loop + all 8 purchase prompts (`tests/live_check_v24.md`, `tests/screens/run2/v24_*`) |
| DevTest (Studio, in-server) | **44/44 PASS**. New checks: part budget, JUMP signs, decor CanTouch off, migration keeps v1 values / adds v2 defaults / rejects wrong types, quest generation (3, one per tier), pad/play progress, claim pays, double/unfinished/out-of-range/string claims ignored, quest attribute sync, BestSpeed tracking |
| 2 clients, local server | separate quests per player; DevTest on Player1 left Player2 untouched (`tests/release_v2_checklist.log`) |
| Clean session | 11.5 min with 2 clients and 10 min single client: Output had only the "server ready" line, **0 errors / 0 warnings** |
| Phone (iPhone 7 emulator) | grid clear of the thumbstick, Quests panel fits (`run2/r1_phone_iphone7.jpg`, `run2/r2_quests_phone.jpg`) |
| Live v30 after publish | loads, server log clean, core loop + quests work, **all 5 products prompt (with icons) and all 3 passes prompt** ("already own" for the owner), all closed without buying (`tests/live_check_v30.md`) |
| Backup = live | `backup/last-known-good.rbxl` sha256 equals the uploaded `game.rbxl` (`6b1f0634ca717bc5`) |

## Skipped, approximated or unverified
- **PLAN_V2 items 6–7 cut** (companions; new thumbnails/description). Reason: turn budget. Both need another full release cycle.
- **Yellow glow over Wins pads is not fixed.** I found the cause this run: the pad's sparkle ParticleEmitter (LightEmission 1) plus bloom makes a large yellow cone when the camera is near a pad. My first-run guess that it was the guide beam was wrong. Fix: in `MapBuilder.pad()` set Rate ≈ 5, Size `NumberSequence.new(0.4, 0)`, LightEmission ≈ 0.3, Speed 2–4. It wasn't released because it needs a full test cycle I couldn't fit.
- **Game-pass purchase flow** is still only "already own" for the owner. A first-time pass purchase can't be tested on this account.
- **Quest balance:** rewards at the top end are large (e.g. "Play 25 min" = 4 × 1,000,000 Wins at stage 15). They're tied to the player's best stage pad, but untested with real players.
- **Old servers:** if a v24 server is still running when a player with v2 data joins it, v24 saves without the new fields, so quest progress and BestSpeed would reset. No other data is affected. Roblox migrates servers on publish, but I didn't use "shut down all servers".
- **The tutorial for already-progressed test accounts** jumps straight to the "buy boots" step. That's intended (it's derived from progress).
- Carried over from run 1, still unverified: friend boost, Invite, VIP chat tag, cross-server session lock, Experience Detail Page thumbnail, reach limit (16+), console disabled.

## What you need to do by hand
1. **API key** "clde": still unrestricted and stored in plain text in `3D Objects/.env`. Restrict it to this experience and regenerate it.
2. **Reach:** Creator Hub still shows "Ages 16+ and trusted friends". Lifting that needs engagement, or the refundable publishing fee (your decision; nothing paid).
3. **Optional:** Creator Hub → Servers → "Restart servers for updates", so no v24 servers linger (see the old-servers note).
4. **Payouts/DevEx** setup and the Experience Detail Page thumbnail check (from run 1) are still open.

## Next 5 improvements, ranked
1. **Fix the pad glow** (the 10-minute change above). It's the most visible rough edge, every new player sees it at the first pad, and it costs almost nothing.
2. **Companions bought with Wins (fixed price, no eggs).** This is the genre's main collection and status loop, and it gives quest Wins a lasting use. The Blender pipeline (`blender/props.py`) and the Boots shop pattern are already in place.
3. **Fresh thumbnails + description** showing quests, Galaxy 2 and the arrow guide. The current homepage thumbnails predate both content updates, and click-through matters most while the audience is small.
4. **Quest variety and a weekly streak bonus.** More pool entries (rebirth, buy boots, reach stage N) and a 7-day completion bonus. It's cheap with the new Quests module and directly targets D2–D7 retention.
5. **Use the analytics once there are ~100+ visits.** Check D1 retention and where players stop (BestStage distribution via a DataStore/analytics event), then tune `Config.Stages` and quest targets. Without data, every balance change is a guess.
