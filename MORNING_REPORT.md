# MORNING REPORT: +1 Speed Comet Run

**Live game:** https://www.roblox.com/games/111550268150564/ (universe 10769274719, place version 24, visibility **Public**)
**Repo:** `C:\Users\user\3D Objects\roblox-game` (git, 20+ commits; `.env` stays one folder up and is not in the repo)
**Run time:** started 2026-10-03 ~23:10; all phases done by ~01:00; post-report additions until ~01:12 (welcome gift, server announcements, Galaxy 2). Each one was tested in Studio (DevTest 30/30) and checked live before this report was finalized.

## What was built
A "+1 Speed" incremental runner with an original low-gravity space theme. Research picked this genre because it's the only finishable-in-one-night concept with top-chart evidence: "+1 Speed Keyboard Escape" had 88.6K concurrent players and a 97% like ratio on 2026-10-03 (`RESEARCH.md`).

- **Loop:** Speed +1 every second (×multipliers) → energy gates need ⚡25 … ⚡100,000 → Wins pads behind each gate → spend Wins on 8 boots (x1–x128) → finish pad gives a big bonus and starts a new lap → rebirth for +1x permanent. RESTART button re-runs early pads to farm Wins.
- **World:** 15 stages over 6 zones (Moon, Mars, Ice Planet, Nebula, Star Core, and "Galaxy 2": Event Horizon). Generated in code at server start (`src/server/MapBuilder.luau`), with Gravity 80 for floaty jumps over crater gaps, Blender-made rocks/crystals, background planets and a starfield.
- **Systems:** welcome gift (3x Speed for 2 min on first join), server-wide toasts on finish/rebirth, DataStore saving (retries, UpdateAsync, session lock, autosave, BindToClose), HUD with next-gate progress bar, Boots/Rebirth/Store/Daily panels, daily streak reward, friend boost (+10% per friend, max 30%), invite button, global Top Runners board (OrderedDataStore), slow-mode toggle, music toggle, onboarding hints + guide beam, mobile layout.
- **Monetization (`MONETIZATION.md`):** 3 passes (2x Speed 149, 2x Wins 199, VIP 99) and 5 products (Speed Burst 25, Skip Stage 29, 3x Potion 39, 750 Wins 49, 5,000 Wins 149). All were created through Open Cloud with generated icons. **No paid randomness anywhere.** `ProcessReceipt` stores the PurchaseId and saves before returning PurchaseGranted, and rolls back on save failure.
- **Assets (`ASSETS.md`):** all original. 4 Blender meshes, 6 synthesized SFX and a synthesized music loop (Python math, no samples), a Blender icon, PIL pass icons, and Studio-screenshot thumbnails. No Creator Store assets.
- **Experience settings:** name, description, genre (Simulation › Incremental Simulator), max players 20, icon, 3 homepage thumbnails (personalization on), maturity questionnaire → **Minimal**, access age All Ages.

## What was verified and how (details and evidence in `TESTING.md`, `tests/`)
| Check | How | Result |
|---|---|---|
| Open Cloud key + scopes | read-only GETs and invalid-body writes (`STATUS.md`) | all needed scopes work; developer-product scope was missing and was added to the existing key |
| Core loop, gates, pads, laps, falling, shop, rebirth, daily, all 5 product handlers, receipt grant-once | `DevTest` inside the live Studio server | **30/30 PASS** (latest run 00:59) |
| Real physics | ran and jumped through stage 1–2 in Play | gaps jumpable, pads paid, fall → checkpoint |
| Save/load across rejoin | stop/play with Speed logged before and after | 674 → 739 (expected with potion active) |
| Studio test purchase via UI | Speed Burst through the real Store button | granted +750 Speed |
| 10-minute session | Output copied after 10.5 min of play | **0 errors, 0 warnings** |
| 2 players | Studio local server, 2 clients | independent profiles, DevTest 27/27 with player 2 untouched |
| Phone / tablet | Device Emulator iPhone 7 667×375, iPad 1024×768 | two layout bugs found and fixed, then re-checked |
| Exploits | remote audit table + DevTest bad-argument checks + a live client-side teleport attempt | server rejected bad args; anti-cheat rubber-banded an 891-stud client teleport |
| Live game | joined from the Roblox client (v16 and v18) | loads, data persists, Store opens, **real purchase prompt appears (closed without buying)** |

## Skipped, approximated or unverified (plain list)
1. **Reach is limited.** Creator Hub → Audience reach says a new experience is "limited to 16+ users and trusted friends" until it has enough highly engaged players, or until a refundable publishing fee / 50,000 R$ expedited-review fee is paid. I did not pay anything (rule: no real-money spending). Under-16 players may not see the game for now.
2. **Experience Detail Page thumbnail:** the Creator Hub uploader did not register files from automation. Homepage thumbnails were uploaded through the Thumbnail Personalization API (approved, active), but I could not confirm what the detail page shows.
3. **Game-pass purchase flow** was not testable: your account owns its own passes (the creator always does), so `PromptGamePassPurchaseFinished` has only been code-reviewed. Pass *effects* were verified (gain = 1 × 2 × 1.25 = 2.5/s).
4. **Friend boost and Invite button** are untested: Studio test accounts aren't friends, and invites don't work in Studio. The VIP chat tag is untested with a second player.
5. **Session lock across two real servers** is untested (needs two live servers). BindToClose saving was only tested by stopping Studio.
6. **Balance** comes from `tools/balance_sim.py` (stage 4 at ~5 min, stage 10 at ~59 min, stage 11 at ~82 min free; stages 13–15 are multi-hour goals), not real players. Galaxy 2 visuals were only checked from a fly-by camera, since the anti-cheat correctly blocks teleporting a low-Speed character there.
7. **Cut from the design:** meteor hazards. Everything else on the cut list was built.
8. **Thumbnails** are Studio captures (1112×626) upscaled to 1920×1080, so they're slightly soft.
9. **Music** asset was still "Reviewing" at 00:58. If moderation rejects it, the game simply plays no music (no errors). The SFX are approved.
10. **Your in-game progress is test data.** The owner profile was reset with a Studio-only hook and then played during QA, so its numbers are test values. Player1/Player2 entries (UserIds -1/-2) exist from local-server tests. It's harmless, but wipe it if you want a clean leaderboard. The leaderboard currently shows "tiiow".
11. Console is disabled in device access (the UI isn't gamepad-navigable yet).

## Things you need to do by hand
1. **API key hygiene (important).** The key in `3D Objects/.env` is a plain-text file, and the key has **no experience restriction** (Creator Hub warned "Unrestricted Experience Access" when I added the developer-product scope). In Creator Hub → Open Cloud → API Keys → "clde": restrict it to this experience and remove scopes you don't need (legacy-*, asset-permissions, universe-place-instances…). Consider regenerating it, since it has been read by an AI session.
2. **Reach decision:** decide whether to pay the refundable publishing fee in Creator Hub → Audience → Reach to unlock under-16 audiences sooner.
3. **Payouts:** DevEx and payouts need your identity/tax setup in Creator Hub → Finances (not touched).
4. **Check the Experience Detail Page thumbnails** in Creator Hub → Places → Thumbnails; upload `art/thumbs/*_1080p.png` there if empty.
5. **Optional:** enable paid private servers (Creator Hub → Access settings) for extra revenue and co-play; I left them off. The Rojo Studio plugin has an update (7.7.1).

## Next 5 changes most likely to improve retention and revenue (ranked)
(Galaxy 2, the welcome gift and server announcements were added after the first draft of this list. These are what's left.)
1. **Pets/companions bought with Wins (fixed price, no eggs)** that add multipliers and follow the player. Collection plus visible status is the strongest retention driver in the genre. Keeping it non-random stays clear of paid-random-item rules.
2. **Time-limited events** (weekend 2x Wins, a rotating "comet shower" stage with an exclusive trail). This gives a reason to return on D2–D7, which the 28-day discovery signal rewards, and a natural slot for a limited pass.
3. **Better first 60 seconds:** a 3-second camera fly-down of the track on first join, treadmills on the spawn pad so Speed visibly climbs while you stand still, and a clearer first gap (arrow decal "JUMP!"). Then measure D1 in Creator Analytics and tune `Config.Stages` (all balance lives there).
4. **Gift passes + Speed leaderboard:** let players buy 2x Speed for a friend in the server, and add a second board for highest Speed. Co-play is an explicit discovery signal, and gifting adds a second purchase path.
5. **Paid private servers + console support:** enable private servers (cheap, e.g. 50 R$/month) for groups of friends, and make the side buttons gamepad-selectable so Console can be turned on in Access settings.
