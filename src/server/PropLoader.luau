--!strict
-- Loads the Blender-generated meshes (uploaded via Open Cloud, IDs in ASSETS.md)
-- into ServerStorage.Props before the map is built. Any failure just leaves
-- MapBuilder on its primitive fallbacks.

local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")

local PropLoader = {}

local PROPS: { [string]: number } = {
	Rock1 = 72645655828561,
	Rock2 = 121471108529248,
	Rock3 = 79693074857712,
	Crystal = 103157670483871,
	CometHead = 95764825699862,
	CometTail = 125542314750590,
	SpawnArch = 140335356772770,
}

function PropLoader.load(timeout: number)
	local folder = ServerStorage:FindFirstChild("Props") or Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = ServerStorage
	local pending = 0
	for name, id in PROPS do
		if folder:FindFirstChild(name) then
			continue
		end
		pending += 1
		task.spawn(function()
			local ok, model = pcall(InsertService.LoadAsset, InsertService, id)
			if ok and model then
				local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
				if mesh then
					mesh.Name = name
					mesh.Anchored = true
					mesh.CanCollide = false
					mesh.CastShadow = false
					mesh.CanTouch = false -- clones inherit these; decor needs no touch/raycast work
					mesh.CanQuery = false
					mesh.Parent = folder
				else
					warn("[Props] no MeshPart in asset " .. id)
				end
				model:Destroy()
			else
				warn("[Props] failed to load " .. name .. ": " .. tostring(model))
			end
			pending -= 1
		end)
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < timeout do
		task.wait(0.1)
	end
end

return PropLoader
