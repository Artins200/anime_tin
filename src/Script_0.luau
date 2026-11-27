local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WD = require(RS:WaitForChild("WeaponData"))
Players.RespawnTime = 3

------------------------------------------------------------------ REMOTES
local Remotes = Instance.new("Folder"); Remotes.Name = "Remotes"; Remotes.Parent = RS
local function newRemote(n) local r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = Remotes; return r end
local AttackRE, NotifyRE, FadeRE = newRemote("Attack"), newRemote("Notify"), newRemote("Fade")
local StateRE, HitRE, EndRE, ShakeRE = newRemote("State"), newRemote("Hit"), newRemote("End"), newRemote("Shake")
local KickRE, FocusRE, DoorStateRE = newRemote("Kick"), newRemote("Focus"), newRemote("DoorState")
local CutsceneRE, MusicRE, CreditsRE = newRemote("Cutscene"), newRemote("Music"), newRemote("Credits")
local SceneReadyRE=newRemote("SceneReady")
local readyClients, preparedClients = {}, {}
local prepareId=0
SceneReadyRE.OnServerEvent:Connect(function(player,command,id)
 if command=="ready" then readyClients[player]=true
 elseif command=="prepared" and id==prepareId then preparedClients[player]=id end
end)
Players.PlayerRemoving:Connect(function(player)
 readyClients[player]=nil; preparedClients[player]=nil
end)
local function prepareView(position)
 prepareId+=1
 local id=prepareId
 CutsceneRE:FireAllClients("prepare",position,id)
 local deadline=os.clock()+8
 repeat
  local complete=true
  for _,player in ipairs(Players:GetPlayers()) do
   if readyClients[player] and preparedClients[player]~=id then complete=false end
  end
  if complete then return end
  task.wait(0.1)
 until os.clock()>=deadline
 warn("Cinematic preparation timed out; revealing scene instead of leaving a black screen")
end

------------------------------------------------------------------ ЗВУКИ
local SOUNDS = {PowerOff = "", DoorBreak = "", Shot = "", Punch = ""}
local function playSound(id, parent)
	if id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Parent = parent or workspace; s:Play(); Debris:AddItem(s, 6)
end

------------------------------------------------------------------ СОСТОЯНИЕ
local currentLevel, currentName, levelToken = 0, "", 0
local enemiesLeft, currentWave, totalWaves = 0, 0, 0
local canFight = false
local levelFolder, enemiesFolder
local enemies = {}
local currentSpawn = CFrame.new(0, 10, 0)
local fxFolder = Instance.new("Folder"); fxFolder.Name = "FX"; fxFolder.Parent = workspace
local currentExitDoor, currentDoorCF, doorUnlocked = nil, nil, false
local Levels
local activeLevelInfo
local introActive = false
local breachDoor, entranceUsed = nil, false

------------------------------------------------------------------ ГРАФОН
pcall(function()
	Lighting.GlobalShadows = true; Lighting.ShadowSoftness = 0.2
	Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
end)
local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
local cc = Instance.new("ColorCorrectionEffect", Lighting)
local bloom = Instance.new("BloomEffect", Lighting); bloom.Size = 20; bloom.Threshold = 1.5
local dof = Instance.new("DepthOfFieldEffect", Lighting)
dof.FarIntensity = 0.1; dof.NearIntensity = 0; dof.FocusDistance = 60; dof.InFocusRadius = 120
local rays = Instance.new("SunRaysEffect", Lighting); rays.Intensity = 0.05; rays.Spread = 0.5

local function C(r, g, b) return Color3.fromRGB(r, g, b) end
local Presets = {
	Forest    = {A=C(70,78,90),    B=2,   Clock=16.5, D=0.25, AC=C(180,195,210), CT=0.08, S=-0.12, T=C(250,245,238), BL=0.05},
	Apartment = {A=C(110,105,100), B=1,   Clock=0,    D=0.00, AC=C(195,195,195), CT=0.06, S=-0.10, T=C(250,248,242), BL=0.05},
	Lab       = {A=C(140,145,150), B=1,   Clock=0,    D=0.00, AC=C(205,210,215), CT=0.06, S=-0.15, T=C(242,248,255), BL=0.05},
	Warehouse = {A=C(95,90,82),    B=1,   Clock=0,    D=0.05, AC=C(180,175,160), CT=0.10, S=-0.15, T=C(250,242,228), BL=0.05},
	Server    = {A=C(75,70,75),    B=1,   Clock=0,    D=0.05, AC=C(140,130,135), CT=0.10, S=-0.15, T=C(250,240,240), BL=0.05},
	Base      = {A=C(110,115,125), B=1,   Clock=0,    D=0.05, AC=C(185,195,210), CT=0.06, S=-0.10, T=C(248,250,255), BL=0.05},
	BaseDark  = {A=C(18,18,26),    B=0,   Clock=0,    D=0.12, AC=C(55,35,40),    CT=0.12, S=-0.12, T=C(250,220,220), BL=0.15},
	Office    = {A=C(60,50,45),    B=0.8, Clock=0,    D=0.02, AC=C(180,160,140), CT=0.05, S=-0.10, T=C(240,230,220), BL=0.08},
}
local function applyPreset(name, t)
	local p = Presets[name]; local ti = TweenInfo.new(t)
	TweenService:Create(Lighting, ti, {Ambient=p.A, OutdoorAmbient=p.A, Brightness=p.B, ClockTime=p.Clock}):Play()
	TweenService:Create(atm, ti, {Density=p.D, Color=p.AC, Haze=1}):Play()
	TweenService:Create(cc, ti, {Contrast=p.CT, Saturation=p.S, TintColor=p.T}):Play()
	TweenService:Create(bloom, ti, {Intensity=p.BL}):Play()
end

------------------------------------------------------------------ ХЕЛПЕРЫ
local function soft(mat, color)
	if mat == Enum.Material.Neon then
		local h, s, v = color:ToHSV()
		return Enum.Material.SmoothPlastic, Color3.fromHSV(h, s * 0.55, v * 0.75)
	end
	return mat or Enum.Material.SmoothPlastic, color
end
local function part(parent, size, pos, color, mat, rot)
	local p = Instance.new("Part")
	p.Anchored = true; p.Size = size
	p.CFrame = CFrame.new(pos) * (rot or CFrame.new())
	local mm, cc2 = soft(mat, color)
	p.Material = mm; p.Color = cc2
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function light(parent, color, range, brightness)
	local l = Instance.new("PointLight"); l.Color = color; l.Range = range; l.Brightness = brightness; l.Parent = parent
	return l
end
-- Soft local fixtures ONLY for the starting briefing laboratory.
local function briefingLight(parent, position, width, depth)
 local panel=part(parent,Vector3.new(width or 7,0.2,depth or 3),position,C(175,178,180))
 panel.Name="BriefingLight"; panel.Material=Enum.Material.SmoothPlastic
 local area=Instance.new("SurfaceLight")
 area.Face=Enum.NormalId.Bottom; area.Angle=110; area.Range=24
 area.Brightness=0.65; area.Color=C(245,235,220); area.Shadows=false; area.Parent=panel
 -- No overlapping point-light fill: keep contrast and avoid washed-out walls.
 return panel
end

local function anchorAll(m)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
end
local function spreadDir(dir, deg)
	if deg <= 0 then return dir end
	local s = math.rad(deg)
	return (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles((math.random()-0.5)*2*s, (math.random()-0.5)*2*s, 0)).LookVector
end
local function tracer(a, b, color)
	local d = (b - a).Magnitude
	if d < 0.5 then return end
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = Enum.Material.Neon; p.Color = color; p.Size = Vector3.new(0.08, 0.08, d)
	p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -d/2)
	p.Parent = fxFolder; Debris:AddItem(p, 0.06)
end

------------------------------------------------------------------ ТИПЫ ВРАГОВ
local Base = {
	Skin=C(195,170,155), Shirt=C(160,160,180), Skirt=C(30,30,65), Legs=C(18,18,30),
	Hair=C(165,75,120), Eye=C(35,105,115), Accent=C(150,45,95), HP=60, Speed=14, Name="Андроид-тянка",
}
local function T(o) for k, v in pairs(Base) do if o[k] == nil then o[k] = v end end return o end
local Types = {
	Melee   = T{HP=60,  Speed=15, Melee=true, Dmg=9, Cd=0.9},
	Pistol  = T{HP=70,  Speed=11, Gun=true, Range=80, Dmg=7,   Cd=1.1,  Pellets=1, Spread=4, Hair=C(80,110,190), Skirt=C(85,25,40)},
	SMG     = T{HP=80,  Speed=12, Gun=true, Range=70, Dmg=3,   Cd=0.18, Pellets=1, Spread=6, Hair=C(150,85,200), Skirt=C(35,35,35)},
	Shotgun = T{HP=120, Speed=12, Gun=true, Range=38, Dmg=4,   Cd=1.7,  Pellets=6, Spread=9, Hair=C(200,120,55), Skirt=C(70,40,25)},
	Boss    = T{HP=450, Speed=13, Gun=true, Range=90, Dmg=5,   Cd=0.28, Pellets=1, Spread=5, Hair=C(200,35,50), Eye=C(220,30,30), Shirt=C(22,22,28), Skirt=C(95,0,15), Name="Главная тянка"},
	Commander = T{Name="Командир", Male=true, Hair=C(35,28,22), Shirt=C(60,80,55), Skirt=C(45,50,45), Eye=C(28,28,28)},
	Neuro   = T{Name="Нейро-тянка", Hair=C(0,220,205), Eye=C(0,220,205), Shirt=C(18,18,24), Skirt=C(8,8,12), Accent=C(0,220,205)},
	Mafiozi = T{Name="Мафиози", Male=true, Hair=C(15,15,18), Shirt=C(15,15,20), Skirt=C(12,12,15), Legs=C(10,10,12), Eye=C(220,30,40), Accent=C(200,160,40)},
}

------------------------------------------------------------------ СБОРКА R6-РИГА
local function buildRig(cfg, cf)
	local m = Instance.new("Model"); m.Name = cfg.Name
	local function mk(name, size, color, mat)
		local p = Instance.new("Part"); p.Name = name; p.Size = size
		local mm, c2 = soft(mat, color)
		p.Material = mm; p.Color = c2
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m; return p
	end
	local hrp = mk("HumanoidRootPart", Vector3.new(2,2,1), cfg.Skirt); hrp.Transparency = 1; hrp.CanCollide = false
	local torso = mk("Torso", Vector3.new(2,2,1), cfg.Shirt)
	local head  = mk("Head", Vector3.new(2,1,1), cfg.Skin)
	local ra = mk("Right Arm", Vector3.new(1,2,1), cfg.Skin)
	local la = mk("Left Arm",  Vector3.new(1,2,1), cfg.Skin)
	local rl = mk("Right Leg", Vector3.new(1,2,1), cfg.Legs)
	local ll = mk("Left Leg",  Vector3.new(1,2,1), cfg.Legs)
	hrp.CFrame = cf

	local function J(name, p0, p1, c0, c1)
		local mo = Instance.new("Motor6D"); mo.Name = name; mo.Part0 = p0; mo.Part1 = p1; mo.C0 = c0; mo.C1 = c1
		p1.CFrame = p0.CFrame * c0 * c1:Inverse()
		mo.Parent = p0; return mo
	end
	local rsC0 = CFrame.new(1,0.5,0, 0,0,1, 0,1,0, -1,0,0)
	if cfg.Gun then rsC0 = rsC0 * CFrame.Angles(0, 0, math.rad(90)) end
	J("RootJoint", hrp, torso, CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,0,0,-1,0,0,0,0,1,0,1,0))
	J("Neck", torso, head, CFrame.new(0,1,0,-1,0,0,0,0,1,0,1,0), CFrame.new(0,-0.5,0,-1,0,0,0,0,1,0,1,0))
	local joints = {
		RS = J("Right Shoulder", torso, ra, rsC0, CFrame.new(-0.5,0.5,0, 0,0,1, 0,1,0, -1,0,0)),
		LS = J("Left Shoulder",  torso, la, CFrame.new(-1,0.5,0, 0,0,-1, 0,1,0, 1,0,0), CFrame.new(0.5,0.5,0, 0,0,-1, 0,1,0, 1,0,0)),
		RH = J("Right Hip", torso, rl, CFrame.new(1,-1,0, 0,0,1, 0,1,0, -1,0,0),  CFrame.new(0.5,1,0, 0,0,1, 0,1,0, -1,0,0)),
		LH = J("Left Hip",  torso, ll, CFrame.new(-1,-1,0, 0,0,-1, 0,1,0, 1,0,0), CFrame.new(-0.5,1,0, 0,0,-1, 0,1,0, 1,0,0)),
	}

	local function acc(name, size, off, color, mat, base)
		local p = mk(name, size, color, mat); p.CanCollide = false; p.Massless = true
		p.CFrame = (base or head).CFrame * off
		local w = Instance.new("WeldConstraint"); w.Part0 = base or head; w.Part1 = p; w.Parent = p
		return p
	end
	acc("Hair", Vector3.new(2.3,0.5,1.3), CFrame.new(0,0.65,0.05), cfg.Hair, Enum.Material.SmoothPlastic)
	acc("Hair", Vector3.new(2.3,1.6,0.4), CFrame.new(0,-0.05,0.6), cfg.Hair)
	if not cfg.Male then
		acc("Hair", Vector3.new(0.4,1.2,1.2), CFrame.new(1.05,-0.1,0), cfg.Hair)
		acc("Hair", Vector3.new(0.4,1.2,1.2), CFrame.new(-1.05,-0.1,0), cfg.Hair)
		acc("Tail", Vector3.new(0.7,2.8,0.7), CFrame.new(1.7,-0.9,0.5), cfg.Hair)
		acc("Tail", Vector3.new(0.7,2.8,0.7), CFrame.new(-1.7,-0.9,0.5), cfg.Hair)
		acc("Bow", Vector3.new(0.7,0.45,0.25), CFrame.new(0.9,0.75,-0.4), cfg.Accent)
		acc("Skirt", Vector3.new(2.5,0.7,1.6), CFrame.new(0,-0.85,0), cfg.Skirt, nil, torso)
	end
	acc("Eye", Vector3.new(0.32,0.42,0.08), CFrame.new(0.42,0.05,-0.52), cfg.Eye)
	acc("Eye", Vector3.new(0.32,0.42,0.08), CFrame.new(-0.42,0.05,-0.52), cfg.Eye)
	local gun
	if cfg.Gun then
		gun = mk("Gun", Vector3.new(0.35,0.6,1.5), C(25,25,30), Enum.Material.Metal)
		gun.CanCollide = false; gun.Massless = true
		gun.CFrame = CFrame.new(ra.CFrame:PointToWorldSpace(Vector3.new(0,-0.8,0))) * torso.CFrame.Rotation * CFrame.new(0,0.2,-0.5)
		local w = Instance.new("WeldConstraint"); w.Part0 = ra; w.Part1 = gun; w.Parent = gun
		local strip = mk("Strip", Vector3.new(0.38,0.08,1.0), cfg.Eye)
		strip.CanCollide = false; strip.Massless = true; strip.CFrame = gun.CFrame * CFrame.new(0,0.33,0)
		local w2 = Instance.new("WeldConstraint"); w2.Part0 = gun; w2.Part1 = strip; w2.Parent = strip
	end

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.MaxHealth = cfg.HP; hum.Health = cfg.HP; hum.WalkSpeed = cfg.Speed
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = m
	m.PrimaryPart = hrp
	return m, hum, hrp, joints, gun
end

------------------------------------------------------------------ КИБЕР-ТЕЛО НЕЙРО
local function enhanceNeuroCyber(neuro)
	local torso = neuro:FindFirstChild("Torso")
	local ra = neuro:FindFirstChild("Right Arm")
	local la = neuro:FindFirstChild("Left Arm")
	local rl = neuro:FindFirstChild("Right Leg")
	local ll = neuro:FindFirstChild("Left Leg")
	if not torso then return end
	local function addTo(base, size, offset, color)
		local p = Instance.new("Part")
		p.Size = size; p.Color = color; p.Material = Enum.Material.Neon
		p.CanCollide = false; p.Massless = true
		p.Parent = neuro
		p.CFrame = base.CFrame * offset
		local w = Instance.new("WeldConstraint"); w.Part0 = base; w.Part1 = p; w.Parent = p
		return p
	end
	local chest = addTo(torso, Vector3.new(1.4, 1.2, 0.08), CFrame.new(0, 0.1, -0.55), C(0, 220, 205))
	light(chest, C(0, 220, 205), 12, 2)
	addTo(torso, Vector3.new(0.5, 0.5, 0.1), CFrame.new(0, 0.1, -0.6), C(255, 255, 255))
	if ra then addTo(ra, Vector3.new(0.1, 1.8, 0.1), CFrame.new(0.52, 0, 0), C(0, 220, 205)) end
	if la then addTo(la, Vector3.new(0.1, 1.8, 0.1), CFrame.new(-0.52, 0, 0), C(0, 220, 205)) end
	if rl then addTo(rl, Vector3.new(0.1, 1.8, 0.1), CFrame.new(0.52, 0, 0), C(0, 220, 205)) end
	if ll then addTo(ll, Vector3.new(0.1, 1.8, 0.1), CFrame.new(-0.52, 0, 0), C(0, 220, 205)) end
	for _, side in ipairs({-1, 1}) do
		local wing = addTo(torso, Vector3.new(0.08, 1.4, 0.8), CFrame.new(side * 1.1, 0.2, 0.6) * CFrame.Angles(0, 0, side * math.rad(20)), C(0, 220, 205))
		wing.Transparency = 0.5
	end
end

------------------------------------------------------------------ РЭГДОЛЛ NPC
local function ragdoll(m)
	local dir = m:GetAttribute("LastDir") or Vector3.new(0, 0, 0)
	local force = math.max(m:GetAttribute("LastKnock") or 10, 12)
	local torso = m:FindFirstChild("Torso")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	for _, mo in ipairs(m:GetDescendants()) do
		if mo:IsA("Motor6D") and mo.Name ~= "RootJoint" then
			local a0 = Instance.new("Attachment"); a0.CFrame = mo.C0; a0.Parent = mo.Part0
			local a1 = Instance.new("Attachment"); a1.CFrame = mo.C1; a1.Parent = mo.Part1
			local b = Instance.new("BallSocketConstraint")
			b.Attachment0 = a0; b.Attachment1 = a1
			b.LimitsEnabled = true; b.UpperAngle = 70
			b.TwistLimitsEnabled = true; b.TwistLowerAngle = -40; b.TwistUpperAngle = 40
			b.Parent = mo.Part0
			local nc = Instance.new("NoCollisionConstraint"); nc.Part0 = mo.Part0; nc.Part1 = mo.Part1; nc.Parent = mo.Part0
			mo:Destroy()
		end
	end
	if hrp then hrp:Destroy() end
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "Hair" then
			p:ApplyImpulse((dir * force + Vector3.new(0, force * 0.3, 0)) * p.AssemblyMass)
		end
	end
	if torso then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(C(255,200,80)); pe.LightEmission = 1; pe.Size = NumberSequence.new(0.35, 0)
		pe.Lifetime = NumberRange.new(0.4, 0.9); pe.Speed = NumberRange.new(15, 35); pe.SpreadAngle = Vector2.new(180, 180)
		pe.Rate = 0; pe.Parent = torso; pe:Emit(35)
	end
end

------------------------------------------------------------------ РЭГДОЛЛ ИГРОКА (сбить без смерти)
local function knockPlayer(char, dirX, dirZ)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	hum.PlatformStand = true
	hum.AutoRotate = false
	local dir = Vector3.new(dirX or 0, 15, dirZ or 15).Unit
	hrp:ApplyImpulse(dir * 50 * hrp.AssemblyMass)
	hrp.AssemblyAngularVelocity = Vector3.new(math.random(-8,8), math.random(-8,8), math.random(-8,8))
end

------------------------------------------------------------------ ИИ
local function nearestPlayer(pos)
	local best, bd
	for _, pl in ipairs(Players:GetPlayers()) do
		local c = pl.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if h and r and h.Health > 0 then
			local d = (r.Position - pos).Magnitude
			if not bd or d < bd then best, bd = c, d end
		end
	end
	return best, bd
end
local function rayParams()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {enemiesFolder, fxFolder}
	return rp
end
local function hasLOS(e, tc)
	local o = e.Hrp.Position + Vector3.new(0, 1.5, 0)
	local r = workspace:Raycast(o, tc.HumanoidRootPart.Position - o, rayParams())
	return r == nil or r.Instance:IsDescendantOf(tc)
end
local function enemyShoot(e, tc)
	local cfg = e.Cfg
	local origin = e.Gun.Position + e.Hrp.CFrame.LookVector * 0.8
	local target = tc.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
	local dir = (target - origin).Unit
	local rp = rayParams()
	for _ = 1, cfg.Pellets do
		local d = spreadDir(dir, cfg.Spread)
		local r = workspace:Raycast(origin, d * 200, rp)
		local hitPos = r and r.Position or origin + d * 200
		tracer(origin, hitPos, cfg.Eye)
		if r then
			local mdl = r.Instance:FindFirstAncestorOfClass("Model")
			local h = mdl and mdl:FindFirstChildOfClass("Humanoid")
			if h and Players:GetPlayerFromCharacter(mdl) then h:TakeDamage(cfg.Dmg) end
		end
	end
	playSound(SOUNDS.Shot, e.Gun)
end
local function swing(e)
	e.Busy = true
	local rs = e.J.RS
	TweenService:Create(rs, TweenInfo.new(0.12), {C0 = e.Base.RS * CFrame.Angles(0, 0, math.rad(150))}):Play()
	task.delay(0.14, function()
		if rs.Parent then TweenService:Create(rs, TweenInfo.new(0.25), {C0 = e.Base.RS}):Play() end
	end)
	task.delay(0.45, function() e.Busy = false end)
end
local function runAI(e)
	task.spawn(function()
		local hum, hrp, cfg, m = e.Hum, e.Hrp, e.Cfg, e.Model
		local lastAtk = 0
		e.strafeDir = math.random() < 0.5 and 1 or -1
		e.strafeT = 0
		task.wait(math.random() * 2 + 1)
		while hum.Health > 0 and m.Parent do
			local tc, dist = nearestPlayer(hrp.Position)
			if tc then
				local tr = tc.HumanoidRootPart
				local now = os.clock()
				local flat = Vector3.new(tr.Position.X, hrp.Position.Y, tr.Position.Z)
				local look = CFrame.lookAt(hrp.Position, flat)
				if cfg.Gun then
					local range = cfg.Range
					if dist <= range * 1.05 and hasLOS(e, tc) then
						hrp.CFrame = look
						if now - lastAtk >= cfg.Cd then lastAtk = now; enemyShoot(e, tc) end
					end
					if dist > range * 0.9 then hum:MoveTo(tr.Position)
					elseif dist < range * 0.45 then
						local away = hrp.Position + (hrp.Position - tr.Position).Unit * 8
						hum:MoveTo(away)
					else
						if now > e.strafeT then
							e.strafeT = now + math.random() * 1.5 + 0.8
							e.strafeDir = math.random() < 0.5 and 1 or -1
						end
						hum:MoveTo(hrp.Position + look.RightVector * e.strafeDir * 6)
					end
					if hasLOS(e, tc) then hrp.CFrame = look end
				else
					if dist <= 5 then
						hum:MoveTo(hrp.Position); hrp.CFrame = look
						if now - lastAtk >= cfg.Cd then
							lastAtk = now; swing(e)
							task.delay(0.15, function()
								local th = tc:FindFirstChildOfClass("Humanoid")
								if hum.Health > 0 and th and th.Health > 0 and tc:FindFirstChild("HumanoidRootPart")
									and (tc.HumanoidRootPart.Position - hrp.Position).Magnitude < 7 then
									th:TakeDamage(cfg.Dmg)
								end
							end)
						end
					else hum:MoveTo(tr.Position) end
				end
				if dist > 8 and hrp.AssemblyLinearVelocity.Magnitude < 1 then hum.Jump = true end
			end
			task.wait(0.08)
		end
	end)
end
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, e in pairs(enemies) do
		if e.Hrp.Parent then
			local v = e.Hrp.AssemblyLinearVelocity
			local sp = Vector3.new(v.X, 0, v.Z).Magnitude
			local s = math.sin(t * 11) * math.clamp(sp / 10, 0, 1) * 0.9
			e.J.RH.C0 = e.Base.RH * CFrame.Angles(0, 0, s)
			e.J.LH.C0 = e.Base.LH * CFrame.Angles(0, 0, s)
			if not e.Cfg.Gun then
				e.J.LS.C0 = e.Base.LS * CFrame.Angles(0, 0, -s)
				if not e.Busy then e.J.RS.C0 = e.Base.RS * CFrame.Angles(0, 0, -s) end
			else e.J.LS.C0 = e.Base.LS * CFrame.Angles(0, 0, -s * 0.5) end
		end
	end
end)

------------------------------------------------------------------ ВОЛНЫ / ДВЕРЬ
local onCleared, startLevel, startBase
local function broadcast()
	StateRE:FireAllClients(currentLevel, currentName, enemiesLeft, currentWave, totalWaves)
end

local function spawnEnemy(kind, pos, token)
	local cfg = Types[kind]
	local m, hum, hrp, j, gun = buildRig(cfg, CFrame.new(pos))
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	hum.HealthDisplayDistance = 60
	if cfg.Boss then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer; hum.NameDisplayDistance = 80 end
	m:SetAttribute("Enemy", true)
	m.Parent = enemiesFolder
	hrp:SetNetworkOwner(nil)
	local e = {Model=m, Hum=hum, Hrp=hrp, Cfg=cfg, J=j, Gun=gun,
		Base={RS=j.RS.C0, LS=j.LS.C0, RH=j.RH.C0, LH=j.LH.C0}}
	enemies[m] = e
	hum.Died:Connect(function()
		enemies[m] = nil
		ragdoll(m)
		Debris:AddItem(m, 12)
		if token == levelToken then
			enemiesLeft -= 1
			broadcast()
			if enemiesLeft <= 0 then task.spawn(onCleared, currentLevel, token) end
		end
	end)
	runAI(e)
end

local function spawnWave(w, token, info)
	currentWave = w
	local L = Levels[currentLevel]
	local wave = L.Waves[w]
	local count = 0
	for _, pair in ipairs(wave) do count += pair[2] end
	enemiesLeft = count
	local spots = info.GetSpots(count)
	local i = 0
	for _, pair in ipairs(wave) do
		for _ = 1, pair[2] do i += 1; spawnEnemy(pair[1], spots[i], token) end
	end
	broadcast()
end

-- ИСПРАВЛЕННАЯ ДВЕРЬ
local function makeExitDoor(cf, roomH)
 local height = currentLevel == 1 and 8 or math.min(10, (roomH or 14) - 2)
 local width = currentLevel == 1 and 6 or 9
 local base = cf * CFrame.new(0, -cf.Y, 0)
 local function piece(size, offset, color, material)
  local p = part(levelFolder, size, Vector3.zero, color, material)
  p.CFrame = base * offset
  return p
 end
 for _, x in ipairs({-width/2-0.35, width/2+0.35}) do
  piece(Vector3.new(0.7,height,1.2), CFrame.new(x,height/2,0), C(25,30,40), Enum.Material.Metal)
 end
 piece(Vector3.new(width+1.4,0.7,1.2), CFrame.new(0,height+0.35,0), C(25,30,40), Enum.Material.Metal)
 local d = piece(Vector3.new(width,height,0.65), CFrame.new(0,height/2,0), C(50,60,72), Enum.Material.DiamondPlate)
 d.Name = "ExitDoor"
 local ind = piece(Vector3.new(width-1,0.25,0.2), CFrame.new(0,height+0.35,0.75), C(255,40,50), Enum.Material.Neon)
 ind.Name = "DoorIndicator"
 light(ind, C(255,40,50), 15, 1.8)
 for _, z in ipairs({-0.5,0.5}) do
  local handle = piece(Vector3.new(0.3,1.8,0.25), CFrame.new(width/2-1,height/2,z), C(160,180,190), Enum.Material.Metal)
  handle.Anchored = false; handle.CanCollide = false
  local weld = Instance.new("WeldConstraint"); weld.Part0=d; weld.Part1=handle; weld.Parent=handle
 end
 return d, ind
end

local function prepareEntrance()
 entranceUsed=false
 local indicator
 breachDoor, indicator = makeExitDoor(CFrame.new(0,4,12),12)
 breachDoor.Name="BreachableEntrance"
 indicator.Name="BreachIndicator"
 indicator.Color=C(255,180,60)
 DoorStateRE:FireAllClients(breachDoor.Position,true)
 NotifyRE:FireAllClients("Вход в дом: [E] — выбить ногой. Выход с обратной стороны откроется после зачистки.",7)
end

local function unlockDoor()
	if not currentExitDoor then return end
	doorUnlocked = true
	local ind = levelFolder:FindFirstChild("DoorIndicator")
	if ind then
		ind.Color = C(40, 255, 130)
		local l = ind:FindFirstChildOfClass("PointLight")
		if l then l.Color = C(40, 255, 130); l.Brightness = 3; l.Range = 18 end
	end
	DoorStateRE:FireAllClients(currentExitDoor.Position, true)
	NotifyRE:FireAllClients("Дверь открыта! Подойди и выбей её (E).", 5)
end

------------------------------------------------------------------ ЛЕС
local function buildForest(f)
	local rng = Random.new(7)
	local info = {}
	part(f, Vector3.new(500,2,500), Vector3.new(0,-1,0), C(52,96,46), Enum.Material.Grass)
	local W, H = 24, 12
	local wood, dark = C(120,80,50), C(80,50,35)
	local WM = Enum.Material.Wood
	part(f, Vector3.new(W,0.3,W), Vector3.new(0,0.15,0), C(150,105,70), Enum.Material.WoodPlanks)
	-- Rear exit uses the same real 6 x 8 opening as the front entrance.
 for _, sign in ipairs({-1,1}) do
  part(f,Vector3.new(9,H,1),Vector3.new(sign*7.5,H/2,-W/2),wood,WM)
 end
 part(f,Vector3.new(6,4,1),Vector3.new(0,10,-W/2),wood,WM)
	part(f, Vector3.new(1,H,W), Vector3.new(-W/2,H/2,0), wood, WM)
	part(f, Vector3.new(1,H,W), Vector3.new(W/2,H/2,0), wood, WM)
	local seg = (W-6)/2
	part(f, Vector3.new(seg,H,1), Vector3.new(-(3+seg/2),H/2,W/2), wood, WM)
	part(f, Vector3.new(seg,H,1), Vector3.new(3+seg/2,H/2,W/2), wood, WM)
	part(f, Vector3.new(6,H-8,1), Vector3.new(0,8+(H-8)/2,W/2), wood, WM)
	part(f, Vector3.new(W+4,1,W+4), Vector3.new(0,H+0.5,0), dark, WM)
	part(f, Vector3.new(W-2,2.5,W-2), Vector3.new(0,H+2,0), dark, WM)
	part(f, Vector3.new(3,6,3), Vector3.new(7,H+4,-6), C(90,90,95), Enum.Material.Brick)
	for _, z in ipairs({-6, 6}) do
		part(f, Vector3.new(0.2,3,4), Vector3.new(-W/2-0.55,6,z), C(220,180,110))
		part(f, Vector3.new(0.2,3,4), Vector3.new(W/2+0.55,6,z), C(220,180,110))
	end
	local bulb = part(f, Vector3.new(1.2,1.2,1.2), Vector3.new(0,H-1,0), C(220,200,150))
	local l = light(bulb, C(220,190,140), 30, 1.5); l.Shadows = true
	part(f, Vector3.new(4,1.5,7), Vector3.new(-8,0.9,-8), C(180,120,150), Enum.Material.Fabric)
	part(f, Vector3.new(5,2.2,3), Vector3.new(7,1.2,-7), dark, WM)
	part(f, Vector3.new(7,5,0.2), Vector3.new(0,6,-W/2+0.6), C(180,70,140))
	part(f, Vector3.new(5,3.5,0.2), Vector3.new(-8,6.5,-W/2+0.6), C(90,140,200))
	part(f, Vector3.new(6,0.1,60), Vector3.new(0,0.05,42), C(120,115,105), Enum.Material.Cobblestone)
	for _, z in ipairs({22, 38, 54}) do
		for _, x in ipairs({-5, 5}) do
			part(f, Vector3.new(0.4,6,0.4), Vector3.new(x,3,z), C(30,30,35), Enum.Material.Metal)
			local b = part(f, Vector3.new(1,1,1), Vector3.new(x,6.3,z), C(220,190,130))
			light(b, C(220,190,130), 24, 1.2)
		end
	end
	for _ = 1, 140 do
		local x, z = rng:NextNumber(-120,120), rng:NextNumber(-120,120)
		if (math.abs(x) < 20 and math.abs(z) < 20) or (math.abs(x) < 8 and z > 0) or (x > 10 and z > 20) then continue end
		local h = rng:NextNumber(14, 24)
		part(f, Vector3.new(2,h,2), Vector3.new(x,h/2,z), C(75,50,35), WM)
		for i = 0, 2 do
			local s = rng:NextNumber(10, 14) - i * 2
			local leaf = part(f, Vector3.new(s,s,s), Vector3.new(x+rng:NextNumber(-1,1), h+i*3, z+rng:NextNumber(-1,1)),
				C(30+rng:NextInteger(0,25), 70+rng:NextInteger(0,40), 35), Enum.Material.Grass)
			leaf.Shape = Enum.PartType.Ball
		end
	end
	local ff = part(f, Vector3.new(240,10,240), Vector3.new(0,6,0), C(255,255,255)); ff.Transparency = 1; ff.CanCollide = false; ff.CanQuery = false
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(C(200,230,110)); pe.LightEmission = 1; pe.Size = NumberSequence.new(0.35)
	pe.Lifetime = NumberRange.new(5, 8); pe.Speed = NumberRange.new(0.5, 2); pe.Rate = 40
	pe.Shape = Enum.ParticleEmitterShape.Box; pe.Parent = ff
	for _, d in ipairs({{0,128,262,6},{0,-128,262,6},{128,0,6,262},{-128,0,6,262}}) do
		part(f, Vector3.new(d[3],70,d[4]), Vector3.new(d[1],35,d[2]), C(95,95,90), Enum.Material.Slate)
	end
	info.Spawn = CFrame.lookAt(Vector3.new(0,4,70), Vector3.new(0,4,0))
	info.ExitDoorCF = CFrame.new(0, 4, -W/2)
	info.GetSpots = function(n)
		local t = {}
		for i = 1, n do
			t[i] = Vector3.new((i-1) * 4 - (n-1)*2, 3.2, -5 - ((i-1) * 3))
		end
		return t
	end
	return info
end

------------------------------------------------------------------ КОМНАТЫ
local RoomCfg = {
	[2] = {W=50, H=14, D=60,  Floor=C(110,85,65),  FM=Enum.Material.WoodPlanks, Wall=C(200,185,180), Neon=C(120,70,90), Crates=5},
	[3] = {W=70, H=18, D=80,  Floor=C(180,190,200),FM=Enum.Material.Marble,     Wall=C(210,215,225), Neon=C(70,105,120), Crates=7},
	[4] = {W=90, H=22, D=100, Floor=C(80,80,85),   FM=Enum.Material.Concrete,   Wall=C(115,105,95),  Neon=C(130,95,50),  Crates=12},
	[5] = {W=100,H=24, D=120, Floor=C(40,40,50),   FM=Enum.Material.DiamondPlate,Wall=C(60,60,75),   Neon=C(110,35,45),  Crates=14},
}
local function buildRoom(f, c)
	local W, H, D = c.W, c.H, c.D
	local rng = Random.new(c.W)
	part(f, Vector3.new(W+2,1,D+2), Vector3.new(0,-0.5,0), c.Floor, c.FM)
	part(f, Vector3.new(W+2,1,D+2), Vector3.new(0,H+0.5,0), c.Wall, Enum.Material.Concrete)
	-- A real opening, not a door placed in front of a solid wall.
 for _, sign in ipairs({-1,1}) do
  part(f, Vector3.new((W-10)/2,H,1), Vector3.new(sign*(W+10)/4,H/2,-D/2-0.5), c.Wall, Enum.Material.Concrete)
 end
 part(f, Vector3.new(10,H-10,1), Vector3.new(0,10+(H-10)/2,-D/2-0.5), c.Wall, Enum.Material.Concrete)
	part(f, Vector3.new(W+2,H,1), Vector3.new(0,H/2,D/2+0.5), c.Wall, Enum.Material.Concrete)
	part(f, Vector3.new(1,H,D+2), Vector3.new(-W/2-0.5,H/2,0), c.Wall, Enum.Material.Concrete)
	part(f, Vector3.new(1,H,D+2), Vector3.new(W/2+0.5,H/2,0), c.Wall, Enum.Material.Concrete)
	part(f, Vector3.new(W,0.3,0.2), Vector3.new(0,H-1.5,-D/2+0.2), c.Neon)
	part(f, Vector3.new(W,0.3,0.2), Vector3.new(0,H-1.5,D/2-0.2), c.Neon)
	part(f, Vector3.new(0.2,0.3,D), Vector3.new(-W/2+0.2,H-1.5,0), c.Neon)
	part(f, Vector3.new(0.2,0.3,D), Vector3.new(W/2-0.2,H-1.5,0), c.Neon)
	for ix = -1, 1 do for iz = -2, 2 do
			local lp = part(f, Vector3.new(6,0.3,1.5), Vector3.new(ix*W/3, H-0.2, iz*D/5), C(230,225,215))
			if (ix + iz) % 2 == 0 then light(lp, c.Neon:Lerp(C(240,240,240), 0.6), 35, 1.0) end
		end end
	for _ = 1, c.Crates do
		local s = rng:NextNumber(4, 7)
		local cr = part(f, Vector3.new(s,s,s), Vector3.new(rng:NextNumber(-W/2+6, W/2-6), s/2, rng:NextNumber(-D/6, D/6)),
			c.Wall:Lerp(C(60,60,60), 0.4), Enum.Material.Metal, CFrame.Angles(0, rng:NextNumber(0,3), 0))
		part(f, Vector3.new(s+0.1,0.2,s+0.1), cr.Position + Vector3.new(0, s/2-0.5, 0), c.Neon, nil, CFrame.Angles(0, select(2, cr.CFrame:ToEulerAnglesYXZ()), 0))
	end
	local info = {}
	info.Spawn = CFrame.lookAt(Vector3.new(0,4,D/2-6), Vector3.new(0,4,0))
	info.ExitDoorCF = CFrame.new(0, 5, -D/2-0.5)
	info.GetSpots = function(n)
		local t = {}
		for i = 1, n do t[i] = Vector3.new(rng:NextNumber(-W/2+5, W/2-5), 3.2, rng:NextNumber(-D/2+5, -D/6-3)) end
		return t
	end
	return info
end


local function buildLaboratory(f)
 local info=buildRoom(f,RoomCfg[3])
 -- Dedicated side bays leave the central combat and exit lane unobstructed.
 for _, sign in ipairs({-1,1}) do
  part(f,Vector3.new(1,12,38),Vector3.new(sign*23,6,0),C(175,195,210),Enum.Material.Metal)
  for _, z in ipairs({-24,0,24}) do
   local desk=part(f,Vector3.new(7,3,5),Vector3.new(sign*29,1.5,z),C(210,220,225),Enum.Material.Metal)
   part(f,Vector3.new(7.4,0.3,5.4),desk.Position+Vector3.new(0,1.7,0),C(235,245,250))
   local screen=part(f,Vector3.new(4,2.5,0.3),Vector3.new(sign*29,4.5,z-1.5),C(30,160,190))
   screen.Material=Enum.Material.SmoothPlastic
  end
 end
 return info
end

------------------------------------------------------------------ БАЗА
local function buildBase(f)
	local info = {Lamps = {}, Alarms = {}}
	local W, D, H = 50, 50, 16
	local metal = C(70,76,88)
	part(f, Vector3.new(600,2,600), Vector3.new(0,-1.01,0), C(35,35,40), Enum.Material.Asphalt)
	part(f, Vector3.new(W,0.2,D), Vector3.new(0,0.1,0), C(60,64,74), Enum.Material.DiamondPlate)
	part(f, Vector3.new(W,H,1), Vector3.new(0,H/2,-D/2), metal, Enum.Material.Metal)
	part(f, Vector3.new(1,H,D), Vector3.new(-W/2,H/2,0), metal, Enum.Material.Metal)
	part(f, Vector3.new(1,H,D), Vector3.new(W/2,H/2,0), metal, Enum.Material.Metal)
	part(f, Vector3.new(20,H,1), Vector3.new(-15,H/2,D/2), metal, Enum.Material.Metal)
	part(f, Vector3.new(20,H,1), Vector3.new(15,H/2,D/2), metal, Enum.Material.Metal)
	part(f, Vector3.new(10,H-10,1), Vector3.new(0,10+(H-10)/2,D/2), metal, Enum.Material.Metal)
	part(f, Vector3.new(W+1,1,D+1), Vector3.new(0,H+0.5,0), metal, Enum.Material.Metal)
	local door = part(f, Vector3.new(10,10,1), Vector3.new(0,5,D/2), C(95,100,112), Enum.Material.DiamondPlate)
	door.Name = "Door"; info.Door = door
	for _, p in ipairs({{-12,-12},{12,-12},{-12,12},{12,12}}) do
		local lp = part(f, Vector3.new(8,0.3,2), Vector3.new(p[1],H-0.3,p[2]), C(200,220,235))
		table.insert(info.Lamps, {lp, light(lp, C(200,220,235), 35, 1.3)})
	end
	for _, p in ipairs({{-24,-24},{24,-24},{-24,24},{24,24}}) do
		local al = part(f, Vector3.new(1.2,1.2,1.2), Vector3.new(p[1],H-2,p[2]), C(35,0,0))
		local lt = light(al, C(255,30,40), 40, 2.5); lt.Enabled = false
		table.insert(info.Alarms, {al, lt})
	end
	part(f, Vector3.new(8,3,4), Vector3.new(-9,1.6,-4), metal, Enum.Material.Metal)
	local holo = part(f, Vector3.new(6,0.2,3), Vector3.new(-9,3.2,-4), C(0,200,180)); holo.Transparency = 0.3
	for i = -1, 1 do part(f, Vector3.new(10,6,0.3), Vector3.new(i*13,9,-D/2+0.7), C(35,100,200)).Transparency = 0.25 end
	part(f, Vector3.new(6,3,3), Vector3.new(14,1.6,-14), C(50,55,60), Enum.Material.Metal)
	local rng = Random.new(3)
	for _ = 1, 40 do
		local x, z = rng:NextNumber(-90, 90), rng:NextNumber(40, 150)
		if math.abs(x) < 10 then continue end
		local sx, sy, sz = rng:NextNumber(6,16), rng:NextNumber(8,45), rng:NextNumber(6,16)
		local b = part(f, Vector3.new(sx,sy,sz), Vector3.new(x,sy/2,z), C(40,42,50), Enum.Material.Concrete, CFrame.Angles(0, rng:NextNumber(0,3), 0))
		if rng:NextNumber() < 0.35 then
			local fire = Instance.new("Fire"); fire.Size = 14; fire.Heat = 12; fire.Parent = b
			light(b, C(255,140,60), 40, 1.8)
		end
	end
	for _, d in ipairs({{0,175,356,6},{0,-175,356,6},{175,0,6,356},{-175,0,6,356}}) do
		part(f, Vector3.new(d[3],50,d[4]), Vector3.new(d[1],25,d[2]), C(55,57,64), Enum.Material.Concrete)
	end
	info.Spawn = CFrame.lookAt(Vector3.new(0,4,-16), Vector3.new(0,4,25))
	info.CommanderCF = CFrame.lookAt(Vector3.new(7,3,-4), Vector3.new(0,3,-16))
	info.NeuroCF = CFrame.lookAt(Vector3.new(0,3,62), Vector3.new(0,3,0))
	info.CitadelPos = Vector3.new(0, 0, 250)
	return info
end

------------------------------------------------------------------ ЦИТАДЕЛЬ
local function buildCitadel(f, position)
	local W = 100
	part(f, Vector3.new(W*1.2, 10, W*1.2), position + Vector3.new(0, 5, 0), C(20, 20, 30), Enum.Material.Concrete)
	part(f, Vector3.new(W*0.6, 180, W*0.6), position + Vector3.new(0, 90, 0), C(15, 15, 25), Enum.Material.Metal)
	for ring = 1, 8 do
		local y = ring * 18
		local radius = 35 + ring * 3
		local count = 8 + ring * 2
		for i = 1, count do
			local angle = (i / count) * math.pi * 2
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			part(f, Vector3.new(2.5, 4, 1.5), position + Vector3.new(x, y + 2, z), C(85, 35, 55), Enum.Material.SmoothPlastic)
			part(f, Vector3.new(1.8, 1.5, 1.5), position + Vector3.new(x, y + 5, z), C(180, 155, 145), Enum.Material.SmoothPlastic)
			part(f, Vector3.new(1.2, 0.4, 0.3), position + Vector3.new(x, y + 5, z - 0.7), C(255, 40, 60), Enum.Material.Neon)
		end
	end
	local beacon = part(f, Vector3.new(15, 15, 15), position + Vector3.new(0, 195, 0), C(255, 30, 50), Enum.Material.Neon)
	light(beacon, C(255, 30, 50), 150, 8)
	for _, off in ipairs({Vector3.new(50,0,0), Vector3.new(-50,0,0), Vector3.new(0,0,50), Vector3.new(0,0,-50)}) do
		local spot = part(f, Vector3.new(2, 2, 2), position + off + Vector3.new(0, 60, 0), C(255, 30, 50), Enum.Material.Neon)
		light(spot, C(255, 30, 50), 80, 5)
	end
end

------------------------------------------------------------------ ХЕЛИКОПТЕР
local function buildHelicopter(cf)
	local m = Instance.new("Model"); m.Name = "Helicopter"
	local function mk(size, color, mat, offset)
		local p = Instance.new("Part")
		p.Size = size; p.Color = color; p.Material = mat or Enum.Material.Metal
		p.Anchored = true; p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf * offset
		p.Parent = m
		return p
	end
	local body = mk(Vector3.new(7, 5, 11), C(55, 65, 45), Enum.Material.Metal, CFrame.new(0, 0, 0))
	m.PrimaryPart = body
 body.Transparency=1
 -- Open cabin with a visible starboard doorway for boarding.
 local cabinFloor=mk(Vector3.new(7,0.4,11),C(35,43,39),Enum.Material.Metal,CFrame.new(0,-2.4,0))
 cabinFloor.CanCollide=true
 mk(Vector3.new(7,0.4,11),C(55,65,45),Enum.Material.Metal,CFrame.new(0,2.4,0))
 mk(Vector3.new(0.3,4.5,11),C(55,65,45),Enum.Material.Metal,CFrame.new(-3.4,0,0))
 for _, z in ipairs({-4.3,4.3}) do
  mk(Vector3.new(0.3,4.5,2.4),C(55,65,45),Enum.Material.Metal,CFrame.new(3.4,0,z))
 end
 mk(Vector3.new(7,4.5,0.3),C(55,65,45),Enum.Material.Metal,CFrame.new(0,0,-5.4))
 local boardingRamp=mk(Vector3.new(2.5,0.3,4),C(35,40,45),Enum.Material.Metal,CFrame.new(4.4,-2.4,0))
 boardingRamp.CanCollide=true
 for _, x in ipairs({-2,2}) do
  mk(Vector3.new(1.6,0.6,6),C(20,25,30),Enum.Material.Fabric,CFrame.new(x,-1.8,0))
 end
 mk(Vector3.new(4.5, 3.5, 3), C(20, 30, 40), Enum.Material.Glass, CFrame.new(0, 1, 5))
	mk(Vector3.new(1.5, 1.5, 9), C(55, 65, 45), Enum.Material.Metal, CFrame.new(0, 2, -9))
	mk(Vector3.new(0.3, 5, 1), C(25, 25, 30), Enum.Material.Metal, CFrame.new(0, 2, -13))
	mk(Vector3.new(20, 0.2, 2), C(25, 25, 30), Enum.Material.Metal, CFrame.new(0, 4, 0))
	mk(Vector3.new(2, 0.2, 20), C(25, 25, 30), Enum.Material.Metal, CFrame.new(0, 4, 0))
	for _, x in ipairs({-2.8, 2.8}) do
		mk(Vector3.new(0.4, 0.4, 9), C(30, 30, 30), Enum.Material.Metal, CFrame.new(x, -4, 0))
	end
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p ~= body then
			local w = Instance.new("WeldConstraint"); w.Part0 = body; w.Part1 = p; w.Parent = p
		end
	end
	return m
end

------------------------------------------------------------------ САМОЛЁТ
local function buildPlane(cf)
	local m = Instance.new("Model"); m.Name = "Plane"
	local function mk(size, color, mat, offset)
		local p = Instance.new("Part")
		p.Size = size; p.Color = color; p.Material = mat or Enum.Material.Metal
		p.Anchored = true; p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf * offset
		p.Parent = m
		return p
	end
	local body = mk(Vector3.new(5, 4, 22), C(230,230,240), Enum.Material.Metal, CFrame.new(0, 0, 0))
	m.PrimaryPart = body
	mk(Vector3.new(4, 3, 4), C(30,50,80), Enum.Material.Glass, CFrame.new(0, 0.5, 11))
	mk(Vector3.new(28, 0.5, 4), C(220,220,230), Enum.Material.Metal, CFrame.new(0, 0, 0))
	mk(Vector3.new(0.5, 4, 3), C(220,220,230), Enum.Material.Metal, CFrame.new(0, 2, -11))
	mk(Vector3.new(9, 0.5, 2), C(220,220,230), Enum.Material.Metal, CFrame.new(0, 1, -11))
	for _, x in ipairs({-3, 3}) do
		mk(Vector3.new(1, 1, 3), C(60,60,70), Enum.Material.Metal, CFrame.new(x, -1, 0))
	end
	mk(Vector3.new(5.2, 0.5, 22), C(200,50,60), Enum.Material.SmoothPlastic, CFrame.new(0, -1.5, 0))
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p ~= body then
			local w = Instance.new("WeldConstraint"); w.Part0 = body; w.Part1 = p; w.Parent = p
		end
	end
	return m
end

local function setCharTransparency(char, val)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = val
		end
	end
end
local function placeCharAt(char, cf) char:PivotTo(cf) end
local function moveModel(model, target, duration, walk)
 local origin = model:GetPivot()
 local start = os.clock()
 local joints = {}
 if walk then
  for _, j in ipairs(model:GetDescendants()) do
   if j:IsA("Motor6D") and (j.Name:find("Hip") or j.Name:find("Shoulder")) then joints[j] = j.C0 end
  end
 end
 repeat
  local t = math.clamp((os.clock()-start)/duration,0,1)
  model:PivotTo(origin:Lerp(target, t*t*(3-2*t)))
  for j, cf in pairs(joints) do
   local sign = j.Name:find("Left") and -1 or 1
   local hip=j.Name:find("Hip")
   local angle=math.sin(t*duration*10)*0.5*sign*(hip and 1 or -0.7)
   j.C0=cf*CFrame.fromAxisAngle(cf:VectorToObjectSpace(Vector3.xAxis),angle)
  end
  if walk then
   -- NPC rigs are anchored: explicitly solve their motors so legs actually move.
   for _=1,3 do
    for _,motor in ipairs(model:GetDescendants()) do
     if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
      motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.Transform*motor.C1:Inverse()
     end
    end
   end
  end
  RunService.Heartbeat:Wait()
 until os.clock()-start >= duration or not model.Parent
 if model.Parent then model:PivotTo(target) end
 for j, cf in pairs(joints) do j.C0 = cf end
end
-- Grounded cinematic blocking: fixed walking speed, raycast support and no physics fall state.
local function tweenCharTo(char, target, _duration)
 local root=char:FindFirstChild("HumanoidRootPart")
 local hum=char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then return false end
 local wasAnchored=root.Anchored
 root.Anchored=true; root.AssemblyLinearVelocity=Vector3.zero
 local animate=char:FindFirstChild("Animate")
 local animateEnabled=animate and not animate.Disabled
 if animate then animate.Disabled=true end
 local animator=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
 for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.1) end
 local animation=Instance.new("Animation")
 animation.AnimationId=hum.RigType==Enum.HumanoidRigType.R15 and "rbxassetid://507777826" or "rbxassetid://180426354"
 local track
 pcall(function() track=animator:LoadAnimation(animation); track.Priority=Enum.AnimationPriority.Action; track.Looped=true; track:Play(0.12); track:AdjustSpeed(1.5) end)
 local filter={char}
 for _,player in ipairs(Players:GetPlayers()) do if player.Character then table.insert(filter,player.Character) end end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances=filter; params.RespectCanCollide=true
 local clearance=hum.HipHeight+root.Size.Y/2
 if hum.RigType==Enum.HumanoidRigType.R6 then clearance=3 end
 local start=root.Position
 local distance=((target.Position-start)*Vector3.new(1,0,1)).Magnitude
 local duration=math.max(distance/12,0.12) -- consistent 12 studs/s, not 3-stud/s shuffling
 local began=os.clock(); local reached=true
 char:SetAttribute("CinematicWalk",true)
 repeat
  local t=math.clamp((os.clock()-began)/duration,0,1)
  local nextPosition=start:Lerp(target.Position,t)
  local floor=workspace:Raycast(nextPosition+Vector3.new(0,4,0),Vector3.new(0,-12,0),params)
  if not floor then reached=false; break end
  nextPosition=Vector3.new(nextPosition.X,floor.Position.Y+clearance,nextPosition.Z)
  local delta=(nextPosition-root.Position)*Vector3.new(1,0,1)
  local obstacle=workspace:Raycast(root.Position,delta,params)
  if obstacle and obstacle.Normal.Y<0.5 then reached=false; break end
  if delta.Magnitude>0.001 then
   local facing=CFrame.lookAt(nextPosition,nextPosition+delta.Unit)
   local rotation=root.CFrame:Lerp(facing,0.45).Rotation
   root.CFrame=CFrame.new(nextPosition)*rotation
  else root.Position=nextPosition end
  RunService.Heartbeat:Wait()
 until os.clock()-began>=duration or not char.Parent or hum.Health<=0
 char:SetAttribute("CinematicWalk",false)
 if track then track:Stop(0.12); track:Destroy() end
 animation:Destroy()
 if animate then animate.Disabled=not animateEnabled end
 root.AssemblyLinearVelocity=Vector3.zero
 root.Anchored=wasAnchored
 if not reached then warn("Cinematic route has no support or is obstructed: "..char.Name) end
 return reached
end

local function sceneLock(on)
 for _, player in ipairs(Players:GetPlayers()) do
  player:SetAttribute("InCinematic", on)
  local char = player.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  local root = char and char:FindFirstChild("HumanoidRootPart")
  local animate=char and char:FindFirstChild("Animate")
  if animate then
   if on then
    if animate:GetAttribute("SceneOriginalDisabled")==nil then animate:SetAttribute("SceneOriginalDisabled",animate.Disabled) end
    animate.Disabled=true
   else
    local disabled=animate:GetAttribute("SceneOriginalDisabled")
    if disabled~=nil then animate.Disabled=disabled; animate:SetAttribute("SceneOriginalDisabled",nil) end
   end
  end
  if hum then
   hum:SetStateEnabled(Enum.HumanoidStateType.Freefall,not on)
   hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,not on)
   if on and hum.Health>0 then
    hum:ChangeState(Enum.HumanoidStateType.Running)
    local animator=hum:FindFirstChildOfClass("Animator")
    if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.1) end end
   end
   hum.WalkSpeed = on and 0 or 16
   hum.JumpPower = on and 0 or 50
   hum.JumpHeight = on and 0 or 7.2
   hum.AutoRotate = not on
   hum:UnequipTools()
  end
  if root then root.Anchored=on; root.AssemblyLinearVelocity=Vector3.zero end
 end
end
local function shot(position, target, duration)
 CutsceneRE:FireAllClients("shot", CFrame.lookAt(position,target), duration or 2)
end
local function follow(subject, offset, aim)
 CutsceneRE:FireAllClients("follow",subject,offset,aim or Vector3.new(0,1,0))
end

local function cameraPlan(fromPosition,toPosition,focus,duration,fov0,fov)
 CutsceneRE:FireAllClients("cam",{
  from=CFrame.lookAt(fromPosition,focus), cf=CFrame.lookAt(toPosition,focus),
  time=duration or 4, fov0=fov0 or 58, fov=fov or 52,
 })
end
local recoverScene
local function runScene(callback)
 local ok,err=xpcall(callback,debug.traceback)
 if not ok then
  warn("[Cinematic] "..tostring(err))
  recoverScene()
 end
end

------------------------------------------------------------------ УРОВНИ
Levels = {
	{Name="Лес и домик", Preset="Forest", Build=buildForest,
		Waves={{{"Melee",1}}, {{"Melee",2}}},
		Intro="Иди к домику. Там прячутся две тянки."},
	{Name="Квартира", Preset="Apartment", Build=function(f) return buildRoom(f, RoomCfg[2]) end,
	Waves={{{"Melee",2}}, {{"Pistol",1},{"Melee",1}}},
	Intro="Квартира. Одна с пистолетом — держи дистанцию."},
	{Name="Лаборатория", Preset="Lab", Build=buildLaboratory,
	Waves={{{"Melee",2}}, {{"Pistol",1},{"SMG",1}}, {{"Melee",1},{"SMG",1}}},
	Intro="Лаборатория. ПП стреляют очередями — укрывайся."},
	{Name="Склад", Preset="Warehouse", Build=function(f) return buildRoom(f, RoomCfg[4]) end,
	Waves={{{"Melee",2},{"Pistol",1}}, {{"Shotgun",1},{"SMG",1}}, {{"Melee",2},{"Shotgun",1}}},
	Intro="Склад. Осторожно: дробовики бьют в упор."},
	{Name="Серверная", Preset="Server", Build=function(f) return buildRoom(f, RoomCfg[5]) end,
	Waves={{{"SMG",2}}, {{"Melee",2},{"Shotgun",1}}, {{"Boss",1}}},
	Intro="Серверная. Здесь главная тянка."},
}

local function clearLevel()
	if levelFolder then levelFolder:Destroy() end
	enemies = {}
	fxFolder:ClearAllChildren()
	currentExitDoor = nil; doorUnlocked = false
 breachDoor=nil
end

local function placePlayer(plr, idx)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
		hum.PlatformStand = false
		char:PivotTo(currentSpawn * CFrame.new(((idx or 0) % 4 - 1.5) * 3, 0, 0))
		hum.Health = hum.MaxHealth
	end
end
local function placeAll()
	for i, plr in ipairs(Players:GetPlayers()) do
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then plr:LoadCharacter() else placePlayer(plr, i) end
	end
end
local function newFolders()
	levelFolder = Instance.new("Folder"); levelFolder.Name = "Level"; levelFolder.Parent = workspace
	enemiesFolder = Instance.new("Folder"); enemiesFolder.Name = "Enemies"; enemiesFolder.Parent = levelFolder
end

function startLevel(n)
	levelToken += 1
	local token = levelToken
	canFight = false
	FadeRE:FireAllClients(true, ("ЛОКАЦИЯ %d / 5\n%s"):format(n, Levels[n].Name))
	task.wait(1.3)
	clearLevel(); newFolders()
	currentLevel, currentName = n, Levels[n].Name
	local L = Levels[n]
	local info = L.Build(levelFolder)
 activeLevelInfo=info
	currentSpawn = info.Spawn
	applyPreset(L.Preset, 0.1)
	for _, plr in ipairs(Players:GetPlayers()) do plr:SetAttribute("WeaponLevel", n) end
	placeAll()
 sceneLock(false)
	local door, ind = makeExitDoor(info.ExitDoorCF, RoomCfg[n] and RoomCfg[n].H or 14)
	currentExitDoor = door
	currentDoorCF = info.ExitDoorCF
	doorUnlocked = false
	totalWaves = #L.Waves
	spawnWave(1, token, info)
	task.wait(0.6)
	FadeRE:FireAllClients(false)
	local txt = L.Intro
	if n >= 2 then txt ..= ("\n[Новое оружие: %s — клавиша %d]"):format(WD.Stats[WD.Order[n]].Display, n) end
	NotifyRE:FireAllClients(txt, 6)
 introActive=false
	canFight = true
 if n == 1 then prepareEntrance() end
end

local recovering=false
recoverScene=function()
 if recovering then return end
 recovering=true
 introActive=false; canFight=false; levelToken+=1
 Players.RespawnTime=3
 CutsceneRE:FireAllClients("armyClear")
 for _,object in ipairs(workspace:GetChildren()) do
  if object.Name=="Helicopter" or object.Name=="Plane" then object:Destroy() end
 end
 for _,player in ipairs(Players:GetPlayers()) do
  if player.Character then
   for _,name in ipairs({"CinematicWalk","CinematicSeated","CinematicKick"}) do player.Character:SetAttribute(name,nil) end
  end
 end
 sceneLock(false)
 CreditsRE:FireAllClients(false)
 MusicRE:FireAllClients("stop")
 CutsceneRE:FireAllClients("recover")
 FadeRE:FireAllClients(false)
 local ok,err=pcall(function() startLevel(1) end)
 if not ok then
  warn("[Cinematic recovery] "..tostring(err))
  -- Last-resort supported spawn, even if rebuilding the mission failed.
  local floor=part(workspace,Vector3.new(80,2,80),Vector3.new(0,-1,0),C(65,70,75),Enum.Material.Concrete)
  floor.Name="RecoveryFloor"
  currentSpawn=CFrame.new(0,4,0); placeAll(); sceneLock(false)
  FadeRE:FireAllClients(false)
 end
 NotifyRE:FireAllClients("Сцена прервана из-за ошибки. Управление восстановлено.",6)
 recovering=false
end

function onCleared(n, token)
	if token ~= levelToken then return end
	if currentWave < totalWaves then
		NotifyRE:FireAllClients(("Волна %d / %d зачищена. Готовься!"):format(currentWave, totalWaves), 2.5)
		task.wait(2)
		if token ~= levelToken then return end
		local L = Levels[n]
		local remainingW = L.Waves[currentWave + 1]
		local count = 0
		for _, pair in ipairs(remainingW) do count += pair[2] end
  local spots=activeLevelInfo.GetSpots(count)
		currentWave += 1
		enemiesLeft = count
		local i = 0
		for _, pair in ipairs(remainingW) do
			for _ = 1, pair[2] do i += 1; spawnEnemy(pair[1], spots[i], token) end
		end
		broadcast()
		return
	end
	NotifyRE:FireAllClients("Зона зачищена! Дверь разблокирована.", 2.5)
	task.wait(1.5)
	unlockDoor()
end

------------------------------------------------------------------ ИНТРО-КАТСЦЕНА (без падения)
local function playIntro()
 local player
 for _,candidate in ipairs(Players:GetPlayers()) do if readyClients[candidate] then player=candidate; break end end
 if not player then return end
 local char=player.Character or player.CharacterAdded:Wait()
 char:WaitForChild("HumanoidRootPart")
 task.wait(2)
 introActive=true; canFight=false
 levelToken+=1
 local token=levelToken
 FadeRE:FireAllClients(true, "ОПЕРАТИВНАЯ БАЗА // 06:40")
 task.wait(1)
 clearLevel(); newFolders()
 currentLevel,currentName=1,Levels[1].Name
 local info=Levels[1].Build(levelFolder)
 activeLevelInfo=info
 currentSpawn=info.Spawn
 applyPreset("Forest",0.1)
 for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("WeaponLevel",1) end
 -- An open-front briefing shelter: all walking paths and camera setups stay outside walls.
 local base=Instance.new("Model"); base.Name="BriefingLaboratory"; base.Parent=levelFolder
 local baseOffset=Vector3.new(2000,0,0)
 local function baseCF(cf) return CFrame.new(baseOffset)*cf end
 local function basePoint(point) return point+baseOffset end
 part(base,Vector3.new(180,2,180),Vector3.new(70,-1,55),C(60,72,80),Enum.Material.Concrete)
 -- A closed laboratory with one real 6-stud doorway to the helipad.
 part(base,Vector3.new(1,12,22),Vector3.new(91,6,39),C(55,65,78),Enum.Material.Metal)
 part(base,Vector3.new(30,12,1),Vector3.new(64,6,50),C(55,65,78),Enum.Material.Metal)
 part(base,Vector3.new(6,12,1),Vector3.new(88,6,50),C(55,65,78),Enum.Material.Metal)
 part(base,Vector3.new(6,3,1),Vector3.new(82,10.5,50),C(55,65,78),Enum.Material.Metal)
 for _, x in ipairs({57,70,83}) do briefingLight(base,Vector3.new(x,11.2,39),7,4) end
 for _, z in ipairs({32,41}) do
  part(base,Vector3.new(6,3,5),Vector3.new(54,1.5,z),C(170,190,205),Enum.Material.Metal)
  local monitor=part(base,Vector3.new(4,2,0.3),Vector3.new(54,4,z-1),C(20,160,180)); monitor.Material=Enum.Material.SmoothPlastic
 end
 for _, wall in ipairs({{70,15,-35,180,30,2},{70,15,145,180,30,2},{-20,15,55,2,30,180},{160,15,55,2,30,180}}) do
  part(base,Vector3.new(wall[4],wall[5],wall[6]),Vector3.new(wall[1],wall[2],wall[3]),C(65,78,90),Enum.Material.Concrete)
 end
 local pad=part(base,Vector3.new(24,0.15,24),Vector3.new(70,0.15,65),C(38,48,54),Enum.Material.Metal)
 for _, x in ipairs({60,80}) do
  local lamp=part(base,Vector3.new(0.5,6,0.5),Vector3.new(x,3,76),C(70,85,95),Enum.Material.Metal)
  light(lamp,C(245,235,220),20,0.6)
 end
 part(base,Vector3.new(42,0.2,40),Vector3.new(70,0.1,48),C(85,94,96),Enum.Material.Concrete)
 part(base,Vector3.new(42,12,1),Vector3.new(70,6,28),C(45,55,65),Enum.Material.Metal)
 part(base,Vector3.new(1,12,22),Vector3.new(49,6,39),C(45,55,65),Enum.Material.Metal)
 part(base,Vector3.new(43,0.5,24),Vector3.new(70,12,39),C(40,48,57),Enum.Material.Metal)
 local board=part(base,Vector3.new(14,7,0.2),Vector3.new(70,6,28.7),C(12,28,35),Enum.Material.SmoothPlastic)
 local surface=Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Back; surface.Parent=board
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1
 text.Text="РАЗВЕДКА // ОБЪЕКТ 07\nКРИМИНАЛЬНАЯ БАЗА ОБНАРУЖЕНА\nЛЕСНОЙ СЕКТОР • ВЫСАДКА В 07:00"
 text.TextColor3=C(100,255,220); text.TextScaled=true; text.Font=Enum.Font.GothamBold; text.Parent=surface
 local tableTop=part(base,Vector3.new(9,0.4,5),Vector3.new(70,2.8,37.5),C(35,43,48),Enum.Material.Metal)
 for _,x in ipairs({67,73}) do part(base,Vector3.new(0.6,2.5,3),Vector3.new(x,1.3,37.5),C(35,43,48),Enum.Material.Metal) end
 local hologram=part(base,Vector3.new(3,1.8,2.2),Vector3.new(70,4,37.5),C(75,145,155),Enum.Material.Glass)
 hologram.Transparency=0.55; hologram.CanCollide=false
 for _,x in ipairs({67.5,70,72.5}) do
  part(base,Vector3.new(0.4,0.1,0.4),Vector3.new(x,3.1,37.5),C(170,115,80),Enum.Material.SmoothPlastic)
 end
 local entrance=Instance.new("Model"); entrance.Name="BriefingDoor"; entrance.Parent=base
 local slab=part(entrance,Vector3.new(5.8,9,0.35),Vector3.new(82,4.5,50),C(55,65,70),Enum.Material.Metal)
 entrance.PrimaryPart=slab
 part(entrance,Vector3.new(0.25,1,0.3),Vector3.new(84,4.3,50.3),C(150,155,160),Enum.Material.Metal)
 local commander=buildRig(Types.Commander,CFrame.lookAt(Vector3.new(70,3,34),Vector3.new(70,3,45)))
 -- Only the root is anchored so Motor6D briefing gestures can move the limbs.
 for _,limb in ipairs(commander:GetDescendants()) do
  if limb:IsA("BasePart") then limb.Anchored=limb.Name=="HumanoidRootPart"; limb.CanCollide=false end
 end
 commander.Parent=base
 base:PivotTo(CFrame.new(baseOffset)*base:GetPivot())
 -- Walk to briefing, pause, then walk to the helicopter. No hidden teleport mid-shot.
 for i,p in ipairs(Players:GetPlayers()) do
  if p.Character then p.Character:PivotTo(baseCF(CFrame.lookAt(Vector3.new(81+(i-1)*0.7,3.2,54),Vector3.new(82,3.2,43)))) end
 end
 sceneLock(true)
 CutsceneRE:FireAllClients("start")
 cameraPlan(basePoint(Vector3.new(88,6,60)),basePoint(Vector3.new(87,6,57)),basePoint(Vector3.new(82,4,50)),3,60,54)
 prepareView(basePoint(Vector3.new(82,4,48)))
 FadeRE:FireAllClients(false)
 task.wait(1)
 local closedDoor=entrance:GetPivot()
 moveModel(entrance,closedDoor*CFrame.new(0,9.5,0),1.8)
 follow(char,Vector3.new(4,3,8))
 currentSpawn=baseCF(CFrame.new(82,3.2,46))
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,46)),3)
 tweenCharTo(char,baseCF(CFrame.new(70,3.2,43)),3)
 cameraPlan(basePoint(Vector3.new(81,6,46)),basePoint(Vector3.new(79,6,45)),basePoint(Vector3.new(70,4,35)),6,54,46)
 NotifyRE:FireAllClients("КОМАНДИР: Проходи, спец. Разведка обнаружила ещё одну криминальную базу картеля.",6)
 local shoulder=commander:FindFirstChild("Right Shoulder",true)
 if shoulder then
  local original=shoulder.C0
  TweenService:Create(shoulder,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,2,true),{C0=original*CFrame.Angles(math.rad(25),0,math.rad(-15))}):Play()
 end
 task.wait(6)
 cameraPlan(basePoint(Vector3.new(63,6,44)),basePoint(Vector3.new(65,6,43)),basePoint(Vector3.new(70,5,29)),7,52,44)
 NotifyRE:FireAllClients("КОМАНДИР: Вот снимок объекта. Это перевалочный пункт в лесу. Нужно проникнуть внутрь и зачистить его.",7)
 task.wait(7)
 cameraPlan(basePoint(Vector3.new(77,5.5,43)),basePoint(Vector3.new(76,5.5,42)),basePoint(Vector3.new(70,4.5,34)),7,48,40)
 NotifyRE:FireAllClients("КОМАНДИР: Спешки нет. Подготовься. Вертолёт доставит тебя к южной тропе — дальше пешком.",7)
 task.wait(7)
 local departure=baseCF(CFrame.new(70,4,65))
 local landing=CFrame.new(24,4,60)
 local heli=buildHelicopter(departure); heli.Parent=workspace
 -- Steps align with the open starboard doorway (local X positive, Z=0).
 local function stairs(cf)
  local m=Instance.new("Model"); m.Name="BoardingSteps"; m.Parent=levelFolder
  for i=1,4 do
   local p=part(m,Vector3.new(0.8,i*0.4,4),Vector3.zero,C(50,60,66),Enum.Material.Metal)
   p.CFrame=cf*CFrame.new(7.2-i*0.8,-4+i*0.2,0)
  end
  return m
 end
 local steps=stairs(departure)
 local rotors={}
 for _, p in ipairs(heli:GetChildren()) do
  if p:IsA("BasePart") and p.Size.Y==0.2 then rotors[p]=heli:GetPivot():ToObjectSpace(p.CFrame) end
 end
 local rotorConnection=RunService.Heartbeat:Connect(function()
  if heli.Parent then
   for p,offset in pairs(rotors) do p.CFrame=heli:GetPivot()*CFrame.Angles(0,os.clock()*24,0)*offset end
  end
 end)
 follow(char,Vector3.new(12,7,-10))
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,48)),3)
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,65)),3)
 shot(basePoint(Vector3.new(86,8,77)),basePoint(Vector3.new(72,4,65)),0)
 tweenCharTo(char,baseCF(CFrame.new(77,3.2,65)),2)
 tweenCharTo(char,baseCF(CFrame.new(74.5,4.8,65)),2)
 local boarded=tweenCharTo(char,baseCF(CFrame.new(71.5,4.8,65)),2)
 if not boarded then
  -- Recover only behind a full fade; never show a slide through the fuselage.
  FadeRE:FireAllClients(true,"ПОСАДКА НА БОРТ")
  task.wait(0.8)
  char:PivotTo(departure*CFrame.new(1.5,0.8,0))
 end
 sceneLock(true)
 char:SetAttribute("CinematicSeated",true)
 local ride=RunService.Heartbeat:Connect(function()
  if not heli.Parent then return end
  for i,passenger in ipairs(Players:GetPlayers()) do
   local character=passenger.Character
   if character then
    character:SetAttribute("CinematicSeated",true)
    character:PivotTo(heli:GetPivot()*CFrame.new(1.5,0.8,(i-1)*1.5))
   end
  end
 end)
 steps:Destroy()
 NotifyRE:FireAllClients("ПИЛОТ: Все на борту. Взлетаем. До точки пара минут.",5)
 follow(heli,Vector3.new(20,10,22),Vector3.new(0,1,0))
 FadeRE:FireAllClients(false)
 moveModel(heli,departure*CFrame.new(0,38,0),6)
 -- Separate maps: travel cut is hidden, never fly across an empty world.
 FadeRE:FireAllClients(true,"ПЕРЕЛЁТ // ЛЕСНОЙ СЕКТОР")
 task.wait(1)
 heli:PivotTo(landing*CFrame.new(0,38,0))
 currentSpawn=info.Spawn
 prepareView(landing.Position)
 shot(Vector3.new(43,12,81),landing.Position+Vector3.new(0,5,0),0)
 FadeRE:FireAllClients(false)
 moveModel(heli,landing,7)
 steps=stairs(landing)
 ride:Disconnect()
 for _,passenger in ipairs(Players:GetPlayers()) do
  if passenger.Character then passenger.Character:SetAttribute("CinematicSeated",false) end
 end
 follow(char,Vector3.new(13,7,12))
 tweenCharTo(char,CFrame.new(28.5,4.8,60),2)
 tweenCharTo(char,CFrame.new(31,3.2,60),2)
 tweenCharTo(char,CFrame.new(12,3.2,65),5)
 tweenCharTo(char,CFrame.new(8,3.2,55),3)
 NotifyRE:FireAllClients("ПИЛОТ: Высадка завершена. Дом прямо по тропе. Связь с командиром открыта.",5)
 task.wait(3)
 rotorConnection:Disconnect()
 heli:Destroy(); steps:Destroy()
 CutsceneRE:FireAllClients("end")
 sceneLock(false); introActive=false
 currentSpawn=info.Spawn
 currentExitDoor=makeExitDoor(info.ExitDoorCF,14)
 currentDoorCF=info.ExitDoorCF; doorUnlocked=false
 totalWaves=#Levels[1].Waves
 spawnWave(1,token,info)
 canFight=true
 prepareEntrance()
 MusicRE:FireAllClients("intro")
end

------------------------------------------------------------------ МАФИОЗИ-КАТСЦЕНА
local function playMafioziScene()
	introActive = true
	canFight = false
 sceneLock(true)
	FadeRE:FireAllClients(true, "ОФИС ГЛАВНОЙ ТЯНКИ")
	task.wait(2)
	clearLevel(); newFolders()
	currentLevel, currentName = 5, "Офис"

	-- Строим офис
	local office = levelFolder
	local W, H, D = 30, 12, 30
 -- Entrance starts at Z=18: the original room floor ended at Z=15.5.
 part(office,Vector3.new(44,2,60),Vector3.new(0,-1,7),C(65,62,62),Enum.Material.Concrete)
 for _, sign in ipairs({-1,1}) do
  part(office,Vector3.new(11,12,1),Vector3.new(sign*9.5,6,15.5),C(60,45,35),Enum.Material.Wood)
 end
 part(office,Vector3.new(8,2,1),Vector3.new(0,11,15.5),C(60,45,35),Enum.Material.Wood)
	part(office, Vector3.new(W+2, 1, D+2), Vector3.new(0, -0.5, 0), C(80, 60, 50), Enum.Material.WoodPlanks)
	part(office, Vector3.new(W+2, 1, D+2), Vector3.new(0, H+0.5, 0), C(40, 30, 25), Enum.Material.Wood)
	part(office, Vector3.new(W+2, H, 1), Vector3.new(0, H/2, -D/2-0.5), C(60, 45, 35), Enum.Material.Wood)
	part(office, Vector3.new(1, H, D+2), Vector3.new(-W/2-0.5, H/2, 0), C(60, 45, 35), Enum.Material.Wood)
	part(office, Vector3.new(1, H, D+2), Vector3.new(W/2+0.5, H/2, 0), C(60, 45, 35), Enum.Material.Wood)
	-- Стол
	part(office, Vector3.new(10, 0.3, 5), Vector3.new(0, 3, -8), C(50, 30, 20), Enum.Material.Wood)
	for _, p in ipairs({{-4, -10}, {4, -10}, {-4, -6}, {4, -6}}) do
		part(office, Vector3.new(0.4, 3, 0.4), Vector3.new(p[1], 1.5, p[2]), C(40, 25, 15), Enum.Material.Wood)
	end
	-- Кресло мафиози (спинка)
	part(office, Vector3.new(3, 4, 0.4), Vector3.new(0, 4, -11), C(30, 20, 15), Enum.Material.Wood)
	-- Лампа
	local lamp = part(office, Vector3.new(3, 0.3, 3), Vector3.new(0, H-0.5, -3), C(240,220,160), Enum.Material.Neon)
	light(lamp, C(240,220,160), 20, 2)
	-- Дверь сзади (куда мы врываемся)
	local backDoor = part(office, Vector3.new(8, 10, 0.5), Vector3.new(0, 5, D/2), C(60,60,60), Enum.Material.DiamondPlate)

	-- Мафиози за столом (сидит)
	local mafCfg = Types.Mafiozi
	local maf, mafHum, mafHrp, mafJ = buildRig(mafCfg, CFrame.lookAt(Vector3.new(0, 3, -9), Vector3.new(0, 3, 10)))
	anchorAll(maf); maf.Parent = office
	-- Поза сидящего
	mafJ.RH.C0 = mafJ.RH.C0 * CFrame.Angles(0, 0, math.rad(-75))
	mafJ.LH.C0 = mafJ.LH.C0 * CFrame.Angles(0, 0, math.rad(75))
	-- Руки на стол (опущены)
	mafJ.RS.C0 = mafJ.RS.C0 * CFrame.Angles(math.rad(-20), 0, 0)
	mafJ.LS.C0 = mafJ.LS.C0 * CFrame.Angles(math.rad(-20), 0, 0)

	-- Игрок за дверью
	local plr = Players:GetPlayers()[1]
	local char = plr.Character
 currentSpawn=CFrame.lookAt(Vector3.new(0,3.2,20),Vector3.new(0,3.2,0))
 placeAll()
 sceneLock(true)
	-- Управление выкл
	local h = char:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = 0; h.JumpPower = 0; h.AutoRotate = false end

	applyPreset("Office", 0.5)
	FadeRE:FireAllClients(false, "")
	CutsceneRE:FireAllClients("start")
 shot(Vector3.new(10,7,26),Vector3.new(0,4,15),0)
	task.wait(1)

	-- Врываемся через дверь
	NotifyRE:FireAllClients("Вы врываетесь в дверь!", 2)
	backDoor.Anchored = false
	backDoor.AssemblyLinearVelocity = Vector3.new(0, 5, 25)
	backDoor.AssemblyAngularVelocity = Vector3.new(math.random(-6,6), math.random(-6,6), math.random(-6,6))
	ShakeRE:FireAllClients(12)
	task.wait(0.3)

	-- Забегаем внутрь
	tweenCharTo(char, CFrame.lookAt(Vector3.new(0, 3, 5), Vector3.new(0, 3, -8)), 1.5)
 shot(Vector3.new(10,7,10),Vector3.new(0,4,-6),0)
	task.wait(1.2)

	-- Мафиози видит нас, поднимает руки
	NotifyRE:FireAllClients("Мафиози: Стой! Я сдаюсь! Я всё расскажу!", 3)
	mafJ.RS.C0 = mafJ.RS.C0 * CFrame.Angles(math.rad(100), 0, math.rad(-30))
	mafJ.LS.C0 = mafJ.LS.C0 * CFrame.Angles(math.rad(100), 0, math.rad(30))
	task.wait(1.5)

	-- Мы целимся (небольшая пауза)
	task.wait(0.8)

	-- Стреляем
	local headPos = char:FindFirstChild("Head") and char.Head.Position or char.HumanoidRootPart.Position
	tracer(headPos, mafHrp.Position, Color3.fromRGB(255, 200, 100))
	ShakeRE:FireAllClients(10)
	NotifyRE:FireAllClients("*ВЫСТРЕЛ*", 0.8)
	task.wait(0.3)

 -- A scripted rig does not have the enemies' Died connection: animate the reaction explicitly.
 CutsceneRE:FireAllClients("blood",0.45)
 local wound=Instance.new("ParticleEmitter")
 wound.Texture="rbxasset://textures/particles/sparkles_main.dds"
 wound.Color=ColorSequence.new(C(130,12,20)); wound.LightEmission=0
 wound.Size=NumberSequence.new(0.15,0); wound.Lifetime=NumberRange.new(0.2,0.5)
 wound.Speed=NumberRange.new(5,10); wound.Rate=0; wound.SpreadAngle=Vector2.new(60,60)
 wound.Parent=maf:FindFirstChild("Torso"); wound:Emit(22)
 local hitCF=maf:GetPivot()
 moveModel(maf,hitCF*CFrame.Angles(math.rad(-18),0,math.rad(10)),0.18)
 mafHum.BreakJointsOnDeath=false; mafHum.Health=0
 moveModel(maf,hitCF*CFrame.new(1,-2,2)*CFrame.Angles(math.rad(-80),0,math.rad(12)),0.7)
 local stain=part(office,Vector3.new(2.5,0.03,1.8),Vector3.new(1,0.03,-7),C(95,12,18),Enum.Material.SmoothPlastic)
 stain.CanCollide=false
 task.wait(1.5)

	CutsceneRE:FireAllClients("end")
 -- Keep actors frozen across the office -> plane -> base transition.
	FadeRE:FireAllClients(true, "")
	task.wait(1.5)
end

------------------------------------------------------------------ САМОЛЁТ-КАТСЦЕНА
local function playPlaneScene()
	introActive = true
 sceneLock(true)
	clearLevel(); newFolders()
 -- Actors remain anchored during the aerial insert; there is no walkable sky floor.
 currentSpawn=CFrame.new(0,301,0)
 placeAll()
 sceneLock(true)

	-- Самолёт летит в небе
	local plane = buildPlane(CFrame.new(0, 300, 0))
	plane.Parent = workspace
 local planeRide=RunService.Heartbeat:Connect(function()
  if not plane.Parent then return end
  currentSpawn=plane:GetPivot()*CFrame.new(0,-0.5,0)
  for i,player in ipairs(Players:GetPlayers()) do
   local character=player.Character
   if character then
    character:SetAttribute("CinematicSeated",true)
    character:PivotTo(currentSpawn*CFrame.new(0,0,(i-1)*2))
   end
  end
 end)

	CutsceneRE:FireAllClients("start")
	FadeRE:FireAllClients(false, "")
 follow(plane,Vector3.new(25,12,32),Vector3.new(0,0,0))
	NotifyRE:FireAllClients("Вы возвращаетесь на базу...", 4)

	-- Самолёт летит
	task.spawn(function() moveModel(plane,plane:GetPivot()*CFrame.new(0,0,300),7) end)
	task.wait(6)

	FadeRE:FireAllClients(true, "")
	task.wait(1.5)
 planeRide:Disconnect()
	plane:Destroy()
 for _,player in ipairs(Players:GetPlayers()) do
  if player.Character then player.Character:SetAttribute("CinematicSeated",false) end
 end
	CutsceneRE:FireAllClients("end")
 -- startBase builds the destination before releasing the scene lock.
end

------------------------------------------------------------------ ФИНАЛ НА БАЗЕ — смерть агента и раскрытие нейро-армии
local function say(text, dur) NotifyRE:FireAllClients(text, dur); task.wait(dur + 0.4) end

function startBase()
 sceneLock(true); introActive=true; canFight=false; levelToken+=1
 FadeRE:FireAllClients(true,"ВОЗВРАЩЕНИЕ НА БАЗУ")
 task.wait(1)
 clearLevel(); newFolders()
 currentLevel,currentName,enemiesLeft,currentWave,totalWaves=6,"Последний приказ",-1,0,0
 local info=buildBase(levelFolder)
 currentSpawn=info.Spawn
 applyPreset("Base",0.1)
 placeAll(); sceneLock(true); broadcast()
 local cmd=buildRig(Types.Commander,info.CommanderCF); anchorAll(cmd); cmd.Parent=levelFolder
 local neuro,nHum,nRoot,nj=buildRig(Types.Neuro,CFrame.lookAt(Vector3.new(0,3,30),Vector3.new(0,3,-16)))
 anchorAll(neuro); neuro.Parent=levelFolder; enhanceNeuroCyber(neuro)
 -- The army is a client-side cinematic crowd, not thousands of expensive Humanoids.
 part(levelFolder,Vector3.new(600,2,600),Vector3.new(0,-1,360),C(28,32,38),Enum.Material.Concrete)
 CutsceneRE:FireAllClients("start")
 CutsceneRE:FireAllClients("army",Vector3.new(0,0,190))
 CutsceneRE:FireAllClients("pov",Vector3.new(7,4.5,-4))
 prepareView(currentSpawn.Position)
 FadeRE:FireAllClients(false)
 say("КОМАНДИР: Пять объектов зачищены. Но разведка ошиблась: Нейро — не одиночка.",5)
 say("КОМАНДИР: Её тело синтетическое. Каждая копия подключена к одной сети.",4)
 CutsceneRE:FireAllClients("pov",Vector3.new(0,5,25))
 for _,lamp in ipairs(info.Lamps) do lamp[2].Brightness=0.25 end
 task.wait(1)
 -- Explicitly rotate and lower the slab. No physics-dependent upright sliding door.
 local door=info.Door
 local closed=door.CFrame
 door.CanCollide=false
 local hinge=CFrame.new(closed.Position-Vector3.new(0,5,0))
 local relative=hinge:ToObjectSpace(closed)
 local began=os.clock()
 repeat
  local t=math.clamp((os.clock()-began)/0.65,0,1)
  door.CFrame=hinge*CFrame.Angles(math.rad(-90)*t,0,0)*relative
  RunService.Heartbeat:Wait()
 until os.clock()-began>=0.65
 door.CFrame=CFrame.new(0,0.65,20)*CFrame.Angles(math.rad(-90),0,0)
 ShakeRE:FireAllClients(9)
 CutsceneRE:FireAllClients("pov",neuro:FindFirstChild("Head"))
 -- Place the attacker through the now-open doorway into a clear, visible lane.
 moveModel(neuro,CFrame.lookAt(Vector3.new(0,3,7),Vector3.new(0,3,-16)),2,true)
 say("НЕЙРО: Ты уничтожил аванпосты. Но не нас.",3)
 say("НЕЙРО: Посмотри на меня. Это тело — лишь одна из тысяч копий.",4)
 MusicRE:FireAllClients("final")
 local finaleStart=os.clock()
 say("НЕЙРО: Твоя миссия закончена. Наше наступление только начинается.",4)
 -- Show the attack from the victim's eyes, without giving gameplay control back.
 local hand=neuro:FindFirstChild("Right Arm")
 local orb=part(fxFolder,Vector3.new(0.8,0.8,0.8),hand.Position,C(55,190,180),Enum.Material.Neon)
 orb.Shape=Enum.PartType.Ball; orb.CanCollide=false
 local victim=Players:GetPlayers()[1]
 local victimHead=victim and victim.Character and victim.Character:FindFirstChild("Head")
 if victimHead then
  TweenService:Create(orb,TweenInfo.new(0.4),{Position=victimHead.Position}):Play()
 end
 task.wait(0.4); orb:Destroy()
 CutsceneRE:FireAllClients("blood",0.8); ShakeRE:FireAllClients(14)
 local oldRespawn=Players.RespawnTime
 Players.RespawnTime=120 -- retain the actual dead character during the reveal/credits
 for _,player in ipairs(Players:GetPlayers()) do
  local character=player.Character
  local hum=character and character:FindFirstChildOfClass("Humanoid")
  if hum then
   hum.BreakJointsOnDeath=false
   player:SetAttribute("FinalDeath",true)
   hum.Health=0
  end
 end
 local eye=Vector3.new(0,5.5,-16)
 cameraPlan(eye,Vector3.new(0,1.4,-17),Vector3.new(0,4.5,7),1,58,65)
 for _,player in ipairs(Players:GetPlayers()) do
  local character=player.Character
  if character then moveModel(character,character:GetPivot()*CFrame.new(0,-2,0)*CFrame.Angles(math.rad(-80),0,0),0.7) end
 end
 task.wait(1)
 -- Open the roof BEFORE the camera rises. It never interpolates through an intact wall.
 for _,object in ipairs(levelFolder:GetChildren()) do
  if object:IsA("BasePart") and object.Size.Y==1 and object.Position.Y>16 and object.Position.Y<17 then object:Destroy() end
 end
 cameraPlan(Vector3.new(0,1.4,-17),Vector3.new(0,85,-17),Vector3.new(0,4,7),5,65,70)
 task.wait(5)
 cameraPlan(Vector3.new(0,85,-17),Vector3.new(0,180,90),Vector3.new(0,0,315),7,70,78)
 task.wait(7)
 NotifyRE:FireAllClients("НЕЙРО-СЕТЬ // 2 048 АКТИВНЫХ КОПИЙ // НАСТУПЛЕНИЕ НАЧАЛОСЬ",6)
 task.wait(math.max(0,30-(os.clock()-finaleStart)))
 task.wait(35)
 FadeRE:FireAllClients(true,"ПРОДОЛЖЕНИЕ СЛЕДУЕТ")
 task.wait(1)
 CreditsRE:FireAllClients(false); MusicRE:FireAllClients("stop")
 CutsceneRE:FireAllClients("armyClear")
 CutsceneRE:FireAllClients("end")
 Players.RespawnTime=oldRespawn
 for _,player in ipairs(Players:GetPlayers()) do player:SetAttribute("FinalDeath",nil) end
 startLevel(1)
end

------------------------------------------------------------------ KICK (дверь)
KickRE.OnServerEvent:Connect(function(plr)
 if not introActive and currentLevel==1 and breachDoor and not entranceUsed then
  local char=plr.Character
  local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if not root or not hum or hum.Health<=0 or (root.Position-breachDoor.Position).Magnitude>9 then return end
  if root.CFrame.LookVector:Dot((breachDoor.Position-root.Position).Unit)<0.2 then return end
  entranceUsed=true -- consume before yielding; simultaneous E cannot trigger twice
  local door=breachDoor; breachDoor=nil
  DoorStateRE:FireAllClients(nil,false)
  local anchored=root.Anchored; root.Anchored=true
  CutsceneRE:FireClient(plr,"start")
  follow(char,Vector3.new(7,4,7))
  char:SetAttribute("CinematicKick",workspace:GetServerTimeNow())
  task.wait(0.35)
  door.CanCollide=false; door.Anchored=false
  door.AssemblyLinearVelocity=Vector3.new(0,5,-28)
  door.AssemblyAngularVelocity=Vector3.new(-4,1,2)
  Debris:AddItem(door,3)
  ShakeRE:FireClient(plr,5)
  task.wait(0.65)
  char:SetAttribute("CinematicKick",nil)
  root.Anchored=anchored
  CutsceneRE:FireClient(plr,"end")
  NotifyRE:FireClient(plr,"Проход открыт. Зачисти дом. Выход — на противоположной стороне.",5)
  return -- entrance breach never advances the level
 end

	if introActive then return end
	if not doorUnlocked or not currentExitDoor or not currentExitDoor.Parent then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if (hrp.Position - currentExitDoor.Position).Magnitude > 12 then return end
	doorUnlocked = false
	local door = currentExitDoor
	currentExitDoor = nil
	door.Anchored = false
	local dir = (door.Position - hrp.Position).Unit * 40
	door.AssemblyLinearVelocity = dir * Vector3.new(1, 0, 1) + Vector3.new(0, 8, 0)
	door.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
	playSound(SOUNDS.DoorBreak, door)
	ShakeRE:FireAllClients(15)
	DoorStateRE:FireAllClients(nil, false)
	task.wait(0.8)
	if currentLevel < 5 then
		startLevel(currentLevel + 1)
	else
		-- Цепочка: мафиози → самолёт → база
		task.spawn(function()
   runScene(function()
    playMafioziScene()
    playPlaneScene()
    startBase()
   end)
		end)
	end
end)

------------------------------------------------------------------ ИГРОКИ И АТАКИ
Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("WeaponLevel", math.clamp(currentLevel, 1, 5))
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart"); task.wait(0.1)
		if not introActive then
   placePlayer(plr)
  else
   char:PivotTo(currentSpawn)
   sceneLock(true)
   CutsceneRE:FireClient(plr,"start")
  end
	end)
	task.delay(3, function() StateRE:FireClient(plr, currentLevel, currentName, enemiesLeft, currentWave, totalWaves) end)
end)

local lastAttack = {}
AttackRE.OnServerEvent:Connect(function(plr, wname, origin, dir, charge)
	if introActive then return end
	local w = WD.Stats[tostring(wname)]
	if not w or not canFight then return end
	local idx = table.find(WD.Order, wname)
	if not idx or idx > (plr:GetAttribute("WeaponLevel") or 1) then return end
	if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.1 then return end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local head = char and char:FindFirstChild("Head")
	if not hum or hum.Health <= 0 or not head then return end
	local now = os.clock()
	if lastAttack[plr] and now - lastAttack[plr] < w.Cooldown * 0.85 then return end
	lastAttack[plr] = now
	if (origin - head.Position).Magnitude > 12 then origin = head.Position end
	dir = dir.Unit

	if wname == "Rifle" and w.Charge then
		local c = math.clamp(tonumber(charge) or 0, 0, 1)
		local dmg = w.MinDamage + (w.MaxDamage - w.MinDamage) * c
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {char, fxFolder}
		local res = workspace:Raycast(origin, dir * w.Range, rp)
		local hitPos = res and res.Position or origin + dir * w.Range
		local beam = Instance.new("Part")
		beam.Anchored = true; beam.CanCollide = false; beam.CanQuery = false
		beam.Material = Enum.Material.Neon; beam.Color = Color3.fromRGB(255,80,200)
		beam.Size = Vector3.new(1.5 + c * 1.5, 1.5 + c * 1.5, (hitPos - origin).Magnitude)
		beam.CFrame = CFrame.lookAt(origin, hitPos) * CFrame.new(0, 0, -(hitPos - origin).Magnitude/2)
		beam.Parent = fxFolder
		light(beam, Color3.fromRGB(255,80,200), 30, 5)
		Debris:AddItem(beam, 0.25)
		local hitAny, killed = false, false
		for _, e in pairs(enemies) do
			if e.Hrp.Parent and e.Hum.Health > 0 then
				local toE = e.Hrp.Position - origin
				local proj = toE:Dot(dir)
				if proj > 0 and proj < w.Range then
					local perp = (toE - dir * proj).Magnitude
					if perp < 3.5 then
						e.Model:SetAttribute("LastDir", dir); e.Model:SetAttribute("LastKnock", w.Knock * (0.5 + c))
						e.Hum:TakeDamage(dmg)
						hitAny = true
						if e.Hum.Health <= 0 then killed = true end
					end
				end
			end
		end
		if hitAny then HitRE:FireClient(plr, killed) end
		return
	end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {char, fxFolder}
	local hitAny, killed = false, false
	for _ = 1, w.Pellets do
		local d = spreadDir(dir, w.Spread)
		local res = workspace:Raycast(origin, d * w.Range, rp)
		local hitPos = res and res.Position or origin + d * w.Range
		if wname ~= "Fists" then
			tracer(head.Position + head.CFrame.RightVector * 1 - Vector3.new(0, 0.6, 0) + d * 2, hitPos, w.Color)
		end
		if res then
			local mdl = res.Instance:FindFirstAncestorOfClass("Model")
			local eh = mdl and mdl:FindFirstChildOfClass("Humanoid")
			if eh and eh.Health > 0 and mdl:GetAttribute("Enemy") then
				local dmg = w.Damage * (res.Instance.Name == "Head" and 2 or 1)
				mdl:SetAttribute("LastDir", d); mdl:SetAttribute("LastKnock", w.Knock)
				eh:TakeDamage(dmg)
				hitAny = true
				if eh.Health <= 0 then killed = true end
				local body = res.Instance
				if eh.Health > 0 and wname == "Fists" then
					body:ApplyImpulse((d * w.Knock + Vector3.new(0, 12, 0)) * body.AssemblyMass)
				end
			end
		end
	end
	if wname == "Fists" then playSound(SOUNDS.Punch, head) end
	if hitAny then HitRE:FireClient(plr, killed) end
end)

------------------------------------------------------------------ ЗАЩИТА ОТ ПАДЕНИЯ
task.spawn(function()
	while true do
		task.wait(0.5)
		for i, plr in ipairs(Players:GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.Y < -20 then
    if introActive then
     hrp.Anchored=true
     plr.Character:PivotTo(currentSpawn)
     hrp.AssemblyLinearVelocity=Vector3.zero
    else placePlayer(plr,i) end
   end
		end
		for _, e in pairs(enemies) do
			if e.Hrp.Position.Y < -20 then e.Hum.Health = 0 end
		end
	end
end)

------------------------------------------------------------------ СТАРТ
task.spawn(function()
 -- Do not send the initial fade/camera events before client listeners exist.
 local selected
 repeat
  for _,player in ipairs(Players:GetPlayers()) do
   if readyClients[player] then selected=player; break end
  end
  if not selected then task.wait(0.1) end
 until selected
 runScene(playIntro)
end)