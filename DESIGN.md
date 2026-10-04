# DESIGN — "+1 Speed Comet Run"

## Pitch
Every second you run, you gain +1 Speed. Use it to break through energy gates on a glowing track across a low-gravity galaxy, collect Wins, upgrade your boots, and rebirth to go even faster.

## Core loop (minute to minute)
1. Run → Speed rises every second you are moving. The server ticks it and checks that you really moved.
2. Reach an **energy gate** showing "⚡ 500". If your Speed ≥ 500, it turns green and you pass through. If not, it stays red and solid.
3. Behind each gate is a **Wins pad**. Step on it for Wins (paid once per lap per stage).
4. Spend Wins on **Boots**, which multiply Speed gain (fixed, listed multipliers, no randomness).
5. At the end of the track, the **Finish pad** gives a big Wins bonus and sends you back to the start for another lap.
6. **Rebirth** once Speed passes a threshold: Speed and Wins reset, boots are kept, and you get a permanent +1x multiplier.

## Progression
- Speed stat (shown) grows multiplicatively. Actual WalkSpeed is `16 + 12·ln(1 + Speed/5)`, capped at 140, so the number gets huge while movement stays controllable.
- Low gravity (Workspace.Gravity 80) gives long, floaty jumps. Crater gaps sit between gates.
- 10 stages across 5 zones (Moon, Mars, Ice Planet, Nebula, Star Core), gate requirements 25 → 100,000.
- Boots: Starter x1, Moon x2 (50 W), Rocket x4 (300 W), Comet x8 (1,500 W), Nova x16 (7,500 W), Galaxy x32 (35,000 W), each with its own trail colour.
- Rebirths: requirement 2,500 × (rebirths+1) Speed; +1x multiplier each.
- Retention: daily streak reward (day n → 25·n Wins, capped at day 7, plus a free 10-minute 2x potion on day 7). Friend boost: +10% speed gain for each friend in the server (max +30%), with an "Invite friends" button.

## Session length
Target 10–20 minutes. Stage 3–4 in the first 8–10 minutes. The full track takes a few sessions without paying.

## First 60 seconds
- 0 s: spawn on a launch pad facing the track. A big arrow/beam points at the first gate, and the HUD says **"Walk to get faster! ⚡ +1 every second"**.
- 5 s: Speed ticks up with a pop animation. The HUD bar fills toward "Gate 1 ⚡25".
- 25 s: gate turns green with a chime, the player runs through, and the hint changes to **"Step on the Wins pad!"**
- 35 s: Wins pad gives +5 with a sparkle and sound. Hint: **"Keep going! Next gate ⚡75"**. After the first Wins, the Shop button pulses once.
- 60 s: the player has seen gain, gate, reward and shop.

## Systems and build order
1. `Config` (shared) for stages, boots and products. `MapBuilder` (server) generates the track, gates, pads, zones, spawn and decorations from Config.
2. `SpeedService`: tick, WalkSpeed, leaderstats. `GateClient`: local gate passability. `PadService`: Wins pads and laps. Void/kill-plane respawn at the last checkpoint. **This is the playable loop.**
3. `DataService`: DataStore with retries, pcall, UpdateAsync, autosave every 60 s, PlayerRemoving, BindToClose.
4. HUD (speed, wins, next-gate bar, hints), Shop (boots), Rebirth, Store (passes/products), all scaled with UIScale.
5. Blender props: asteroid rocks, crystals, gate frame, pad ring, planets. If upload fails, use primitives.
6. Polish: space lighting/sky, particles on gates/pads, tweened UI, generated SFX.
7. `MonetizationService`: game pass checks (with PromptGamePassPurchaseFinished), `ProcessReceipt` with purchase-id dedupe saved in the profile.
8. Onboarding hints and a beam to the next target.
9. Anti-exploit: server-only currency, rate-limited remotes, gate-crossing validation, teleport/speed sanity checks.
10. Daily reward, friend boost, invite button.

## Monetization (no paid randomness anywhere)
Game passes:
| Pass | Price | Benefit |
|---|---|---|
| 2x Speed | 149 R$ | Speed gain ×2, forever |
| 2x Wins | 199 R$ | Wins from pads and finish ×2 |
| VIP | 99 R$ | Gold VIP trail, 1.25x speed gain, [VIP] chat tag |

Developer products:
| Product | Price | Benefit |
|---|---|---|
| Speed Burst | 25 R$ | Instantly gain 5 minutes' worth of your current speed gain (min +250) |
| Skip Stage | 29 R$ | Speed raised to the next gate's requirement and teleport past it |
| 3x Speed Potion (10 min) | 39 R$ | Speed gain ×3 for 10 minutes (stacks duration) |
| Wins Pack S | 49 R$ | +750 Wins |
| Wins Pack L | 149 R$ | +5,000 Wins |

The whole track can be finished without paying. Purchases only speed things up.

## Name, description, icon
- Name: **+1 Speed Comet Run** ("+1 Speed" is the genre's search term; "Comet Run" is the distinctive part).
- Description: "Every second you run = +1 Speed! ⚡ Break through energy gates across a low-gravity galaxy, collect Wins, upgrade your boots and rebirth to become the fastest in space. 10 stages · 5 planets · daily rewards · play with friends for a speed boost!"
- Icon: Blender render of a glowing comet over a ringed planet with a big "+1" in the corner. Thumbnails: Studio/Blender shots of the track, a gate opening, and the boots shop.

## Cut list (in cut order if time runs short)
1. [VIP] chat tag
2. Global leaderboard board (keep in-server leaderstats)
3. Generated SFX (fall back to silence or Roblox-owned library sounds)
4. Blender meshes (fall back to primitive-built props)
5. Meteor hazards
6. Daily reward
7. Friend boost (keep the invite button)
Never cut: core loop, saving, purchases with correct ProcessReceipt, onboarding hints, mobile UI.
