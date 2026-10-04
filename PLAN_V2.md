# PLAN V2 (follow-up run, written 2026-10-04 01:26)

Ranked by expected impact on retention and revenue per hour of effort. Only items I can finish **and test** in this run are planned. There's no analytics data yet (0 visits), so the ranking is based on the genre research and my own playtests, not live metrics.

Releases: **R1** = items 1–3, **R2** = items 4–5, **R3** = items 6–7. Each release runs the full TESTING.md checklist (DevTest in Studio, 2-client local server, phone emulator, 10-min clean session) before publishing, then a live check, then a `backup/last-known-good.rbxl` update.

| # | Item | Why (impact) | Effort | Release | Test added |
|---|---|---|---|---|---|
| 1 | **Rough edges**: guide beam becomes a giant cone near its target → replace with a bobbing arrow marker over the target (beam only when far); tutorial hint goes stale ("gate is open" while already past it) → derive the step from server state; HUD rebuilds boost labels every second → rebuild only on change; product icons missing on 2 prompts → check and re-upload | Confusing first impression; cheap | S | R1 | DevTest + visual |
| 2 | **First 60 seconds**: "JUMP!" floor arrows before the first gaps (stages 1–2); a 3 s camera fly-down of the track on a player's first join; Gate-1 progress explained in the hint | New players stall and fall at the first gap (seen in my own runs) | S | R1 | visual on phone + desktop |
| 3 | **Performance basics**: decorative parts CanTouch/CanQuery off; count parts and report | Low-end phones; touch events on hundreds of decor parts | S | R1 | part count log |
| 4 | **Daily quests**: 3 quests per day from a fixed pool (claim pads, open gates, play minutes, buy boots, rebirth), Wins reward, quest panel with progress bars, red dot when claimable | Strongest cheap D1/D7 driver; gives a reason to return tomorrow; free to earn | M | R2 | DevTest quest progress/claim/reset; save migration test with an old-format profile |
| 5 | **Top Speed leaderboard** (second board beside Top Runners) | Social status for high-speed players; reuses existing OrderedDataStore code | S | R2 | DevTest submit + visual |
| 6 | **Companions** (content): 4 Blender-generated low-poly companions bought with Wins at fixed prices (no randomness), one equipped, follows the player, multiplies Speed gain | Collection + visible status is the genre's main retention driver | M–L | R3 | DevTest buy/equip/validate; migration test |
| 7 | **Discoverability**: new thumbnails showing Galaxy 2 / companions / quests; description updated to list only features that exist | Better click-through; current thumbnails predate new content | S | R3 | visual + API status |

## Cut (with reason)
- **Gifting / trading** — exploit and policy risk (paid item trading must be declared and changes the maturity questionnaire); can't be made safe and tested tonight.
- **PvP / co-op modes** — large scope, can't be tested well with 2 local test clients.
- **StreamingEnabled** — the client finds gates/pads by tag across the whole 7.6k-stud track; streaming would need a rework of Gates/Guide plus device testing I can't do.
- **New Robux products or price changes** — no data to justify changes; existing items must not change for past buyers. Monetization tuning is limited to placement (none needed after review; see DECISIONS).
- **Meteor hazards** (run-1 cut list) — adds frustration to a casual loop; lower value than quests/companions.
- **Private servers / console support** — console needs gamepad UI selection work I can't test without a controller; private-server pricing is a business decision left to the owner.

## Outcome (02:05)
| # | Item | Status |
|---|---|---|
| 1 | Rough edges | **Published v30** (arrow marker, derived tutorial, HUD diffing). The product-icon issue fixed itself (CDN lag; icons show on v30). Pad glow root cause found, but the fix was **cut** (turn budget; see report). |
| 2 | First 60 seconds | **Published v30** (intro fly-down, JUMP signs, jump hints) |
| 3 | Performance basics | **Published v30** (CanTouch/CanQuery off on decor, part count 1,171 logged + DevTest budget check) |
| 4 | Daily quests | **Published v30** (DevTest + 2-client + phone + live) |
| 5 | Top Speed board | **Published v30** |
| 6 | Companions | **Cut**: no turn budget left for another full release cycle (80-turn limit) |
| 7 | Discoverability (thumbnails/description) | **Cut**: same reason; the description still only claims features that exist |

R1 and R2 were merged into one release (v30) to fit the turn budget; see DECISIONS.md.
