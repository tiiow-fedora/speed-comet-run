# Follow-up run: expand and improve the published game

You are running unattended again for up to 6 hours. Nobody will answer questions. When a decision comes up, pick the best option, write the reason in `DECISIONS.md`, and keep going. All rules from the first run still apply (Roblox Terms and Community Standards, no real-money spending, no botting or fake traffic, original assets only, never print the API key, all-ages content, no deleting files outside the project, commit to git after every working milestone).

## Step 1: Take stock (about 20 minutes)

1. Read `MORNING_REPORT.md`, `STATUS.md`, `DESIGN.md`, `TESTING.md`, `MONETIZATION.md`, `ASSETS.md`, and `DECISIONS.md`. List every item the first run skipped, approximated, or marked unverified, and every item on the cut list.
2. Re-test the API key with one read-only request, as in Step 0 of the first run, and record which capabilities work.
3. Open the live game in Studio or Chrome and confirm it loads, the core loop works, and every purchase prompts correctly. If anything is broken, fixing it comes before all new work.
4. Open Creator Hub analytics for the experience in Chrome and record whatever data exists (visits, concurrent players, retention, revenue). If there is too little data to mean anything, say so in `STATUS.md` and do not draw conclusions from it.
5. Save the current published place as `backup/last-known-good.rbxl` and tag the git commit.

## Step 2: Plan the work (about 20 minutes)

Write `PLAN_V2.md` that ranks the work below by expected impact on player retention and revenue per hour of effort. Include only items you can finish and test. Cut the rest.

Candidate work, in the order I would consider it:

1. **Bugs and rough edges** from the first-run report and from your own playtests.
2. **First-session experience.** Make the first 60 seconds clearer and more rewarding. Reduce anything that confuses a new player. Test on phone-size screens.
3. **Retention systems.** Daily rewards, streaks, quests or goals, a visible progression path, and a reason to come back tomorrow. Keep rewards earnable without paying.
4. **More content.** New levels, items, enemies, areas, or modes, built to the same style as the existing game. Generate new models with the Blender scripts in `blender/`, and extend them rather than starting over.
5. **Social features.** Leaderboards, player-vs-player or co-op elements, and trading or gifting only if you can make them safe against exploits.
6. **Monetization tuning.** Review pass and product placement, pricing, and what each one gives. Add or change items only where the benefit is clear to the player and consistent with current Roblox policy. Re-read the policies first.
7. **Discoverability.** Improve the title, description, genre tags, icon, and thumbnails. Generate new thumbnails from Blender renders or Studio screenshots. Do not make claims in the description that the game does not deliver.
8. **Performance.** Check for lag on low-end devices: reduce part counts, use streaming where it applies, and remove per-frame work on the client that is not needed.
9. **Polish.** Sound, particles, UI animation, and small feedback effects that make actions feel good.

## Step 3: Build in small releases

1. Work on one item at a time from `PLAN_V2.md`. After each item, run the Studio playtest checks from `TESTING.md` again and add new checks for what you changed.
2. Publish an update to the live game only when the full checklist passes. Use Rojo to build, then publish through Open Cloud or Studio.
3. After each publish, open the live game and confirm it loads and the previous features still work. If anything regressed and you cannot fix it within 15 minutes, republish `backup/last-known-good.rbxl` (or the latest tagged good build) and log what happened.
4. Update `backup/last-known-good.rbxl` after every verified release.
5. Never change the data store key names or the saved data format in a way that would wipe or corrupt existing player data. If a data change is needed, write a migration, test it with sample data, and keep old fields readable.
6. Never change the price or purpose of an existing game pass or developer product in a way that breaks what a past buyer already received.

## Step 4: Time limits

- At hour 4, anything unfinished gets cut. Only finish and test what is nearly done.
- At hour 5.5, stop adding features and only fix bugs and write the report.
- Update `STATUS.md` every 30 minutes with the current item, what works, and what is blocked.

## If you get stuck

- A tool fails twice the same way: switch routes (API instead of Chrome, Chrome instead of API, primitives instead of Blender assets) and log it.
- A login, 2FA, or identity prompt appears: do not bypass it. Log it in the report and continue with other work.
- A change might break the live game and you cannot test it well: skip it and say why.

## Final report

Write `MORNING_REPORT_V2.md` with:

- What changed in the live game, as a short list with the version published for each
- What you verified and how (screenshots, logs, checklist results)
- Anything skipped, approximated, or unverified, stated directly
- What I need to do by hand
- The 5 best next improvements, ranked, with the reason for each

Keep it plain and specific. No marketing language.
