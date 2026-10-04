# RESEARCH

Done 2026-10-03, ~23:20–23:50. All player counts are from pages fetched tonight; most come from rblxdb.com, which says it refreshes every 3 hours and labels its data "October 3, 2026". CCU = concurrent players at fetch time. Anything I could not confirm from a fetched page is marked *unverified* and was not used to decide.

## Sources fetched
- rblxdb top games: https://rblxdb.com/best-roblox-games
- rblxdb genre lists: https://rblxdb.com/best-roblox-games/obby , /tycoon , /simulator
- rblxdb fastest growing (24.9 h window): https://rblxdb.com/charts/fastest-growing
- levelupplay trending (player-to-visit ratio): https://levelupplay.my/charts/trending
- Roblox discovery article (Jun 2026): https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- Paid random items policy: https://create.roblox.com/docs/production/monetization/paid-random-items
- +1 Speed Keyboard Escape structure: https://techwiser.com/1-speed-keyboard-escape-stages/ and search-result summaries (Sportskeeda/GameRant guides)
- Solo earnings write-ups (search summaries, rolearn.dev / endsights.com): power-law distribution; ~85% of developers earn < $100/month. I'm using this only as background.

## What the platform rewards right now
- In 2026, Recommended-For-You switched from a 7-day window to a **28-day retention view**: D1, D2–7 and D8–28 retention, plus session quality, spending and **co-play** (friends joining together). Roblox says it no longer over-rewards "exciting thumbnails" that don't deliver (newsroom, Jun 2026). For a small game, this means the 30-second hook, a reason to come back each day, and something worth doing with a friend count for more than the thumbnail.
- **Paid random items** (eggs, crates or spins paid for with Robux, or with currency that Robux can buy) require every outcome's odds as percentages summing to 100%, luck boosts disclosed numerically, and a PolicyService `ArePaidRandomItemsRestricted` alternative. **Decision: no randomness anywhere in a paid path.** It's simpler, policy-safe, and it rules out any currency-to-egg loop.

## Candidates

| # | Concept | Evidence (fetched 2026-10-03) | Build difficulty, 1 dev / 1 night | Monetization fit | Retention loop | Art/content dependence |
|---|---|---|---|---|---|---|
| 1 | **"+1 Speed" escape run** (speed rises every second; gates/gaps need more speed; wins → multipliers → rebirth) | "[X2] +1 Speed Keyboard Escape" **88,596 CCU, 6.2B visits, 97% like** (#12 overall). "+1 Wings Obby Escape" 2,863 CCU / 56.7M / 88%. "Build a +1 Obby" 4,833 CCU / 91%. Many themed clones (Snow, Hot Lava, Space, Jetpack, Ice Skate…) found on roblox.com, so new entries keep being made and played. | **Low–medium.** Linear course plus a stat tick plus gates. Course can be generated in code. | Strong and natural: 2x speed, 2x wins, skip stage, speed boosts. No randomness needed. | Very strong short loop (understood in 5 s); medium-term loop via rebirth multipliers; daily reward helps D1/D7 | Low: primitives plus a few low-poly props |
| 2 | Steal-a-X creature collection | "Steal An Egg" **1,930,331 CCU**, 6.4B visits, 92%; "Steal a Brainrot" 83,620 CCU / 73.8B | **High.** Base defence, stealing netcode, dozens of creatures | Strong, but leans on random eggs (odds disclosure + PolicyService) | Strong | **High** (many creature models) |
| 3 | 2-player co-op obby | "Grapple Cart Obby" 10,075 CCU / 19.9M / 93%; "Carry the Glass Together" 6,001 / 88%; "Biker Duo" 2,766 / **98%** | Medium–high: physics contraptions, and needs 2 players to test properly | Weak–medium (skips, cosmetics) | Weak after completion; co-play signal is good | Medium |
| 4 | Pet ride / collect sim | "Ride A Pet" **234,977 CCU**, 256.5M visits, 97%, created 2026-04-14 (Rolimons summary) | High (riding, many pets, eggs) | Strong, but random eggs | Strong | **High** |
| 5 | Classic tower obby (Tower of Hell style) | Tower of Hell 28,575 CCU / 29B / **74%** like | Low–medium | Weak (skips, gear) | Medium; low like ratio in the genre | Low |
| 6 | Tycoon | Restaurant Tycoon 3 9,085 / 95%; "Start a Farm!" **+403%** in 24 h (1,192→6,284) | Medium–high (many buttons/droppers to balance) | Strong (2x cash, auto-collect) | Strong | Medium–high (lots of unique builds) |
| 7 | Fishing sim | "Fish It!" 71,863 CCU / 4.8B / 83%; "Heavyweight Fishing" 7.3K / 96% (levelupplay trending #2) | Medium–high (catch minigame, fish table, rod tiers) | Strong, but paid luck boosts = paid random items | Strong | Medium–high (fish art) |
| 8 | "Build a tower / ASMR tower" sandbox | "Build an ASMR Tower" 2,940 / 87.6M / 94%; "[☀️] ASMR Tower" 2,127 / 97% | Medium–high (building system, plot saving) | Medium | Medium | Medium |
| 9 | Clicker simulator | "[⌛4H] Clicker Simulator!" 3,790 CCU / 10.7M / 98% | **Low** | Medium (multipliers) | Medium; very saturated, generic | Low–medium |
| 10 | Silly physics animal sim | "the best flamingo simulator" 13,098 CCU / 7.5M / 95%; "survive simulator" 17,776 / 17.4M / 91% | Medium (custom character controller) | Weak–medium | Unclear (*unverified*: these may be short viral spikes) | Medium |
| 11 | Escape-the-chaser obby | "Escape Angry Head" **+257%** (620→2,361); "BARRY'S PRISON RUN" 15,531 / 61% | Medium (chaser AI, scripted set pieces) | Medium (skips, revives) | Weak after completion; low like ratios | Medium–high (set pieces) |

Not candidates (out of solo-night scope): horror (Dandy's World 213K, DOORS 80K), RPG/anime fighters, FPS, roleplay towns, driving sims.

## Scoring
Weights follow the brief's priority order: finishable ×5, demand/niche ×4, short-session loop ×3, monetization ×2, cheap art ×1. Each criterion is scored 1–5.

| # | Concept | Finishable (×5) | Demand + room (×4) | 30-s loop (×3) | Monetization (×2) | Cheap art (×1) | **Total** |
|---|---|---|---|---|---|---|---|
| 1 | +1 Speed escape run | 5 | 4 | 5 | 5 | 5 | **71** |
| 9 | Clicker sim | 5 | 2 | 5 | 3 | 4 | 58 |
| 5 | Tower obby | 4 | 2 | 5 | 2 | 5 | 52 |
| 6 | Tycoon | 2 | 4 | 3 | 5 | 2 | 47 |
| 2 | Steal-a-X | 1 | 5 | 4 | 4 | 1 | 46* |
| 3 | 2-player co-op obby | 2 | 4 | 4 | 2 | 3 | 45 |
| 11 | Escape-the-chaser obby | 3 | 3 | 4 | 2 | 2 | 45 |
| 7 | Fishing sim | 2 | 4 | 3 | 4 | 2 | 45 |
| 4 | Ride a pet | 1 | 5 | 3 | 4 | 1 | 43* |
| 8 | Build-a-tower | 2 | 3 | 3 | 3 | 3 | 40 |
| 10 | Physics animal sim | 2 | 3 | 4 | 2 | 2 | 40 |

\* Scores well on demand, but finishability of 1 means it can't be built to a polished state tonight.

## Winner: "+1 Speed" escape run, with an original space / low-gravity theme
Why:
- It's the only concept that scores 5 on finishability and loop clarity and also has top-15 evidence (Keyboard Escape: 88.6K CCU, 97% like). The like ratios across the sub-genre are high (88–97%), which suggests players enjoy the format rather than just clicking it.
- Monetization fits without randomness. Every purchase gives a fixed, stated benefit.
- The course can be generated in code, so art is primitives plus a few scripted Blender props.
- Risk: the sub-genre is crowded with themed clones (Keyboard, Snow, Hot Lava, Space, Jetpack, Plane, Ice Skate…), and "+1 Speed Space Escape" already exists. To stand apart, I'm using **low gravity as a real mechanic** (long floaty jumps over crater gaps, with landing as the skill) and an original name, plus two things that target the 2026 discovery signals: a **daily streak reward** (D1/D7 retention) and a **friend boost** (+10% speed gain per friend in the server, up to +30%, plus an invite button) for the co-play signal.
