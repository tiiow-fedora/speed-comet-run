# THUMBNAILS (run 3, 2026-10-04)

## Requirements followed (fetched 13:05 from create.roblox.com/docs/production/publishing/thumbnails and the icons page)
- Thumbnails: 16:9, 1920x1080, under 3 MB, png/jpg; up to 10; Home personalization works best with 2–5 active. No mechanics, UI or interactions that aren't in the game; no ad text or misleading claims.
- Icon: square, at least 512x512, must stay readable at 150x150.
- Self-imposed: little or no text, no Robux imagery, no fake rewards, no brands, nothing copied from other games.

## How they were made
`blender/thumbnails/render_thumbs.py` rebuilds the real track in Blender from `src/shared/Config.luau`, using the same rules as `MapBuilder.luau`: zone colors, stage lengths, 6-stud first gaps, islands, gates (red = locked, green = open), gold Wins pads, Comet Shards, rocks and crystals, planets, the comet landmark and the spawn arch. It uses the game's own meshes (`blender/out/*.fbx`). The runner is a blocky stand-in for a Roblox avatar. EEVEE, Standard view transform, about 3 s per image. All 9 originals are in `assets/thumbnails/`.

## Review (each render looked at at full size and as a 150 px icon)
| Render | Verdict | Why |
|---|---|---|
| thumb_spawn_hero | **WINNER** | Clear focal subject (runner under the spawn arch), comet landmark and first gate ahead, planets framing it. This is literally the player's first view |
| thumb_mars_shards | **WINNER** | Shows the action: runner on the Mars track, shards, gate and pads ahead, rocks |
| thumb_aerial_track | **WINNER** | Explains the game at a glance: a long track with gates through zones, plus the comet |
| thumb_event_horizon | rejected | Two thirds empty sky; the track is small in a corner |
| thumb_gap_leap | rejected | Runner floats off the side of the track, which is misleading and cluttered |
| thumb_locked_gate | rejected | The gate fills the frame; flat and hard to read |
| icon_comet_track | **WINNER (icon)** | Big comet (the game's landmark) over a glowing gate, still readable at 150 px |
| icon_runner_comet | rejected (kept) | Runner too small at 150 px |
| icon_gate_runner | rejected (kept) | Mostly a pink rectangle at 150 px |

The first attempt (AgX tone mapping, grey sky, a box "trail" behind the runner that read as a white plank) was rejected and fixed before choosing. Rejected renders are kept for future A/B tests.

## Upload proof
- Homepage thumbnails (Thumbnail Personalization API, 13:05): 3 uploaded, asset ids 80754079463507 / 116825158592566 / 128942246979952, moderation "Reviewing" at upload. New personalization config `8ff73fd5-ee5c-437d-8af6-bc79e21a3b10` created with these 3, replacing the run-1 set. Ids are in `assets/thumbnails/uploaded_ids.json`.
- Icon: uploaded in Creator Hub → Places → Icon and saved; the page then shows the "pending moderation" placeholder (`tests/screens/run3/icon_upload_preview.jpg`, `icon_saved_pending.jpg`).
- Title kept as "+1 Speed Comet Run" (accurate, uses the genre's search term). Description rewritten to list only features that exist in v32.
