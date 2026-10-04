# PLAN V3: ranked by expected effect on the recommendation signals

Signals: click-through (thumbnail/icon), first-60-s exits and play-through, D1/D2–7 returns, playtime/day, co-play.
Context: 0 visits so far, so **impressions → clicks** (thumbnails/icon) and **first-minute quality** matter most. Everything else only pays off once players arrive.

| Rank | Item | Signal | Scope (smallest testable version) |
|---|---|---|---|
| 1 | **A. First 60 seconds** | early exits, play-through | remove guide beam (keep ⬇ marker); hints ≤ 6 words; stage-1 gaps shrunk to 6 studs (no falls from holding jump); fix pad glow; **Comet Shard pickups** along stages 1–3 (+Speed, sound, sparkle, "+⚡" pop) so there is something to grab every few seconds; gate-open burst effect |
| 2 | **B. Brighter map** | first impression, click→play match | daytime pastel sky via Atmosphere (purple/pink), bold saturated zone palette (cool grounds, warm interactive objects), Blender **comet landmark** visible from spawn + spawn arch, ambient sparkle particles; perf check (part count, FPS on phone profile) |
| 3 | **D. Thumbnails + icon** | click-through | Blender scene rebuilt from Config values + real meshes; 6 thumbnails + 3 icons; pick the best, upload (Thumbnail Personalization API + icon via Creator Hub); title/description review |
| 4 | **C. Retention** | D1, D2–7, playtime | (1) daily streak exists; add 7-day streak strip to the panel; (2) quests exist; add a one-line **"Next goal"** under the gate bar; (3) **galaxy progress strip** (15 stage dots, zone colors); (4) friends: friend boost exists (+10%/friend); make it visible on the Invite button ("+10%"); (5) **weekly rotation** from a schedule in Config chosen by UTC week number (changes weekly with no new build) |
| 5 | **E. UPDATE_PLAN.md** | future runs | 4 weekly updates |

Cut up front: companions (largest scope, needs its own release); co-op modes (can't test with real friends); paid ads/promotion (not allowed: owner decision).
Release plan: one release with A+B+C (full TESTING checklist), then thumbnails (no build needed), then docs.
