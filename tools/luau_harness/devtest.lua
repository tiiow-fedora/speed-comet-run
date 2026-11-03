-- Runs the REAL Main.server + MapBuilder + DevTest (the Studio self test) against the mock.
-- Movement is simulated by the mock (PivotTo sets the root part position), so this validates the test logic and the
-- modules together, not Roblox physics. Anything that needs real physics/rendering still needs Studio.
local ENV = setmetatable({ ARGS = ARGS, __exists = __exists, __loadfile = __loadfile }, { __index = _G })
local ROOT = ARGS[1]
local M = __loadfile(ROOT .. "/tools/luau_harness/mock.lua", ENV)()
local workspace = M.workspace
local pass, fail = 0, 0
local lines = {}

local test = function()
	local G = M.globals
	-- DevTest requires the client Pets/Ambience modules through StarterPlayer.StarterPlayerScripts.Client
	local sp = M.game:GetService("StarterPlayer")
	rawget(sp, "_children")[1] = { Name = "StarterPlayerScripts", Client = M.clientDir }
	local origPrint, origWarn = G.print, G.warn
	G.print = function(...) local t = table.pack(...); local s = {}; for i = 1, t.n do s[i] = tostring(t[i]) end; table.insert(lines, table.concat(s, "\t")) end
	G.warn = function(...) local t = table.pack(...); local s = {}; for i = 1, t.n do s[i] = tostring(t[i]) end; table.insert(lines, "WARN " .. table.concat(s, "\t")) end
	M.stub("Leaderboard.luau", { build = function() end, start = function() end, submit = function() end, submitTo = function() end })
	M.stub("PropLoader.luau", { load = function() end })
	local menv = setmetatable({ script = { Name = "Main", Parent = M.serverDir }, require = M.require }, { __index = G })
	__loadfile(ROOT .. "/src/server/Main.server.luau", menv)()
	local Players = M.game:GetService("Players")
	local plr, hrp = M.newPlayer("Tester")
	plr.Parent = Players
	Players.PlayerAdded:Fire(plr)
	M.advance(1)
	local devRun = M.game:GetService("ServerScriptService"):FindFirstChild("DevRun")
	assert(devRun, "DevRun missing")
	local res = devRun.OnInvoke()
	G.print, G.warn = origPrint, origWarn
	-- Checks that cannot pass outside Studio: receipts need a working DataStore save; the landmark needs the imported Blender meshes.
	local envLimited = { "receipt .- granted exactly once", "landmark uses Blender meshes" }
	local skipped = 0
	for _, l in ipairs(lines) do
		local body = l:gsub("^WARN ", "")
		if body:sub(1, 4) == "PASS" then
			pass = pass + 1
		elseif body:sub(1, 4) == "FAIL" then
			local limited = false
			for _, pat in ipairs(envLimited) do if body:find(pat) then limited = true end end
			if limited then skipped = skipped + 1 else fail = fail + 1; print(l) end
		elseif l:find("server ready") then
			print(l)
		elseif l:sub(1, 4) == "WARN" and not l:find("DataStore unavailable") then
			print(l)
		end
	end
	print("environment-limited checks skipped (need Studio): " .. skipped)
	print("DevTest returned: pass=" .. tostring(res and res.pass) .. " fail=" .. tostring(res and res.fail))
end

local co = coroutine.create(test)
local ok, err = coroutine.resume(co)
local guard = 0
while coroutine.status(co) ~= "dead" and guard < 200000 do guard = guard + 1; M.advance(0.1) end
if not ok then print("TEST ERROR: " .. tostring(err) .. "\n" .. debug.traceback(co)); fail = fail + 1 end
print(string.format("DEVTEST-IN-MOCK DONE: %d pass, %d fail, %d thread errors", pass, fail, M.failures()))
if fail > 0 or M.failures() > 0 then error("devtest harness failed") end
