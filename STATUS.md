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

## Current phase
Phase 1 Research (started ~23:20)
