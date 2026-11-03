# STATUS

Started: 2026-10-03 ~23:15 local. Project dir: `3D Objects/roblox-game` (`.env` lives one level up in `3D Objects/`, read by `tools/rbx.py`; never printed).

## Local tools
| Tool | Result |
|---|---|
| Rojo | `rojo --version` → Rojo 7.6.1 ✅ |
| Blender | not on PATH; found `C:\Program Files\Blender Foundation\blender.exe` → Blender 5.1.2 ✅ (call by full path) |
| Roblox Studio | installed, `RobloxStudioBeta.exe` already running ✅ |
| `.env` | has ROBLOX_API_KEY, UNIVERSE_ID=10769274719, PLACE_ID=111550268150564 ✅ |
| git / python | available ✅ |

## Open Cloud key tests (2026-10-03)
Docs used: create.roblox.com/docs/cloud/reference/features/universes, /docs/cloud/reference/domains/apis.
| Capability | Request | Result |
|---|---|---|
| Key valid / universe read | GET /cloud/v2/universes/{U} | 200 ✅ (universe "Untitled Experience", PRIVATE, owner user 418736264) |
| Place read | GET /cloud/v2/universes/{U}/places/{P} | 200 ✅ |
| Universe write (name/description) | PATCH with bogus updateMask | 400 validation (auth passed) ✅ |
| Place publishing | POST /universes/v1/{U}/places/{P}/versions with empty body | 500 (not 401/403 → scope present; proper test at publish time) ⚠️ likely OK |
| Game pass read | GET /game-passes/v1/universes/{U}/game-passes/creator | 200 ✅ (none exist) |
| Game pass write | POST create with no fields | 400 "Name required" (auth passed) ✅ |
| Developer product read/write | GET list / POST create | initially 403 "Scope not authorized"; added developer-product:read+write to existing key `clde` in Creator Hub 23:15 → now 200 / 400-validation ✅ |
| Asset upload | POST /assets/v1/assets with no fields | 400 "FileContent required" (auth passed) ✅ |
| Asset operation read | GET /assets/v1/operations/{fake} | 404 not found (auth passed) ✅ |

Note: Creator Hub showed an "Unrestricted Experience Access" warning on save — the key already had no experience restriction (pre-existing). Recommend restricting it to this experience (see MORNING_REPORT).

**All needed capabilities confirmed. Proceeding to Phase 1.**

## Current phase (final, 2026-10-04 01:13)
**Done.** Live place version 24 is PUBLIC (https://www.roblox.com/games/111550268150564/). See MORNING_REPORT.md.

Works: core loop (15 stages, 6 zones, 8 boots), saving, HUD/shop/rebirth/store/daily, leaderboard, onboarding, mobile layout, 3 passes + 5 products, anti-exploit. DevTest 30/30. Live join verified for v16, v18, v20, v24.
Blocked: reach limited to 16+/trusted friends until engagement threshold or publishing fee (user decision). Experience Detail Page thumbnail unconfirmed.


# FOLLOW-UP RUN (started 2026-10-04 01:20)

## Step 1 take stock
**API key re-test (01:20, this run):** key valid. universe read 200 (PUBLIC, "+1 Speed Comet Run"), place read 200, game-pass read 200 (3 passes), dev-product read 200 (5 products), asset create / game-pass create / dev-product create with empty bodies → 400 validation (auth OK), thumbnail-personalization read 200. All capabilities needed for this run work.

**Analytics (Creator Hub overview, 01:22):** 0 visits; D1 retention, new users, playtime, DAU, revenue all "--" ("No data for selected period"). Audience reach: "Ages 16+ and trusted friends". Too little data to mean anything; no conclusions drawn.

**Backup:** `backup/last-known-good.rbxl` = rojo build of the source published as v24 (manifest in `backup/manifest.json`), git tag `live-v24`.

**Skipped/unverified items carried over from run 1:** reach limited (needs fee/engagement); Experience Detail Page thumbnail unconfirmed; game-pass purchase flow untestable for the owner (owns all passes); friend boost + Invite + VIP chat tag untested; cross-server session lock untested; balance only simulated; meteor hazards (cut list) not built; thumbnails upscaled Studio captures; console disabled; owner/test-account saves hold test data.

## Follow-up status (final, 02:06)
Live **v30** verified; backup = exact v30 bytes (tag live-v30). Done: PLAN_V2 items 1–5. Cut: 6–7 (turn budget). Blocked: nothing; reach limit still needs the owner's decision.


# FOLLOW-UP RUN 3 (started 2026-10-04 12:36)
**API key test (12:36, this run):** universe read 200 (PUBLIC), place read 200, game-pass read 200, dev-product read 200, thumbnail-personalization read 200 (3 thumbnails), asset create with empty body 400 (auth OK). All capabilities needed work.
**Analytics 12:37:** 0 visits, no engagement/retention/revenue data ("No data for selected period"); reach 16+ and trusted friends. Too little data for conclusions.
**Backup:** live = v30 = `backup/last-known-good.rbxl` (sha 6b1f0634ca717bc5); git tag `run3-start`.
**Current item:** A (first 60 s) + B (bright map) + C (retention) as one release.

**13:08 status:** live v32 verified (A+B+C released). Thumbnails/icon uploaded (pending moderation). UPDATE_PLAN.md written. Next: report.


# CLOUD BURN SESSION (v4), started 2026-11-02, branch `claude/cloud-burn`
Environment: Linux container, no Roblox Studio, nothing published, no Open Cloud calls. Live game is still v32.
**Tools installed:** rojo 7.7.1, selene 0.31, stylua 2.6 (cargo), Blender 4.0.2 (apt), and a Luau test harness built in `tools/luau_harness` (mlua with vendored Luau).
**Built:** Companions (5, bought with Wins), server-wide shard goal (shared boost), playtime gifts, Daily Trio quests + streak, 9 new quests with a stage filter, first-clear stage bonus, friend-joined toast, free Premium perk, zone sky ambience, code-built scenery (clouds, lantern orbs, pennants), companion purchase nudge, store transparency text.
**Checks:** `tools/run_checks.sh` passes (rojo, selene, stylua, compile, 3 harness runs). Not run in Studio.
**Renders:** 4 Blender candidates in `promo/renders/` (see THUMBNAILS.md). Not uploaded.
**Next:** Studio pass per TESTING.md "V4 release checklist", then publish.
