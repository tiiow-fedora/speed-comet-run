# MORNING REPORT V3: grow players (follow-up run 3)

**Live game:** https://www.roblox.com/games/111550268150564/, **place version 32** (Public). Run: 2026-10-04 12:36 → 13:10.
**Rollback:** `backup/last-known-good.rbxl` is a byte copy of the file uploaded as v32 (sha256 prefix `c0e084043dbdedcd`, `backup/manifest.json`), git tag `live-v32`. Earlier good builds: tags `live-v30`, `live-v24`.
I stopped after about 35 minutes because of the 80-turn budget, not the 6-hour clock. Everything in PLAN_V3 is either published or written, and nothing is half-done.

## What changed in the live game (all in v32; previous live v30)
1. **Brighter, distinct map:** daytime blue-violet sky (Atmosphere), a saturated per-zone palette (cool grounds, warm interactive objects), less bloom so neon keeps its color, plus a big warm **comet landmark** (Blender meshes) visible from spawn and a glowing **spawn arch**.
2. **First 60 seconds:**
   - **Comet Shards** (24 pickups along stages 1–3): instant Speed with a burst, sound and "+N ⚡" pop; once per lap, checked on the server.
   - Stage-1 gaps cut to 6 studs, so holding jump no longer drops new players.
   - Hints now ≤ 6 words, with an always-on **"Next: …" goal**.
   - Guide beam removed; the ⬇ marker stays.
   - Gate-open particle burst.
   - **Pad glow cone fixed** (sparkle emitter tamed).
   - Ambient sparkles.
3. **Retention:**
   - 7-day **streak strip** in the Daily panel.
   - **Galaxy progress strip** (15 zone-colored dots).
   - **Next goal** line.
   - **Weekly rotation** from a Config schedule by UTC week (Comet Shower / Wins Rush / Quest Bonus / Speed Week), shown as an 🎉 chip. It changes every Monday with no new build; this week is Wins Rush.
   - Invite button now says **"+10%"** (the existing friend boost).
   - Daily quests and both leaderboards are unchanged from v30.
4. **Discoverability (no build):** 3 new homepage thumbnails + new icon rendered from the real layout; description rewritten to list only real features. Title kept.

**Before / after (map):** `tests/screens/run3/before_spawn_t8s.jpg` (v30: dark floor, black sky) → `tests/screens/run3/after_spawn_live_v32.jpg` (v32: bright sky, lavender floor, comet landmark). Pad before: `before_first_pad_t20s.jpg` (glow cone) → after: `after_pad_fps_live_v32.jpg`.
**Before / after (thumbnails):** run-1 Studio captures `art/thumbs/thumb*_1080p.png` → new `assets/thumbnails/thumb_spawn_hero.png`, `thumb_mars_shards.png`, `thumb_aerial_track.png`. Icon: `blender/out/icon_512.png` → `assets/thumbnails/icon_comet_track.png`.

## Analytics at the start of this run (baseline; **next run must compare against these**)
Creator Hub, 2026-10-04 12:37, about 10.5 h after going public: **0 visits, 0 concurrent players**. Play-through rate, first-session length, D1 retention and revenue all show "--" / "No data for selected period". Audience reach: "Ages 16+ and trusted friends". That's too little to draw any conclusion about gameplay. The zero is most likely a discovery problem (new experience, limited reach, no traffic source).

## What was verified and how
| Check | Result / evidence |
|---|---|
| API key (this run) | universe/place/pass/product/thumbnail reads 200; asset create with empty body 400 (auth OK) — `STATUS.md` |
| DevTest in Studio | **58/58** on desktop, iPhone 7 emulator, and 2-client server. 14 new checks for palette, atmosphere, landmark, shards, weekly events (`tests/release_v3_checklist.log`) |
| Multiplayer | 2 clients: Player2 untouched while DevTest drove Player1 |
| Clean session | 10.4 min, 2 clients, Output only "server ready": 0 errors / 0 warnings |
| Screen sizes | phone 667×375, tablet 1024×768, desktop screenshots in `tests/screens/run3/` |
| Performance | 1,195 map parts (v30: 1,171); decor has no touch/query; live client ~241 FPS on this PC |
| Live v32 | loads; bright map visible; shards → pad "+15 Wins" (2x pass × 1.5 Wins Rush) → gate opened; **all 5 products show the Buy dialog with icons, all 3 passes prompt ("already own" for the owner)**, closed without buying; console `V32 PROMPT SEQUENCE DONE`; server log clean (`tests/live_check_v32.md`) |
| Thumbnails | 9 renders; 3 + 1 chosen with reasons (`THUMBNAILS.md`); uploaded, then **Approved / Active** (API check 13:08); old set now Inactive |
| Icon | uploaded and saved in Creator Hub; pending moderation at upload (`tests/screens/run3/icon_saved_pending.jpg`) |
| Backup = live | backup sha equals the uploaded `game.rbxl` |

## Skipped, approximated or unverified
- **Low-end performance:** no real low-end phone available. The Studio emulator doesn't throttle CPU or GPU, so "frame rate on a low-end profile" is approximated by part count and a ~241 FPS desktop reading.
- **Icon moderation** was still pending at the end of the run. If rejected, the game shows a placeholder icon; re-upload `assets/thumbnails/icon_runner_comet.png`.
- **Thumbnails show a blocky stand-in runner**, not a real avatar render. Everything else is the real track and meshes. Players' avatars will look different.
- **Co-op goal** (server-wide shard target) was not built. "Reason to play with friends" relies on the existing +10% friend boost, now labelled on the Invite button. Still untested with real friends.
- **Weekly events only tested in Studio** (forced with `ForceEvent`); the live game shows this week's Wins Rush. The Monday rollover itself hasn't happened yet.
- Carried over: companions not built; first game-pass purchase untestable on the owner account; cross-server session lock untested; Experience Detail Page thumbnails unconfirmed; console disabled; top-end quest rewards unbalanced.

## What you need to do by hand
1. **Promotion decision (money or your accounts):** the experience has had no impressions. Options that cost money or need your login: Roblox Sponsored Experiences/Ads, or the **refundable publishing fee** to lift the 16+ reach limit. Free outside promotion (YouTube/TikTok clips, Discord) needs your accounts. None of this was done.
2. **API key:** restrict "clde" to this experience and regenerate it (it's still unrestricted and stored in plain text).
3. **Check icon moderation** in Creator Hub → Places → Icon.
4. Optional: Creator Hub → Servers → restart old servers after updates.

## Next 5 improvements, ranked
1. **Get the first players in**, through the reach/fee decision or free outside sharing. Nothing else moves the signals while visits are 0, and only you can do this.
2. **Companions** (UPDATE_PLAN week 1). This is the genre's main collection and status loop, it gives Wins a lasting use, and it's a strong new thumbnail subject.
3. **Thumbnail A/B after 7 days of data.** Compare impressions and qualified plays per thumbnail in Creator Hub and swap in kept renders. Click-through is the first signal.
4. **Co-op shard goal** (server-wide target → everyone boosted). It adds a co-play signal on top of the friend boost and is cheap with the shard system now in place.
5. **Measure the first minute once data exists.** Use Creator Analytics funnels or custom events (shard 1 → gate 1 → pad 1) to find where new players drop, then tune shard spacing and gate 1's requirement in Config.
