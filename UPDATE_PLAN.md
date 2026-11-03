# UPDATE PLAN: next 4 weeks (one concrete change per week)

Each week, follow FOLLOWUP2.md's release rules: DevTest + 2-client + phone + 10-min clean session → publish → live check → backup + tag. Compare analytics against the run-3 baseline in FINDINGS_V3.md (0 visits on 2026-10-04).

| Week (Mon UTC) | Auto event (already scheduled in Config, no build needed) | Planned change | Why / success signal |
|---|---|---|---|
| **Oct 5** | Wins Rush (+50% pad Wins) | **Companions v1**: 4 Blender-made companions bought with Wins at fixed prices (no eggs), one equipped, small Speed multiplier, follows the player. Reuse the Boots shop pattern and the `blender/` pipeline. Add DevTest buy/equip/validate and a migration check for a new `Companions` save field | Collection and status loop. Watch D1/D7 retention and session time |
| **Oct 12** | Quest Bonus (quest rewards x2) | **More quests + weekly streak**: 4 new pool entries (rebirth once, buy boots, reach stage 5, collect 30 shards) and a 7-day quest-completion bonus | Gives a reason to come back on D2–7. Watch returning users |
| **Oct 19** | Speed Week (+25% Speed gain) | **Thumbnail test**: swap one homepage thumbnail for a rejected or new render (e.g. a companion shot) and compare impressions/qualified plays in Creator Hub's Thumbnail performance table after 7 days | Click-through. Keep 2–5 active |
| **Oct 26** | Comet Shower (shards x3) | **Shards in every zone + a server-wide shard goal** (co-op: when the server collects N shards, everyone gets a 2-minute boost) | Co-play signal and a reason to play together. Watch friends-joined sessions |

Owner decisions that could change this plan: paying the refundable publishing fee (reach is 16+ only), and any outside promotion (YouTube/TikTok/Roblox ads cost money or need your accounts, so these runs don't do them).


## Status after the v4 cloud-burn session (2026-11-02, branch `claude/cloud-burn`, not published)
| Planned item | State |
|---|---|
| Oct 5: Companions v1 | Built in code, fixed prices in Wins, 5 companions with +10% to +200% Speed gain, persistent (`Pets`, `Pet`), previews in the panel. Models are code-built primitives, not Blender meshes (see MORNING_REPORT_V4.md). Untested in Studio |
| Oct 12: more quests + weekly streak | 9 new quest pool entries (shards, boots, companion, rebirth), a `MinStage` filter so new players never get late-game quests, and the Daily Trio bonus with a 7-day streak (free potion). Untested in Studio |
| Oct 19: thumbnail test | Not done. 4 new candidates are in `promo/renders/`; needs a live Studio-free upload and 7 days of data |
| Oct 26: shards in every zone + server shard goal | Server goal built (shared bar, 1.5x Speed for 2 min). Shards are still only in stages 1-3, so the goal fills slowly past the first zone; extending `Config.ShardStages` is a one-line change but changes map part count and balance |

Next ideas not yet built: shards in every zone, a leaderboard for Rebirths, Blender-made companion meshes (replace `Pets.build`), companion fusion or a second slot as a sink for late-game Wins, a badge set (each costs Robux to create, owner decision).
