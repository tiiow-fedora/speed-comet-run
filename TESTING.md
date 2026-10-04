# TESTING

All tests ran in Roblox Studio against the real place (universe 10769274719), with code synced by Rojo, between 2026-10-03 23:31 and 2026-10-04 00:xx. Evidence is in `tests/` (logs and screenshots).

The automated part is `src/server/DevTest.luau`. It drives a real player through gates, pads, shop, rebirth, falling, finish/lap and every purchase handler, and calls `ProcessReceipt` twice with the same PurchaseId for each product. It runs inside the live server via a Studio-only BindableFunction (`game.ServerScriptService.DevRun:Invoke()`). Requiring the module from the command bar gives a separate module cache with no players loaded, so that route doesn't work.

## Checklist

- [x] **Fresh player joins, understands what to do, completes the loop**
  - Fresh profiles (local-server test accounts Player1/Player2) loaded with Speed 0. The hint banner shows "Every second you get +⚡ Speed! Reach ⚡25 to open the gate (n/25)", and a gold guide beam points at gate 1. When the gate opens, the hint changes to "The gate is open! Run through and step on the 🏆 Wins pad". After the first Wins, the hint becomes "Spend Wins on faster Boots! Tap 👟 BOOTS" and the BOOTS button pulses. The tutorial finishes after the shop is opened and closed. Screens: `tests/screens/tablet_ipad_1024x768.jpg`, `phone_iphone7_hud.jpg`.
  - Real-physics run (no teleports): W+Space crossed the stage-1 and stage-2 gaps, passed gates 1–2, and claimed pads (+10, +10 Wins with the owner's 2x Wins pass). Missing a jump in Mars dropped the character into space, and it was put back on the stage-2 checkpoint after about 1.5 s.
  - DevTest: `gate1 rejects speed 0`, `pad1 pays wins`, `checkpoint=1`, `finish pays`, `finish returns to spawn`, `lap reset`: all PASS (`tests/devtest_run1.log`).
- [x] **Data saves and loads across rejoin**
  - BEFORE_STOP 23:48:24 → Speed 674. Stop (BindToClose save) → new Play → AFTER_REJOIN 23:49:00 → Speed 739 (= 674 + about 20 s at 3x while the saved potion was still active). Wins, Rebirths, Boots and potion time persisted too.
  - Save on leave: same code path (`PlayerRemoving` → `DataService.release`). Autosave every 60 s. Session lock via UpdateAsync with a 180 s timeout.
- [x] **Every purchase handler fires and grants correctly**
  - Studio test purchase of Speed Burst through the real Store UI: the Roblox "test purchase, account will not be charged" dialog → Purchase completed → Speed 949 → 1,722 (+750 = 2.5/s × 300 s). Screen: `tests/screens/purchase_speedburst_studio.jpg`.
  - DevTest calls `ProcessReceipt` twice with the same PurchaseId for all 5 products. Each returns PurchaseGranted both times, state changes after the first call and is unchanged after the second: `receipt <X> granted exactly once` PASS ×5 (`tests/devtest_2player_localserver.log`).
  - Game passes: owner account shows all 3 as OWNED (creator owns their own passes), and the HUD shows the 2x Speed / VIP boosts. Gain is 2.5/s = 1 × 2 × 1.25, which matches the formula. Test accounts show them for sale.
- [x] **No errors in Output during a 10-minute play session**
  - Play session 00:04:46 → 00:15:14 (10.5 min) with real running, jumping, two pad claims, a fall/respawn, and idle time. Output (All Messages, all contexts) contained exactly one line: `00:04:46.907 [CometRun] server ready, 10 stages, track length 4519 - Server - Main:121`. Zero errors, zero warnings. Log: `tests/output_10min_session.log`.
  - Earlier sessions: the only red line ever seen was `DataStoreService: StudioAccessToApisNotAllowed` before Studio API access was enabled. A Rojo plugin warning (`ChangeBatcher`) comes from the Rojo plugin, not game code.
- [x] **UI usable at phone, tablet, desktop**
  - Device Emulator: iPhone 7 (667×375, the smallest preset), iPad 6th gen (1024×768), and the desktop Studio viewport. Phone pass found two bugs, both fixed and re-checked: side buttons overlapped the thumbstick (moved to a 2-column grid top-left and a right column), and the Store panel was cut off (panel height now adapts with a max size). Screens: `phone_iphone7_hud.jpg`, `phone_iphone7_store.jpg`, `tablet_ipad_1024x768.jpg`, `store_panel.jpg`.
- [x] **No exploitable remotes**: see the table below. DevTest checks: `bad boot args ignored` (99, 1.5, "2"), `equip unowned rejected`, `boot rejected when poor`, `rebirth rejected when slow`, `gate1/gate5 rejects` (server teleports back anyone past a gate without the Speed).

## Live game (Roblox client, after publishing and going public)
- [x] v16, 00:47: joined with `roblox://placeId=111550268150564`. The game loaded with saved progress (same DataStore as Studio), the leaderboard showed "tiiow — 30", and the server console (F9 → Server) had only the `server ready` line.
- Bug found live: on desktop the Roblox chat window opens top-left, over the left button grid, and takes the clicks. Fixed in v18: the desktop grid now starts at y=236, below the chat. Touch devices keep the top position because chat is collapsed and the thumbstick owns the bottom-left. Re-checked live on v18: Store opens.
- [x] v18, 00:53: tapped Speed Burst R$25 → the real Roblox "Buy item" prompt appeared with the product icon and price 25. **Closed without buying.** Screen: `tests/screens/live_purchase_prompt_cancelled.jpg`, `live_client_join_v18.jpg`.
- Daily reward: in Studio, the real UI click on CLAIM gave +25 Wins and the toast "Day 1 reward: +25 Wins". DevTest adds `daily ready attr`, `daily pays day 1`, `daily second claim rejected` (DevTest now 30/30, 00:50).

## Multiplayer
- [x] 2-client local server (Test → Server and Clients → Add Clients ×2): both players load independent profiles (Player1 107 Speed, Player2 62 Speed). DevTest driving Player1 left Player2 untouched (62 → 87 from normal ticks). 27/27 PASS. Log: `tests/devtest_2player_localserver.log`.

## Post-report additions (01:05)
- [x] Welcome gift: `DevRun('fresh',1)` → `FRESH Player1 welcomed=true potion=120` (3x Speed for 2 min on a player's first join).
- [x] Server-wide announcements: with 2 clients, DevTest drove Player1 through the finish. Player2's screen showed "Player1 reached the FINISH! 🏁" (`tests/screens/announce_finish_player2.jpg`). DevTest 30/30, Player2 state untouched (Speed 171 from normal ticks).
- [x] Side walls on floor segments (no accidental side falls). Gaps still kill. Run with W+Space stayed on the track.
- [x] Music: `CometMusic` IsLoaded=true, IsPlaying=true, TimeLength=30. MUSIC toggle on the right column.

## Remote audit
| Remote | Client sends | Server validation | Rate limit |
|---|---|---|---|
| BuyBoot | boot index | integer in 1..#Boots, not owned, Wins ≥ cost (server profile) | 3/s, burst 4 |
| EquipBoot | boot index | integer in range, must own | 3/s |
| Rebirth | nothing | Speed ≥ RebirthCost(rebirths) | 1/s |
| ClaimDaily | nothing | server clock: ≥ 20 h since last claim | 1/s |
| RestartLap | nothing | only resets your own lap and teleports you to spawn (gives nothing) | 0.5/s |
| SetSlow | bool | `== true` coerced; only lowers your own WalkSpeed | 2/s |
| TutorialDone | nothing | sets a cosmetic flag | 1/s |
| Notify | server → client only | n/a | n/a |

Live check (00:24): a client-side `Character:PivotTo` jump of ~890 studs from the command bar was caught: `[AntiCheat] tiiow moved 891 studs in 1.1s (allowed 267)`, and the character was rubber-banded back.

Currency and progress never come from the client. Speed is ticked by the server. Wins are paid when the server sees your HumanoidRootPart inside a pad zone, and only if Speed ≥ that stage's requirement. Gate crossings are validated on the server (10 Hz). A 1-second-window horizontal speed check rubber-bands teleport/speed exploits (allowance = 2 × WalkSpeed + 40 studs/s).


# V2 release (v30) checklist, follow-up run
- [x] DevTest 44/44 (Play + phone emulator, 01:47; again with 2 clients, 02:00). Log: `tests/release_v2_checklist.log`
- [x] 2-client local server: independent quests and state per player
- [x] Clean session: 11.5 min with 2 clients + 10 min single client, 0 errors / 0 warnings
- [x] Phone layout (iPhone 7): grid clear of thumbstick, Quests panel fits
- [x] Save migration: v1-format sample save keeps all values, gains v2 defaults; wrong types rejected
- [x] Live v30: loads, core loop, quests, all 5 products + 3 passes prompt (`tests/live_check_v30.md`)
- New checks added for v2: part budget, JUMP signs, decor CanTouch, migration ×3, quests ×7, BestSpeed
