if _G.CustomRageLoaded then return end
_G.CustomRageLoaded = true

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")

local Config = {
	Url = "https://raw.githubusercontent.com/nkojimioji-bit/customragemode/main/READYORNOTHARDCORE.mp3",
	FileName = "READYORNOTHARDCORE.mp3",
	Volume = 1,
	LoudnessMultiplier = 2.5
}

local function getAsset()
	if not isfile(Config.FileName) then
		warn("Downloading custom Rage music...")
		writefile(Config.FileName, game:HttpGet(Config.Url))
		print("Custom Rage download complete.")
	end
	return getcustomasset(Config.FileName)
end

local assetId = getAsset()
if not assetId then return end

local old = SoundService:FindFirstChild("CustomRage")
if old then old:Destroy() end

local CustomSound = Instance.new("Sound")
CustomSound.Name = "CustomRage"
CustomSound.SoundId = assetId
CustomSound.Volume = Config.Volume
CustomSound.Looped = false
CustomSound.Parent = SoundService

warn("Preloading custom Rage music...")
local t = tick()
ContentProvider:PreloadAsync({ CustomSound })
warn("Custom Rage preloaded in " .. math.round((tick() - t) * 1000) .. "ms")

local function clearEffects(sound)
	for _, c in ipairs(sound:GetChildren()) do
		if c:IsA("SoundEffect") then
			c:Destroy()
		end
	end
end

local function copyEffects(fromSound, toSound)
	clearEffects(toSound)
	for _, c in ipairs(fromSound:GetChildren()) do
		if c:IsA("SoundEffect") then
			c:Clone().Parent = toSound
		end
	end
end

local function hookRage(rage)
	if not rage:IsA("Sound") or rage.Name ~= "Rage" then return end

	print("Rage detected:", rage:GetFullName())

	copyEffects(rage, CustomSound)

	local rageGroup = rage.SoundGroup
	local rageVolume = (rage.Volume > 0 and rage.Volume or 1) * Config.LoudnessMultiplier

	rage:GetPropertyChangedSignal("Playing"):Connect(function()
		if rage.Playing then
			rage.Volume = 0
			CustomSound.SoundGroup = rageGroup
			CustomSound.Volume = rageVolume
			if not CustomSound.IsPlaying then
				print("Custom Rage playing")
				CustomSound:Play()
			end
		else
			CustomSound:Stop()
		end
	end)

	if rage.Playing then
		rage.Volume = 0
		CustomSound.SoundGroup = rageGroup
		CustomSound.Volume = rageVolume
		CustomSound:Play()
	end
end

local Assets = Workspace:WaitForChild("Assets")
local Songs = Assets:WaitForChild("Songs")

warn("Watching workspace.Assets.Songs for Rage music")

for _, obj in ipairs(Songs:GetDescendants()) do
	hookRage(obj)
end

Songs.DescendantAdded:Connect(function(obj)
	task.wait()
	hookRage(obj)
end)