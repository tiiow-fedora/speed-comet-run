# Follow-up run 2: grow players (map, first minute, thumbnails, retention)

You are running unattended for up to 6 hours. Nobody will answer questions. When a decision comes up, pick the best option, write the reason in `DECISIONS.md`, and keep going. All rules from the earlier runs still apply: follow the Roblox Terms of Use and Community Standards, spend no real money, no ads or paid promotion, no botting or fake traffic, original work only, never print the API key, all-ages content, no deleting files outside the project, and commit to git after every working milestone.

## What this run is for

The game is live and the goal now is getting more players to try it and come back. Roblox's recommendation system weighs these signals most: play-through rate, how many players leave within the first 60 seconds, how many days each player returns (day 1, days 2 to 7, days 8 to 28), and playtime per day. Co-play with friends and spending count too. Roblox also says thumbnails must match the real gameplay, that games resembling existing ones are ranked lower, and that marketing built around Robux rewards limits exposure. Work on the items below with those signals in mind. A thumbnail that attracts clicks the game cannot satisfy is a failure.

## Step 1: Take stock (about 20 minutes)

1. Read every report and plan file from the earlier runs: `MORNING_REPORT.md`, `MORNING_REPORT_V2.md`, `PLAN_V2.md`, `STATUS.md`, `DESIGN.md`, `TESTING.md`, `MONETIZATION.md`, `ASSETS.md`, `DECISIONS.md`. List everything skipped, unverified, or cut.
2. Test the API key with one read-only request and record which capabilities work in `STATUS.md`.
3. Open Creator Hub analytics for the experience in Chrome. It has now been live for about a day. Record visits, concurrent players, play-through rate, first-session length, day-1 retention, and revenue if any are shown. If the numbers are too small to mean much, say so and do not draw firm conclusions from them.
4. Playtest the live game from a new player's point of view and time how long it takes to understand what to do. Note every place a player could get confused, bored, or stuck in the first 60 seconds. Save screenshots.
5. Save the live place as `backup/last-known-good.rbxl` and tag the git commit.

Write `FINDINGS_V3.md` with what you saw, then `PLAN_V3.md` ranking the work below by expected effect on the signals above.

## Step 2: Work items

### A. First 60 seconds (do this first)

Make a new player understand the game and get a reward within the first minute. Cut any waiting, long text, or dead walking. Add a clear first goal, a quick early win, and visible feedback (sound, particles, UI animation) for each action. Test at phone, tablet, and desktop sizes.

### B. A better, brighter map

Redesign or extend the map so it looks distinct and inviting from the spawn point.

- Use a bold, saturated color palette with strong contrast between ground, landmarks, and interactive objects. Pick one palette and keep it consistent.
- Give the player a clear landmark and a visible direction to go from spawn.
- Place content so there is always something interesting within sight: pickups, objectives, other players.
- Add lighting, atmosphere, and effects that make it feel finished (skybox, bloom, color correction, ambient particles), without hurting performance on phones.
- Build new props and set pieces with the Blender scripts in `blender/`. Keep the style consistent with the existing game, and make the look original so it does not resemble another popular game's art.
- Check performance after the change: part count, draw calls, and frame rate on a low-end device profile in Studio. Reduce anything that hurts it.

### C. Retention and social systems

Build the smallest version of each that you can fully test:

1. A daily reward with a streak that rewards coming back and is fully earnable without paying
2. A short list of quests or goals that always gives the player a next thing to do
3. A visible progression path (levels, unlocks, or collection) so players can see what they are working toward
4. A reason to play with friends: shared bonuses, a co-op goal, or a leaderboard among friends
5. A first limited-time event or weekly rotation, with the content scheduled so it can change weekly without a new build when possible

Protect against exploits: validate everything on the server and rate-limit remote events.

### D. Thumbnails and icon (Blender)

1. Fetch the current Roblox docs for icon and thumbnail requirements (size, format, number allowed, content rules) and follow them exactly.
2. Write Blender Python scripts in `blender/thumbnails/` that render from the actual game assets and map. Run Blender in background mode and render with Cycles or Eevee, whichever gives a clean result in reasonable time.
3. Produce at least 6 thumbnail variations and 3 icon variations. Vary composition, camera angle, and focal point. Each one must show things that are really in the game, with a clear focal subject readable at small size, bright saturated colors, and little or no text. No Robux imagery, no fake rewards, no real brands, and no imitation of another game's thumbnail.
4. Look at every render yourself. Reject any that are blurry, cluttered, dark, or misleading. Write a short note on why you picked the winners in `THUMBNAILS.md`, and save the originals in `assets/thumbnails/`.
5. Upload through the documented API if one exists for it, otherwise through Creator Hub in Chrome. Replace the icon and thumbnails with the winners. Keep the rejected renders for later tests.
6. Also review the game title and description for clarity and accuracy. Use only keywords that honestly describe the game. Do not copy another game's title.

### E. Update plan

Write `UPDATE_PLAN.md`: a weekly update schedule for the next 4 weeks, with one concrete change per week, so future runs can follow it.

## Step 3: Release rules

1. Work one item at a time. After each one, rerun the playtest checks from `TESTING.md` and add checks for what changed.
2. Publish an update only when every check passes. Build with Rojo, then publish through Open Cloud or Studio.
3. After every publish, open the live game and confirm it loads, the core loop works, and every pass and product still prompts. If anything regressed and cannot be fixed within 15 minutes, republish the last known good build and log it.
4. Update `backup/last-known-good.rbxl` after every verified release.
5. Never change the save format or data store keys in a way that could wipe or corrupt existing player data. If you must change them, write a migration, test it with sample data, and keep old fields readable.
6. Never change an existing game pass or developer product so it breaks what past buyers already received.

## Step 4: Time limits

- At hour 4, anything unfinished gets cut. Only finish what is nearly done.
- At hour 5.5, stop adding features and only fix bugs and write the report.
- Update `STATUS.md` every 30 minutes with the current item, what works, and what is blocked.

## If you get stuck

- A tool fails twice the same way: switch routes (API instead of Chrome, Chrome instead of API, primitives instead of Blender assets) and log it.
- A login, 2FA, or identity prompt appears: do not bypass it. Log it and continue with other work.
- Anything that needs real money, including Roblox ads: do not do it. List it in the report as something for me to decide.
- A change might break the live game and cannot be tested well: skip it and say why.

## Final report

Write `MORNING_REPORT_V3.md` with:

- What changed in the live game, as a short list, with before and after screenshots of the map and the thumbnails
- The analytics numbers recorded at the start of the run, and a note that the next run should compare against them
- What was verified and how
- Anything skipped, approximated, or unverified, stated directly
- What I need to do by hand, including any decision about paid ads or outside promotion such as YouTube or TikTok
- The 5 best next improvements, ranked, with the reason for each

Keep it plain and specific. No marketing language.
