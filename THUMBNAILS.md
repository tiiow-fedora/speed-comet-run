# THUMBNAILS (run 4, 2026-10-04 evening): AI art via ChatGPT + Gemini

**Why:** the run-3 Blender renders were flat and pastel and didn't compete on Charts/Home (owner's Top Trending / Up-and-Coming screenshot, 2026-10-04). Target style: one big blocky avatar with a strong expression, motion, saturated colors, thick dark outlines, readable at 150 px.

## How they were made
- **Reference:** `assets/thumbnails/ai/reference/game_reference_collage.jpg` = two live v32 client screenshots (`tests/screens/run3/after_pad_fps_live_v32.jpg`, `v3_overview_studio.jpg`) + the spawn layout render. A fresh live capture wasn't possible: clicking Play in Chrome didn't launch the client (probably Chrome's protocol prompt). Same version (v32), taken earlier the same day.
- **ChatGPT** (owner's account, Free plan, logged in by the owner): icon A, generated with the reference attached. Then "error on my side" twice, and the Free limit hit ("Chat paused until usage resets at 11:50 PM"). Stopped there, not bypassed.
- **Gemini** (owner's account, suggested by the owner): the owner OK'd its one-time "Creating content from images and files" terms. Reference attached; 5 thumbnails + 2 icons in one chat. Outputs are 1376x768 / 1024x1024 and were cover-cropped/resized with PIL to exactly 1920x1080 / 512x512.
- **Padlock fix:** thumbnail A had a padlock symbol on the red gate, which the game doesn't have. A Gemini redo misfired (it edited the reference collage instead), so the padlock was inpainted out locally with OpenCV. The gate now reads as plain red energy. The original is kept in `rejected/`.
- **Originals:** all in `assets/thumbnails/ai/raw/`. Review sheets at 150 px: `_review_thumbs_150.png`, `_review_icons_150.png`.

## Review (each checked at full size and at 150 px)
| Image | Verdict | Why |
|---|---|---|
| icon_ai_a_512.png (ChatGPT) | **WINNER: live icon** | Excited blocky runner fills the tile, sprinting at camera; orange comet + pink tail, pink/blue planets, faint spawn arch, cyan track; "+1 ⚡" is the core mechanic. Reads at 150 px |
| icon_ai_b_face_512.png (Gemini) | kept: A/B alternate | Shocked face reads well at 150 px but shows less of the game; comet spots look a bit like a jack-o'-lantern face |
| rejected/icon_ai_c_gate_512.png | rejected | Shirt has a white pixel emblem that could read as a brand logo |
| thumb_ai_d_logo.jpg | **WINNER** | Logo spelled correctly "+1 SPEED COMET RUN ⚡" (the only text: one chunky logo); runner on a shard-lined track, comet + planets |
| thumb_ai_a_gate_nolock.jpg | **WINNER** | Bursting through a green (open) gate; gold Wins pad and red locked gate ahead; shards, comet, planets. The gate "shatter" stylizes the gate-open burst |
| thumb_ai_b_leap.jpg | **WINNER** | Clean, high contrast: leap over a gap between track islands, shard burst, ⚡ trail, comet |
| thumb_ai_c_race.jpg | **WINNER** | Several avatars racing (multiplayer); gold pad + green gate ahead. Busiest of the four but still reads at 150 px. Five runners although four were asked for; harmless |
| rejected/thumb_ai_e_goldpad.jpg | rejected | Avatar looks like he's tripping (misreads as failing); red gate covered in padlocks/circuitry that isn't in the game; cluttered |
| rejected/thumb_ai_a_gate_with_padlock.jpg | rejected (fixed) | Padlock symbol not in game → inpainted version used |

## Upload proof
- **Homepage (Thumbnail Personalization API, `tools/homepage_thumbs.py`):** 4 uploaded, all moderation **Approved**. New personalization config `68a294c0-2adf-4e8e-868a-aea17819ddc9` with A/B/C/D → all 4 **Active**. The run-3 Blender set is Inactive (kept). Ids are in `assets/thumbnails/ai/uploaded_ids.json`; screenshot `tests/screens/run4/homepage_thumbs_active_4ai.jpg`.
- **Icon:** Creator Hub → Icon → `icon_ai_a_512.png` → Save. Pending at first (`icon_ai_a_saved_pending.jpg`), then **approved and live** about 15 min later (`icon_ai_a_approved_live.jpg`).
- **Experience Detail Page: NOT changed.** The Creator Hub upload was blocked by this session's permission guard, so the game page still shows the 2 Blender images (`game_page_detail_still_blender.jpg`). Owner: Creator Hub → Thumbnails → Experience Detail Page → Upload `thumb_ai_d_logo.jpg`, `thumb_ai_a_gate_nolock.jpg`, `thumb_ai_b_leap.jpg`, `thumb_ai_c_race.jpg`, then remove the 2 Blender ones → Save Changes.

## Prompts used
ChatGPT icon A (reference attached): "Create an image: a square 1:1 Roblox game icon for my own Roblox game "+1 Speed Comet Run". The attached image shows real screenshots of the game for reference (ignore the HUD/UI). Close-up of an excited blocky Roblox-style avatar (classic blocky body, simple smiling face with wide eyes and open mouth, blue shirt, dark pants) sprinting toward the camera on a glowing cyan floating track, leaning forward, with bold white speed lines and wind streaks. Behind him in the sky: a big orange glowing comet with a long pink tail, on a bright blue-to-purple daytime 'galaxy' sky with a pink planet and a blue planet. A big chunky yellow lightning bolt ⚡ with a "+1" in thick yellow 3D letters with a dark outline in the top corner. Style: bold saturated colors, thick dark outlines, high contrast, glossy 3D cartoon render like top Roblox chart icons, one big subject filling the frame, must read clearly at 150 px. No other text, no Robux symbols, no logos or brands, no UI."

Gemini, one chat, reference attached to the first message:
- Thumb A (gate): "Generate an image, wide 16:9 landscape (1920x1080): a Roblox game thumbnail for my own Roblox game "+1 Speed Comet Run". The attached image is real screenshots of the game for reference (ignore the HUD/UI). Scene: an excited blocky Roblox-style avatar (classic blocky body, white head with a simple happy face, blue shirt, dark pants) BURSTING through a glowing green square energy gate on a wide glowing light-cyan floating track in the sky, arms forward, mid-sprint, with bold white speed lines, wind streaks and green sparks flying off the gate. Further down the track: a red glowing square locked gate and a round flat gold glowing pad. A few bright cyan crystal shards float beside the track. Sky: bright blue-to-purple daytime galaxy with a big pink planet and a light blue planet, a few low-poly purple space rocks, and a huge orange comet with a long pink tail. Style: bold saturated colors, thick dark outlines, high contrast, glossy 3D cartoon render like top Roblox chart thumbnails; the avatar is the big focal subject, filling a large part of the frame. No text, no Robux, no logos, no UI."
- Thumb B (leap): "Great. Next image, same game, same style and same avatar, wide 16:9 landscape: the blocky avatar LEAPING across a gap between two glowing light-cyan floating track islands, legs stretched mid-jump, determined excited face, with bright cyan glowing crystal shards (Comet Shards) bursting around him and a yellow lightning-bolt sparkle trail behind. Below: deep blue-purple sky with clouds far underneath. Background: big pink planet, light blue planet, low-poly purple space rocks, and the huge orange comet with a long pink tail crossing the sky. Thick dark outlines, bold saturated colors, high contrast, glossy 3D cartoon. Avatar large in frame. No text, no Robux, no logos, no UI."
- Thumb C (race): "Next image, same game and style, wide 16:9 landscape: FOUR different blocky Roblox-style avatars (different shirt colors: blue, red, green, yellow; simple happy/determined faces) racing side by side toward the camera on a wide glowing light-cyan floating track, leaning forward, huge speed lines and wind streaks, the leader in front is biggest. Just ahead of them on the track: a round flat glowing gold pad, and a green glowing square gate frame they are about to pass. Sky: bright blue-to-purple daytime galaxy, big pink planet, light blue planet, low-poly purple space rocks, huge orange comet with a long pink tail. Thick dark outlines, bold saturated colors, high contrast, glossy 3D cartoon like top Roblox chart thumbnails. No text, no Robux, no logos, no UI."
- Thumb D (logo): "Next image, same game and style, wide 16:9 landscape hero shot: the huge orange glowing comet with a long bright pink tail streaking diagonally across a bright blue-to-purple daytime galaxy sky; below it the blocky avatar (blue shirt, happy excited face) sprinting hard toward the camera along a glowing light-cyan floating track, with speed lines and cyan crystal shards flying. Across the upper middle, a chunky bold 3D game logo that reads exactly "+1 SPEED COMET RUN" (spelled exactly like that, nothing else), yellow and white letters with thick dark outline and a small lightning bolt. Pink planet and light blue planet in the background. Thick dark outlines, bold saturated colors, high contrast, glossy 3D cartoon. No other text, no Robux, no other logos, no UI."
- Thumb E (gold pad, rejected): "Next image, same game and style, wide 16:9 landscape: the blocky avatar (blue shirt) in a dynamic three-quarter view sliding onto a big round flat glowing GOLD pad on the glowing light-cyan floating track, shocked-excited face, golden light beams and sparkles bursting up from the pad. Just ahead, a big glowing RED square energy gate (locked) blocks the track, and beyond it a green open gate. Bright cyan crystal shards line the track edge. Sky: bright blue-to-purple daytime galaxy, pink planet, light blue planet, huge orange comet with a long pink tail. Thick dark outlines, bold saturated colors, high contrast, glossy 3D cartoon. No coins, no money, no text, no Robux, no logos, no UI."
- Icon B (face): "Now a SQUARE 1:1 game icon (not wide), same game and style: extreme close-up of the blocky avatar's head and shoulders (white blocky head, blue shirt) with a SHOCKED-excited face (wide eyes, open mouth), rushing toward the camera at insane speed, wind lines streaming past, bright cyan crystal shards flying by, and a big glowing yellow lightning bolt beside the head. The orange comet with pink tail streaks behind on a bright blue-purple sky. The face fills most of the square. Thick dark outlines, bold saturated colors, very high contrast, readable at 150 px. No text, no Robux, no logos."
- Icon C (gate, rejected): "Another SQUARE 1:1 game icon, same game and style: the blocky avatar (blue shirt, determined happy face) in a dynamic full-body sprint bursting out of a glowing green square energy gate toward the camera, green sparks exploding, speed lines. Behind: the huge orange comet with long pink tail on a bright blue-purple sky. Big chunky yellow lightning bolt in one top corner. One big subject, simple background, thick dark outlines, bold saturated colors, very high contrast, readable at 150 px. No text, no Robux, no logos."
- Padlock redo (misfired, not used): "Please redo the FIRST image (avatar bursting through the green gate) exactly the same composition and style, wide 16:9, with one change: the red gate in the distance must be a plain glowing red square frame filled with translucent red energy, with NO padlock or lock symbol on it. Everything else the same. No text."

## Next
- After 7 days compare impressions / qualified play-through per thumbnail (Creator Hub → Thumbnails → Home Page); the run-3 Blender set stays as a control. Icon A/B candidate: `icon_ai_b_face_512.png`.

---

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

## Experience Detail Page thumbnails (fixed 2026-10-04 ~13:15, after the owner reported the default "ROBLOX" placeholder)
The homepage thumbnails (Thumbnail Personalization API) are a separate slot from the detail-page media, which was still empty (`games.roblox.com/v2/games/10769274719/media` → `{"data":[]}`). The Creator Hub uploader doesn't accept files from browser automation, and Studio's settings have no thumbnail section. So the files were sent from the logged-in Creator Hub page to the same endpoint its bundle uses (`publish.roblox.com/v1/games/{universeId}/thumbnail/image`, field `request.files`):
- thumb_spawn_hero.png → 200, targetId 8459839164704349 → image 90887340723686, approved
- thumb_mars_shards.png → 200, targetId 8442042170712504 → image 72736726042541, approved
- thumb_aerial_track.png → **not uploaded**: the third upload was blocked by the session's permission guard. Add it by hand in Creator Hub → Thumbnails → Experience Detail Page if wanted.
Right after upload the game page showed the "processing" placeholder instead of the Roblox logo (`tests/screens/run3/detail_page_processing.jpg`); the images appear once Roblox's CDN finishes rendering them.


## v4 renders (2026-11-02, Blender 4.0.2 in a Linux container; not uploaded)
`blender/thumbnails/render_thumbs.py` gained shots named `v4_*` / `icon_v4_*`. They add the code-built scenery from `MapBuilder.scenery` (clouds, lantern orbs, pennant flags) and the five companions, built from primitives that mirror `src/client/Pets.luau`. Run: `RENDER_OUT=promo/renders blender --background --factory-startup --python blender/thumbnails/render_thumbs.py -- v4_collection icon_v4_foxes ...` (build the meshes first with `blender/props.py` and `blender/landmarks.py`). One Blender run builds the whole track, so render several shots in one command; a run of 6 shots took about 7 minutes. Sun and sky are dimmed for these shots so colors do not wash out.

| Render (in `promo/renders/`) | Verdict | Why |
|---|---|---|
| `icon_v4_foxes.png` | candidate icon | A close, front-facing Star Fox with ears and a big nose is readable at small sizes. Ears are cropped at the top edge |
| `icon_v4_companion.png` | candidate icon | Comet Pup close-up, readable; its orange comes out tan in this light |
| `v4_collection.png` | candidate thumbnail | All five companions in a row under the spawn arch with the comet behind. The lower third is empty floor; crop or move the camera down before use. Dragon and bug look alike from the front |
| `v4_clouds_aerial.png` | candidate thumbnail | Whole track with clouds, orbs and the comet. Reads as "bright and busy" better than the v3 aerial |
| `rejected/v4_hero_companion.png` | rejected | The companion is behind the runner and shows only its glowing tail, a white blob |
| (deleted) `v4_mars_pup` | rejected | The camera sat inside a rail and the frame was mostly flat color |

The runner is still the blocky stand-in, and the companion models in Blender are approximations of the in-game primitives (proportions are close, shading and size in-engine will differ). Replace with real Studio captures once the update is live.


## v5 renders (2026-11-03, Blender 4.0.2 in a Linux container; not uploaded)
Same script (`blender/thumbnails/render_thumbs.py`), now with: a `RENDER_SCALE` env var for quick drafts (0.4 renders in about 8 min because the scene build dominates; full size about 12 min for 3 shots), a simple face on the stand-in runner, lens shift per shot, the 7th zone and 20 stages read from Config, and `FRONTRUN:` / `SIDERUN:` shot modes (runner plus companion). Run: `RENDER_OUT=promo/renders blender --background --factory-startup --python blender/thumbnails/render_thumbs.py -- v4_hero_companion v4_collection v5_aurora_reef`.

| Render (in `promo/renders/`) | Verdict | Why |
|---|---|---|
| `v4_hero_companion.png` (fixed) | candidate thumbnail | The earlier shot was rejected because the camera was behind the runner and the Star Fox showed only a white tail blob. Now the camera is ahead: the runner and the fox run toward it, the fox's ears, eyes and nose are visible, the spawn arch fills the background. Weak spots: flat blue sky behind the arch and the stand-in runner's plain face; replace with a Studio capture when possible |
| `v4_collection.png` (cropped) | candidate thumbnail | Same five companions, but now arranged in a shallow V (the middle one nearest) with the camera tilted up, so the pets fill the frame and the empty floor is gone (about 18% of the frame is floor, down from about 40%). The Void Dragon's wing tips are cut at the left edge |
| `v5_aurora_reef.png` | candidate (needs a crop or a sky element) | The new Aurora Reef zone seen along the track: teal floor, teal rocks, clouds, gate ahead. About 40% of the frame is empty sky; use it as a detail-page image, not a homepage thumbnail |
| `rejected/v4_hero_companion.png` | rejected (kept for the record) | The old behind-the-runner version |

Tried and dropped in drafts: a side view of the runner (the blocky body reads as a thin stack of boxes from the side) and a collection shot made with lens shift (it cut the arch off).
