# MORNING REPORT V4: engagement update (cloud-burn session)

**Branch:** `claude/cloud-burn` (pushed). **Live game:** still v32; nothing was published and no Roblox API was called.
**Environment:** Linux container, no Roblox Studio. Every change below is untested in Studio. `TESTING.md` ("V4 release checklist") lists what to run before publishing.
**Rollback:** nothing to roll back; `backup/last-known-good.rbxl` is still the v32 file. The new profile fields are additive, so v32 saves load unchanged.

## What changed (all in code, grouped by goal)

### More reasons to play and return
1. **Companions (UPDATE_PLAN week 1).** Five companions (Glow Bug, Comet Pup, Star Fox, Nebula Cat, Void Dragon) cost 100 / 800 / 5,000 / 30,000 / 200,000 Wins and add +10% / +25% / +50% / +100% / +200% Speed gain. Fixed prices, no randomness, no Robux. One is equipped at a time; they persist through rebirth. Each client draws every player's companion next to them (3D previews in the new Companions panel, opened from the SHOP button). A one-time nudge appears when the first one becomes affordable.
2. **Server shard goal.** Every Comet Shard anyone collects fills one shared bar (chip under the top bar). When it fills, everyone on the server gets x1.5 Speed gain for 2 minutes. Target is 30 shards, +15 per extra player, max 150. Shards collected during the boost do not count.
3. **Shards in every zone.** v3 had them in stages 1-3 only. Stages 4-15 now have them at 30-stud spacing. Pickup is now swept along Z between the 10 Hz samples, so a runner at 140 studs/s cannot skip over one.
4. **Playtime gifts.** Six free gifts at 3, 8, 15, 25, 40 and 60 minutes played per UTC day (Wins scaled like quests; the 25 and 60 minute gifts add a 3x potion). Progress is saved, so rejoining neither resets nor repeats them. They are in the DAILY panel, now "DAILY & GIFTS", and the DAILY button shows a red dot when one is ready.
5. **Quests.** Nine new quest entries (collect shards, buy boots, adopt a companion, rebirth). A `MinStage` filter keeps late-game quests (Reach the FINISH, Rebirth) away from new players. **Daily Trio:** claiming all three quests in one UTC day pays 2x your best quest reward and starts a streak; the 7th day in a row also gives a free potion.
6. **First-clear bonus.** The first time an account clears a stage, the pad pays its base Wins once more, with a "NEW STAGE" toast.
7. **Social.** Toast when a friend joins ("N friend(s) here! +X% Speed gain"), announcement when someone adopts one of the two top companions, and the shared boost above.

### Brighter, more varied map
8. **Zone sky.** The client eases the Atmosphere haze, decay and ambient light toward each zone's color as you cross gates (`Config.ZoneSky`, 2.5 s tween).
9. **Code-built scenery.** Per stage: two puffy clouds (plus a low one every second stage), six glowing lantern orbs tinted by the zone, and pennant flags beside each Wins pad. All non-colliding, no touch or query. Offline estimate: about 1,640 parts (v3: 1,195), well under the 4,000 DevTest budget.
10. **Juice.** Sparkle bursts on the character for Wins, purchases and the shared boost.

### Monetization (fair, within MONETIZATION.md)
11. No new passes or products (that needs Open Cloud). Store panel now states that everything is optional and nothing is random, and shows what Speed Burst and Skip Stage give you right now.
12. Free **Roblox Premium perk:** +10% Speed gain for Premium members, shown as a chip.
13. Balance (greedy sim, free player): stage 10 at 47 min vs 59 min without companions; stage 14 at 161 vs 379 min. The 2x Speed pass still cuts early-game time by about half.

## How it was checked (no Studio)
`tools/run_checks.sh` runs everything below and passes at the last commit.

| Check | Result |
|---|---|
| `rojo build` | OK (rojo 7.7.1) |
| `selene src` | 0 errors, 0 warnings. Uses `roblox_min.yml` (minimal Roblox globals) because selene's full Roblox std needs a download this session did not make |
| `stylua --check src` | clean (`stylua.toml`: width 200, tabs, LF) |
| Luau compile of all 24 files | OK |
| Server logic harness (`tools/luau_harness/test.lua`) | 40/40. Runs the real `Main.server` plus Gameplay/Shop/Quests/Gifts/Goal/DataService against a Roblox mock and drives the real remotes |
| Client smoke (`client_smoke.lua`) | 30/30. Builds the real HUD, opens every panel in 3 attribute states, clicks every button, checks the texts |
| Real `DevTest.luau` in the mock (`devtest.lua`) | 99 pass, 6 skipped. The 6 need Studio: 5 receipt checks (need a DataStore save) and the Blender-mesh landmark check |

The mock proves syntax and logic, not physics, layout, rendering, real DataStores or Roblox types. Pet models, the HUD layout and the sky tween have never been seen on a screen.

## Renders (Blender 4.0.2 installed in the container)
Four candidates rendered with `blender/thumbnails/render_thumbs.py` (new `v4_*` shots), saved in `promo/renders/`. None uploaded.

| File | Use |
|---|---|
| `icon_v4_foxes.png` | candidate icon (Star Fox close-up; ears cropped at the top) |
| `icon_v4_companion.png` | candidate icon (Comet Pup; orange renders tan) |
| `v4_collection.png` | candidate thumbnail (all five companions under the spawn arch; crop the empty floor) |
| `v4_clouds_aerial.png` | candidate thumbnail (whole track with clouds and orbs) |
| `rejected/v4_hero_companion.png` | rejected: companion shows only a white tail blob |

Details and verdicts are in `THUMBNAILS.md`. The companions in Blender are approximations of the in-game primitives. Real Studio captures will look different.

## What you must test in Studio before publishing
Do these in order. Each step says what to do and what you should get.

1. Run `rojo serve`, open the place, press Play, then run `game.ServerScriptService.DevRun:Invoke()` in the command bar. You get 105 PASS and 0 FAIL in Output. If any of the 6 mock-skipped checks fail (receipts, landmark meshes), those are real failures.
2. Repeat with 2 clients (Test, Clients and Servers), and once in the iPhone 7 emulator. You get the same count and no errors.
3. Open SHOP, press the pink COMPANIONS row. You get five rows with 3D previews. Check that no model is cropped (camera is `cam.CFrame` in `Hud.buildPets`).
4. Give yourself Wins, buy Glow Bug. You get a bug floating beside you that keeps up when you run fast, and a second client sees it too.
5. Open DAILY & GIFTS. You get the streak strip, the claim row and six gift rows with countdowns. Wait 3 minutes (or raise `GiftSeconds`) and claim gift 1. You get Wins; rejoin and the claimed state and timer persist.
6. With 2 clients, collect shards on both until the bar fills. You get the "COMET BOOST" toast on both and a countdown chip.
7. Run through a gate into the next zone. You get a smooth sky color change.
8. Look along the track on desktop and phone. Check that clouds, orbs and pennants do not block the path and the top-bar chips do not overflow when 5 or more show.
9. Check the Output line `[CometRun] server ready ... map parts N` and the phone-emulator frame rate.
10. Load an account that saved on v32. You get all old progress intact and no companion or gift state.
11. After publishing, join live and check that each pass and product still prompts (template: `tests/live_check_v32.md`).

## Unverified without Studio
- Everything visual and everything involving physics or the engine: pet look and follow behavior, ViewportFrame previews, scenery placement and clipping, sky tween, the extra top-bar chips on a phone. Companions live inside the SHOP button, so no 4th row was added to the side grid (a 4th row would have reached the phone thumbstick area).
- Roblox API behavior the mock cannot judge: `Player.MembershipType`, `workspace:GetServerTimeNow()` agreement between server and clients, DataStore round-trip of the new fields, ProcessReceipt.
- Pet models use non-uniform spheres built as Block + SpecialMesh; Ball parts are always round, so this was chosen on purpose but not seen.
- Strict-mode type warnings: the type checker (luau-lsp) was not run; a downloaded binary would not run here. Studio may show script-analysis warnings that the offline checks cannot.
- Balance is simulated only (`tools/balance_sim.py`), and the first-clear bonus and gift rewards are not in the sim.
- Thumbnails and icons were not uploaded; Blender renders use a stand-in runner.

## Decisions for you
1. **Publish v4 after the Studio pass?** The branch is ready to merge for that; nothing else depends on it.
2. **Promotion and reach** (unchanged from V3): zero visits is a discovery problem. The refundable publishing fee and outside sharing (YouTube/TikTok/Discord) are still yours to decide.
3. **Game description:** after publishing, add one line to the Creator Hub description about companions, daily gifts and the shared Comet Boost. Do not mention anything not in the build.
4. **API key:** `clde` is still unrestricted and stored in plain text (from V3). Restrict it to this experience and regenerate.
5. **Optional spend:** badges (cost Robux to create) and a Starter Pack product are listed in `MONETIZATION.md` under "Ideas that need the owner".

## Next improvements, ranked
1. Studio pass and publish (above), then watch D1 and playtime once there are visits.
2. Replace `Pets.build` primitives with Blender meshes uploaded through Open Cloud (the single swap point is `src/client/Pets.luau`) and take real Studio captures for thumbnails.
3. Upload two of the new renders as an A/B test against the v3 thumbnails, then compare click-through after 7 days.
4. A Rebirths leaderboard and a second companion slot or fusion as late-game Wins sinks.
5. Custom analytics events (shard 1, gate 1, first companion, first gift) to find where new players leave.

## Files
New: `src/server/Goal.luau`, `src/server/Gifts.luau`, `src/client/Pets.luau`, `src/client/Ambience.luau`, `tools/luau_harness/`, `tools/run_checks.sh`, `selene.toml`, `roblox_min.yml`, `stylua.toml`, `promo/renders/`. Changed: Config, DataService (new fields only), Gameplay, Shop, Quests, State, MapBuilder, Hud, Main.client, Main.server, DevTest, `blender/thumbnails/render_thumbs.py`, `tools/balance_sim.py`, and the docs (TESTING, STATUS, MONETIZATION, UPDATE_PLAN, THUMBNAILS, DECISIONS). `stylua` also reformatted the existing files (whitespace and wrapping only; four files changed from CRLF to LF).


---

# ROUND 2 (same branch, `claude/cloud-burn`): more content, risk fixes, renders

Still nothing published, no Open Cloud call, master untouched. Everything below is untested in Studio; `TESTING.md` section "V5 additions" lists the steps (12 numbered steps, each with the expected result).

## What changed
**Risk fixes (things the v4 report left open or this review found)**
1. **Top-bar chips could overflow on phones** when 5+ boosts showed (v4 "unverified" item). They now wrap onto a second row (4 per row); the galaxy strip and hint banner moved to make room.
2. **Companion previews used a fixed camera** (v4: "camera framing never seen"). They are now framed from each model's bounding box (`Pets.previewCamera`), with the old camera as a fallback.
3. **"Reach the FINISH" daily quest was offered from stage 6**, which nobody can finish in a day. It now needs stage 19 (the finish is stage 20).
4. **`balance_sim.py` had drifted from the game** (Void Dragon 200,000 in the sim and in the v4 report; the game charges 250,000). The sim now parses `Config.luau`, so it cannot drift.
5. The mock harness gained `typeof` -> "Instance" and a Player class, which the new high-five tests need.

**More to do and keep (all free, fixed rewards, no randomness)**
6. **Aurora Reef**: a 7th zone with stages 16-20 (Req 14M to 400M), its own colors and sky tint, two more boots (Aurora x256 for 4.5M Wins, Infinity x512 for 22M Wins), shards in every new stage. The FINISH is now stage 20 (a lap is about 11,200 studs, up from 7,600). A "Entering <zone>" toast shows when you cross a zone.
7. **Trophies**: 24 achievements (stage milestones, finishes, shards, companions, boots, Daily Trio streaks, playtime, high-fives, first rebirth). Awarded by the server on its tick, each pays Wins scaled like quests; many at once show one toast. Panel: QUESTS -> TROPHIES. Roblox badges are wired but off (`Config.BadgeIds`; creating a badge costs Robux, so that is your call).
8. **Rebirth depth**: after a rebirth you start with 10% of that rebirth's cost as Speed (head start); every 5 rebirths adds +20% Speed gain (star); titles at 1, 3, 5, 10, 15, 25, 50 rebirths, each with a one-time Wins purse and a potion; the title shows as a pink tag in chat. The REBIRTH panel explains all of it.
9. **Social**: high-fives (a prompt over nearby players; both get 15 s of their own gain, double for Roblox friends; server-checked distance, 10 min per pair, 8 per hour per player) and a third leaderboard, "Top Rebirths".
10. **Two more weekly events** (6 now): Companion Craze (companion bonuses x2) and Gift Week (playtime gifts x2). A toast on join names the week's event.

## Balance (python3 tools/balance_sim.py; greedy free player, hours = real play)
| Scenario | Stage 10 | Stage 15 | Stage 20 |
|---|---|---|---|
| free, no companions, no rebirth | 57 min | 334 min | not reached in 24 h |
| free + companions | 46 min | 167 min | not reached |
| + rebirth policy (rebirth when blocked and it gains 15%+) | 32 min | 61 min | 575 min (9.6 h) |
| 2x Speed pass + companions + rebirth | 22 min | 40 min | 300 min |

The early game (stages 1-10) is unchanged. Rebirths are now the main lever for the endgame, which is the intent: they give the 20-stage run a reason to loop. The sim does not model trophies, gifts, quests, shards, events or friends, so real players are faster than this. The 2x pass still roughly halves time to any stage, no more than in v4.

## Checks (last commit)
| Check | Result |
|---|---|
| `tools/run_checks.sh` (rojo build, selene, stylua --check, Luau compile of all 28 files) | ALL PASSED |
| Server logic harness | 73/73 (was 40): config integrity, trophies, rebirth head start/purse/star, both new events, high-fives incl. cooldown, distance, bad targets and hourly cap, finish-quest gating |
| Client smoke | 37/37 (was 30): Trophies panel, rebirth text, high-five prompt and remote |
| Real DevTest in the mock | 106 pass, 6 skipped (same 6 as v4) = 112 total; expect 112 PASS in Studio |
| luau-lsp / strict type warnings | not run (downloaded binary was denied); Studio may still show analyzer warnings |

## Renders (not uploaded; details in THUMBNAILS.md)
- `promo/renders/v4_hero_companion.png`: the rejected companion shot, redone. The camera is now ahead of the runner, so the Star Fox shows its face, ears and nose instead of a white tail.
- `promo/renders/v4_collection.png`: re-rendered with a V formation and a tilted-up camera; the empty floor is down from about 40% to about 18% of the frame.
- `promo/renders/v5_aurora_reef.png`: the new zone; about 40% empty sky, so use it as a detail-page image.
The runner is still a stand-in and the companions are approximations; real Studio captures will differ.

## What needs Studio before publishing (in addition to the v4 list)
The 12 steps in `TESTING.md` "V5 additions". The riskiest ones: the 5 new stages (jump gaps, scenery clipping, phone frame rate; offline part estimate 2,340, v4 1,640, v3 1,195, budget 4,000), the wrapped chip row and the shifted hint banner on the phone emulator, the high-five prompt (ProximityPrompt look, overlap with HUD, mobile tap), the third leaderboard board position, and chat tags.

## Decisions for you
1. **Publish?** Same answer as v4: after the Studio pass. The save format is additive again (`Stats`, `Trophies`), so older saves load.
2. **Part count / phones:** 20 stages add about 700 parts. If the phone emulator drops frames, cut `lanterns` or `clouds` in `MapBuilder.scenery` for stages 11+ first.
3. **Badges:** create badges (Robux) for the five suggested trophies in MONETIZATION.md and fill `Config.BadgeIds`, or leave them off.
4. **Existing players:** anyone who finished the old 15-stage lap now has 5 more stages ahead and gets a burst of trophies (one toast) on their first join. Intended, but say so in the update notes.
5. Still open from before: API key restriction, reach/promotion, game description (add companions, trophies, high-fives, Aurora Reef once published).

## Next improvements, ranked
1. Studio pass, publish, watch D1 and session length.
2. Real Studio captures for thumbnails (the stand-in runner is the weakest part of the renders).
3. Custom analytics events (first shard, first companion, first trophy, first rebirth, zone reached) to see where players leave.
4. A second companion slot as a rebirth-25 reward (free; needs `Pets.luau` to draw two per player).
5. Rebirth shop with permanent Wins sinks.

## Files (round 2)
New: `src/server/Achievements.luau`, `src/server/Social.luau`, `src/client/Social.luau`. Changed: Config (zone, stages, boots, trophies, rebirth, events, high-five), DataService (`Stats`, `Trophies`), Gameplay, Shop, Gifts, Main.server, Leaderboard, Hud, Main.client, Ambience, Pets, Format, DevTest, harness (`mock.lua`, `test.lua`, `client_smoke.lua`), `tools/balance_sim.py`, `blender/thumbnails/render_thumbs.py`, docs (TESTING, MONETIZATION, THUMBNAILS, this file), `promo/renders/`.
