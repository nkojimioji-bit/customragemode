if _G.CustomRageLoaded then return end
_G.CustomRageLoaded = true

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Workspace = game:GetService("Workspace")

local Config = {
	Url = "https://raw.githubusercontent.com/nkojimioji-bit/customragemode/1bbb302967d3743121da209b4c8203000bd76490/READYORNOTHEREICOME.mp3",
	FileName = "READYORNOTHEREICOME.mp3",
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

local function fadeOutToEnd(sound)
	if not sound.IsPlaying then return end
	local remaining = math.max(sound.TimeLength - sound.TimePosition, 0.01)
	local tweenInfo = TweenInfo.new(remaining, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween = TweenService:Create(sound, tweenInfo, {Volume = 0})
	tween:Play()
	tween.Completed:Wait()
	sound:Stop()
	sound.Volume = Config.Volume
end

local Assets = Workspace:WaitForChild("Assets")
local Songs = Assets:WaitForChild("Songs")

local SoloTracks = {
	"AmySolo", "BlazeSolo", "CreamSolo", "EggmanSolo", 
	"KnucklesSolo", "MetalSonicSolo", "SilverSolo", "SonicSolo", "TailsSolo"
}

local function hookSound(sound)
	if not sound:IsA("Sound") then return end

	local name = sound.Name
	if name == "Rage" or table.find(SoloTracks, name) then
		print(name, "detected:", sound:GetFullName())

		copyEffects(sound, CustomSound)
		local soundGroup = sound.SoundGroup
		local soundVolume = (sound.Volume > 0 and sound.Volume or 1) * Config.LoudnessMultiplier

		sound:GetPropertyChangedSignal("Playing"):Connect(function()
			if sound.Playing then
				sound.Volume = 0
				CustomSound.SoundGroup = soundGroup
				CustomSound.Volume = soundVolume
				if not CustomSound.IsPlaying then
					print("Custom", name, "playing")
					CustomSound:Play()
				end
			else
				fadeOutToEnd(CustomSound)
			end
		end)

		if sound.Playing then
			sound.Volume = 0
			CustomSound.SoundGroup = soundGroup
			CustomSound.Volume = soundVolume
			CustomSound:Play()
		end
	end
end

for _, obj in ipairs(Songs:GetDescendants()) do
	hookSound(obj)
end

Songs.DescendantAdded:Connect(function(obj)
	task.wait()
	hookSound(obj)
end)

Songs.DescendantRemoving:Connect(function(obj)
	if obj:IsA("Sound") and (obj.Name == "Rage" or table.find(SoloTracks, obj.Name)) then
		fadeOutToEnd(CustomSound)
		print(obj.Name, "removed – Custom sound stopped")
	end
end)
