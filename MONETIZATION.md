# MONETIZATION

Created 2026-10-03 ~23:46 via Open Cloud (`POST /game-passes/v1/universes/{U}/game-passes`, `POST /developer-products/v2/universes/{U}/developer-products`). IDs are wired into `src/shared/Config.luau`. **No paid randomness:** every item gives a fixed, stated result.

## Game passes
| Key | Name | Price | Pass ID | Benefit | Code |
|---|---|---|---|---|---|
| Speed2x | 2x Speed | 149 R$ | 2006253072 | Speed gain x2 | `Gameplay.multiplier`/`winsMultiplier`/`applyTrail`, client chat tag |
| Wins2x | 2x Wins | 199 R$ | 2005263080 | Wins from pads x2 | `Gameplay.multiplier`/`winsMultiplier`/`applyTrail`, client chat tag |
| VIP | VIP | 99 R$ | 2004981019 | Gold trail, 1.25x speed gain, [VIP] chat tag | `Gameplay.multiplier`/`winsMultiplier`/`applyTrail`, client chat tag |

## Developer products
| Key | Name | Price | Product ID | Grant |
|---|---|---|---|---|
| SpeedBurst | Speed Burst | 25 R$ | 3716391390 | Instantly get 5 minutes' worth of your current Speed gain (at least +250). |
| SkipStage | Skip Stage | 29 R$ | 3716391393 | Raises your Speed to the next gate's requirement and moves you past it. |
| Potion3x | 3x Speed Potion | 39 R$ | 3716391395 | 3x Speed gain for 10 minutes. Extra potions add time. |
| WinsS | 750 Wins | 49 R$ | 3716391399 | +750 Wins. |
| WinsL | 5,000 Wins | 149 R$ | 3716391402 | +5,000 Wins. |

## Purchase handling
- Passes: `UserOwnsGamePassAsync` on join (pcall) + `PromptGamePassPurchaseFinished` for in-session purchases (`src/server/Passes.luau`, `Monetization.luau`).
- Products: `MarketplaceService.ProcessReceipt` in `src/server/Monetization.luau`:
  1. player not in server or profile not loaded → `NotProcessedYet`
  2. `PurchaseId` already in the profile's `Receipts` → `PurchaseGranted` (no second grant)
  3. apply grant, record `PurchaseId`, **save the profile with UpdateAsync**; if the save fails → roll back grant + receipt and return `NotProcessedYet` (Roblox retries)
  4. only after a successful save → `PurchaseGranted`

## Prompt placement
- STORE side button → panel with all passes and products
- SKIP ⏩ button next to the gate progress bar (only shown while the next gate is still locked)


## v4 changes (branch `claude/cloud-burn`, not published)
No new passes or products were created (that needs Open Cloud, which this session did not use). Existing IDs, prices and grants are unchanged.
- **Store panel** now says purchases are optional and nothing is random, and shows what each item gives this player right now (Speed Burst amount, which gate Skip Stage passes).
- **Free systems added, none purchasable:** companions (Wins only), playtime gifts, Daily Trio, server shard goal, first-clear stage bonus.
- **Roblox Premium perk:** members get +10% Speed gain (`Config.PremiumMult`). This is the platform's own subscription, not a purchase in this game; it is shown as a chip and gated on `Player.MembershipType`.
- **Fairness check against this file's rules:** no paid randomness; companions have fixed prices; every Robux item still has a fixed stated result; the 3x potion and Speed Burst scale with the player (no flat amounts that become meaningless or overpowered); no reward asks for anything off-platform.
- **Balance** (`tools/balance_sim.py`, greedy player, free): stage 10 at 47 min with companions vs 59 min without; stage 14 at 161 min vs 379 min. With the 2x Speed pass the sim gives 31 vs 36 min for stage 10. The 2x pass still roughly halves early-game time.

## Ideas that need the owner (not done)
1. A second "Starter Pack" product (for example Speed Burst + 10 min potion at a discount) would need a new developer product ID.
2. Badges (welcome, first rebirth, all companions) cost Robux to create but are a common retention and discovery hook.
3. A companion-slot pass would be pay-to-win adjacent; skipped.
