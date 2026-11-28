local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerStorage=game:GetService("ServerStorage")
local GAME_TITLE="Уничтожь Тянку 3"
workspace:SetAttribute("GameTitle",GAME_TITLE)

local WD = require(RS:WaitForChild("WeaponData"))
Players.RespawnTime = 3

------------------------------------------------------------------ REMOTES
local Remotes = Instance.new("Folder"); Remotes.Name = "Remotes"; Remotes.Parent = RS
local function newRemote(n) local r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = Remotes; return r end
local AttackRE, NotifyRE, FadeRE = newRemote("Attack"), newRemote("Notify"), newRemote("Fade")
local StateRE, HitRE, EndRE, ShakeRE = newRemote("State"), newRemote("Hit"), newRemote("End"), newRemote("Shake")
local KickRE, FocusRE, DoorStateRE = newRemote("Kick"), newRemote("Focus"), newRemote("DoorState")
local CutsceneRE, MusicRE, CreditsRE = newRemote("Cutscene"), newRemote("Music"), newRemote("Credits")
local LobbyRE=newRemote("Lobby")
local sessionSize, sessionStarted, pushLobbyState=1,false,nil
local returnToMenu
local c2Attack,c3Attack
local buildConversionFactory
local STORIES={
 [1]={name="ОДИНОЧНЫЙ СЛЕД",brief="На этот раз идешь один. Найди их архив и попробуй выяснить, куда увозят людей.",plan="В доме спрятан маршрут перевозок. Забери данные, затем двигайся к лаборатории.",office="В архиве есть адрес закрытого цеха. Мафиози наверняка знает, кому его отдали.",ending="Последний агент не вышел на связь. Запись с его камеры пережила его."},
 [2]={name="ДВОЙНОЙ СИГНАЛ",brief="Работаете вдвоем. Один проверяет маршрут, второй ищет следы пропавших людей. Держитесь рядом.",plan="Держитесь вместе. Один прикрывает дом, второй проверяет архив. Данные нужны обоим.",office="Смотри, записи совпадают. На обоих приказах о перевозке стоит одна подпись.",ending="Оба канала погасли. Но общая запись группы уже ушла в штаб."},
 [3]={name="ТРЕТИЙ КАНАЛ",brief="Вас трое. Один идет первым, второй ищет данные, третий держит связь. Нужно узнать, что происходит с пленниками.",plan="Штурмовик ведёт, разведчик читает маршрут, связист сохраняет копию. Проходите точки вместе.",office="Удалось перехватить их связь. Похоже, мафиози работал на завод, а не только на картель.",ending="Три сигнала исчезли. Резервный канал успел передать координаты завода."},
 [4]={name="ПРОТОКОЛ СВИДЕТЕЛЬ",brief="Вас четверо. Прикрывайте друг друга и сохраняйте все, что найдете. Нам нужны доказательства того, что делает картель.",plan="Соберите четыре части архива в одной операции. Свидетель отправляет доказательства за пределы сети.",office="Теперь у нас весь архив. Мафиози отправлял пленников прямо на завод.",ending="Отряд погиб. Протокол «Свидетель» опубликовал запись: тайна завода раскрыта."},
}
local function story() return STORIES[math.clamp(sessionSize,1,4)] end
local SceneReadyRE=newRemote("SceneReady")
local readyClients, preparedClients = {}, {}
local prepareId=0
local finaleId=0
local scanAcknowledged,blackAcknowledged,armyAcknowledged={},{},{}
SceneReadyRE.OnServerEvent:Connect(function(player,command,id)
 if command=="ready" then readyClients[player]=true; if pushLobbyState then pushLobbyState() end
 elseif command=="prepared" and id==prepareId then preparedClients[player]=id
 elseif command=="scanDone" and id==finaleId then scanAcknowledged[player]=id
 elseif command=="black" and id==finaleId then blackAcknowledged[player]=id
 elseif command=="armyDone" and id==finaleId then armyAcknowledged[player]=id end
end)
Players.PlayerRemoving:Connect(function(player)
 readyClients[player]=nil; preparedClients[player]=nil; scanAcknowledged[player]=nil; blackAcknowledged[player]=nil; armyAcknowledged[player]=nil
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
local evidenceNeeded,evidenceCollected,combatCleared=false,{},false

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
	p.Material = mm; p.Color = cc2; p.Reflectance=0
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
	Hair=C(165,75,120), Eye=C(35,105,115), Accent=C(150,45,95), HP=60, Speed=14, Name="Боец картеля",
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
 if sessionSize>=2 then hum.MaxHealth*=2; hum.Health=hum.MaxHealth end
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
 NotifyRE:FireAllClients("Подойди к двери и нажми E, чтобы выбить ее ногой. Задний выход откроется после зачистки.",7)
end

local function unlockDoor()
 if evidenceNeeded then
  for _,player in ipairs(Players:GetPlayers()) do
   if not evidenceCollected[player.UserId] then
    NotifyRE:FireAllClients("Здесь чисто. Теперь каждому нужно забрать свою часть архива у входа.",5)
    return
   end
  end
 end
	if not currentExitDoor then return end
	doorUnlocked = true
	local ind = levelFolder:FindFirstChild("DoorIndicator")
	if ind then
		ind.Color = C(40, 255, 130)
		local l = ind:FindFirstChildOfClass("PointLight")
		if l then l.Color = C(40, 255, 130); l.Brightness = 3; l.Range = 18 end
	end
	DoorStateRE:FireAllClients(currentExitDoor.Position, true)
	NotifyRE:FireAllClients("Замок снят. Подойди к двери и нажми E.", 5)
end

local function buildEvidenceTerminal(info,n)
 evidenceNeeded=sessionSize>=2 and n>=2 and n<=5
 evidenceCollected={}; combatCleared=false
 if not evidenceNeeded then return end
 local terminal=part(levelFolder,Vector3.new(2,3,2),info.Spawn.Position+Vector3.new(5,-2,-1),C(40,75,85),Enum.Material.Metal)
 terminal.Name="SquadArchive"
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Сохранить свою часть"; prompt.ObjectText=story().name.." // Архив "..(n-1).."/4"
 prompt.HoldDuration=1; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=true; prompt.Parent=terminal
 local token=levelToken
 prompt.Triggered:Connect(function(player)
  if token~=levelToken or introActive or evidenceCollected[player.UserId] then return end
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if not root or (root.Position-terminal.Position).Magnitude>12 then return end
  evidenceCollected[player.UserId]=true
  NotifyRE:FireClient(player,(player:GetAttribute("SquadRole") or "Агент")..". Моя часть архива у меня. "..story().office,6)
  if combatCleared then unlockDoor() end
 end)
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
	part(f, Vector3.new(600,2,600), Vector3.new(0,-1.2,0), C(35,35,40), Enum.Material.Asphalt)
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
local function tweenCharTo(char, target, _duration, lockFacing)
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
 local partnerAnchors={}
 local distance=((target.Position-start)*Vector3.new(1,0,1)).Magnitude
 local faceDirection
 if lockFacing then
  faceDirection=target.LookVector*Vector3.new(1,0,1)
  if faceDirection.Magnitude<0.001 then faceDirection=(target.Position-start)*Vector3.new(1,0,1) end
  if faceDirection.Magnitude<0.001 then faceDirection=root.CFrame.LookVector*Vector3.new(1,0,1) end
  faceDirection=faceDirection.Unit
  -- Turn toward the marked destination before the first walking frame, then
  -- keep that heading throughout the path instead of snapping at the window.
  root.CFrame=CFrame.lookAt(root.Position,root.Position+faceDirection,Vector3.yAxis)
 end
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
  local direction
  if lockFacing then
   direction=faceDirection
  elseif delta.Magnitude>0.001 then
   -- Face the horizontal travel vector directly; smoothing the whole rotation
   -- frame-by-frame caused visible sideways drift and tilted-looking turns.
   direction=delta.Unit
  else
   direction=target.LookVector*Vector3.new(1,0,1)
   if direction.Magnitude<0.001 then direction=Vector3.new(0,0,-1) else direction=direction.Unit end
  end
  root.CFrame=CFrame.lookAt(nextPosition,nextPosition+direction,Vector3.yAxis)
  for _,partner in ipairs(Players:GetPlayers()) do
   local other=partner.Character
   local partnerRoot=other and other~=char and other:FindFirstChild("HumanoidRootPart")
   if partnerRoot then
    if partnerAnchors[partnerRoot]==nil then partnerAnchors[partnerRoot]=partnerRoot.Anchored end
    other:SetAttribute("CinematicWalk",true)
    partnerRoot.Anchored=true
    partnerRoot.CFrame=root.CFrame*CFrame.new(0.45,0,1.2)
   end
  end
  RunService.Heartbeat:Wait()
 until os.clock()-began>=duration or not char.Parent or hum.Health<=0
 char:SetAttribute("CinematicWalk",false)
 for partnerRoot,anchored in pairs(partnerAnchors) do
  if partnerRoot.Parent then partnerRoot.Anchored=anchored end
 end
 for _,partner in ipairs(Players:GetPlayers()) do
  if partner.Character and partner.Character~=char then partner.Character:SetAttribute("CinematicWalk",false) end
 end
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
  if not on then player.ReplicationFocus=nil end
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
		Intro="Иди к дому. Внутри остались двое."},
	{Name="Квартира", Preset="Apartment", Build=function(f) return buildRoom(f, RoomCfg[2]) end,
	Waves={{{"Melee",2}}, {{"Pistol",1},{"Melee",1}}},
	Intro="Осторожнее в квартире. У одной из них пистолет, не подходи близко."},
	{Name="Лаборатория", Preset="Lab", Build=buildLaboratory,
	Waves={{{"Melee",2}}, {{"Pistol",1},{"SMG",1}}, {{"Melee",1},{"SMG",1}}},
	Intro="В лаборатории автоматическое оружие. Держись ближе к укрытиям."},
	{Name="Склад", Preset="Warehouse", Build=function(f) return buildRoom(f, RoomCfg[4]) end,
	Waves={{{"Melee",2},{"Pistol",1}}, {{"Shotgun",1},{"SMG",1}}, {{"Melee",2},{"Shotgun",1}}},
	Intro="На складе дробовики. Не подпускай их к себе."},
	{Name="Серверная", Preset="Server", Build=function(f) return buildRoom(f, RoomCfg[5]) end,
	Waves={{{"SMG",2}}, {{"Melee",2},{"Shotgun",1}}, {{"Boss",1}}},
	Intro="Мы добрались до серверной. Похоже, главная здесь."},
}

local function clearLevel()
 local recovery=workspace:FindFirstChild("RecoveryFloor"); if recovery then recovery:Destroy() end
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
 buildEvidenceTerminal(info,n)
	local door, ind = makeExitDoor(info.ExitDoorCF, RoomCfg[n] and RoomCfg[n].H or 14)
	currentExitDoor = door
	currentDoorCF = info.ExitDoorCF
	doorUnlocked = false
	totalWaves = #L.Waves
	spawnWave(1, token, info)
	task.wait(0.6)
	FadeRE:FireAllClients(false)
	local txt = L.Intro
	if n >= 2 then txt ..= ("\n[Новое оружие: %s , клавиша %d]"):format(WD.Stats[WD.Order[n]].Display, n) end
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
		NotifyRE:FireAllClients(("С группой %d из %d разобрались. Слышно, как подходят еще."):format(currentWave, totalWaves), 2.5)
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
 combatCleared=true
	NotifyRE:FireAllClients("Здесь чисто. Проверьте выход и заберите архивы.", 2.5)
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
 evidenceNeeded=false; evidenceCollected={}; combatCleared=false
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
 local pad=part(base,Vector3.new(24,0.15,24),Vector3.new(70,0.285,65),C(38,48,54),Enum.Material.Metal)
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
 local prior=RS:FindFirstChild("ReconScene"); if prior then prior:Destroy() end
 local recon=Instance.new("WorldModel"); recon.Name="ReconScene"; recon.Parent=RS
 for _,object in ipairs(levelFolder:GetChildren()) do
  if object:IsA("BasePart") and math.abs(object.Position.X)<19 and math.abs(object.Position.Z)<19 and object.Size.X<60 then
   local clone=object:Clone(); clone.Anchored=true; clone.Parent=recon
  end
 end
 CutsceneRE:FireAllClients("recon",board,recon)
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
 CutsceneRE:FireAllClients("pov",basePoint(Vector3.new(82,4.8,49)))
 prepareView(basePoint(Vector3.new(82,4,48)))
 FadeRE:FireAllClients(false)
 task.wait(1)
 local closedDoor=entrance:GetPivot()
 moveModel(entrance,closedDoor*CFrame.new(0,9.5,0),1.8)
 CutsceneRE:FireAllClients("povForward")
 currentSpawn=baseCF(CFrame.new(82,3.2,46))
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,46)),3)
 tweenCharTo(char,baseCF(CFrame.new(70,3.2,43)),3)
 CutsceneRE:FireAllClients("pov",commander:FindFirstChild("Head"))
 NotifyRE:FireAllClients(story().brief,6)
 local shoulder=commander:FindFirstChild("Right Shoulder",true)
 if shoulder then
  local original=shoulder.C0
  TweenService:Create(shoulder,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,2,true),{C0=original*CFrame.Angles(math.rad(25),0,math.rad(-15))}):Play()
 end
 task.wait(6)
 CutsceneRE:FireAllClients("pov",commander:FindFirstChild("Head"))
 CutsceneRE:FireAllClients("pov",basePoint(Vector3.new(70,6,28.7)))
 NotifyRE:FireAllClients("Вот снимки дома. "..story().plan,7)
 task.wait(7)
 CutsceneRE:FireAllClients("pov",commander:FindFirstChild("Head"))
 NotifyRE:FireAllClients("Не торопись, осмотрись. Вертолет довезет до южной тропы, дальше пойдете пешком.",7)
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
 CutsceneRE:FireAllClients("povForward")
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,48)),3)
 tweenCharTo(char,baseCF(CFrame.new(82,3.2,65)),3)
 CutsceneRE:FireAllClients("povForward")
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
 NotifyRE:FireAllClients("Все сели. Взлетаем, скоро будем на месте.",5)
 CutsceneRE:FireAllClients("povRide",heli)
 FadeRE:FireAllClients(false)
 moveModel(heli,departure*CFrame.new(0,38,0),6)
 -- Separate maps: travel cut is hidden, never fly across an empty world.
 FadeRE:FireAllClients(true,"ПЕРЕЛЁТ // ЛЕСНОЙ СЕКТОР")
 task.wait(1)
 heli:PivotTo(landing*CFrame.new(0,38,0))
 currentSpawn=info.Spawn
 prepareView(landing.Position)
 CutsceneRE:FireAllClients("povRide",heli)
 FadeRE:FireAllClients(false)
 moveModel(heli,landing,7)
 steps=stairs(landing)
 ride:Disconnect()
 for _,passenger in ipairs(Players:GetPlayers()) do
  if passenger.Character then passenger.Character:SetAttribute("CinematicSeated",false) end
 end
 CutsceneRE:FireAllClients("povForward")
 tweenCharTo(char,CFrame.new(28.5,4.8,60),2)
 tweenCharTo(char,CFrame.new(31,3.2,60),2)
 tweenCharTo(char,CFrame.new(12,3.2,65),5)
 tweenCharTo(char,CFrame.new(8,3.2,55),3)
 NotifyRE:FireAllClients("Приехали. Дом дальше по тропе, командир остается на связи.",5)
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
local function sceneLine(text,minimum)
 local duration=math.max(minimum or 3,(utf8.len(text) or #text)*0.045+2)
 NotifyRE:FireAllClients(text,duration)
 task.wait(duration+0.35)
end
local function playMafioziScene()
 introActive=true; canFight=false; sceneLock(true)
 FadeRE:FireAllClients(true,"Завод синдиката")
 task.wait(0.8)
 clearLevel(); newFolders()
 currentLevel,currentName=5,"Завод синдиката"
 local factory=buildConversionFactory()
 currentSpawn=factory.Spawn
 applyPreset("Base",0.1)
 placeAll(); sceneLock(true)
 local maf,mafHum=buildRig(Types.Mafiozi,CFrame.lookAt(factory.Origin+Vector3.new(0,3,9),factory.Origin+Vector3.new(0,3,-18)))
 maf.Name="Главный антагонист"; maf:SetAttribute("FactoryAntagonist",true)
 anchorAll(maf); maf.Parent=factory.Model
 CutsceneRE:FireAllClients("start")
 CutsceneRE:FireAllClients("pov",maf.Head)
 prepareView(currentSpawn.Position)
 CutsceneRE:FireAllClients("reveal")
 sceneLine(story().office,6)
 sceneLine("Стой, не стреляй. Я сдаюсь, я все расскажу.",5)
 CutsceneRE:FireAllClients("blaster",true)
 task.wait(1.5)
 CutsceneRE:FireAllClients("pulse")
 local target=maf.Head.Position
 local bullet=part(fxFolder,Vector3.new(0.7,0.7,0.7),factory.Origin+Vector3.new(1,4,-16),C(90,200,210),Enum.Material.Neon)
 bullet.Shape=Enum.PartType.Ball; bullet.CanCollide=false; bullet.CanQuery=false
 TweenService:Create(bullet,TweenInfo.new(0.4),{Position=target}):Play()
 task.wait(0.45); bullet:Destroy()
 local hitCF=maf:GetPivot()
 moveModel(maf,hitCF*CFrame.Angles(math.rad(-18),0,0),0.18)
 mafHum.BreakJointsOnDeath=false; mafHum.Health=0
 moveModel(maf,hitCF*CFrame.new(7,-1.8,1)*CFrame.Angles(math.rad(-80),0,0),0.8)
 task.wait(4)
 CutsceneRE:FireAllClients("blaster",false)
 FadeRE:FireAllClients(true,"")
 task.wait(0.8)
 -- Only player Characters travel. This factory-owned NPC is never reparented or cloned to the base.
 maf:Destroy()
 CutsceneRE:FireAllClients("end")
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
	NotifyRE:FireAllClients("Возвращаемся. Есть о чем поговорить.", 4)

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

------------------------------------------------------------------ ФИНАЛ НА БАЗЕ , смерть агента и раскрытие нейро-армии
local function say(text, dur) sceneLine(text,dur) end

buildConversionFactory=function()
 local f=Instance.new("Model"); f.Name="ConversionFactory"; f.Parent=levelFolder
 local origin=Vector3.new(4000,0,0)
 local lamps,emergency={},{}
 local function machine(name,size,pos,color,material)
  local p=part(f,size,origin+pos,color,material or Enum.Material.Metal); p.Name=name; return p
 end
 machine("FactoryFloor",Vector3.new(72,1,80),Vector3.new(0,-0.5,5),C(40,44,49),Enum.Material.Concrete)
 machine("FrontWall",Vector3.new(72,18,1),Vector3.new(0,9,-35),C(53,62,70))
 machine("Roof",Vector3.new(74,1,82),Vector3.new(0,18.5,5),C(46,54,61))
 for _,x in ipairs({-36,36}) do machine("SideWall",Vector3.new(1,18,80),Vector3.new(x,9,5),C(53,62,70)) end
 for _,x in ipairs({-20,20}) do machine("EntranceWall",Vector3.new(32,18,1),Vector3.new(x,9,25),C(53,62,70)) end
 machine("EntranceHeader",Vector3.new(8,8,1),Vector3.new(0,14,25),C(53,62,70))
 machine("CorridorEnd",Vector3.new(72,18,1),Vector3.new(0,9,45),C(45,55,65))
 local door=machine("FactoryDoor",Vector3.new(7.8,10,0.5),Vector3.new(0,5,25),C(60,70,80))
 for _,z in ipairs({-24,-8,8,23,37}) do
  local fixture=machine("FactoryLamp",Vector3.new(16,0.2,2),Vector3.new(0,17,z),C(170,180,185))
  local source=light(fixture,C(200,215,225),30,0.9); source.Shadows=false; table.insert(lamps,source)
  machine("CeilingTruss",Vector3.new(70,0.6,0.6),Vector3.new(0,16,z+2),C(75,85,95))
 end
 for _,x in ipairs({-33,33}) do
  for _,z in ipairs({-24,-9,7,22,38}) do
   local housing=machine("EmergencyLamp",Vector3.new(0.5,0.8,1.4),Vector3.new(x,8,z),C(70,28,22))
   local source=light(housing,C(195,75,50),19,0.7); source.Enabled=false; table.insert(emergency,source)
  end
 end
 for _,z in ipairs({-18,18,37}) do
  local housing=machine("EmergencyCeiling",Vector3.new(1.8,0.3,1.8),Vector3.new(0,13,z),C(75,35,28))
  local source=light(housing,C(185,90,65),28,0.4); source.Enabled=false; table.insert(emergency,source)
 end
 for _,x in ipairs({-29,29}) do
  for _,z in ipairs({-25,-15,-5,5,16,35}) do
   machine("ServerRack",Vector3.new(4,10,5),Vector3.new(x,5,z),C(25,32,40))
   for y=2,8,2 do
    machine("ServerPanel",Vector3.new(3.6,1.4,0.15),Vector3.new(x,y,z-2.6),C(50,65,75))
    machine("ServerLED",Vector3.new(0.25,0.2,0.1),Vector3.new(x+1,y,z-2.72),C(70,130,120))
   end
  end
 end
 for _,x in ipairs({-20,20}) do
  machine("ConveyorFrame",Vector3.new(8,1.2,48),Vector3.new(x,0.6,0),C(60,69,78))
  machine("ConveyorBelt",Vector3.new(7.4,0.2,47),Vector3.new(x,1.4,0),C(23,28,32),Enum.Material.SmoothPlastic)
  for z=-22,22,4 do
   machine("ConveyorRoller",Vector3.new(7.7,0.4,0.6),Vector3.new(x,1.7,z),C(90,100,110))
  end
  machine("MachineGantry",Vector3.new(10,1,3),Vector3.new(x,10,3),C(100,110,120))
  for _,offset in ipairs({-4.5,4.5}) do machine("GantryPost",Vector3.new(0.6,9,0.6),Vector3.new(x+offset,5,3),C(90,100,110)) end
  machine("Manipulator",Vector3.new(0.8,5,0.8),Vector3.new(x,7,3),C(100,115,125))
 end
 for _,z in ipairs({-25,15,38}) do
  machine("StorageCrate",Vector3.new(4,3,4),Vector3.new(-11,1.5,z),C(75,82,73))
  machine("UtilityCabinet",Vector3.new(4,6,2),Vector3.new(12,3,z),C(65,75,85))
 end
 return {Origin=origin,Model=f,Lamps=lamps,Emergency=emergency,Door=door,
  Spawn=CFrame.lookAt(origin+Vector3.new(0,3.2,-18),origin+Vector3.new(0,4.5,9))}
end

local function buildProductionEpilogue()
 local origin=Vector3.new(6000,0,0)
 local f=Instance.new("Model"); f.Name="TyanProductionPlant"; f.Parent=levelFolder
 local function prop(name,size,offset,color)
  local p=part(f,size,origin+offset,color,Enum.Material.Metal); p.Name=name; return p
 end
 prop("Floor",Vector3.new(64,1,64),Vector3.new(0,-0.5,0),C(40,47,52))
 prop("Roof",Vector3.new(64,1,64),Vector3.new(0,18.5,0),C(45,52,60))
 for _,x in ipairs({-32,32}) do prop("Wall",Vector3.new(1,18,64),Vector3.new(x,9,0),C(50,60,68)) end
 for _,z in ipairs({-32,32}) do prop("Wall",Vector3.new(64,18,1),Vector3.new(0,9,z),C(50,60,68)) end
 for _,z in ipairs({-23,-7,10,25}) do
  local fixture=prop("Lamp",Vector3.new(22,0.3,2),Vector3.new(0,16,z),C(170,185,190))
  light(fixture,C(205,215,225),35,1)
 end
 for _,x in ipairs({-22,22}) do
  prop("Conveyor",Vector3.new(8,1.2,52),Vector3.new(x,0.6,0),C(62,72,80))
  for z=-24,24,4 do prop("Roller",Vector3.new(7.8,0.4,0.8),Vector3.new(x,1.5,z),C(105,115,120)) end
 end
 for _,x in ipairs({-29,29}) do
  for _,z in ipairs({-22,-11,0,11,22}) do prop("ServerRack",Vector3.new(3,11,5),Vector3.new(x,5.5,z),C(24,35,43)) end
 end
 local before=table.clone(Types.Commander); before.Name="Пленник"; before.Shirt=C(95,95,100)
 local captive=buildRig(before,CFrame.new(origin+Vector3.new(-10,3,1))); anchorAll(captive); captive.Parent=f
 prop("Platform",Vector3.new(8,0.3,8),Vector3.new(-10,0.2,1),C(70,80,85))
 local shutter=prop("ConversionShutter",Vector3.new(8,10,0.4),Vector3.new(-10,15,-2),C(75,88,95))
 for _,x in ipairs({-15,-5}) do prop("ChamberFrame",Vector3.new(0.7,12,0.7),Vector3.new(x,6,1),C(105,115,125)) end
 local arm=prop("Manipulator",Vector3.new(0.7,5,0.7),Vector3.new(-13,8,1),C(100,115,130))
 local output=table.clone(Types.Melee); output.Name="Боец картеля"; output.Hair=C(130,80,105)
 local soldier=buildRig(output,CFrame.new(origin+Vector3.new(10,3,1))); anchorAll(soldier); soldier.Parent=f
 for _,z in ipairs({8,15,22}) do
  local unit=buildRig(output,CFrame.new(origin+Vector3.new(10,3,z))); anchorAll(unit); unit.Parent=f
 end
 return origin,captive,shutter,arm
end
local function focusStreaming(position)
 local focus=levelFolder:FindFirstChild("CinematicStreamingFocus")
 if not focus then
  focus=part(levelFolder,Vector3.new(1,1,1),position,C(0,0,0))
  focus.Name="CinematicStreamingFocus"; focus.Transparency=1; focus.CanCollide=false; focus.CanQuery=false
 end
 focus.Position=position
 for _,player in ipairs(Players:GetPlayers()) do player.ReplicationFocus=focus end
end
local function buildHordeStage()
 local origin=Vector3.new(8000,0,0)
 local f=Instance.new("Folder"); f.Name="HordeStage"; f.Parent=levelFolder
 part(f,Vector3.new(520,2,400),origin+Vector3.new(0,-1,145),C(35,42,48),Enum.Material.Concrete)
 for _,x in ipairs({-250,250}) do part(f,Vector3.new(2,40,400),origin+Vector3.new(x,20,145),C(45,55,64),Enum.Material.Concrete) end
 part(f,Vector3.new(500,40,2),origin+Vector3.new(0,20,340),C(45,55,64),Enum.Material.Concrete)
 return origin
end
-- Rename this constant to change the new character's name in dialogue and UI.
local ANDROID_NAME="Нейро"
local function awaitFinalAck(states,id,timeout)
 local deadline=os.clock()+timeout
 repeat
  local complete=true
  for _,player in ipairs(Players:GetPlayers()) do
   if readyClients[player] and states[player]~=id then complete=false end
  end
  if complete then return true end
  task.wait(0.05)
 until os.clock()>=deadline
 return false
end
local SECRET_DIALOGUE={
 {name="Артем",text="Мда, им вроде за это платят, да? Каким образом андроиды, которых мы в свое время легко контрили, так сильно переигрывают компанию, спонсируемую государством, которая как раз и создана для борьбы с ними?"},
 {name="Демид",text="Ага, есть такое. Я думаю, что они не справятся. Нам нужно вернуться в старые добрые и поставить их на место, согласен?"},
 {name="Артем",text="Ага, думаю, хорошая идея, а то они что-то совсем попутали."},
 {name="Демид",text="Короче, выдвигаемся помогать уже завтра. Так что нам нужно потренироваться и вспомнить скилл, согласен?"},
 {name="Артем",text="Хах, ну хорошо. С чего начнем? С тренировочной площадки или с чего-то еще?"},
 {name="Демид",text="Лучше давай заходим в Blade Ball быстрее, а то у нас всего лишь одна ночь, чтобы вспомнить скилл."},
}
local function secretActor(room,sourceName,displayName,target)
 local source=ServerStorage:FindFirstChild(sourceName)
 local rig
 if source and source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart",true) then
  local archivable=source.Archivable; source.Archivable=true
  local ok,copy=pcall(function() return source:Clone() end)
  source.Archivable=archivable
  if ok then rig=copy end
 end
 if not rig then
  warn("[SecretScene] ServerStorage."..sourceName.." is missing. Using a temporary placeholder for "..displayName)
  local cfg=table.clone(Types.Commander); cfg.Name=displayName
  cfg.Shirt=displayName=="Артем" and C(70,75,85) or C(45,65,95)
  rig=buildRig(cfg,CFrame.new())
  rig:SetAttribute("Placeholder",true)
 end
 rig.Name=displayName; rig:SetAttribute("SourceModel",sourceName)
 for _,object in ipairs(rig:GetDescendants()) do
  if object:IsA("BaseScript") then object.Disabled=true end
  if object:IsA("BasePart") then object.Anchored=true; object.CanCollide=false; object.CanTouch=false end
  if object:IsA("Humanoid") then object.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
 end
 rig.Parent=room; rig:PivotTo(target)
 local bounds,size=rig:GetBoundingBox()
 local floorY=target.Position.Y
 rig:PivotTo(rig:GetPivot()+Vector3.new(0,floorY-(bounds.Position.Y-size.Y/2),0))
 return rig
end
local function playSecretScene()
 sceneLock(true); introActive=true; canFight=false
 -- Credits left the screen opaque. Do not end the cutscene or release controls between scenes.
 local room=Instance.new("Model"); room.Name="PostCreditsRoom"; room.Parent=levelFolder
 local origin=Vector3.new(10000,0,0)
 local function prop(name,size,offset,color,material)
  local p=part(room,size,origin+offset,color,material or Enum.Material.SmoothPlastic); p.Name=name; return p
 end
 prop("Floor",Vector3.new(52,1,40),Vector3.new(0,-0.5,0),C(63,58,55),Enum.Material.WoodPlanks)
 prop("Ceiling",Vector3.new(52,1,40),Vector3.new(0,13.5,0),C(63,65,70))
 for _,x in ipairs({-26,26}) do prop("Wall",Vector3.new(1,13,40),Vector3.new(x,6.5,0),C(80,83,90)) end
 for _,z in ipairs({-20,20}) do prop("Wall",Vector3.new(52,13,1),Vector3.new(0,6.5,z),C(80,83,90)) end
 prop("SofaBase",Vector3.new(17,1.5,5),Vector3.new(0,0.75,-5),C(42,56,65),Enum.Material.Fabric)
 prop("SofaBack",Vector3.new(17,3,0.8),Vector3.new(0,2,-7.1),C(42,56,65),Enum.Material.Fabric)
 for _,x in ipairs({-8,8}) do prop("SofaArm",Vector3.new(1,2.5,5),Vector3.new(x,1.5,-5),C(48,62,70),Enum.Material.Fabric) end
 for _,x in ipairs({-4.5,0,4.5}) do prop("Cushion",Vector3.new(4.2,0.5,3.6),Vector3.new(x,1.75,-4.7),C(57,72,80),Enum.Material.Fabric) end
 prop("CoffeeTable",Vector3.new(10,1.2,4),Vector3.new(0,0.6,4),C(65,50,42),Enum.Material.Wood)
 local tv=prop("Television",Vector3.new(23,9,0.6),Vector3.new(0,7.2,19.2),C(12,14,18))
 local display=Instance.new("SurfaceGui"); display.Name="TVStatic"; display.Face=Enum.NormalId.Front; display.CanvasSize=Vector2.new(920,360); display.Parent=tv
 for row=0,7 do
  for column=0,19 do
   local value=((row*19+column*31)%90)+35
   local pixel=Instance.new("Frame"); pixel.Size=UDim2.fromScale(0.05,0.125); pixel.Position=UDim2.fromScale(column/20,row/8)
   pixel.BackgroundColor3=C(value,value,value); pixel.BorderSizePixel=0; pixel.Parent=display
  end
 end
 for _,x in ipairs({-13,13}) do
  local fixture=prop("Lamp",Vector3.new(5,0.3,3),Vector3.new(x,12,1),C(190,180,160))
  light(fixture,C(235,220,195),35,1)
 end
 light(tv,C(150,175,200),25,0.5)
 secretActor(room,"eurtyoeyrntiu","Артем",CFrame.lookAt(origin+Vector3.new(-4,0.1,-1),origin+Vector3.new(0,0.1,8)))
 secretActor(room,"ZamestitelDiomchica","Демид",CFrame.lookAt(origin+Vector3.new(4,0.1,-1),origin+Vector3.new(0,0.1,8)))
 applyPreset("Base",0.1)
 focusStreaming(origin+Vector3.new(0,5,4))
 cameraPlan(origin+Vector3.new(22,9,-16),origin+Vector3.new(22,9,-16),origin+Vector3.new(0,5,5),0,78,78)
 prepareView(origin+Vector3.new(0,5,4))
 CutsceneRE:FireAllClients("reveal")
 for _,line in ipairs(SECRET_DIALOGUE) do
  local duration=math.max(4,(utf8.len(line.text) or #line.text)*0.055+2.5)
  -- Literal dialogue bypasses the normal punctuation cleanup, preserving the supplied text exactly.
  CutsceneRE:FireAllClients("dialogue",{name=line.name,text=line.text,duration=duration})
  task.wait(duration+0.4)
 end
 FadeRE:FireAllClients(true,"")
 task.wait(1)
 room:Destroy()
end
function startBase()
 sceneLock(true); introActive=true; canFight=false; levelToken+=1
 MusicRE:FireAllClients("stop")
 CreditsRE:FireAllClients(false)
 FadeRE:FireAllClients(true,"")
 task.wait(0.8)
 clearLevel(); newFolders()
 currentLevel,currentName,enemiesLeft,currentWave,totalWaves=6,"Возвращение на базу",-1,0,0
 local baseInfo=buildBase(levelFolder)
 local factory={Origin=Vector3.zero,Spawn=baseInfo.Spawn,Door=baseInfo.Door,Lamps={},Emergency={}}
 for _,entry in ipairs(baseInfo.Lamps) do table.insert(factory.Lamps,entry[2]) end
 for _,entry in ipairs(baseInfo.Alarms) do table.insert(factory.Emergency,entry[2]) end
 local origin=factory.Origin
 currentSpawn=factory.Spawn
 applyPreset("Base",0.1)
 placeAll(); sceneLock(true); broadcast()
 local ally=buildRig(Types.Commander,CFrame.lookAt(origin+Vector3.new(8,3,-2),origin+Vector3.new(0,3,-18)))
 anchorAll(ally); ally.Name="Связной"; ally.Parent=levelFolder
 CutsceneRE:FireAllClients("start")
 CutsceneRE:FireAllClients("pov",ally.Head)
 prepareView(currentSpawn.Position)
 CutsceneRE:FireAllClients("reveal")
 CutsceneRE:FireAllClients("pov",ally.Head)
 say("Пока ты был на миссии, нашу базу на Дальнем Востоке полностью разрушили. Появилась очень опасная женщина, в народе ее уже прозвали "..ANDROID_NAME..".",10)
 for _,lamp in ipairs(factory.Lamps) do lamp.Enabled=false end
 for _,lamp in ipairs(factory.Emergency) do lamp.Enabled=true end
 -- Final-scene-only dimming. The next location's preset restores normal lighting.
 TweenService:Create(Lighting,TweenInfo.new(0.5),{Ambient=C(25,28,35),OutdoorAmbient=C(20,23,28),Brightness=0.5}):Play()
 MusicRE:FireAllClients("finalSlow")
 say("Черт, кажется, нас обнаружили.",3)
 local allyCF=ally:GetPivot()
 moveModel(ally,CFrame.lookAt(allyCF.Position,origin+Vector3.new(0,3,25)),0.8)
 CutsceneRE:FireAllClients("pov",origin+Vector3.new(0,5,25))
 local door=factory.Door
 TweenService:Create(door,TweenInfo.new(1.5),{CFrame=door.CFrame*CFrame.new(0,11,0)}):Play()
 task.wait(1.6)
 local androidCfg=table.clone(Types.Neuro); androidCfg.Name=ANDROID_NAME
 local android=buildRig(androidCfg,CFrame.lookAt(origin+Vector3.new(0,3,33),origin+Vector3.new(0,3,-18)))
 anchorAll(android); android.Parent=levelFolder; enhanceNeuroCyber(android)
 local visor=part(android,Vector3.new(1.8,0.22,0.15),android.Head.Position+Vector3.new(0,0,-0.55),C(45,190,180),Enum.Material.SmoothPlastic)
 visor.Name="Visor"; visor.Material=Enum.Material.Neon; visor.CanCollide=false; visor.Anchored=false
 local visorWeld=Instance.new("WeldConstraint"); visorWeld.Part0=android.Head; visorWeld.Part1=visor; visorWeld.Parent=visor
 light(visor,C(50,170,165),8,0.5)
 CutsceneRE:FireAllClients("pov",android.Head,44)
 moveModel(android,CFrame.lookAt(origin+Vector3.new(0,3,18),origin+Vector3.new(0,3,-18)),1.5,true)
 say("Не трогай его. Слышишь меня.",2.5)
 local bolt=part(fxFolder,Vector3.new(0.7,0.7,0.7),android.Head.Position,C(65,190,195),Enum.Material.Neon)
 bolt.Shape=Enum.PartType.Ball; bolt.CanCollide=false; bolt.CanQuery=false
 TweenService:Create(bolt,TweenInfo.new(0.3),{Position=ally.Head.Position}):Play()
 task.wait(0.3); bolt:Destroy(); ShakeRE:FireAllClients(4)
 CutsceneRE:FireAllClients("pov",ally.Head)
 moveModel(ally,ally:GetPivot()*CFrame.new(0,-2,0)*CFrame.Angles(math.rad(80),0,0),0.9)
 task.wait(2)
 CutsceneRE:FireAllClients("pov",android.Head,44)
 moveModel(android,CFrame.lookAt(origin+Vector3.new(0,3,8),origin+Vector3.new(0,3,-18)),1,true)
 say("Не двигайся. Сначала я заберу все, что ты знаешь.",4)
 finaleId+=1
 local id=finaleId
 CutsceneRE:FireAllClients("scan",{id=id,seconds=7})
 if not awaitFinalAck(scanAcknowledged,id,12) then warn("Scan acknowledgement timed out") end
 say("Все, что мне нужно, я получила.",3)
 -- Show the charge, launch and victim's fall without hiding the attacker behind UI.
 CutsceneRE:FireAllClients("pov",android.Head,44)
 local charge=part(fxFolder,Vector3.new(0.4,0.4,0.4),android.Head.Position+Vector3.new(0,-1,-1),C(65,190,190),Enum.Material.Neon)
 charge.Shape=Enum.PartType.Ball; charge.CanCollide=false; charge.CanQuery=false
 TweenService:Create(charge,TweenInfo.new(1.4),{Size=Vector3.new(1.8,1.8,1.8)}):Play()
 task.wait(2)
 for _,player in ipairs(Players:GetPlayers()) do
  local head=player.Character and player.Character:FindFirstChild("Head")
  if head then
   local shot=part(fxFolder,Vector3.new(1,1,1),charge.Position,C(70,200,200),Enum.Material.Neon)
   shot.Shape=Enum.PartType.Ball; shot.CanCollide=false; shot.CanQuery=false
   TweenService:Create(shot,TweenInfo.new(0.7,Enum.EasingStyle.Linear),{Position=head.Position}):Play()
   Debris:AddItem(shot,0.8)
  end
 end
 charge:Destroy()
 task.wait(0.75)
 CutsceneRE:FireAllClients("blood",0.25); ShakeRE:FireAllClients(8)
 local oldRespawn=Players.RespawnTime; Players.RespawnTime=600
 for _,player in ipairs(Players:GetPlayers()) do
  local character=player.Character
  local hum=character and character:FindFirstChildOfClass("Humanoid")
  if hum then hum.BreakJointsOnDeath=false; hum.Health=0 end
 end
 cameraPlan(origin+Vector3.new(0,5,-18),origin+Vector3.new(0,1.5,-19),android.Head.Position,1.2,58,60)
 for _,player in ipairs(Players:GetPlayers()) do
  if player.Character then moveModel(player.Character,player.Character:GetPivot()*CFrame.new(0,-2,0)*CFrame.Angles(math.rad(-80),0,0),0.7) end
 end
 task.wait(3)
 FadeRE:FireAllClients(true,"")
 task.wait(0.8)
 local horde=buildHordeStage()
 focusStreaming(horde+Vector3.new(0,4,50))
 applyPreset("Base",0.1)
 CutsceneRE:FireAllClients("army",horde,id)
 cameraPlan(horde+Vector3.new(0,7,-18),horde+Vector3.new(0,6,-11),horde+Vector3.new(0,4,55),8,38,30)
 prepareView(horde)
 if not awaitFinalAck(armyAcknowledged,id,10) then warn("Horde loading timed out") end
 CutsceneRE:FireAllClients("reveal")
 say("Это не один отряд. Здесь целая армия. Теперь понятно, зачем им завод.",8)
 task.wait(3)
 FadeRE:FireAllClients(true,"")
 task.wait(0.8)
 local production,captive,shutter,arm=buildProductionEpilogue()
 focusStreaming(production)
 cameraPlan(production+Vector3.new(-19,6,-18),production+Vector3.new(-17,5,-13),production+Vector3.new(-10,4,1),8,52,44)
 prepareView(production)
 CutsceneRE:FireAllClients("reveal")
 say("Сюда привозят взрослых пленников. Назад их уже не выпускают.",6)
 TweenService:Create(shutter,TweenInfo.new(1.5),{Position=production+Vector3.new(-10,5,-2)}):Play()
 task.wait(1.6)
 TweenService:Create(arm,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,1,true),{Position=arm.Position+Vector3.new(2,-2,0)}):Play()
 say("За створками людей переделывают в бойцов картеля. Конвейер работает без остановки.",7)
 captive:Destroy()
 FadeRE:FireAllClients(true,"")
 task.wait(0.8)
 cameraPlan(production+Vector3.new(19,5,-13),production+Vector3.new(16,5,-9),production+Vector3.new(10,4,4),8,48,40)
 CutsceneRE:FireAllClients("reveal")
 say("Они уже готовят следующих. И таких линий здесь десятки.",7)
 task.wait(3)
 -- Blackout is reserved for the end, after BOTH restored epilogue inserts.
 CutsceneRE:FireAllClients("blackout",id)
 if not awaitFinalAck(blackAcknowledged,id,8) then warn("Blackout acknowledgement timed out") end
 -- Credits are server-commanded here only, never from the music playback clock.
 CreditsRE:FireAllClients(true)
 task.wait(35)
 CreditsRE:FireAllClients(false); MusicRE:FireAllClients("stop")
 CutsceneRE:FireAllClients("armyClear")
 playSecretScene()
 Players.RespawnTime=oldRespawn
 returnToMenu()
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
  CutsceneRE:FireAllClients("pov",door.Position)
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
  NotifyRE:FireClient(plr,"Заходи, теперь проход свободен. Задний выход с другой стороны дома.",5)
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
 if plr:GetAttribute("Chapter")==3 then if c3Attack then c3Attack(plr,wname,origin,dir,charge) end; return end
 if plr:GetAttribute("Chapter")==2 then if c2Attack then c2Attack(plr,wname,origin,dir,charge) end; return end
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

-- Public servers are lobby hubs. Each launch reserves an isolated match server.
local TeleportService=game:GetService("TeleportService")
local RunService=game:GetService("RunService")
local lobbies,membership,launching={},{},{}
local sessionRoster
local rosterWaitStart
local hasFinishedSession=false
local function snapshot()
 local list={}
 for owner,lobby in pairs(lobbies) do
  local members={}
  for _,player in ipairs(lobby.members) do table.insert(members,{id=player.UserId,name=player.DisplayName,hero=player:GetAttribute("HeroChosen") and player:GetAttribute("Hero") or nil}) end
  table.insert(list,{owner=owner,name=lobby.host.DisplayName..(" • Глава "..({"I","II","III"})[lobby.host:GetAttribute("SelectedChapter") or 1]),members=members,launching=launching[owner]==true})
 end
 table.sort(list,function(a,b) return a.owner<b.owner end)
 return {lobbies=list,started=sessionStarted,size=sessionSize,story=story().name,waitingReserved=sessionRoster~=nil}
end
pushLobbyState=function() LobbyRE:FireAllClients("state",snapshot()) end
local function leaveLobby(player)
 local owner=membership[player]
 if not owner then return end
 if launching[owner] then return end
 local lobby=lobbies[owner]
 membership[player]=nil
 if not lobby then return end
 if owner==player.UserId then
  for _,member in ipairs(lobby.members) do membership[member]=nil end
  lobbies[owner]=nil
 else
  local index=table.find(lobby.members,player)
  if index then table.remove(lobby.members,index) end
 end
end
-- Inert originals for the character picker viewports.
do
 local previews=Instance.new("Folder"); previews.Name="HeroPreviews"; previews.Parent=RS
 for hero,sourceName in pairs({Artem="eurtyoeyrntiu",Demid="ZamestitelDiomchica"}) do
  local source=ServerStorage:FindFirstChild(sourceName)
  if source and source:IsA("Model") then
   local archivable=source.Archivable; source.Archivable=true
   local ok,model=pcall(function() return source:Clone() end); source.Archivable=archivable
   if ok and model then
    model.Name=hero
    for _,object in ipairs(model:GetDescendants()) do
     if object:IsA("BaseScript") then object:Destroy()
     elseif object:IsA("BasePart") then object.Anchored=true; object.CanCollide=false end
    end
    model.Parent=previews
   end
  end
 end
end
-- BEGIN CHAPTER TWO
-- Chapter 2 is embedded into GameServer by tools/build.py; shares its local services/helpers.
-- All combat, role checks, objective completion and the escape clock are server authoritative.
local C2={active=false,serial=0,stage=1,escaping=false,finished=false,mobs={},party={},connections={},alarm=false}
local C2RE=newRemote("Chapter2")
local C2_ZONES={
 {name="01 / СОСНОВЫЙ ПОДЪЕЗД",theme="forest",task="Перехватить питание внешнего шлюза",kind="hack"},
 {name="02 / ГРУЗОВОЙ ТЕРМИНАЛ",theme="cargo",task="Срезать замок грузовых ворот",kind="weld"},
 {name="03 / ТЕХНИЧЕСКИЙ КОЛЛЕКТОР",theme="pipes",task="Перекрыть охлаждение охранной сети",kind="valve"},
 {name="04 / ЦЕХ ШТАМПОВКИ",theme="press",task="Остановить конвейер",kind="weld"},
 {name="05 / АРХИВ ЛИЧНОСТЕЙ",theme="servers",task="Взломать архив и скопировать планы",kind="hack"},
 {name="06 / ЛАБОРАТОРИЯ КОПИЙ",theme="lab",task="Обесточить капсулы",kind="hack"},
 {name="07 / РАКЕТНЫЙ АНГАР",theme="mech",task="Срезать подачу ракет меха-тян",kind="weld"},
 {name="08 / ГАЛЕРЕЯ РЕАКТОРА",theme="reactor",task="Открыть аварийные клапаны",kind="valve"},
 {name="09 / КОМАНДНЫЙ МОСТ",theme="command",task="Отключить защиту кабинета",kind="hack"},
 {name="10 / КАБИНЕТ МАФИИ",theme="boss",task="Забрать ключи эвакуации",kind="hack"},
}
local c2Origin=Vector3.new(0,0,0)
local PathfindingService=game:GetService("PathfindingService")
local C2_LAYOUT={{46,26},{42,24},{28,18},{48,30},{34,20},{42,24},{48,34},{32,30},{38,22},{32,24}}
local c2Send,c2Finish,c2Activate,c2Escape
local function c2Part(parent,name,size,pos,color,material)
 local p=part(parent,size,pos,color,material or Enum.Material.SmoothPlastic); p.Name=name; return p
end
-- No BillboardGui objectives: interactions are visible only within arm's reach.
local function c2Root(p)
 if not p.Parent then return nil end
 local char=p.Character; local h=char and char:FindFirstChildOfClass("Humanoid")
 return h and h.Health>0 and char:FindFirstChild("HumanoidRootPart"),h
end
local function c2Alive()
 for _,p in ipairs(C2.party) do if p.Parent and c2Root(p) then return true end end
 return false
end
local function c2Count(zone)
 local n=0
 for m,e in pairs(C2.mobs) do if m.Parent and e.hum.Health>0 and not e.defeated and not e.boss and e.zone==zone then n+=1 end end
 return n
end
c2Send=function()
 local z=C2.zones and C2.zones[C2.stage]
 for _,p in ipairs(C2.party) do if p.Parent then
  local displayStage=C2.stage
  local root=c2Root(p)
  if C2.escaping and root then displayStage=math.clamp(math.floor((root.Position.X-c2Origin.X+75)/160)+1,1,10) end
  C2RE:FireClient(p,"state",{stage=displayStage,name=C2_ZONES[displayStage].name,weaponLevel=p:GetAttribute("WeaponLevel") or 2,role=p:GetAttribute("Hero"),escaping=C2.escaping,deadline=C2.deadline,alarm=C2.alarm,enemies=c2Count(displayStage),wave=z and z.wave or 0,rounds=z and z.rounds or 2,keycard=z and z.keyCollected==true,bossPhase=C2.bossPhase,shieldHP=C2.shieldHP,shieldMax=C2.shieldMax})
 end end
end
local function c2Dress(m,mech)
 -- Layered hair, uniform, face and trim, rather than recolored combat blocks.
 local head=m:FindFirstChild("Head"); local torso=m:FindFirstChild("Torso")
 if not head or not torso then return end
 for _,old in ipairs(m:GetChildren()) do
  if old:IsA("BasePart") and (old.Name=="Hair" or old.Name=="Tail" or old.Name=="Bow" or old.Name=="Eye" or old.Name=="Skirt") then old:Destroy() end
 end
 local headMesh=head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh")
 headMesh.MeshType=Enum.MeshType.Head; headMesh.Scale=Vector3.new(1.05,1.05,1.05); headMesh.Parent=head
 local function trim(name,size,offset,color,base,shape)
  local p=c2Part(m,name,size,Vector3.zero,color); p.Anchored=false; p.CanCollide=false; p.Massless=true; p.CFrame=base.CFrame*offset
  if shape then p.Shape=shape end
  local w=Instance.new("WeldConstraint"); w.Part0=base; w.Part1=p; w.Parent=p
  return p
 end
 local hair=C(57,40,69)
 trim("HairCrown",Vector3.new(2.2,0.85,1.45),CFrame.new(0,0.5,0.1),hair,head,Enum.PartType.Ball)
 trim("HairBack",Vector3.new(2.05,1.9,0.65),CFrame.new(0,-0.15,0.5),hair,head,Enum.PartType.Ball)
 for _,side in ipairs({-1,1}) do
  trim("SideLock",Vector3.new(0.48,1.9,0.85),CFrame.new(side*0.95,-0.25,0.1)*CFrame.Angles(0,0,side*0.12),hair,head,Enum.PartType.Ball)
  trim("HairRibbon",Vector3.new(0.55,0.3,0.3),CFrame.new(side*1.03,0.3,0.1),C(153,65,92),head)
  trim("EyeWhite",Vector3.new(0.46,0.25,0.08),CFrame.new(side*0.4,0.02,-0.52),C(227,223,223),head,Enum.PartType.Ball)
  trim("Iris",Vector3.new(0.2,0.25,0.08),CFrame.new(side*0.4,0.02,-0.57),C(82,72,124),head,Enum.PartType.Ball)
  trim("Pupil",Vector3.new(0.08,0.18,0.04),CFrame.new(side*0.4,0.02,-0.62),C(24,25,33),head,Enum.PartType.Ball)
  trim("EyeGlint",Vector3.new(0.055,0.055,0.04),CFrame.new(side*0.4-0.035,0.08,-0.65),C(245,245,242),head,Enum.PartType.Ball)
  trim("Brow",Vector3.new(0.47,0.06,0.08),CFrame.new(side*0.4,0.24,-0.54)*CFrame.Angles(0,0,side*0.07),hair,head)
  local arm=m:FindFirstChild(side==1 and "Right Arm" or "Left Arm")
  local leg=m:FindFirstChild(side==1 and "Right Leg" or "Left Leg")
  if arm then trim("UniformSleeve",Vector3.new(1.04,1.15,1.04),CFrame.new(0,0.43,0),C(48,61,80),arm) end
  if leg then trim("Boot",Vector3.new(1.05,1,1.15),CFrame.new(0,-0.52,-0.03),C(32,34,43),leg) end
 end
 for k=1,5 do
  trim("Fringe",Vector3.new(0.43,0.6,0.28),CFrame.new(-1.03+k*0.34,0.37,-0.48)*CFrame.Angles(0,0,0.18),hair,head,Enum.PartType.Ball)
 end
 trim("Mouth",Vector3.new(0.23,0.04,0.06),CFrame.new(0,-0.28,-0.53),C(151,83,90),head)
 trim("Collar",Vector3.new(1.8,0.18,1.08),CFrame.new(0,0.85,0),C(218,220,221),torso)
 trim("Tie",Vector3.new(0.28,0.8,0.12),CFrame.new(0,0.35,-0.58),C(150,60,87),torso)
 trim("Belt",Vector3.new(2.1,0.2,1.13),CFrame.new(0,-0.62,0),C(30,35,43),torso)
 trim("Buckle",Vector3.new(0.3,0.25,0.12),CFrame.new(0,-0.62,-0.64),C(162,154,127),torso)
 for k=0,6 do
  local angle=(k/6-0.5)*1.6
  trim("UniformPleat",Vector3.new(0.4,0.72,0.2),CFrame.new(math.sin(angle)*1.23,-1.02,-math.cos(angle)*0.75)*CFrame.Angles(0,-angle,0),C(42+k%2*7,49,68),torso)
 end
 if mech then
  trim("MechArmor",Vector3.new(2.6,2.3,1.5),CFrame.new(),C(55,65,80),torso)
  for _,s in ipairs({-1,1}) do trim("RocketPod",Vector3.new(1,1,2.3),CFrame.new(s*1.8,0.8,0),C(90,100,115),torso) end
 end
end
local function c2Rocket(e,target,serial)
 local from=e.root.Position+Vector3.new(0,2,0); local goal=target.Position
 local marker=c2Part(C2.map,"RocketWarning",Vector3.new(9,0.08,9),Vector3.new(goal.X,0.28,goal.Z),C(245,80,40),Enum.Material.Neon); marker.CanCollide=false
 marker.Transparency=0.35; marker.CanQuery=false
 task.wait(1.15)
 if not C2.active or C2.serial~=serial or e.hum.Health<=0 then marker:Destroy(); return end
 local rocket=c2Part(C2.map,"Rocket",Vector3.new(0.7,0.7,2.3),from,C(230,145,65),Enum.Material.Neon); rocket.CanCollide=false
 TweenService:Create(rocket,TweenInfo.new(0.65),{Position=goal}):Play(); task.wait(0.65)
 if not C2.active or C2.serial~=serial or introActive or C2.finished or e.hum.Health<=0 then rocket:Destroy(); marker:Destroy(); return end
 rocket:Destroy(); marker:Destroy()
 local flash=c2Part(C2.map,"Blast",Vector3.new(10,10,10),goal,C(245,125,55),Enum.Material.Neon); flash.Shape=Enum.PartType.Ball; flash.CanCollide=false; Debris:AddItem(flash,0.25)
 for _,p in ipairs(C2.party) do local r,h=c2Root(p); if r and (r.Position-goal).Magnitude<11 then h:TakeDamage(48) end end
end
local function c2Mobilize(model,hum,root)
 for _,body in ipairs(model:GetDescendants()) do
  if body:IsA("BasePart") then body.Anchored=false; body.CanCollide=body.Name=="Torso"; body.CollisionGroup="C2Enemy" end
 end
 hum.PlatformStand=false; hum.AutoRotate=true; hum:ChangeState(Enum.HumanoidStateType.Running)
 root:SetNetworkOwner(nil)
end
local function c2Spawn(zone,pos,mech,boss)
 local cfg=table.clone(boss and Types.Mafiozi or Types.Pistol)
 if boss then cfg.Male=false; cfg.Hair=C(160,170,195); cfg.Shirt=C(25,28,40); cfg.Skirt=C(30,25,40) end
 if not boss then
  cfg.Male=false; cfg.Name=mech and "Меха-тян • ракетчица" or "Охрана мини-завода"
  cfg.Hair=C(75+zone*7,45,95+zone*4); cfg.Shirt=C(45,55,85); cfg.Skirt=C(35,40,65); cfg.Legs=C(55,50,65)
 end
 local m,h,r,j=buildRig(cfg,CFrame.new(pos)); m.Parent=C2.map; m:SetAttribute("Enemy",true); m:SetAttribute("Chapter2Enemy",true)
 h.HealthDisplayType=Enum.HumanoidHealthDisplayType.DisplayWhenDamaged; h.HealthDisplayDistance=80
 h.MaxHealth=(boss and 750 or mech and 180 or 85)*(#C2.party>1 and 1.6 or 1); h.Health=h.MaxHealth; h.WalkSpeed=boss and 9 or 12
 if not boss then c2Dress(m,mech) end
 c2Mobilize(m,h,r)
 local e={hum=h,root=r,zone=zone,mech=mech,boss=boss,blind=0,last=0,patrol=pos,alertUntil=0,pathAt=0,waypoints=nil,waypoint=1,stuckAt=os.clock(),lastPosition=pos,joints=j,base={RH=j.RH.C0,LH=j.LH.C0,LS=j.LS.C0,RS=j.RS.C0}}; C2.mobs[m]=e
 h.Died:Connect(function() if C2.active then c2Send(); C2.OnEnemyDown(zone,e,m) end; ragdoll(m); Debris:AddItem(m,boss and 60 or 12) end)
 if boss then anchorAll(m); return m end
 local serial=C2.serial
 task.spawn(function()
  while C2.active and serial==C2.serial and m.Parent and h.Health>0 and not e.defeated do
   if e.deployGoal and (r.Position-e.deployGoal).Magnitude>5 then
    h:MoveTo(e.deployGoal); task.wait(0.25); continue
   end
   e.deployGoal=nil
   local target,dist=nil,math.huge
   for _,p in ipairs(C2.party) do local root=c2Root(p); if root then local d=(root.Position-r.Position).Magnitude; if d<dist then target=root; dist=d end end end
   if target and workspace:GetServerTimeNow()>e.blind then
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={m}
    local hit=workspace:Raycast(r.Position,target.Position-r.Position,rp)
    local visible=hit and hit.Instance:IsDescendantOf(target.Parent)
    local delta=target.Position-r.Position
    local facing=delta.Magnitude<0.1 or r.CFrame.LookVector:Dot(delta.Unit)>-0.15
    if dist<110 and visible and (C2.alarm or facing or dist<12) then
     e.alertUntil=os.clock()+12; e.lastSeen=target.Position
     if not C2.alarm then C2.alarm=true; c2Send() end
    end
    local pursuing=os.clock()<e.alertUntil or (C2.alarm and dist<140)
    if pursuing then
     local goal=visible and target.Position or e.lastSeen or target.Position
     local zoneInfo=C2.zones[zone]
     if e.tactic=="cover" and e.cover and visible then goal=e.cover+Vector3.new(0,0,math.sin(os.clock()*1.2)*4)
     elseif e.tactic=="flank" and visible then goal=Vector3.new(math.clamp(target.Position.X+9,c2Origin.X+zoneInfo.x-60,c2Origin.X+zoneInfo.x+60),target.Position.Y,math.clamp(target.Position.Z+(e.side or 1)*14,-C2_LAYOUT[zone][1]+5,C2_LAYOUT[zone][1]-5)) end
     local advance=e.tactic=="rush" and dist>8 or e.tactic~="rush" and (goal-r.Position).Magnitude>4
     if not visible or advance then
      if os.clock()-e.pathAt>1.3 then
       e.pathAt=os.clock()
       local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=5})
       local ok=pcall(function() path:ComputeAsync(r.Position,goal) end)
       if ok and path.Status==Enum.PathStatus.Success then e.waypoints=path:GetWaypoints(); e.waypoint=2 else e.waypoints=nil end
      end
      local wp=e.waypoints and e.waypoints[e.waypoint]
      if wp and (r.Position-wp.Position).Magnitude<4 then e.waypoint+=1; wp=e.waypoints[e.waypoint] end
      if wp and wp.Action==Enum.PathWaypointAction.Jump then h.Jump=true end
      h:MoveTo(wp and wp.Position or goal)
      if (r.Position-e.lastPosition).Magnitude>1 then e.lastPosition=r.Position; e.stuckAt=os.clock()
      elseif os.clock()-e.stuckAt>2 then h.Jump=true; e.pathAt=0; e.stuckAt=os.clock() end
     else h:MoveTo(r.Position) end
     if visible and dist<85 and os.clock()-e.last>(mech and 5 or 1.6) then
      e.last=os.clock()
      if mech then task.spawn(c2Rocket,e,target,serial)
      else
       tracer(r.Position+Vector3.new(0,1,0),target.Position,C(245,170,90))
       local th=target.Parent:FindFirstChildOfClass("Humanoid"); if th then th:TakeDamage(boss and 16 or 9) end
      end
     end
    else
     local offset=math.sin(os.clock()*0.32+zone)*9
     h:MoveTo(e.patrol+Vector3.new(0,0,offset))
    end
   else h:MoveTo(r.Position) end
   task.wait(0.3)
  end
 end)
 return m
end
local function c2Allowed(player,tool)
 local living=0
 for _,p in ipairs(C2.party) do if c2Root(p) then living+=1 end end
 if living<=1 then return true end
 return tool=="combat" or player:GetAttribute("Hero")=="Artem"
end
local function c2Prompt(p,label,hold,callback)
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=label; prompt.ObjectText="ГЛАВА II"; prompt.HoldDuration=hold; prompt.MaxActivationDistance=9; prompt.RequiresLineOfSight=true; prompt.Parent=p
 local busy={}; local held={}
 table.insert(C2.connections,prompt.PromptButtonHoldBegan:Connect(function(player) held[player]=os.clock() end))
 table.insert(C2.connections,prompt.PromptButtonHoldEnded:Connect(function(player) task.defer(function() held[player]=nil end) end))
 local connection=prompt.Triggered:Connect(function(player)
  if not C2.active or C2.finished or not table.find(C2.party,player) or busy[player] then return end
  local r=c2Root(player); if not r or (r.Position-p.Position).Magnitude>12 then return end
  if hold>0 and (not held[player] or os.clock()-held[player]<hold-0.3) then return end
  busy[player]=true; callback(player,prompt); busy[player]=nil
 end)
 table.insert(C2.connections,connection)
 return prompt
end
-- All engineering solutions are verified on the server, never by a client 'success' flag.
local function c2CircuitSolved(board)
 local function has(cell,direction)
  for _,port in ipairs(board.base[cell]) do if (port+board.rotations[cell])%4==direction then return true end end
  return false
 end
 local visited={}; local queue={4}; local at=1
 if not has(4,3) then return false,visited end
 visited[4]=true
 while queue[at] do
  local cell=queue[at]; at+=1
  if cell==6 and has(6,1) then return true,visited end
  local row,col=math.floor((cell-1)/3),((cell-1)%3)
  for direction=0,3 do
   if has(cell,direction) then
    local nr=row+({-1,0,1,0})[direction+1]; local nc=col+({0,1,0,-1})[direction+1]
    local nextCell=nr*3+nc+1
    if nr>=0 and nr<3 and nc>=0 and nc<3 and not visited[nextCell] and has(nextCell,(direction+2)%4) then
     visited[nextCell]=true; table.insert(queue,nextCell)
    end
   end
  end
 end
 return false,visited
end
local function c2CircuitBoard(rng)
 local board={base={{2,1},{3,2},{1,2},{3,0},{0,2},{2,1},{0,1},{0,1},{3,0}},rotations={}}
 repeat
  for i=1,9 do board.rotations[i]=rng:NextInteger(0,3) end
 until not c2CircuitSolved(board)
 return board
end
local function c2EndEngineering(player,message)
 local ch=C2.challenges and C2.challenges[player]
 if not ch then return end
 C2.challenges[player]=nil
 if ch.zone.owner==player then ch.zone.owner=nil end
 local _,h=c2Root(player)
 if h and not introActive and not C2.finished then h.WalkSpeed=16; h.JumpPower=50 end
 if player.Parent then C2RE:FireClient(player,"engineeringClose",{message=message}) end
end
local function c2EngineeringState(player,ch)
 local connected={}
 if ch.board then local _,visited=c2CircuitSolved(ch.board); for cell in pairs(visited) do table.insert(connected,cell) end end
 C2RE:FireClient(player,"engineering",{token=ch.token,kind=ch.zone.kind,board=ch.board,connected=connected,progress=ch.progress,expires=ch.expires,start=ch.start,target=ch.target,fast=ch.fast,required=ch.required})
end
local function c2Engineering(player,z)
 if C2.challenges[player] or (z.owner and z.owner~=player) or introActive then return end
 if not C2.CanUseTerminal(z) then C2RE:FireClient(player,"terminalLocked",{keycard=z.keyCollected==true,cleared=z.cleared==true}); return end
 local r,h=c2Root(player); if not r or (r.Position-z.panel.Position).Magnitude>10 then return end
 C2.challengeSerial+=1
 local ch={zone=z,token=tostring(C2.serial)..":"..tostring(C2.challengeSerial),progress=0,expires=workspace:GetServerTimeNow()+90,last=0,start=workspace:GetServerTimeNow(),target=0.3+math.random()*0.4}
 ch.fast=z.kind=="hack" and player:GetAttribute("Hero")=="Artem"; ch.required=18
 if z.kind=="hack" and not ch.fast then ch.board=c2CircuitBoard(Random.new()) end
 z.owner=player; C2.challenges[player]=ch
 h.WalkSpeed=0; h.JumpPower=0
 c2EngineeringState(player,ch)
end
local function c2WorldWeapon(player,name)
 local char=player.Character; if not char then return end
 local old=char:FindFirstChild("Chapter2Equipment"); if old then old:Destroy() end
 local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"); if not hand then return end
 local model=Instance.new("Model"); model.Name="Chapter2Equipment"; model.Parent=char
 local function item(label,size,offset,color,wedge)
  local p=Instance.new(wedge and "WedgePart" or "Part"); p.Name=label; p.Size=size; p.Color=color; p.Material=Enum.Material.Metal
  p.Anchored=false; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
  p.CFrame=hand.CFrame*CFrame.new(0,-0.8,0)*offset; p.Parent=model
  local weld=Instance.new("WeldConstraint"); weld.Part0=hand; weld.Part1=p; weld.Parent=p
 end
 if name=="Fists" then
  if player:GetAttribute("Hero")=="Artem" then
   item("WelderHandle",Vector3.new(0.35,0.75,0.4),CFrame.new(),C(40,66,73))
   item("WelderNozzle",Vector3.new(0.22,0.22,1.1),CFrame.new(0,0.2,-0.6),C(140,144,145))
  else
   item("KnifeGrip",Vector3.new(0.25,0.7,0.3),CFrame.new(),C(35,40,44))
   item("KnifeBlade",Vector3.new(0.12,0.35,1.4),CFrame.new(0,0.25,-0.8),C(175,185,195),true)
  end
 else
  local length=name=="Pistol" and 1.5 or name=="Shotgun" and 3.7 or name=="Rifle" and 4.2 or 2.4
  item("Receiver",Vector3.new(0.45,0.55,length),CFrame.new(0,0.3,-length/2+0.25),C(48,57,65))
  item("Grip",Vector3.new(0.35,0.85,0.45),CFrame.new(0,-0.1,0),C(28,33,38))
  item("Barrel",Vector3.new(0.22,0.22,1),CFrame.new(0,0.35,-length),C(100,110,118))
  if name~="Pistol" then item("Magazine",Vector3.new(0.35,0.9,0.55),CFrame.new(0,-0.3,-0.9),C(38,44,48)) end
  if name=="Rifle" then for k=1,4 do item("RailCoil",Vector3.new(0.65,0.65,0.15),CFrame.new(0,0.3,-1-k*0.55),C(80,150,170)) end end
 end
 player:SetAttribute("EquippedWeapon",name)
end
local function c2Grant(player,level)
 local before=player:GetAttribute("WeaponLevel") or 1
 player:SetAttribute("WeaponLevel",level)
 local equipped=level>before and WD.Order[level] or player:GetAttribute("EquippedWeapon") or "Pistol"
 if not table.find(WD.Order,equipped) or table.find(WD.Order,equipped)>level then equipped=WD.Order[level] end
 c2WorldWeapon(player,equipped)
 C2RE:FireClient(player,"loadout",{level=level,equipped=equipped,hero=player:GetAttribute("Hero")})
end
C2RE.OnServerEvent:Connect(function(player,action,token,value)
 if not C2.active or C2.finished or not table.find(C2.party,player) then return end
 if action=="sprint" then
  if typeof(token)=="boolean" and C2.sprint and C2.sprint[player] then C2.sprint[player].held=token end
  return
 end
 if action=="equip" then
  local index=table.find(WD.Order,token)
  if index and index<=(player:GetAttribute("WeaponLevel") or 1) and not introActive and not C2.challenges[player] then c2WorldWeapon(player,token) end
  return
 end
 local ch=C2.challenges[player]; if not ch or ch.token~=token then return end
 if action=="cancel" then c2EndEngineering(player); return end
 local root=c2Root(player)
 if not root or not C2.CanUseTerminal(ch.zone) or not c2Allowed(player,"engineering") or C2.stage~=ch.zone.index or C2.escaping or ch.expires<workspace:GetServerTimeNow() or (root.Position-ch.zone.panel.Position).Magnitude>12 then c2EndEngineering(player); return end
 if os.clock()-ch.last<(ch.fast and 0.055 or 0.14) then return end; ch.last=os.clock()
 local solved=false
 if action=="type" and ch.fast then
  ch.progress+=1; solved=ch.progress>=ch.required
 elseif action=="rotate" and ch.board and typeof(value)=="number" and value%1==0 and value>=1 and value<=9 then
  ch.board.rotations[value]=(ch.board.rotations[value]+1)%4
  ch.progress+=1; solved=c2CircuitSolved(ch.board)
 elseif action=="pulse" and ch.zone.kind=="weld" then
  local cursor=(math.sin((workspace:GetServerTimeNow()-ch.start)*2.2)+1)/2
  if math.abs(cursor-ch.target)<0.14 then ch.progress+=1 else ch.progress=math.max(0,ch.progress-1) end
  ch.target=0.25+math.random()*0.5; solved=ch.progress>=3
 elseif action=="turn" and ch.zone.kind=="valve" then
  if value==(ch.progress%2==0 and -1 or 1) then ch.progress+=1 else ch.progress=0 end
  solved=ch.progress>=8
 end
 if solved then
  local zone=ch.zone; c2EndEngineering(player,"Готово"); zone.complete()
 else c2EngineeringState(player,ch) end
end)
local function c2Contain(player,root)
 local x=root.Position.X-c2Origin.X; local z=root.Position.Z-c2Origin.Z
 local index=math.clamp(math.floor((x+75)/160)+1,1,10)
 local localX=x-(index-1)*160
 local halfDepth=(localX < -75 or localX>75) and 9 or C2_LAYOUT[index][1]-1.5
 local current=C2.zones[C2.stage]
 local maxX=C2.escaping and 1514 or current.x+(current.done and 88 or 73)
 local valid=x>=-73 and x<=maxX and math.abs(z)<=halfDepth and root.Position.Y>=-2 and root.Position.Y<55
 if not valid then
  local safe=C2.safe[player] or currentSpawn
  player.Character:PivotTo(safe); root.AssemblyLinearVelocity=Vector3.zero
 else
  local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={player.Character}
  local floor=workspace:Raycast(root.Position,Vector3.new(0,-8,0),rp)
  if floor and floor.Normal.Y>0.8 then C2.safe[player]=CFrame.new(root.Position+Vector3.new(0,0.3,0))*root.CFrame.Rotation end
 end
end
local function c2Home()
 if C2.home and C2.home.Parent then return C2.home end
 local home=Instance.new("Model"); home.Name="HeroesHome"; home.Parent=C2.map
 local base=Vector3.new(-180,0,0)
 local function object(name,size,pos,color,material)
  return c2Part(home,name,size,base+pos,color,material)
 end
 object("HouseFoundation",Vector3.new(72,2,60),Vector3.new(0,-1,0),C(50,53,58),Enum.Material.Concrete)
 object("WoodFloor",Vector3.new(64,0.3,48),Vector3.new(0,0.15,0),C(104,79,57),Enum.Material.WoodPlanks)
 for _,side in ipairs({-1,1}) do
  object("HouseSideWall",Vector3.new(1,14,48),Vector3.new(side*32,7,0),C(141,133,121))
  object("HouseEndWall",Vector3.new(64,14,1),Vector3.new(0,7,side*24),C(136,130,119))
 end
 object("HouseCeiling",Vector3.new(65,1,49),Vector3.new(0,14.5,0),C(160,154,142))
 object("KitchenDivider",Vector3.new(1,12,17),Vector3.new(13,6,15),C(143,136,122))
 object("EntranceDivider",Vector3.new(1,12,15),Vector3.new(13,6,-16),C(143,136,122))
 object("EntranceDoor",Vector3.new(1.2,10,6),Vector3.new(31.3,5,-13),C(74,52,38),Enum.Material.Wood)
 object("SofaSeat",Vector3.new(16,2,5),Vector3.new(-8,1.2,-5),C(65,79,87),Enum.Material.Fabric)
 object("SofaBack",Vector3.new(16,4,1),Vector3.new(-8,3,-7.5),C(60,72,80),Enum.Material.Fabric)
 for _,side in ipairs({-1,1}) do object("SofaArm",Vector3.new(1,3,5),Vector3.new(-8+side*8,2,-5),C(60,72,80),Enum.Material.Fabric) end
 object("Rug",Vector3.new(25,0.1,18),Vector3.new(-7,0.37,3),C(91,72,62),Enum.Material.Fabric)
 object("CoffeeTable",Vector3.new(11,2,5),Vector3.new(-7,1.2,4),C(71,48,33),Enum.Material.Wood)
 object("Television",Vector3.new(17,8,0.6),Vector3.new(-7,7,23.2),C(14,20,25))
 object("TVScreen",Vector3.new(15.8,6.8,0.15),Vector3.new(-7,7,22.8),C(42,67,81),Enum.Material.Glass)
 object("KitchenCounter",Vector3.new(17,4,4),Vector3.new(23,2,20),C(115,109,95))
 object("Fridge",Vector3.new(5,9,5),Vector3.new(27,4.5,12),C(165,169,164),Enum.Material.Metal)
 for k=0,2 do object("KitchenCabinet",Vector3.new(5,4,3),Vector3.new(16+k*5,9,21),C(89,69,48),Enum.Material.Wood) end
 for _,pos in ipairs({Vector3.new(-8,13,0),Vector3.new(23,13,10),Vector3.new(23,13,-14)}) do
  local lamp=object("WarmLamp",Vector3.new(4,0.3,3),pos,C(220,205,168)); light(lamp,C(245,219,173),35,1.2)
 end
 object("GearCase",Vector3.new(5,1,2.5),Vector3.new(-7,2.75,4),C(32,42,46),Enum.Material.Metal)
 return home
end

-- BEGIN CAMPAIGN DIRECTOR
-- Chapter-II campaign director. Pure predicates are also executed by the Luau regression suite.
function C2.GateReady(zone)
 return zone.cleared==true and zone.keyCollected==true and zone.hacked==true
end
function C2.CanUseTerminal(zone)
 return zone.cleared==true and zone.keyCollected==true and not zone.waveActive and not zone.deploying
end
function C2.ShieldCanTakeDamage()
 return C2.bossPhase=="exposed" and C2.zones[10].cleared==true
end
function C2.RunProtected(callback)
 local ok,err=xpcall(callback,debug.traceback)
 if not ok then
  warn("[Chapter2 campaign] "..tostring(err))
  C2.active=false; C2.serial+=1; Players.RespawnTime=3
  for _,connection in ipairs(C2.connections) do connection:Disconnect() end; table.clear(C2.connections)
  if C2.restoreHeroes then pcall(C2.restoreHeroes) end
  CreditsRE:FireAllClients(false); C2RE:FireAllClients("chapterCredits",false); C2RE:FireAllClients("clear")
  returnToMenu()
 end
end
function C2.SitRig(rig)
 for _,motor in ipairs(rig:GetDescendants()) do
  if motor:IsA("Motor6D") then
   if motor.Name:find("Hip") then motor.C0*=CFrame.Angles(-1.25,0,0)
   elseif motor.Name:find("Knee") then motor.C0*=CFrame.Angles(1.25,0,0) end
  end
 end
 for _=1,4 do for _,motor in ipairs(rig:GetDescendants()) do if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end end end
end
function C2.Literal(name,text,minimum)
 local duration=math.max(minimum or 3,(utf8.len(text) or #text)*0.045+1.8)
 CutsceneRE:FireAllClients("dialogue",{name=name,text=text,duration=duration})
 task.wait(duration+0.2)
end
function C2.InitCampaign()
 C2.deployEpoch=0
 C2.sprint={}; C2.bossPhase="waiting"; C2.shieldMax=#C2.party>1 and 1400 or 900; C2.shieldHP=C2.shieldMax; C2.spawnSequence=0; C2.home=nil
 local physics=game:GetService("PhysicsService")
 for _,name in ipairs({"C2Enemy","C2Field"}) do pcall(function() physics:RegisterCollisionGroup(name) end) end
 physics:CollisionGroupSetCollidable("C2Enemy","C2Field",false)
 physics:CollisionGroupSetCollidable("C2Enemy","C2Enemy",false)
 physics:CollisionGroupSetCollidable("Default","C2Field",true)
 for _,p in ipairs(C2.party) do C2.sprint[p]={held=false,stamina=100,publish=0,rest=0}; p:SetAttribute("SprintStamina",100); p:SetAttribute("IsSprinting",false) end
end
function C2.SprintTick(dt)
 for p,state in pairs(C2.sprint or {}) do
  local root,h=c2Root(p)
  local enabled=C2.active and not C2.finished and not introActive and not C2.challenges[p]
  if not state.held or state.stamina>=25 then state.exhausted=false end
  local running=enabled and root and state.held and not state.exhausted and state.stamina>1 and h.MoveDirection.Magnitude>0.1
  if running then state.stamina=math.max(0,state.stamina-dt*22); state.rest=0.7
  else state.rest=math.max(0,state.rest-dt); if state.rest==0 then state.stamina=math.min(100,state.stamina+dt*15) end end
  if state.stamina<=0 then state.exhausted=true; running=false end
  if h and enabled then h.WalkSpeed=running and 28 or 16 end
  state.publish+=dt
  if state.publish>=0.15 then state.publish=0; if p.Parent then p:SetAttribute("SprintStamina",state.stamina); p:SetAttribute("IsSprinting",running==true) end end
 end
end
function C2.Door(zone,open)
 local doors=zone.index==10 and zone.sideDoors or {zone.gate}
 for _,door in ipairs(doors) do
  local closed=door:GetAttribute("ClosedFrame")
  if not closed then closed=door.CFrame; door:SetAttribute("ClosedFrame",closed) end
  TweenService:Create(door,TweenInfo.new(1.1,Enum.EasingStyle.Sine),{CFrame=open and closed*CFrame.new(0,15,0) or closed}):Play()
 end
end
function C2.AddField(parent,cf,size)
 local field=c2Part(parent,"DeploymentForcefield",size,cf.Position,C(65,145,185),Enum.Material.ForceField)
 field.CFrame=cf; field.Transparency=0.82; field.CanCollide=true; field.CanQuery=false; field.CanTouch=false; field.CollisionGroup="C2Field"
 return field
end
function C2.SetupRoom(zone,height,depth)
 zone.wave=0; zone.rounds=zone.index==10 and 3 or 2; zone.cleared=false; zone.keyCollected=false; zone.hacked=false
 zone.field=C2.AddField(zone.model,zone.gate.CFrame,Vector3.new(1.2,14,20)); zone.covers={}
 for _,side in ipairs({-1,1}) do for k=1,2 do
  local pos=c2Origin+Vector3.new(zone.x-32+k*24,2.1,side*math.min(20,depth-8))
  local cover=c2Part(zone.model,"TacticalCover",Vector3.new(7,3.5,4),pos,C(58,66,72),Enum.Material.Metal)
  table.insert(zone.covers,cover.Position+Vector3.new(-2,1,side*4))
 end end
 if zone.index==10 then
  zone.sideDoors={}; zone.sideFields={}
  for _,side in ipairs({-1,1}) do
   local center=c2Origin+Vector3.new(zone.x+10,7,side*depth)
   local door=c2Part(zone.model,"BodyguardSideDoor",Vector3.new(18,14,1.2),center,C(38,45,54),Enum.Material.Metal)
   table.insert(zone.sideDoors,door); table.insert(zone.sideFields,C2.AddField(zone.model,door.CFrame,door.Size))
   c2Part(zone.model,"GuardVestibuleFloor",Vector3.new(20,0.35,22),c2Origin+Vector3.new(zone.x+10,0.18,side*(depth+10)),C(42,47,54),Enum.Material.Concrete)
   c2Part(zone.model,"GuardVestibuleRoof",Vector3.new(20,1,22),c2Origin+Vector3.new(zone.x+10,height+0.5,side*(depth+10)),C(27,33,40))
   c2Part(zone.model,"GuardVestibuleEnd",Vector3.new(20,height,2),c2Origin+Vector3.new(zone.x+10,height/2,side*(depth+20)),C(35,41,47))
   for _,edge in ipairs({-1,1}) do c2Part(zone.model,"GuardVestibuleWall",Vector3.new(2,height,22),c2Origin+Vector3.new(zone.x+10+edge*10,height/2,side*(depth+10)),C(35,41,47)) end
  end
 end
end
function C2.DropCard(zone,position)
 local model=Instance.new("Model"); model.Name="WaveKeycard"; model.Parent=C2.map
 local card=c2Part(model,"Keycard",Vector3.new(1.8,0.12,1.1),position+Vector3.new(0,1,0),C(35,51,66),Enum.Material.Metal)
 local strip=c2Part(model,"AccessStripe",Vector3.new(1.5,0.03,0.22),card.Position+Vector3.new(0,0.08,0.2),C(70,210,160),Enum.Material.Neon)
 c2Part(model,"CardChip",Vector3.new(0.35,0.035,0.3),card.Position+Vector3.new(-0.45,0.08,-0.2),C(200,170,85),Enum.Material.Metal)
 for _,p in ipairs(model:GetChildren()) do p.CanCollide=false; p.CanQuery=false end
 light(strip,C(75,220,160),9,0.7)
 model.PrimaryPart=card
 local x=math.clamp(position.X,c2Origin.X+zone.x-60,c2Origin.X+zone.x+63)
 local z=math.clamp(position.Z,c2Origin.Z-C2_LAYOUT[zone.index][1]+5,c2Origin.Z+C2_LAYOUT[zone.index][1]-5)
 local landing=Vector3.new(x,1.1,z); local from=position+Vector3.new(0,1.5,0); local start=os.clock()
 local prompt=c2Prompt(card,"Подобрать ключ-карту",0,function(player)
  zone.keyCollected=true; model:Destroy(); c2Send()
 end); prompt.ObjectText="КЛЮЧ-КАРТА"; prompt.Enabled=false
 local connection
 connection=RunService.Heartbeat:Connect(function()
  if not model.Parent or not C2.active or C2.finished or (zone.done and os.clock()-start>3) then if model.Parent then model:Destroy() end; connection:Disconnect(); return end
  local t=math.clamp((os.clock()-start)/0.9,0,1)
  local p=from:Lerp(landing,t)+Vector3.new(0,math.sin(t*math.pi)*2.5+math.sin(os.clock()*2)*0.12*t,0)
  model:PivotTo(CFrame.new(p)*CFrame.Angles(0,(os.clock()-start)*2.4,0)); prompt.Enabled=t>=1
 end)
 table.insert(C2.connections,connection)
end
function C2.Deploy(zone,count,wave)
 local serial=C2.serial; local epoch=C2.deployEpoch
 zone.deploying=true
 C2.Door(zone,false); task.wait(1.15)
 if not C2.active or C2.finished or C2.serial~=serial or epoch~=C2.deployEpoch then return end
 for k=1,count do
  local side=k%2==0 and -1 or 1
  local pos
  if zone.index==10 then pos=c2Origin+Vector3.new(zone.x+6+(k%3)*3,3.5,side*(C2_LAYOUT[10][1]+9))
  else pos=c2Origin+Vector3.new(zone.x+89+math.floor((k-1)/3)*4,3.5,((k-1)%3-1)*4) end
  local m=c2Spawn(zone.index,pos,zone.index>=7 and k==count,false)
  local e=C2.mobs[m]; e.wave=wave; e.tactic=({"rush","cover","flank"})[(k-1)%3+1]; e.side=side
  e.cover=zone.covers[(k-1)%#zone.covers+1]
  e.deployGoal=c2Origin+Vector3.new(zone.x+(zone.index==10 and 10 or 56),3.5,side*(zone.index==10 and 19 or 8))
 end
 C2.Door(zone,true); task.wait(1.2)
 if C2.serial~=serial or not C2.active or epoch~=C2.deployEpoch then return end
 zone.deploying=false
 if wave and c2Count(zone.index)==0 then C2.OnEnemyDown(zone.index,{wave=wave},nil) end
end
function C2.BeginWave(index)
 local zone=C2.zones[index]
 if C2.finished or C2.escaping then return end
 zone.wave+=1; zone.waveActive=true; zone.deploying=true
 local count=math.min(5,2+math.floor(index/3)+zone.wave)
 local epoch=C2.deployEpoch; local wave=zone.wave
 task.spawn(function() if epoch==C2.deployEpoch then C2.Deploy(zone,count,wave) end end)
 c2Send()
end
function C2.OnEnemyDown(index,enemy,model)
 if not C2.active or C2.finished or C2.escaping then return end
 local zone=C2.zones[index]
 if not zone or not enemy.wave or enemy.wave~=zone.wave or not zone.waveActive or zone.deploying or c2Count(index)>0 then return end
 zone.waveActive=false
 local pos=enemy.root and enemy.root.Position or c2Origin+Vector3.new(zone.x+50,3,0)
 C2.DropCard(zone,pos); C2.Door(zone,false)
 if zone.wave<zone.rounds then
  local serial=C2.serial; local epoch=C2.deployEpoch
  task.delay(3,function() if C2.active and not C2.finished and C2.serial==serial and epoch==C2.deployEpoch and not zone.done then C2.BeginWave(index) end end)
 else
  zone.cleared=true
  if index==10 then C2.bossPhase="exposed"; C2.shield.Color=C(230,135,70); C2.shield.Transparency=0.6 end
 end
 c2Send()
end
function C2.Spark(position,color)
 local p=c2Part(fxFolder,"ShieldImpact",Vector3.new(0.4,0.4,0.4),position,color,Enum.Material.Neon); p.CanCollide=false; p.CanQuery=false
 local particles=Instance.new("ParticleEmitter"); particles.Rate=0; particles.Lifetime=NumberRange.new(0.2,0.55); particles.Speed=NumberRange.new(7,15); particles.SpreadAngle=Vector2.new(130,130); particles.Color=ColorSequence.new(color); particles.LightEmission=1; particles.Parent=p; particles:Emit(18)
 light(p,color,12,2); Debris:AddItem(p,0.7)
end
function C2.CreateBoss()
 local zone=C2.zones[10]; local x=zone.x
 local model=c2Spawn(10,c2Origin+Vector3.new(x+43,3.5,0),false,true)
 model.Name="Кибер-мафия"; C2.boss=model
 model:PivotTo(CFrame.lookAt(c2Origin+Vector3.new(x+43,3.5,0),c2Origin+Vector3.new(x-40,3.5,0)))
 -- Remove the old block hair, oversized mask and duplicate face before dressing.
 for _,p in ipairs(model:GetChildren()) do
  if p:IsA("BasePart") and table.find({"Hair","Eye","Tail","Bow","Skirt"},p.Name) then p:Destroy() end
 end
 local root=model.HumanoidRootPart
 local function armor(name,size,offset,color,material)
  local p=c2Part(model,name,size,root.CFrame:PointToWorldSpace(offset),color,material or Enum.Material.Metal); p.CFrame=root.CFrame*CFrame.new(offset); p.CanCollide=false; return p
 end
 local head=model.Head; head.Color=C(247,219,209)
 local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Head; mesh.Scale=Vector3.new(1,1.08,1); mesh.Parent=head
 local function hair(name,size,offset,color,angle)
  local p=armor(name,size,offset,color,Enum.Material.SmoothPlastic)
  p.Shape=Enum.PartType.Ball; p.CFrame*=CFrame.Angles(0,0,angle or 0); return p
 end
 local silver=C(181,190,216); local shade=C(128,140,172)
 hair("HairCrown",Vector3.new(2.16,0.68,1.38),Vector3.new(0,2.04,0.1),silver)
 hair("HairBack",Vector3.new(2.05,2.35,0.7),Vector3.new(0,1.1,0.62),shade)
 for k=-2,2 do hair("SweptBangs",Vector3.new(0.49,0.78,0.3),Vector3.new(k*0.36,1.96-math.abs(k)*0.08,-0.51),silver,-0.22-k*0.12) end
 for _,side in ipairs({-1,1}) do
  hair("FaceFramingLock",Vector3.new(0.32,1.65,0.48),Vector3.new(side*0.98,1.28,-0.12),silver,side*0.08)
  for k=0,2 do hair("LayeredLongHair",Vector3.new(0.48,2.5-k*0.2,0.55),Vector3.new(side*(1.04+k*0.16),0.75,0.45+k*0.1),k==1 and silver or shade,side*(-0.06+k*0.05)) end
  for wing=-1,1,2 do
   local ribbon=armor("VelvetRibbon",Vector3.new(0.45,0.27,0.18),Vector3.new(side*1.12+wing*0.17,1.78,0),C(112,28,58),Enum.Material.Fabric); ribbon.CFrame*=CFrame.Angles(0,0,wing*0.4)
  end
 end
 -- A readable drawn anime face, not glowing rectangular eyes behind a full mask.
 local face=Instance.new("SurfaceGui"); face.Name="MafiaAnimeFace"; face.Face=Enum.NormalId.Front; face.CanvasSize=Vector2.new(512,256); face.LightInfluence=0.65; face.Parent=head
 local function ink(name,x,y,w,h,color,round)
  local f=Instance.new("Frame"); f.Name=name; f.Position=UDim2.fromScale(x,y); f.Size=UDim2.fromScale(w,h); f.BackgroundColor3=color; f.BorderSizePixel=0; f.Parent=face
  if round then local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0.5,0); c.Parent=f end
  return f
 end
 for _,x in ipairs({0.21,0.62}) do
  ink("Lash",x-0.015,0.32,0.19,0.045,C(40,28,48),true)
  ink("EyeWhite",x,0.36,0.16,0.23,C(255,248,245),true)
  ink("Iris",x+0.042,0.36,0.085,0.22,C(143,66,116),true)
  ink("Pupil",x+0.068,0.38,0.032,0.16,C(38,25,51),true)
  ink("Catchlight",x+0.05,0.38,0.03,0.055,C(255,255,255),true)
  ink("Brow",x,0.24,0.15,0.025,C(101,91,121),true)
  local blush=ink("Blush",x-0.02,0.64,0.17,0.06,C(224,146,151),true); blush.BackgroundTransparency=0.55
 end
 ink("Nose",0.49,0.58,0.018,0.055,C(205,157,152),true)
 ink("ConfidentSmile",0.435,0.75,0.13,0.024,C(147,71,89),true)
 armor("TailoredJacket",Vector3.new(2.05,1.75,1.12),Vector3.new(0,0.05,0),C(29,30,46),Enum.Material.Fabric)
 for _,side in ipairs({-1,1}) do
  local lapel=armor("SilverLapel",Vector3.new(0.32,1.1,0.08),Vector3.new(side*0.4,0.42,-0.6),C(148,153,174)); lapel.CFrame*=CFrame.Angles(0,0,side*0.32)
  armor("CoatTail",Vector3.new(0.7,1.5,0.2),Vector3.new(side*0.64,-1.15,0.61),C(26,27,41),Enum.Material.Fabric)
 end
 armor("CrimsonTie",Vector3.new(0.2,0.75,0.1),Vector3.new(0,0.35,-0.64),C(141,34,65),Enum.Material.Fabric)
 for k=-3,3 do
  local pleat=armor("PleatedSkirt",Vector3.new(0.34,0.72,1.35),Vector3.new(k*0.32,-1.02,0),k%2==0 and C(39,35,54) or C(49,43,64),Enum.Material.Fabric)
  pleat.CFrame*=CFrame.Angles(0,0,-k*0.025)
 end
 -- Only the temple is cybernetic; the face and both eyes stay visible.
 armor("TempleImplant",Vector3.new(0.18,0.52,0.35),Vector3.new(1.02,1.5,-0.27),C(70,80,99))
 local visor=armor("CyborgVisor",Vector3.new(0.11,0.12,0.28),Vector3.new(1.12,1.55,-0.36),C(220,75,110),Enum.Material.Neon); light(visor,C(220,75,110),3,0.2)
 armor("CyberForearm",Vector3.new(0.9,1.3,1.1),Vector3.new(1.5,-0.2,-0.25),C(62,73,87))
 C2.cyberHand=armor("CyberHand",Vector3.new(0.8,0.65,0.9),Vector3.new(1.5,-0.7,-0.55),C(80,92,105))
 for k=1,3 do armor("ImplantContact",Vector3.new(0.08,0.6,0.1),Vector3.new(1.99,-0.2,-0.55+k*0.24),C(190,65,55),Enum.Material.Neon) end
 local entry=C2.mobs[model]
 entry.joints.RH.C0=entry.base.RH*CFrame.Angles(-math.pi/2,0,0); entry.joints.LH.C0=entry.base.LH*CFrame.Angles(-math.pi/2,0,0)
 anchorAll(model)
 for _=1,3 do for _,motor in ipairs(model:GetDescendants()) do if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end end end
 local chair=c2Part(zone.model,"ExecutiveChair",Vector3.new(7,1,7),c2Origin+Vector3.new(x+43,1.8,0),C(20,23,30),Enum.Material.Fabric)
 c2Part(zone.model,"ChairBack",Vector3.new(1,8,7),chair.Position+Vector3.new(3.2,3,0),C(23,26,34),Enum.Material.Fabric)
 C2.bossButton=c2Part(zone.model,"SelfDestructButton",Vector3.new(1.8,0.45,1.8),c2Origin+Vector3.new(x+35,1.2,-4),C(255,20,25),Enum.Material.Neon)
 light(C2.bossButton,C(255,35,30),8,1)
 C2.shield=c2Part(model,"BossEnergyShield",Vector3.new(13,13,13),root.Position+Vector3.new(0,1,0),C(60,150,220),Enum.Material.ForceField)
 C2.shield.Shape=Enum.PartType.Ball; C2.shield.CanCollide=false; C2.shield.Transparency=1
 C2.cracks={}
 for k=1,9 do
  local theta=k*2.399
  local crack=c2Part(model,"ShieldCrack",Vector3.new(0.08,2.2,0.1),C2.shield.Position+Vector3.new(-6,math.sin(theta)*4,math.cos(theta)*4),C(250,165,85),Enum.Material.Neon)
  crack.CFrame*=CFrame.Angles(theta,0,theta*0.4); crack.CanCollide=false; crack.CanQuery=false; crack.Transparency=1; table.insert(C2.cracks,crack)
 end
 C2.bossPhase="guarded"
end
function C2.ScriptedShot(target,deflected)
 CutsceneRE:FireAllClients("blaster",true); task.wait(0.5)
 if deflected then C2.shield.Transparency=0.3 end
 CutsceneRE:FireAllClients("pulse")
 for _,p in ipairs(C2.party) do
  local head=p.Character and p.Character:FindFirstChild("Head")
  if head then tracer(head.Position,target,C(255,210,130)) end
 end
 C2.Spark(target,deflected and C(100,200,255) or C(245,170,105))
 if deflected then tracer(target,target+Vector3.new(-5,4,10),C(100,200,255)) end
 task.wait(0.55); CutsceneRE:FireAllClients("blaster",false)
end
function C2.BossIntro()
 local serial=C2.serial
 introActive=true; canFight=false; sceneLock(true); CutsceneRE:FireAllClients("start")
 C2.CreateBoss(); CutsceneRE:FireAllClients("pov",C2.boss.Head,54)
 prepareView(C2.boss.Head.Position)
 C2.Literal("Мафия","Так-так-так, кто же это?",3)
 if C2.serial~=serial or C2.finished then return end
 C2.ScriptedShot(C2.shield.Position+Vector3.new(-6,0,0),true)
 if C2.serial~=serial or C2.finished then return end
 C2.Literal("Мафия","Хах, технологии тянок быстро развиваются, спасибо Нейро-тян. Кстати, я бы так же поступил. Ну-у, так что, сразу к делу перейдём?",9)
 if C2.serial~=serial or C2.finished then return end
 local hand=C2.cyberHand; local cf=hand.CFrame
 TweenService:Create(hand,TweenInfo.new(0.25),{CFrame=cf*CFrame.new(0,0.5,-0.3)*CFrame.Angles(0,0,0.5)}):Play(); task.wait(0.3)
 C2.Spark(hand.Position,C(195,100,75)); TweenService:Create(hand,TweenInfo.new(0.2),{CFrame=cf}):Play()
 CutsceneRE:FireAllClients("end"); sceneLock(false); introActive=false; canFight=true; C2.BeginWave(10)
end
function C2.HitBoss(damage,position,origin)
 if C2.bossPhase=="broken" then return end
 C2.Spark(position,C(115,200,250))
 if not C2.ShieldCanTakeDamage() then
  if origin then tracer(position,position+(origin-position).Unit*6+Vector3.new(0,3,0),C(110,200,255)) end
  return
 end
 C2.shieldHP=math.max(0,C2.shieldHP-damage)
 local broken=math.floor((1-C2.shieldHP/C2.shieldMax)*#C2.cracks)
 for k,p in ipairs(C2.cracks) do p.Transparency=k<=broken and 0.1 or 1 end
 C2.shield.Transparency=0.45+(1-C2.shieldHP/C2.shieldMax)*0.4
 if C2.shieldHP==0 then
  C2.bossPhase="broken"; C2.shield.Transparency=1; C2.shield.CanQuery=false
  for _,p in ipairs(C2.cracks) do p.Transparency=1 end
  C2.mobs[C2.boss].defeated=true; C2.boss.Humanoid.Health=30
  task.spawn(function() C2.RunProtected(c2Escape) end)
 end
 c2Send()
end
function C2.Collapse(zone,major)
 if not zone or zone.collapsed then return end
 zone.collapsed=true
 local ceiling=zone.model:FindFirstChild("Ceiling"); if ceiling then ceiling.Transparency=1; ceiling.CanCollide=false end
 if major then for _,p in ipairs(zone.model:GetChildren()) do if p:IsA("BasePart") and (p.Name=="SideWall" or p.Name=="BossWallLeft" or p.Name=="BossWallRight" or p.Name=="ArmoredOfficePanel") then p.Transparency=1; p.CanCollide=false end end end
 local center=c2Origin+Vector3.new(zone.x,major and 28 or 10,0)
 local flash=c2Part(C2.map,"FactoryFireball",Vector3.new(3,3,3),center,C(255,150,55),Enum.Material.Neon); flash.Shape=Enum.PartType.Ball; flash.CanCollide=false; flash.CanQuery=false
 light(flash,C(255,150,55),120,5)
 local sound=Instance.new("Sound"); sound.SoundId="rbxasset://sounds/impact_explosion_03.mp3"; sound.Volume=major and 1 or 0.6; sound.RollOffMaxDistance=1200; sound.Parent=flash; sound:Play()
 TweenService:Create(flash,TweenInfo.new(1.4),{Size=Vector3.new(major and 100 or 42,major and 100 or 42,major and 100 or 42),Transparency=1}):Play(); Debris:AddItem(flash,2)
 for k=1,6 do
  local rubble=c2Part(C2.map,k%2==0 and "FallingWall" or "FallingCeiling",Vector3.new(12,0.7,9),c2Origin+Vector3.new(zone.x-45+k*13,C2_LAYOUT[zone.index][2],k%2==0 and 14 or -14),C(48,49,53),Enum.Material.Concrete)
  rubble.CanCollide=false; rubble.CanQuery=false
  TweenService:Create(rubble,TweenInfo.new(0.8+k*0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=rubble.CFrame*CFrame.new(0,-C2_LAYOUT[zone.index][2]+1,0)*CFrame.Angles(0.3*k,0.4,0.6)}):Play()
  if k<=3 then
   local fire=Instance.new("Fire"); fire.Size=major and 22 or 12; fire.Heat=18; fire.Parent=rubble
   local smoke=Instance.new("Smoke"); smoke.Size=major and 35 or 18; smoke.RiseVelocity=18; smoke.Opacity=0.35; smoke.Parent=rubble
  end
  Debris:AddItem(rubble,45)
 end
 for _,p in ipairs(C2.party) do local root=c2Root(p); if root then ShakeRE:FireClient(p,math.clamp(900/math.max(80,(root.Position-center).Magnitude),1,8)) end end
end
function C2.CollapseTick()
 local highest=1
 for _,p in ipairs(C2.party) do local root=c2Root(p); if root then highest=math.max(highest,math.clamp(math.floor((root.Position.X-c2Origin.X+75)/160)+1,1,10)) end end
 C2.Collapse(C2.zones[highest+1],false)
end
function C2.Pursuit(index)
 local zone=C2.zones[index]
 if zone.collapsed or zone.deploying then return end
 for _,p in ipairs(C2.party) do local root=c2Root(p); if root and root.Position.X>c2Origin.X+zone.x+65 then return end end
 task.spawn(function() C2.Deploy(zone,2,nil) end)
end
function C2.DefeatSequence()
 for p in pairs(C2.challenges) do c2EndEngineering(p) end
 introActive=true; canFight=false; sceneLock(true); CutsceneRE:FireAllClients("start")
 FadeRE:FireAllClients(true,""); task.wait(0.6)
 local zone=C2.zones[10]
 for i,p in ipairs(C2.party) do if c2Root(p) then p.Character:PivotTo(CFrame.lookAt(c2Origin+Vector3.new(zone.x+8,4,-12-i*2),C2.boss.Head.Position)) end end
 CutsceneRE:FireAllClients("pov",C2.boss.Head,58); CutsceneRE:FireAllClients("reveal")
 for i,p in ipairs(C2.party) do if c2Root(p) then tweenCharTo(p.Character,CFrame.lookAt(c2Origin+Vector3.new(zone.x+35,4,-8-i*2),C2.boss.Head.Position),2) end end
 C2.Literal("Мафия","Ладно, мне с этим как всегда разобраться.",3)
 local entry=C2.mobs[C2.boss]
 entry.joints.RH.C0=entry.base.RH; entry.joints.LH.C0=entry.base.LH
 for _=1,4 do for _,m in ipairs(C2.boss:GetDescendants()) do if m:IsA("Motor6D") and m.Part0 and m.Part1 then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.C1:Inverse() end end end
 moveModel(C2.boss,C2.boss:GetPivot()+Vector3.new(-5,1.2,0),0.8,true)
 C2.Literal("Мафия","Ну же!",1)
 moveModel(C2.boss,C2.boss:GetPivot()+Vector3.new(-5,0,-4),0.55,true)
 ShakeRE:FireAllClients(4); C2.ScriptedShot(C2.boss.Head.Position,false)
 moveModel(C2.boss,C2.boss:GetPivot()*CFrame.new(0,-2.3,0)*CFrame.Angles(0,0,-1.2),0.7)
 task.wait(0.6)
 -- A fixed insert shows the red switch and the actual moving hand together.
 local button=C2.bossButton
 local hand=C2.cyberHand
 CutsceneRE:FireAllClients("cam",{cf=CFrame.lookAt(button.Position+Vector3.new(-5,5,-6),button.Position+Vector3.new(0,0.6,0)),time=0,fov=42})
 hand.CFrame=CFrame.new(button.Position+Vector3.new(0,2.7,0))
 task.wait(1)
 TweenService:Create(hand,TweenInfo.new(1.1),{CFrame=CFrame.new(button.Position+Vector3.new(0,0.5,0))}):Play(); task.wait(1.2)
 TweenService:Create(button,TweenInfo.new(0.2),{Position=button.Position-Vector3.new(0,0.2,0)}):Play()
 C2.Spark(button.Position,C(255,35,20)); ShakeRE:FireAllClients(2); task.wait(1)
 C2.Literal("Мафия","Хех, скоро здесь всё взорвётся. Гори в аду!",4)
 CutsceneRE:FireAllClients("pov",c2Origin+Vector3.new(zone.x-35,10,-24),68); ShakeRE:FireAllClients(3); task.wait(0.9)
 CutsceneRE:FireAllClients("pov",c2Origin+Vector3.new(zone.x+15,12,25),68); task.wait(0.9)
 CutsceneRE:FireAllClients("pov",C2.boss.Head,56); C2.ScriptedShot(C2.boss.Head.Position,false)
 C2.boss.Humanoid.Health=0
 moveModel(C2.boss,C2.boss:GetPivot()*CFrame.new(0,-1.1,0)*CFrame.Angles(0,0,0.6),0.55)
 C2.escaping=true; C2.escapeStarting=false; C2.deadline=workspace:GetServerTimeNow()+300
 for _,z in ipairs(C2.zones) do z.done=true; z.field.CanCollide=false; z.field.Transparency=1; z.gate.CanCollide=false; TweenService:Create(z.gate,TweenInfo.new(0.6),{CFrame=(z.gate:GetAttribute("ClosedFrame") or z.gate.CFrame)*CFrame.new(0,15,0)}):Play() end
 CutsceneRE:FireAllClients("end"); sceneLock(false); introActive=false; canFight=true
 MusicRE:FireAllClients("finalSlow"); C2RE:FireAllClients("run"); c2Send()
end
function C2.DriveDistance(t)
 t=math.max(0,t)
 -- Smooth acceleration from rest, then cruise. The complete route covers 60s.
 local ramp=math.min(t,4)
 return 4*ramp*ramp+32*math.max(0,t-4)
end
-- Shared geometry is built BEFORE gameplay, not only after the final fade.
function C2.BuildEscapeCity()
 if C2.escapeCity and C2.escapeCity.Parent then return C2.escapeCity end
 local city=Instance.new("Model"); city.Name="EscapeCity"; city.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; city.Parent=C2.map
 C2.escapeCity=city
 local function block(name,size,pos,color,mat)
  assert(math.max(size.X,size.Y,size.Z)<=512,"City parts must be segmented")
  return c2Part(city,name,size,pos,color,mat or Enum.Material.Concrete)
 end
 -- Original pickup bay: floor, three walls and a canopy surround the parked van.
 block("PickupBayFloor",Vector3.new(34,0.6,30),Vector3.new(-58,0,24),C(60,64,70))
 block("PickupBayBack",Vector3.new(1,12,30),Vector3.new(-74,6,24),C(54,61,70))
 for _,z in ipairs({9,39}) do block("PickupBayWall",Vector3.new(33,12,1),Vector3.new(-58,6,z),C(61,68,76)) end
 block("PickupCanopy",Vector3.new(35,0.6,32),Vector3.new(-58,12,24),C(43,50,61),Enum.Material.Metal)
 local bayLamp=block("PickupLamp",Vector3.new(6,0.2,2),Vector3.new(-57,11.5,24),C(240,213,165),Enum.Material.Neon); light(bayLamp,C(245,215,175),28,1)
 -- A complete rendezvous courtyard, including the road under the stationary car.
 block("RendezvousApron",Vector3.new(180,1,90),Vector3.new(-80,-0.2,110),C(48,51,58),Enum.Material.Asphalt)
 block("CourtyardRearWall",Vector3.new(180,14,2),Vector3.new(-80,7,154),C(64,69,78))
 block("CourtyardEastWall",Vector3.new(2,14,86),Vector3.new(9,7,110),C(64,69,78))
 for _,z in ipairs({78,142}) do block("ExitGatePost",Vector3.new(4,16,4),Vector3.new(-164,8,z),C(85,90,100)) end
 -- Roblox clamps oversized BaseParts. Overlapping 128-stud slabs cannot leave
 -- the previous 76-stud hole beneath the beginning of the drive.
 for segment=0,20 do
  local x=58-segment*128
  block("EscapeRoad",Vector3.new(129,1,32),Vector3.new(x,-0.2,100),C(32,35,41),Enum.Material.Asphalt)
  block("CityGround",Vector3.new(129,2,460),Vector3.new(x,-1.7,100),C(49,55,57))
  for _,side in ipairs({-1,1}) do
   block("Sidewalk",Vector3.new(129,0.6,9),Vector3.new(x,0.15,100+side*20.5),C(111,113,119))
   block("Curb",Vector3.new(129,0.35,0.5),Vector3.new(x,0.48,100+side*16.3),C(170,169,163))
   block("EscapeRouteWall",Vector3.new(129,1.4,0.7),Vector3.new(x,1,100+side*25.2),C(75,82,91))
  end
  for line=0,3 do block("RoadMarking",Vector3.new(12,0.025,0.18),Vector3.new(x+line*32-48,0.315,100),C(220,207,159)) end
 end
 local rng=Random.new(4217)
 for k=0,29 do
  local x=-220-k*76
  for _,side in ipairs({-1,1}) do
   local z=100+side*21
   block("StreetLampPole",Vector3.new(0.35,13,0.35),Vector3.new(x,6.6,z),C(56,64,76),Enum.Material.Metal)
   local lamp=block("RoadLamp",Vector3.new(2.5,0.25,1.1),Vector3.new(x,13,100+side*18),C(247,214,162),Enum.Material.Neon)
   if k%2==0 then light(lamp,C(255,222,174),28,0.9) end
   local height=rng:NextInteger(20,65); local width=rng:NextInteger(35,57)
   local facade=C(rng:NextInteger(65,105),rng:NextInteger(68,108),rng:NextInteger(78,118))
   local bz=100+side*54
   block("CityBuilding",Vector3.new(width,height,36),Vector3.new(x,height/2,bz),facade)
   block("BuildingCornice",Vector3.new(width+2,0.7,38),Vector3.new(x,height+0.4,bz),C(53,58,70))
   block("Storefront",Vector3.new(width-5,6,0.2),Vector3.new(x,3.5,bz-side*18.15),C(32,52,65),Enum.Material.Glass)
   for floor=1,math.floor(height/8)-1 do for column=-2,2 do
    local lit=(floor+column+k)%4~=0
    block("CityWindow",Vector3.new(3.8,4.2,0.15),Vector3.new(x+column*(width/6),floor*8+3,bz-side*18.1),lit and C(180,161,121) or C(35,51,68),lit and Enum.Material.Neon or Enum.Material.Glass)
   end end
   block("RooftopPlant",Vector3.new(8,3,6),Vector3.new(x+8,height+2,bz),C(68,76,88),Enum.Material.Metal)
   -- Second skyline row closes distant views between foreground blocks.
   local towerHeight=rng:NextInteger(50,115)
   block("SkylineTower",Vector3.new(61,towerHeight,42),Vector3.new(x-30,towerHeight/2,100+side*118),C(57,68,86))
   for floor=1,math.floor(towerHeight/12) do block("SkylineWindowBand",Vector3.new(49,1.5,0.15),Vector3.new(x-30,floor*11,100+side*96.9),C(126,142,154)) end
  end
 end
 return city
end
function C2.EvacuationDialogue(lead,other)
 -- Use the original party, not the survivor count: a fallen teammate still
 -- watches the shared cooperative ending rather than hearing the solo script.
 if #C2.party>1 then
  C2.Literal("Демид","Круто, мы победили!",2.5)
  C2.Literal("Артём","Дааа, мы их вынесли! Хотя... это же была всего лишь мини-база, да? Ладно, всё будет отлично, я тебя уверяю!",7)
 else
  C2.Literal(other,"На самом деле это было неплохо, отличная работа. Но скажу тебе так — всё довольно плачевно. В плане, это же их мини-центр, мы даже и половину не уничтожили",10)
  C2.Literal(lead:GetAttribute("Hero")=="Artem" and "Артем" or "Демид","Это было легко, но если бы мне кто-то помогал...",4)
 end
end
function C2.CarScene()
 local survivors={}; for _,p in ipairs(C2.party) do if c2Root(p) then table.insert(survivors,p) end end
 local lead=survivors[1] or C2.party[1]
 local other=lead:GetAttribute("Hero")=="Artem" and "Демид" or "Артем"
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 local car=Instance.new("Model"); car.Name="GetawayCar"; car.Parent=C2.map
 local origin=Vector3.new(-70,0.25,100)
 local function body(name,size,offset,color,material)
  local part=c2Part(car,name,size,origin+offset,color,material or Enum.Material.Metal)
  part.CanCollide=false; part.CanTouch=false; return part
 end
 body("Chassis",Vector3.new(15,0.65,7),Vector3.new(0,1.8,0),C(18,20,25))
 body("Body",Vector3.new(15,1.7,7),Vector3.new(0,2.9,0),C(30,43,58))
 body("Hood",Vector3.new(4.5,0.6,6.8),Vector3.new(-5,4,0),C(35,48,65))
 body("Roof",Vector3.new(7.4,0.3,6.5),Vector3.new(0.6,6.3,0),C(24,32,45))
 for _,x in ipairs({-3,4}) do
  local glass=body("Windshield",Vector3.new(0.15,2.2,6.2),Vector3.new(x,5,0),C(90,125,145),Enum.Material.Glass); glass.Transparency=0.4
  for _,side in ipairs({-1,1}) do body("Pillar",Vector3.new(0.25,2.4,0.25),Vector3.new(x,5,side*3.1),C(25,33,45)) end
 end
 for _,side in ipairs({-1,1}) do
  local glass=body("SideWindow",Vector3.new(6.5,1.9,0.12),Vector3.new(0.5,5,side*3.16),C(85,120,140),Enum.Material.Glass); glass.Transparency=0.45
  body("DoorHandle",Vector3.new(0.8,0.15,0.18),Vector3.new(1.7,3.8,side*3.55),C(180,185,195))
  body("Mirror",Vector3.new(0.8,0.4,0.7),Vector3.new(-2.5,4.4,side*3.7),C(30,40,53))
  local lamp=body("Headlight",Vector3.new(0.15,0.7,2),Vector3.new(-7.55,3.3,side*2.1),C(245,235,195),Enum.Material.Neon); light(lamp,C(255,235,190),35,2)
  body("TailLight",Vector3.new(0.15,0.6,1.8),Vector3.new(7.55,3.3,side*2.1),C(235,30,35),Enum.Material.Neon)
  for _,axle in ipairs({-4.8,4.8}) do
   local wheel=body("Wheel",Vector3.new(0.8,3,3),Vector3.new(axle,1.55,side*3.5),C(15,17,21)); wheel.Shape=Enum.PartType.Cylinder; wheel.CFrame*=CFrame.Angles(0,math.pi/2,0)
   local rim=body("AlloyRim",Vector3.new(0.85,1.8,1.8),Vector3.new(axle,1.55,side*3.55),C(140,150,165)); rim.Shape=Enum.PartType.Cylinder; rim.CFrame=wheel.CFrame
  end
 end
 C2.BuildEscapeCity()
 car.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local source=other=="Артем" and "eurtyoeyrntiu" or "ZamestitelDiomchica"
 local buddy=secretActor(C2.map,source,other,CFrame.lookAt(origin+Vector3.new(3,0.5,-8),origin+Vector3.new(10,0.5,-8)))
 for i,p in ipairs(survivors) do p.Character:PivotTo(CFrame.lookAt(origin+Vector3.new(12,4,-8-i*2),buddy.Head.Position)) end
 for _,p in ipairs(C2.party) do if not c2Root(p) then C2RE:FireClient(p,"cinemaEye",lead.Character.Head) end end
 focusStreaming(origin); prepareView(origin)
 CutsceneRE:FireAllClients("pov",buddy.Head,65); CutsceneRE:FireAllClients("reveal")
 C2.Literal(other,"Какого хрена ты там натворил?!",3)
 C2.Literal(other,"Ладно, валим скорее на тачке!",3)
 FadeRE:FireAllClients(true,""); task.wait(0.8)
 -- No physical seats or SeatWelds: deterministic anchored riders cannot stop the car.
 local riders={}; local poses={}
 for i,p in ipairs(survivors) do
  local root,h=c2Root(p)
  if root then root.Anchored=true; h.Sit=true; p.Character:PivotTo(CFrame.lookAt(origin+Vector3.new(0,3.4,(i==1 and -1 or 1)*1.5),origin+Vector3.new(-20,3.4,0))); table.insert(riders,p.Character)
   local pose={}; poses[p.Character]=pose
   for _,m in ipairs(p.Character:GetDescendants()) do if m:IsA("Motor6D") then pose[m]=m.C0 end end
   C2.SitRig(p.Character)
  end
 end
 if #survivors<2 then buddy:PivotTo(CFrame.lookAt(origin+Vector3.new(0,0.7,1.5),origin+Vector3.new(-20,0.7,1.5))); C2.SitRig(buddy); table.insert(riders,buddy) else buddy:Destroy() end
 local pivot=car:GetPivot(); local offsets={}
 for _,rig in ipairs(riders) do offsets[rig]=pivot:ToObjectSpace(rig:GetPivot()) end
 CutsceneRE:FireAllClients("follow",car,Vector3.new(20,9,-14),Vector3.new(-6,2,0))
 CutsceneRE:FireAllClients("reveal"); task.wait(1.2)
 local start=os.clock(); local connection
 connection=RunService.Heartbeat:Connect(function()
  if not car.Parent then connection:Disconnect(); return end
  local t=os.clock()-start
  local distance=C2.DriveDistance(t)
  local cf=pivot+Vector3.new(-distance,0,0); car:PivotTo(cf)
  for rig,offset in pairs(offsets) do if rig.Parent then rig:PivotTo(cf*offset) end end
 end)
 table.insert(C2.connections,connection)
 for _,p in ipairs(C2.party) do p.ReplicationFocus=car:FindFirstChild("Chassis") end
 MusicRE:FireAllClients("finalSlow")
 task.spawn(function() for i=2,10 do C2.Collapse(C2.zones[i],true); task.wait(0.15) end end)
 task.wait(1.5) -- Let the destruction behind the car finish before celebrating.
 C2.EvacuationDialogue(lead,other)
 task.wait(2); FadeRE:FireAllClients(true,""); task.wait(1)
 connection:Disconnect()
 for _,pose in pairs(poses) do for m,cf in pairs(pose) do if m.Parent then m.C0=cf end end end
 for _,rig in ipairs(riders) do local h=rig:FindFirstChildOfClass("Humanoid"); if h then h.Sit=false end end
end
function C2.NewsTwist()
 CreditsRE:FireAllClients(false)
 local home=c2Home(); local screen=home:FindFirstChild("TVScreen")
 local gui=Instance.new("SurfaceGui"); gui.Name="NTyanBreakingNews"; gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(1024,576); gui.Parent=screen
 local background=Instance.new("Frame"); background.Size=UDim2.fromScale(1,1); background.BackgroundColor3=C(12,22,35); background.Parent=gui
 local headline=Instance.new("TextLabel"); headline.Size=UDim2.fromScale(1,0.16); headline.Text="НТЯН • ЭКСТРЕННЫЕ НОВОСТИ"; headline.Font=Enum.Font.GothamBlack; headline.TextScaled=true; headline.TextColor3=C(240,235,220); headline.BackgroundColor3=C(135,35,40); headline.Parent=background
 local caption=headline:Clone(); caption.Position=UDim2.fromScale(0,0.83); caption.Size=UDim2.fromScale(1,0.17); caption.Text="АРТЕМ И ДЕМИД • ОБЪЯВЛЕНЫ В РОЗЫСК"; caption.Parent=background
 for side=0,1 do
  local view=Instance.new("ViewportFrame"); view.Size=UDim2.fromScale(0.49,0.65); view.Position=UDim2.fromScale(side*0.51,0.17); view.BackgroundColor3=C(25,39,52); view.Ambient=C(180,180,185); view.Parent=background
  local world=Instance.new("WorldModel"); world.Parent=view
  local camera=Instance.new("Camera"); camera.Parent=view; view.CurrentCamera=camera
  if side==0 then
   local cfg=table.clone(Types.Commander); cfg.Male=false; cfg.Name="Представительница Нтян"; cfg.Shirt=C(55,67,91)
   local rep=buildRig(cfg,CFrame.new(0,3,0)); rep.Parent=world; c2Dress(rep,false); anchorAll(rep)
   camera.CFrame=CFrame.lookAt(Vector3.new(0,5,-8),Vector3.new(0,4.5,0)); camera.FieldOfView=42
  else
   c2Part(world,"RuinsGround",Vector3.new(36,1,26),Vector3.new(0,-0.5,0),C(47,47,48))
   for k=1,12 do local ruin=c2Part(world,"RuinedCenter",Vector3.new(3+(k%3),1+(k%4),6),Vector3.new((k%4-1.5)*7,k%3*0.5,math.floor(k/4)*5-7),C(65,63,63)); ruin.CFrame*=CFrame.Angles(0,k,0.12*k) end
   camera.CFrame=CFrame.lookAt(Vector3.new(25,22,-30),Vector3.new(0,0,0)); camera.FieldOfView=48
  end
 end
 local present={}
 for _,p in ipairs(C2.party) do
  local root,h=c2Root(p)
  if root then
   local hero=p:GetAttribute("Hero"); present[hero]=true
   local pos=Vector3.new(hero=="Artem" and -191 or -185,3,-4)
   p.Character:PivotTo(CFrame.lookAt(pos,Vector3.new(pos.X,3,22))); h.Sit=true; root.Anchored=true
  end
 end
 if not present.Artem then C2.SitRig(secretActor(home,"eurtyoeyrntiu","Артем",CFrame.lookAt(Vector3.new(-191,0.4,-4),Vector3.new(-191,0.4,22)))) end
 if not present.Demid then C2.SitRig(secretActor(home,"ZamestitelDiomchica","Демид",CFrame.lookAt(Vector3.new(-185,0.4,-4),Vector3.new(-185,0.4,22)))) end
 focusStreaming(Vector3.new(-180,5,0)); prepareView(Vector3.new(-180,5,0)); CutsceneRE:FireAllClients("pov",screen,65); CutsceneRE:FireAllClients("reveal")
 C2.Literal("Нтян","Чувствую, появились новые злодеи, и их планы нам пока не понять. Мы объявили их в розыск. Чувствую, они явно имеют технологии не хуже наших",9)
 ShakeRE:FireAllClients(1.3); task.wait(1)
 C2.Literal("Демид","Эмм... нас объявили в розыск, когда мы сделали доброе дело? Я чёт разочарован...",6)
 task.wait(1); FadeRE:FireAllClients(true,""); task.wait(1)
end

-- END CAMPAIGN DIRECTOR
local function c2Build()
 C2.map=Instance.new("Model"); C2.map.Name="Chapter2Factory"; C2.map.Parent=levelFolder; C2.zones={}
 local function prop(parent,name,size,offset,color,mat) return c2Part(parent,name,size,c2Origin+offset,color,mat) end
 -- The entire retreat is real contiguous geometry, not ten teleporting arenas.
 prop(C2.map,"Ground",Vector3.new(1740,2,260),Vector3.new(780,-1,0),C(36,43,42),Enum.Material.Asphalt)
 prop(C2.map,"ApproachRearFence",Vector3.new(1,18,100),Vector3.new(-75,9,0),C(55,63,72),Enum.Material.Metal)
 local facade=prop(C2.map,"MainFactoryFacade",Vector3.new(1050,40,25),Vector3.new(860,20,-83),C(58,68,79),Enum.Material.CorrodedMetal)
 -- Closed outer shell is a second physical boundary outside individual rooms.
 for _,side in ipairs({-1,1}) do prop(C2.map,"PerimeterWall",Vector3.new(1800,64,4),Vector3.new(650,31,side*68),C(50,57,63),Enum.Material.Concrete) end
 prop(C2.map,"FactoryEndWall",Vector3.new(4,64,140),Vector3.new(1520,31,0),C(50,57,63),Enum.Material.Concrete)
 for i,def in ipairs(C2_ZONES) do
  local room=Instance.new("Model"); room.Name=def.name; room.Parent=C2.map
  local x=(i-1)*160; local indoor=true
  local halfDepth,height=table.unpack(C2_LAYOUT[i])
  local z={model=room,x=x,done=false,entered=false,machines={}}; C2.zones[i]=z
  prop(room,"Floor",Vector3.new(150,0.35,halfDepth*2),Vector3.new(x,0.18,0),i%2==0 and C(62,68,73) or C(53,59,66),Enum.Material.Concrete)
  for _,s in ipairs({-1,1}) do
   if i==10 then
    prop(room,"BossWallLeft",Vector3.new(76,height,2),Vector3.new(x-37,height/2,s*halfDepth),C(25,30,39),Enum.Material.Metal)
    prop(room,"BossWallRight",Vector3.new(56,height,2),Vector3.new(x+47,height/2,s*halfDepth),C(25,30,39),Enum.Material.Metal)
    prop(room,"SideDoorLintel",Vector3.new(18,height-14,2),Vector3.new(x+10,14+(height-14)/2,s*halfDepth),C(25,30,39),Enum.Material.Metal)
   else prop(room,"SideWall",Vector3.new(150,height,2),Vector3.new(x,height/2,s*halfDepth),C(57,65,74),Enum.Material.Metal) end
   prop(room,"GateWall",Vector3.new(2,height,halfDepth-10),Vector3.new(x+75,height/2,s*(halfDepth+10)/2),C(55,63,72),Enum.Material.Metal)
   if i>1 then prop(room,"EntryWall",Vector3.new(2,height,halfDepth-10),Vector3.new(x-75,height/2,s*(halfDepth+10)/2),C(57,65,74),Enum.Material.Metal) end
  end
  prop(room,"ExitLintel",Vector3.new(2,height-14,20),Vector3.new(x+75,14+(height-14)/2,0),C(57,65,74),Enum.Material.Metal)
  if i>1 then prop(room,"EntryLintel",Vector3.new(2,height-14,20),Vector3.new(x-75,14+(height-14)/2,0),C(57,65,74),Enum.Material.Metal) end
  prop(room,"Ceiling",Vector3.new(150,1,halfDepth*2),Vector3.new(x,height+0.5,0),C(42,48,57),Enum.Material.Metal)
  if i<=2 then
   local roof=room:FindFirstChild("Ceiling"); roof.Material=Enum.Material.Glass; roof.Transparency=0.48
   for beam=-2,2 do prop(room,"RoofSupportBeam",Vector3.new(1,1.2,halfDepth*2),Vector3.new(x+beam*27,height-0.3,0),C(45,52,61),Enum.Material.Metal) end
  end
  z.gate=prop(room,"CheckpointGate",Vector3.new(1,14,20),Vector3.new(x+75,7,0),C(95,110,120),Enum.Material.DiamondPlate)
  -- Ten-stud connectors have tall side rails, so locked gates cannot be bypassed outside.
  prop(room,"Connector",Vector3.new(10,0.35,20),Vector3.new(x+80,0.18,0),C(60,67,73))
  prop(room,"ConnectorCeiling",Vector3.new(10,1,20),Vector3.new(x+80,18.5,0),C(37,43,51),Enum.Material.Metal)
  for _,s in ipairs({-1,1}) do prop(room,"ConnectorWall",Vector3.new(10,18,1),Vector3.new(x+80,9,s*10),C(50,58,65)) end
  for k=-2,2 do
   local lamp=prop(room,"IndustrialLight",Vector3.new(5,0.3,3),Vector3.new(x+k*26,indoor and height-1 or 12,0),C(205,215,220)); light(lamp,C(205,220,230),43,1.1)
  end
  -- Different floorplans, not one shared corridor with different prop names.
  if i==3 then
   for k=0,1 do prop(room,"PipeServiceWall",Vector3.new(25,11,2),Vector3.new(x-25+k*45,5.5,k==0 and -9 or 9),C(64,75,78),Enum.Material.Concrete) end
  elseif i==5 then
   prop(room,"ArchivePartition",Vector3.new(72,14,1),Vector3.new(x-4,7,-7),C(65,85,90),Enum.Material.Glass).Transparency=0.3
   prop(room,"ArchiveOffice",Vector3.new(1,14,20),Vector3.new(x-40,7,-23),C(62,73,82))
  elseif i==6 then
   for _,side in ipairs({-1,1}) do prop(room,"LaboratoryGlass",Vector3.new(70,13,0.5),Vector3.new(x-2,6.5,side*13),C(100,150,155),Enum.Material.Glass).Transparency=0.65 end
  elseif i==7 then
   prop(room,"CraneBeam",Vector3.new(95,3,4),Vector3.new(x,26,0),C(170,133,61),Enum.Material.Metal)
   for _,side in ipairs({-1,1}) do prop(room,"CranePillar",Vector3.new(3,25,4),Vector3.new(x+side*46,12.5,0),C(145,123,65),Enum.Material.Metal) end
  elseif i==8 then
   local core=prop(room,"CentralReactor",Vector3.new(22,15,15),Vector3.new(x,11,0),C(48,95,115),Enum.Material.Metal); core.Shape=Enum.PartType.Cylinder; core.CFrame*=CFrame.Angles(0,0,math.pi/2)
   for _,side in ipairs({-1,1}) do prop(room,"ReactorGuardrail",Vector3.new(26,3,1),Vector3.new(x,1.8,side*12),C(155,135,65),Enum.Material.Metal) end
  elseif i==9 then
   for _,side in ipairs({-1,1}) do
    prop(room,"CommandDesk",Vector3.new(45,3,5),Vector3.new(x,1.7,side*20),C(48,54,62),Enum.Material.Metal)
    for monitor=1,4 do prop(room,"CommandMonitor",Vector3.new(7,4,0.4),Vector3.new(x-25+monitor*10,5,side*22),C(55,110,125)) end
   end
  elseif i==10 then
   for _,side in ipairs({-1,1}) do
    prop(room,"CyberOfficeLight",Vector3.new(105,0.14,0.18),Vector3.new(x,2,side*(halfDepth-1.2)),C(180,48,50),Enum.Material.Neon)
    prop(room,"ArmoredOfficePanel",Vector3.new(85,10,0.3),Vector3.new(x,10,side*(halfDepth-1.1)),C(22,27,36),Enum.Material.Metal)
   end
   prop(room,"OfficeCarpet",Vector3.new(90,0.1,34),Vector3.new(x,0.42,0),C(73,33,42),Enum.Material.Fabric)
   prop(room,"OfficeSofa",Vector3.new(17,3,5),Vector3.new(x-28,1.8,-24),C(58,52,50),Enum.Material.Fabric)
   for k=-1,1 do prop(room,"Bookcase",Vector3.new(12,13,3),Vector3.new(x+k*23,6.7,29),C(65,46,34),Enum.Material.Wood) end
  end
  for k=1,7 do
   local px=x-52+(k-1)*16; local sz=k%2==0 and -1 or 1
   local edge=halfDepth-12
   if def.theme=="forest" then
    prop(room,"PineTrunk",Vector3.new(2,16,2),Vector3.new(px,8,sz*edge),C(73,57,43),Enum.Material.Wood)
    local crown=prop(room,"PineCrown",Vector3.new(10,16,10),Vector3.new(px,19,sz*edge),C(35,65,51)); crown.Shape=Enum.PartType.Ball; crown.CanCollide=false
   elseif def.theme=="cargo" then
    prop(room,"FreightContainer",Vector3.new(11,9,16),Vector3.new(px,4.7,sz*edge),k%2==0 and C(72,100,112) or C(115,85,67),Enum.Material.CorrodedMetal)
   elseif def.theme=="pipes" or def.theme=="reactor" then
    local pipe=prop(room,"CoolingPipe",Vector3.new(13,2.6,2.6),Vector3.new(px,height-5,sz*(halfDepth-3)),C(90,115,125),Enum.Material.Metal); pipe.Shape=Enum.PartType.Cylinder
    if def.theme=="reactor" then local core=prop(room,"ReactorCore",Vector3.new(9,12,9),Vector3.new(px,6,sz*edge),C(55,125,150),Enum.Material.Glass); core.Transparency=0.35; light(core,C(70,150,180),16,0.5) end
   elseif def.theme=="press" or def.theme=="mech" then
    prop(room,"Conveyor",Vector3.new(13,2,9),Vector3.new(px,1.2,sz*edge),C(34,39,46),Enum.Material.DiamondPlate)
    prop(room,"PressFrame",Vector3.new(2,12,9),Vector3.new(px+6,6,sz*edge),C(93,108,120),Enum.Material.Metal)
    prop(room,"PressHead",Vector3.new(10,2,8),Vector3.new(px,10,sz*edge),C(120,127,132),Enum.Material.Metal)
   elseif def.theme=="servers" or def.theme=="command" then
    prop(room,"ServerRack",Vector3.new(9,11,5),Vector3.new(px,5.7,sz*edge),C(30,37,47),Enum.Material.Metal)
    for row=1,4 do prop(room,"RackDisplay",Vector3.new(7,0.3,0.1),Vector3.new(px,row*2,sz*edge-2.6),C(70,160,170),Enum.Material.Neon) end
   elseif def.theme=="lab" then
    local glass=prop(room,"CloneCapsule",Vector3.new(7,11,7),Vector3.new(px,5.7,sz*edge),C(95,160,175),Enum.Material.Glass); glass.Transparency=0.7; glass.CanCollide=false
    local cfg=table.clone(Types.Commander); cfg.Male=false; cfg.Name="Копия в капсуле"
    local doll=buildRig(cfg,CFrame.new(c2Origin+Vector3.new(px,3.4,sz*edge))); doll.Parent=room; anchorAll(doll); c2Dress(doll,false)
   else
    prop(room,"MarbleColumn",Vector3.new(4,17,4),Vector3.new(px,8.5,sz*edge),C(115,118,127),Enum.Material.Marble)
   end
  end
  for _,machine in ipairs(room:GetChildren()) do
   if machine:IsA("BasePart") and machine.Name=="PressHead" then
    machine.CanCollide=false; table.insert(z.machines,{part=machine,origin=machine.Position})
   end
  end
  if i==10 then
   prop(room,"BossDesk",Vector3.new(7,3,14),Vector3.new(x+25,1.7,0),C(22,27,34),Enum.Material.Metal)
   prop(room,"DeskHologram",Vector3.new(1.8,0.05,9),Vector3.new(x+25,3.25,0),C(75,145,175),Enum.Material.Neon)
  end
  -- Service panel sits at the far end of the engineering lane.
  local med=prop(room,"MedicalStation",Vector3.new(2,2,2),Vector3.new(x-48,1.3,17),C(70,145,115))
  local used={}
  prop(room,"MedicalCrossH",Vector3.new(1.6,0.35,0.1),Vector3.new(x-48,1.3,15.95),C(220,230,222))
  prop(room,"MedicalCrossV",Vector3.new(0.35,1.6,0.1),Vector3.new(x-48,1.3,15.94),C(220,230,222))
  c2Prompt(med,"Перевязаться",1,function(player)
   if used[player] then return end
   local _,hum=c2Root(player); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+70); used[player]=true end
  end)
  local panel=prop(room,"EngineeringPanel",Vector3.new(3,4,2),Vector3.new(x+45,2.3,-math.min(23,halfDepth-6)),C(45,115,125),Enum.Material.Metal)
  z.panel=panel; z.kind=def.kind; z.index=i
  prop(room,"TerminalScreen",Vector3.new(2.4,1.3,0.15),Vector3.new(x+45,3,-math.min(23,halfDepth-6)+1.05),C(45,115,125),Enum.Material.Glass)
  C2.SetupRoom(z,height,halfDepth)
  z.complete=function()
   z.hacked=true
   if not C2.GateReady(z) then return end
   local prompt=z.prompt
   z.done=true; prompt.Enabled=false; z.field.CanCollide=false; z.field.Transparency=1
   z.gate.CanCollide=false; TweenService:Create(z.gate,TweenInfo.new(1.2),{Position=z.gate.Position+Vector3.new(0,15,0)}):Play()
   for _,object in ipairs(room:GetDescendants()) do if object:IsA("BasePart") and object.Name=="PressHead" then object.Color=C(40,48,53) end end
   c2Send()
  end
  z.prompt=c2Prompt(panel,"Подключиться",0,function(player)
   if C2.escaping or C2.stage~=i or z.done then return end
   if not c2Allowed(player,"engineering") then return end
   if i==10 and c2Count(10)>0 then return end
   c2Engineering(player,z)
  end)
  z.prompt.Enabled=i~=10
 end
 -- Big factory silhouette can be read from the approach, behind playable buildings.
 for k=1,5 do
  local chimney=prop(C2.map,"FactoryChimney",Vector3.new(11,95+k*5,11),Vector3.new(350+k*150,45,-100),C(63,69,75),Enum.Material.Concrete)
  local smoke=Instance.new("Smoke"); smoke.Opacity=0.2; smoke.Size=18; smoke.RiseVelocity=9; smoke.Color=C(90,95,100); smoke.Parent=chimney
 end
 C2.BuildEscapeCity()
 local car=prop(C2.map,"EscapeVan",Vector3.new(13,4,7),Vector3.new(-58,3,24),C(42,65,83),Enum.Material.Metal)
 prop(C2.map,"VanCabin",Vector3.new(5,2.2,7),Vector3.new(-61,6,24),C(50,73,88),Enum.Material.Metal)
 prop(C2.map,"VanWindshield",Vector3.new(0.15,1.5,5.5),Vector3.new(-63.6,6,24),C(85,125,140),Enum.Material.Glass)
 for _,axle in ipairs({-62,-54}) do for _,side in ipairs({-1,1}) do
  local wheel=prop(C2.map,"VanWheel",Vector3.new(2.8,2.8,1),Vector3.new(axle,1.5,24+side*3.6),C(23,26,30)); wheel.Shape=Enum.PartType.Cylinder; wheel.CFrame*=CFrame.Angles(0,math.pi/2,0)
 end end
end
c2Escape=function()
 if C2.escaping or C2.escapeStarting or C2.finished then return end
 C2.escapeStarting=true
 C2.DefeatSequence()
end
c2Activate=function(index)
 C2.stage=index; local z=C2.zones[index]; if z.entered then return end; z.entered=true
 C2.alarm=false
 for _,p in ipairs(C2.party) do
  local artem=p:GetAttribute("Hero")=="Artem"
  c2Grant(p,artem and math.min(3,2+math.floor((index-1)/5)) or math.min(5,2+math.floor((index-1)/2)))
 end
 currentSpawn=CFrame.lookAt(c2Origin+Vector3.new(z.x-60,4,10),c2Origin+Vector3.new(z.x,4,10))
 if index==10 then task.spawn(function() C2.RunProtected(C2.BossIntro) end) else C2.BeginWave(index) end
 c2Send()
end
local function c2Hero(player)
 local source=ServerStorage:FindFirstChild(player:GetAttribute("Hero")=="Artem" and "eurtyoeyrntiu" or "ZamestitelDiomchica")
 local h=source and source:FindFirstChildOfClass("Humanoid")
 local char=player.Character; local target=char and char:FindFirstChildOfClass("Humanoid")
 if target and not C2.originals[player] then
  local ok,desc=pcall(function() return target:GetAppliedDescription() end)
  C2.originals[player]={description=ok and desc or nil,health=target.MaxHealth,name=target.DisplayName}
 end
 if h and target then
  local ok,description=pcall(function() return h:GetAppliedDescription() end)
  if ok then
   local applied,err=pcall(function() target:ApplyDescription(description) end)
   description:Destroy()
   if not applied then warn("[Chapter2] Hero description fallback: "..tostring(err)) end
  end
  -- Preserve the supplied models' actual clothes/accessories even if asset-description loading fails.
  for _,object in ipairs(char:GetChildren()) do
   if object:IsA("Accessory") or object:IsA("Clothing") or object:IsA("BodyColors") or object:IsA("ShirtGraphic") then object:Destroy() end
  end
  for _,object in ipairs(source:GetChildren()) do
   if object:IsA("Clothing") or object:IsA("BodyColors") or object:IsA("ShirtGraphic") then object:Clone().Parent=char
   elseif object:IsA("Accessory") then
    local copy=object:Clone()
    for _,part in ipairs(copy:GetDescendants()) do
     if part:IsA("BaseScript") then part:Destroy()
     elseif part:IsA("BasePart") then part.Anchored=false; part.CanCollide=false; part.Massless=true end
    end
    target:AddAccessory(copy)
   end
  end
 end
 if target then target.DisplayName=player:GetAttribute("Hero")=="Artem" and "Артем • инженер" or "Демид • штурм"; target.MaxHealth=180; target.Health=180 end
end
local function c2RestoreHeroes()
 for player,state in pairs(C2.originals or {}) do
  local target=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  local equipment=player.Character and player.Character:FindFirstChild("Chapter2Equipment"); if equipment then equipment:Destroy() end
  if target and target.Health>0 then
   if state.description then pcall(function() target:ApplyDescriptionReset(state.description) end) end
   target.MaxHealth=state.health; target.Health=state.health; target.DisplayName=state.name
  end
  if state.description then state.description:Destroy() end
 end
 C2.originals={}
end
c2Finish=function(good)
 if C2.finished then return end
 C2.RunProtected(function()
 MusicRE:FireAllClients("stop")
 for player in pairs(C2.challenges) do c2EndEngineering(player) end
 C2.finished=true; C2.escaping=false; C2.serial+=1
 canFight=false; sceneLock(true); introActive=true
 C2RE:FireAllClients("ending",{good=good})
 task.wait(0.5); CutsceneRE:FireAllClients("start")
 if good then
  C2.CarScene()
 else
  CutsceneRE:FireAllClients("povForward"); ShakeRE:FireAllClients(14)
  for i=1,10 do C2.Collapse(C2.zones[i],true) end
  C2.Literal("Операция","Связь оборвалась. Никто не успел выбраться из центра.",5)
 end
 FadeRE:FireAllClients(true,good and "ГЛАВА II ПРОЙДЕНА" or "ГЛАВА II • ПЛОХАЯ КОНЦОВКА"); task.wait(1)
 MusicRE:FireAllClients("final")
 C2RE:FireAllClients("chapterCredits",true); task.wait(35); C2RE:FireAllClients("chapterCredits",false)
 MusicRE:FireAllClients("stop")
 if good then C2.NewsTwist() end
 C2.active=false
 for _,conn in ipairs(C2.connections) do conn:Disconnect() end
 table.clear(C2.connections); table.clear(C2.mobs)
 for _,p in ipairs(C2.party) do p:SetAttribute("Chapter",1); p:SetAttribute("IsSprinting",false); p:SetAttribute("SprintStamina",100) end
 C2.sprint={}
 C2RE:FireAllClients("clear")
 Players.RespawnTime=3
 c2RestoreHeroes()
 returnToMenu()
 end)
end
local function startChapter2(party)
 C2.challenges={}; C2.safe={}; C2.challengeSerial=0; C2.originals={}; C2.bossDefeated=false; C2.escapeStarting=false; C2.shots={}; C2.active=true; C2.finished=false; C2.escaping=false; C2.alarm=false; C2.stage=1; C2.serial+=1; C2.party=table.clone(party); C2.mobs={}
 local serial=C2.serial
 C2.InitCampaign(); C2.restoreHeroes=c2RestoreHeroes
 levelToken+=1; canFight=false; introActive=true; sceneLock(true)
 FadeRE:FireAllClients(true,"ГЛАВА II • НЕ СКРЫТАЯ БАЗА ТЯНОК"); task.wait(1)
 clearLevel(); newFolders(); applyPreset("Base",0.1); c2Build(); c2Home()
 local animTime=0
 table.insert(C2.connections,RunService.Heartbeat:Connect(function(dt)
  if not C2.active or C2.finished then return end
  C2.SprintTick(dt)
  animTime+=dt; if animTime<0.05 then return end; animTime=0
  local z=C2.zones[C2.stage]
  if z and not z.done then for _,machine in ipairs(z.machines) do
   if machine.part.Parent then machine.part.Position=machine.origin+Vector3.new(0,-math.abs(math.sin(os.clock()*1.2))*5,0) end
  end end
  for model,e in pairs(C2.mobs) do
   if model.Parent and e.hum.Health>0 and not e.boss then
    local speed=e.root.AssemblyLinearVelocity.Magnitude
    local swing=math.sin(os.clock()*9)*math.clamp(speed/12,0,1)*0.45
    e.joints.RH.C0=e.base.RH*CFrame.Angles(swing,0,0); e.joints.LH.C0=e.base.LH*CFrame.Angles(-swing,0,0)
    e.joints.LS.C0=e.base.LS*CFrame.Angles(swing*0.5,0,0)
   end
  end
 end))
 currentLevel=0; currentName="Глава II"; currentSpawn=CFrame.lookAt(Vector3.new(-193,4,4),Vector3.new(-187,4,15)); placeAll(); sceneLock(true)
 Players.RespawnTime=1000000
 for _,p in ipairs(party) do p:SetAttribute("Chapter",2); c2Hero(p) end
 CutsceneRE:FireAllClients("start")
 -- Third-person opening inside their furnished home; no duplicate playable actors.
 local opening=Instance.new("Model"); opening.Name="Chapter2OpeningCast"; opening.Parent=C2.map
 local present={}
 for _,p in ipairs(party) do
  local hero=p:GetAttribute("Hero"); present[hero]=true
  local from=hero=="Artem" and Vector3.new(-191,3.5,-1) or Vector3.new(-182,3.5,-1)
  local to=hero=="Artem" and Vector3.new(-182,3.5,0) or Vector3.new(-191,3.5,0)
  if p.Character then p.Character:PivotTo(CFrame.lookAt(from,to)) end
 end
 if not present.Artem then secretActor(opening,"eurtyoeyrntiu","Артем",CFrame.lookAt(Vector3.new(-191,0.4,-1),Vector3.new(-182,0.4,0))) end
 if not present.Demid then secretActor(opening,"ZamestitelDiomchica","Демид",CFrame.lookAt(Vector3.new(-182,0.4,-1),Vector3.new(-191,0.4,0))) end
 focusStreaming(Vector3.new(-180,5,0))
 cameraPlan(Vector3.new(-201,8,17),Vector3.new(-198,7,15),Vector3.new(-187,3.5,-1),6,60,55)
 prepareView(Vector3.new(-180,5,0)); CutsceneRE:FireAllClients("reveal")
 if #party==1 then
  local engineer=party[1]:GetAttribute("Hero")=="Artem"
  sceneLine(engineer and "Демид: Я что-то устал. Отправляйся ты один на миссию, Артем. Буду помогать по связи." or "Артем: Я что-то устал. Отправляйся ты один на миссию, Демид. Удаленный доступ к панелям я настроил.",7)
 else
  sceneLine("Демид: Что-то я не хочу идти на эту миссию.",4)
  sceneLine("Артем: Эй, мы договаривались! Так что давай без НО, короче, работаем.",5)
 end
 sceneLine("Артем: Я тут недавно тянку вычислил по IP, когда в Blade Ball играл. Похоже, она работает на ту самую компанию, где производят тысячи копий.",9)
 sceneLine("Артем: Пробил их в гугле и узнал, где их мини-завод. Они вроде беспалевные, но буквально написали: не скрытая база тянок. Это один из их заводов. Нужно устроить штурм.",11)
 sceneLine("Демид: Эх, ладно, пошли. Я тут подготовился слегка. Бери инженерские приборы: будешь двери открывать, конвейеры ломать. А я прикрою.",9)
 FadeRE:FireAllClients(true,""); task.wait(0.7); opening:Destroy()
 currentSpawn=CFrame.lookAt(c2Origin+Vector3.new(-60,4,0),c2Origin+Vector3.new(100,4,0)); placeAll(); sceneLock(true)
 focusStreaming(c2Origin)
 -- From the approach onwards camera remains at the player's eye position.
 for _,p in ipairs(party) do local root=c2Root(p); local head=p.Character and p.Character:FindFirstChild("Head"); if root and head then
  CutsceneRE:FireClient(p,"pov",c2Origin+Vector3.new(600,120,-83),65)
 end end
 prepareView(c2Origin); CutsceneRE:FireAllClients("reveal")
 sceneLine("Артем: Вон он, за терминалом. Я иду по сервисным проходам, ты забираешь охрану. Панель открывает общий шлюз.",7)
 CutsceneRE:FireAllClients("end"); sceneLock(false); introActive=false; canFight=true
 c2Activate(1); MusicRE:FireAllClients("intro")

 task.spawn(function()
  local lastEscape=0
  while C2.active and serial==C2.serial and not C2.finished do
   for _,p in ipairs(party) do local root=c2Root(p); if root and not introActive then c2Contain(p,root) end end
   for p,ch in pairs(C2.challenges) do
    local root=c2Root(p)
    if not root or ch.expires<workspace:GetServerTimeNow() or (root.Position-ch.zone.panel.Position).Magnitude>12 then c2EndEngineering(p) end
   end
   if not c2Alive() then c2Finish(false); break end
   if C2.escapeStarting then task.wait(0.5); continue end
   if C2.escaping then
    C2.CollapseTick()
    if workspace:GetServerTimeNow()>=C2.deadline then c2Finish(false); break end
    local allSafe=true; local survivors=0
    for _,p in ipairs(party) do local r=c2Root(p); if r then survivors+=1; if (r.Position-(c2Origin+Vector3.new(-58,3,24))).Magnitude>22 then allSafe=false end end end
    if allSafe and survivors>0 then c2Finish(true); break end
    if os.clock()-lastEscape>18 then
     lastEscape=os.clock()
     for _,p in ipairs(party) do local r=c2Root(p); if r then
      local zone=math.clamp(math.floor((r.Position.X-c2Origin.X+75)/160)+1,1,10)
      if c2Count(zone)<2 then C2.Pursuit(zone) end
      break
     end end
    end
   else
    local z=C2.zones[C2.stage]
    if z.done and C2.stage<10 then
     local allAcross=true
     for _,p in ipairs(party) do local r=c2Root(p); if r and r.Position.X<c2Origin.X+z.x+80 then allAcross=false end end
     if allAcross then c2Activate(C2.stage+1) end
    end
   end
   c2Send(); task.wait(1)
  end
 end)
end
c2Attack=function(player,wname,origin,dir,charge)
 if not C2.active or C2.finished or introActive or C2.challenges[player] or not table.find(C2.party,player) then return end
 local root,h=c2Root(player); local head=player.Character and player.Character:FindFirstChild("Head")
 if not root or not head or typeof(origin)~="Vector3" or typeof(dir)~="Vector3" then return end
 local function finite(v) return v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e8 and math.abs(v.Y)<1e8 and math.abs(v.Z)<1e8 end
 if not finite(origin) or not finite(dir) or dir.Magnitude<0.1 or (origin-head.Position).Magnitude>12 then return end
 local index=table.find(WD.Order,wname); if not index or index>(player:GetAttribute("WeaponLevel") or 1) then return end
 dir=dir.Unit
 local engineer=player:GetAttribute("Hero")=="Artem"
 local melee=wname=="Fists"; local weld=melee and engineer
 local now=os.clock(); local cd=weld and 0.2 or melee and 0.5 or WD.Stats[wname].Cooldown
 C2.shots=C2.shots or {}; if now-(C2.shots[player] or 0)<cd*0.9 then return end; C2.shots[player]=now
 local range=melee and (weld and 13 or 8) or WD.Stats[wname].Range
 local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={player.Character,fxFolder}
 local hit=workspace:Raycast(origin,dir*range,rp)
 if not melee then C2.alarm=true end
 if weld then
  local glow=c2Part(fxFolder,"WeldingArc",Vector3.new(0.35,0.35,0.35),origin+dir*2,C(125,220,255),Enum.Material.Neon); glow.CanCollide=false; light(glow,C(140,220,255),15,2); Debris:AddItem(glow,0.15)
 end
 if not hit then return end
 if not melee then tracer(origin,hit.Position,WD.Stats[wname].Color) end
 local model=hit.Instance:FindFirstAncestorOfClass("Model"); local e=model and C2.mobs[model]
 if not e or e.hum.Health<=0 then return end
 local damage=melee and (weld and 17 or 48) or WD.Stats[wname].Damage*(wname=="Shotgun" and 5 or 1)
 if wname=="Rifle" then
  local q=typeof(charge)=="number" and charge==charge and math.clamp(charge,0,1) or 0
  damage=45+235*q
 end
 if hit.Instance.Name=="Head" and not melee then damage*=2 end
 if melee and not weld then
  local behind=e.root.CFrame.LookVector:Dot((root.Position-e.root.Position).Unit)<-0.3
  if behind and not e.boss and not e.mech then damage=e.hum.MaxHealth; NotifyRE:FireClient(player,"Тихое устранение",2) else C2.alarm=true end
 end
 e.alertUntil=os.clock()+12; e.lastSeen=root.Position
 if weld and not e.mech and not e.boss then e.blind=workspace:GetServerTimeNow()+2.5; e.hum:MoveTo(e.root.Position) end
 if weld and e.mech then damage=4; NotifyRE:FireClient(player,"Меха-тян не ослепляется сваркой. Уходи из зоны ракеты!",2) end
 if e.defeated then return end
 if e.boss then
  if not melee then C2.HitBoss(damage,hit.Position,origin) else C2.Spark(hit.Position,C(110,175,220)) end
  return
 end
 e.hum:TakeDamage(damage)
 HitRE:FireClient(player,e.hum.Health<=0 or e.defeated==true)
end

-- END CHAPTER TWO
-- BEGIN CHAPTER THREE
-- Chapter III: authoritative campaign. Embedded after Chapter II helpers.
local C3={active=false,serial=0,party={},mobs={},connections={}}
local C3RE=newRemote("Chapter3")
C3.origin=Vector3.new(0,0,12000)
C3.names={"ЖИЛОЙ КВАРТАЛ","ТОРГОВАЯ УЛИЦА","РАЗВЯЗКА","КВАРТАЛ НТЯН","ПЛОЩАДЬ БАШНИ","СЕРВИСНЫЙ ЭТАЖ","СИЛОВОЙ ЯРУС","СЕРВЕРНЫЙ ЯРУС","АНТЕННЫЙ ЯРУС","ВЕРХНИЙ ПОСТ"}
function C3.Pos(x,y,z) return C3.origin+Vector3.new(x,y,z or 0) end
function C3.Part(parent,name,size,pos,color,mat)
 if parent==C3.map and C3.structure and C3.structure.Parent==C3.map then parent=C3.structure end
 local p=part(parent,size,pos,color,mat or Enum.Material.Concrete); p.Name=name
 if name=="SignalSpine" then p.Material=Enum.Material.Neon end
 return p
end
function C3.ApplyLighting()
 C3.lightingSaved={}
 for _,key in ipairs({"Ambient","OutdoorAmbient","Brightness","ClockTime","ExposureCompensation","FogStart","FogEnd","EnvironmentDiffuseScale","EnvironmentSpecularScale"}) do C3.lightingSaved[key]=Lighting[key] end
 C3.effectsSaved={density=atm.Density,haze=atm.Haze,color=atm.Color,contrast=cc.Contrast,saturation=cc.Saturation,tint=cc.TintColor,brightness=cc.Brightness,bloom=bloom.Intensity}
 Lighting.Ambient=C(128,135,145); Lighting.OutdoorAmbient=C(145,151,160); Lighting.Brightness=1.65; Lighting.ClockTime=14.2; Lighting.ExposureCompensation=-0.12
 Lighting.FogStart=500; Lighting.FogEnd=20000; Lighting.EnvironmentDiffuseScale=0.48; Lighting.EnvironmentSpecularScale=0.28
 atm.Density=0.07; atm.Haze=0.42; atm.Color=C(196,204,211)
 cc.Contrast=0.02; cc.Saturation=-0.1; cc.TintColor=C(248,247,241); cc.Brightness=-0.015; bloom.Intensity=0
end
function C3.RestoreLighting()
 if not C3.lightingSaved then return end
 for key,value in pairs(C3.lightingSaved) do Lighting[key]=value end
 local e=C3.effectsSaved
 atm.Density=e.density; atm.Haze=e.haze; atm.Color=e.color; cc.Contrast=e.contrast; cc.Saturation=e.saturation; cc.TintColor=e.tint; cc.Brightness=e.brightness; bloom.Intensity=e.bloom
 C3.lightingSaved=nil; C3.effectsSaved=nil
end
function C3.ProtectCivilian(model,hum)
 model:SetAttribute("Enemy",false); model:SetAttribute("ProtectedCivilian",true)
 hum.BreakJointsOnDeath=false; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
 local field=Instance.new("ForceField"); field.Name="NonlethalProtection"; field.Visible=false; field.Parent=model
 table.insert(C3.connections,hum.HealthChanged:Connect(function(health)
  if model.Parent and health<hum.MaxHealth then hum.Health=hum.MaxHealth end
 end))
end
function C3.Suppress(model,e,player,amount)
 if e.down then return end
 e.suppression=math.min(100,(e.suppression or 0)+amount); e.stun=os.clock()+2
 e.hum.Health=e.hum.MaxHealth
 if e.suppression>=80 then
  e.down=true; e.hum:MoveTo(e.root.Position); e.hum.WalkSpeed=0; e.hum.Sit=true
  e.root.Anchored=true; C2.SitRig(model)
  model:SetAttribute("SubduedAlive",true)
  for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
  NotifyRE:FireClient(player,"Гражданин обезврежен. Жив, помощь будет оказана.",3)
 end
 C3RE:FireClient(player,"nonlethal",{subdued=e.down,progress=e.suppression})
end
function C3.Valid(player)
 return C3.active and not C3.finished and table.find(C3.party,player)~=nil and player.Parent~=nil
end
function C3.Root(player) return c2Root(player) end
function C3.Living()
 local list={}; for _,p in ipairs(C3.party) do if p.Parent and C3.Root(p) then table.insert(list,p) end end; return list
end
function C3.Count(index)
 local n=0; for m,e in pairs(C3.mobs) do if m.Parent and e.stage==index and not e.down and e.hum.Health>0 then n+=1 end end; return n
end
function C3.Ready(z) return z.cleared==true and z.objective==true end
function C3.CanHack(player)
 local z=C3.zones and C3.zones[10]
 return C3.Valid(player) and C3.Root(player)~=false and C3.Root(player)~=nil and C3.stage==10 and z and z.cleared and C3.key and C3.relays>=4 and not introActive and not C3.towerOff
end
function C3.Engineer(player)
 if player:GetAttribute("Hero")=="Artem" then return true end
 for _,p in ipairs(C3.Living()) do if p:GetAttribute("Hero")=="Artem" then return false end end
 return true
end
function C3.Send(force)
 local z=C3.zones and C3.zones[C3.stage]; if not z then return end
 local payload={stage=C3.stage,name=C3.names[C3.stage],wave=z.wave,rounds=z.rounds,enemies=C3.Count(C3.stage),cleared=z.cleared,objective=z.objective,relays=C3.relays,phase=C3.hackPhase,shield=not C3.towerOff,coop=C3.coop}
 local signature=("%d:%d:%d:%d:%d:%d:%d:%d"):format(payload.stage,payload.wave,payload.enemies,payload.cleared and 1 or 0,payload.objective and 1 or 0,payload.relays,payload.phase,payload.shield and 1 or 0)
 local now=os.clock()
 if not force and signature==C3.lastStateSignature and now-(C3.lastStateSent or 0)<1 then return end
 C3.lastStateSignature=signature; C3.lastStateSent=now
 for _,p in ipairs(C3.party) do if p.Parent then C3RE:FireClient(p,"state",payload) end end
end
function C3.Protected(fn)
 local ok,err=xpcall(fn,debug.traceback)
 if not ok then warn("[Chapter3] "..tostring(err)); C3.Stop(); returnToMenu() end
end
function C3.Stop()
 C3.active=false; C3.serial+=1; C3.RestoreLighting()
 for _,c in ipairs(C3.connections) do c:Disconnect() end; C3.connections={}
 for _,p in ipairs(C3.party) do if p.Parent then p:SetAttribute("IsSprinting",false); p:SetAttribute("Chapter",1); p:SetAttribute("SprintStamina",100); p:SetAttribute("C3GrabbedUntil",nil) end end
 C3RE:FireAllClients("clear"); C2RE:FireAllClients("clear"); CreditsRE:FireAllClients(false)
 if C3.map and C3.map.Parent then C3.map:Destroy() end; C3.map=nil; C3.landmark=nil; C3.home=nil; C3.zones=nil
 C3.lastStateSignature=nil; C3.lastStateSent=nil
 Players.RespawnTime=3; c2RestoreHeroes(); MusicRE:FireAllClients("stop")
end
function C3.Scene(on)
 introActive=on; canFight=not on; sceneLock(on)
 CutsceneRE:FireAllClients(on and "start" or "end")
end
function C3.Say(name,text,time) C2.Literal(name,text,time) end
function C3.Prompt(part_,text,callback,hold)
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=text; prompt.ObjectText=""; prompt.MaxActivationDistance=9; prompt.RequiresLineOfSight=true; prompt.HoldDuration=hold or 0; prompt.Parent=part_
 local held={}
 if hold then
  table.insert(C3.connections,prompt.PromptButtonHoldBegan:Connect(function(p) held[p]=os.clock() end))
  table.insert(C3.connections,prompt.PromptButtonHoldEnded:Connect(function(p)
   local started=held[p]
   task.delay(0.4,function() if held[p]==started then held[p]=nil end end)
  end))
 end
 table.insert(C3.connections,prompt.Triggered:Connect(function(p)
  local root=C3.Root(p); local started=held[p]
  local holdValid=not hold or started and os.clock()-started>=hold-0.25
  held[p]=nil -- every activation consumes its own hold; no replay window
  if C3.Valid(p) and root and not introActive and holdValid and (root.Position-part_.Position).Magnitude<=11 then C3.Protected(function() callback(p) end) end
 end))
 return prompt
end
-- BEGIN CHAPTER THREE WORLD
-- Geometry and physical interactions for Chapter III; embedded into Chapter3.
function C3.Lamp(parent,pos,range,brightness,name)
 local fixture=C3.Part(parent,name or "AreaLamp",Vector3.new(3,0.25,2),pos,C(235,231,216),Enum.Material.SmoothPlastic)
 fixture.CanCollide=false; fixture.CanQuery=false
 local lamp=light(fixture,C(240,238,225),range,brightness); lamp.Shadows=false
 return fixture
end
function C3.Beam(parent,name,a,b,width,color)
 local p=C3.Part(parent,name,Vector3.new(width,width,(b-a).Magnitude),(a+b)*0.5,color,Enum.Material.Metal)
 p.CFrame=CFrame.lookAt((a+b)*0.5,b); return p
end
function C3.BuildRadioMast()
 -- A full-height, tapered, four-leg lattice tower with the painted red/white
 -- maintenance sections of a real cellular mast (not a square neon shaft).
 local function radiusAt(y) return 54-44*(y/324) end
 local function corner(signX,signZ,y)
  local radius=radiusAt(y)
  return C3.Pos(960+signX*radius,y,signZ*radius)
 end
 local corners={{-1,-1},{1,-1},{1,1},{-1,1}}
 local red=C(177,57,48); local ivory=C(192,199,198)
 for level=0,13 do
  local y0=level*24; local y1=math.min(y0+24,324)
  local color=(level<2 or level==7 or level>=12) and red or ivory
  for i,signs in ipairs(corners) do
   local nextSigns=corners[i%#corners+1]
   C3.Beam(C3.landmark,"TaperedTowerLeg",corner(signs[1],signs[2],y0),corner(signs[1],signs[2],y1),2.1,color)
   -- Perimeter tie beams and crossed X-bracing on all four faces.
   C3.Beam(C3.landmark,"TowerHorizontalTie",corner(signs[1],signs[2],y1),corner(nextSigns[1],nextSigns[2],y1),1.0,color)
   C3.Beam(C3.landmark,"TowerXBrace",corner(signs[1],signs[2],y0),corner(nextSigns[1],nextSigns[2],y1),0.85,color)
   C3.Beam(C3.landmark,"TowerXBrace",corner(nextSigns[1],nextSigns[2],y0),corner(signs[1],signs[2],y1),0.85,color)
  end
 end
 -- Four stout anchor shoes and a narrow service platform under the antenna head.
 for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
  C3.Part(C3.landmark,"TowerAnchorShoe",Vector3.new(4,4,4),C3.Pos(960+sx*53,2,sz*53),C(157,61,51),Enum.Material.Metal)
 end end
 C3.Part(C3.landmark,"AntennaServiceDeck",Vector3.new(25,0.8,25),C3.Pos(960,300,0),C(83,94,99),Enum.Material.Metal)
 for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
  C3.Part(C3.landmark,"AntennaDeckRailPost",Vector3.new(0.45,3.5,0.45),C3.Pos(960+sx*11,302,sz*11),C(181,187,185),Enum.Material.Metal)
 end end
 for _,side in ipairs({-1,1}) do
  C3.Part(C3.landmark,"AntennaDeckRail",Vector3.new(22,0.35,0.35),C3.Pos(960,303.5,side*11),C(181,187,185),Enum.Material.Metal)
  C3.Part(C3.landmark,"AntennaDeckRail",Vector3.new(0.35,0.35,22),C3.Pos(960+side*11,303.5,0),C(181,187,185),Enum.Material.Metal)
 end
 C3.Part(C3.landmark,"TopWhipAntenna",Vector3.new(0.8,27,0.8),C3.Pos(960,337.5,0),C(180,186,185),Enum.Material.Metal)
 C3.Part(C3.landmark,"AntennaTopCrossbar",Vector3.new(12,0.6,0.6),C3.Pos(960,341,0),C(180,186,185),Enum.Material.Metal)
 for _,side in ipairs({-1,1}) do
  C3.Part(C3.landmark,"TopPanelAntenna",Vector3.new(1.2,10,2),C3.Pos(960+side*6,335,0),C(198,202,199),Enum.Material.Metal)
 end
 -- Directional panel antennas and small service microwave dishes on the mast.
 for _,y in ipairs({157,205,253,277}) do
  for _,side in ipairs({-1,1}) do
   local radius=radiusAt(y)
   local panel=C3.Part(C3.landmark,"CellularPanelAntenna",Vector3.new(2,14,5.5),C3.Pos(960+side*(radius-5),y,0),C(190,198,199),Enum.Material.Metal)
   panel.CanCollide=false
   C3.Beam(C3.landmark,"AntennaMount",C3.Pos(960+side*(radius-11),y,0),panel.Position,0.8,C(104,115,117))
   local dish=C3.Part(C3.landmark,"MicrowaveDish",Vector3.new(1.2,7,7),C3.Pos(960+side*(radius-12),y,12),C(171,180,182),Enum.Material.Metal)
   dish.Shape=Enum.PartType.Cylinder; dish.CanCollide=false
   C3.Beam(C3.landmark,"DishFeed",dish.Position,C3.Pos(960+side*(radius-4),y,12),0.55,C(94,106,111))
  end
 end
 -- A few low-output red obstruction lamps remain visible while the signal runs.
 for _,y in ipairs({24,120,216,300}) do
  for _,side in ipairs({-1,1}) do
   local marker=C3.Part(C3.landmark,"TowerObstructionLamp",Vector3.new(0.8,1.1,0.8),C3.Pos(960+side*(radiusAt(y)+0.7),y,0),C(174,54,48),Enum.Material.SmoothPlastic)
   table.insert(C3.redLights,marker); light(marker,C(220,66,57),18,0.28)
  end
 end
end
function C3.CommunicationEquipment(index,floor)
 local core=C3.Part(C3.map,"SignalWaveguideCore",Vector3.new(8,16,8),C3.Pos(960,floor+8,0),C(99,120,138),Enum.Material.Metal)
 local stripe=C3.Part(C3.map,"CoreSignalIndicator",Vector3.new(8.2,0.5,8.2),C3.Pos(960,floor+10,0),C(200,66,66),Enum.Material.Neon); table.insert(C3.redLights,stripe)
 for _,side in ipairs({-1,1}) do
  C3.Part(C3.map,"CableTray",Vector3.new(64,0.35,1.1),C3.Pos(960,floor+0.8,side*9),C(190,169,92),Enum.Material.Metal)
  C3.Part(C3.map,"RFEquipmentRack",Vector3.new(5,7,4),C3.Pos(960+side*35,floor+3.8,8),C(65,90,112),Enum.Material.Metal)
  for channel=1,4 do C3.Part(C3.map,"ReceiverModule",Vector3.new(5.1,0.6,4.1),C3.Pos(960+side*35,floor+channel*1.4,8),C(145,166,178),Enum.Material.Metal) end
 end
end
function C3.Room(parent,name,center,size)
 local room=Instance.new("Model"); room.Name=name; room.Parent=parent
 C3.Part(room,"Floor",Vector3.new(size.X,0.6,size.Z),center,C(62,66,73))
 C3.Part(room,"Ceiling",Vector3.new(size.X,0.7,size.Z),center+Vector3.new(0,size.Y,0),C(37,43,53))
 for _,side in ipairs({-1,1}) do C3.Part(room,"Wall",Vector3.new(size.X,size.Y,1),center+Vector3.new(0,size.Y/2,side*size.Z/2),C(60,67,79)) end
 return room
end
function C3.BuildVillain()
 local m=Instance.new("Model"); m.Name="NeuroMegafactory"; m.Parent=C3.map
 local o=C3.Pos(0,0,2200)
 local dark=C(43,49,57); local steel=C(75,83,91); local trim=C(108,116,120)
 -- A complete, human-scale factory bay: continuous floor, four enclosing walls,
 -- roof and visible structural ribs. The old version showed an open black void.
 C3.Part(m,"FactoryFloor",Vector3.new(300,1,280),o+Vector3.new(0,-0.5,105),C(61,65,68),Enum.Material.Concrete)
 C3.Part(m,"FactoryCeiling",Vector3.new(300,1,280),o+Vector3.new(0,52,105),C(42,47,52),Enum.Material.Metal)
 C3.Part(m,"FactoryLeftWall",Vector3.new(1,52,280),o+Vector3.new(-150,26,105),dark,Enum.Material.Concrete)
 C3.Part(m,"FactoryRightWall",Vector3.new(1,52,280),o+Vector3.new(150,26,105),dark,Enum.Material.Concrete)
 C3.Part(m,"FactoryRearWall",Vector3.new(300,52,1),o+Vector3.new(0,26,245),dark,Enum.Material.Concrete)
 C3.Part(m,"FactoryFrontLeft",Vector3.new(132,52,1),o+Vector3.new(-84,26,-35),dark,Enum.Material.Concrete)
 C3.Part(m,"FactoryFrontRight",Vector3.new(132,52,1),o+Vector3.new(84,26,-35),dark,Enum.Material.Concrete)
 C3.Part(m,"FactoryEntryLintel",Vector3.new(36,8,1),o+Vector3.new(0,48,-35),steel,Enum.Material.Metal)
 for x=-120,120,40 do
  C3.Part(m,"FactoryRib",Vector3.new(1.4,50,1.4),o+Vector3.new(x,25,110),trim,Enum.Material.Metal)
  C3.Part(m,"CeilingBeam",Vector3.new(2,1.2,280),o+Vector3.new(x,50.5,105),steel,Enum.Material.Metal)
 end
 for z=0,220,44 do
  C3.Part(m,"SideSupportLeft",Vector3.new(3,50,2),o+Vector3.new(-146,25,z),steel,Enum.Material.Metal)
  C3.Part(m,"SideSupportRight",Vector3.new(3,50,2),o+Vector3.new(146,25,z),steel,Enum.Material.Metal)
 end
 -- Large wall display with an actual miniature of the ruined chapter-II base.
 local screen=C3.Part(m,"RuinsBroadcast",Vector3.new(48,25,0.8),o+Vector3.new(0,22,238),C(17,22,27),Enum.Material.SmoothPlastic)
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(1000,520); gui.LightInfluence=0.45; gui.Parent=screen
 local view=Instance.new("ViewportFrame"); view.Size=UDim2.fromScale(1,1); view.BackgroundColor3=C(25,30,34); view.Ambient=C(145,148,145); view.LightColor=C(190,185,165); view.Parent=gui
 local world=Instance.new("WorldModel"); world.Parent=view
 local ground=Instance.new("Part"); ground.Anchored=true; ground.Size=Vector3.new(100,1,100); ground.Position=Vector3.new(0,-1,0); ground.Color=C(48,51,53); ground.Material=Enum.Material.Concrete; ground.Parent=world
 for k=1,18 do
  local x=(k%5-2)*15; local z=math.floor(k/5)*14-18
  local ruin=Instance.new("Part"); ruin.Anchored=true; ruin.Size=Vector3.new(8+(k%3)*2,3+(k%4)*2,7); ruin.Position=Vector3.new(x,1,z); ruin.Color=C(67,68,65); ruin.Material=Enum.Material.Concrete; ruin.CFrame*=CFrame.Angles(0,k*0.21,0); ruin.Parent=world
  local beam=Instance.new("Part"); beam.Anchored=true; beam.Size=Vector3.new(1,8,1); beam.Position=Vector3.new(x+3,3,z-2); beam.Color=C(89,82,72); beam.Material=Enum.Material.Metal; beam.CFrame*=CFrame.Angles(0,0,math.rad(k%2==0 and 12 or -12)); beam.Parent=world
 end
 local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(58,42,-64),Vector3.new(0,2,0)); camera.Parent=view; view.CurrentCamera=camera

 -- Four restrained conveyor lines, industrial frames, and upright, complete
 -- R6 clone rigs inside clear glass vats; no floating cubes or arbitrary tilt.
 for row=1,4 do
  local z=116+(row-1)*27
  C3.Part(m,"ConveyorBed",Vector3.new(270,0.65,9),o+Vector3.new(0,0.55,z),C(54,61,66),Enum.Material.Metal)
  C3.Part(m,"ConveyorRail",Vector3.new(270,1.1,0.45),o+Vector3.new(0,1.2,z-4.7),trim,Enum.Material.Metal)
  C3.Part(m,"ConveyorRail",Vector3.new(270,1.1,0.45),o+Vector3.new(0,1.2,z+4.7),trim,Enum.Material.Metal)
  for col=1,8 do
   local x=-112+(col-1)*32; local center=o+Vector3.new(x,5.3,z)
   local shell=C3.Part(m,"TransformationCapsule",Vector3.new(9,6.2,6.2),center,C(104,116,119),Enum.Material.Glass)
   shell.Shape=Enum.PartType.Cylinder; shell.CFrame*=CFrame.Angles(0,0,math.rad(90)); shell.Transparency=0.76; shell.CanCollide=false; shell.CanTouch=false; shell.CanQuery=false
   for _,capY in ipairs({0,8.8}) do
    local cap=C3.Part(m,"CapsuleRoundedEnd",Vector3.new(6.2,2,6.2),o+Vector3.new(x,capY,z),C(104,116,119),Enum.Material.Glass)
    cap.Shape=Enum.PartType.Ball; cap.Transparency=0.8; cap.CanCollide=false; cap.CanTouch=false; cap.CanQuery=false
   end
   for _,side in ipairs({-1,1}) do
    local brace=C3.Part(m,"CapsuleFrame",Vector3.new(0.35,8.4,0.35),o+Vector3.new(x+side*3.35,5,z),trim,Enum.Material.Metal); brace.CanCollide=false
   end
   local cloneCfg=table.clone(Types.Pistol); cloneCfg.Name="Заготовка клона"; cloneCfg.Gun=false; cloneCfg.Male=false
   cloneCfg.Skin=C(177+(col%3)*5,158+(row%2)*5,148); cloneCfg.Hair=C(74,80,82); cloneCfg.Eye=C(92,111,113)
   cloneCfg.Shirt=C(97,105,108); cloneCfg.Skirt=C(66,73,77); cloneCfg.Legs=C(58,63,66); cloneCfg.Accent=C(112,126,127)
   local clone=buildRig(cloneCfg,CFrame.new(o+Vector3.new(x,3.15,z))); clone.Name="SuspendedClone"; clone.Parent=m; anchorAll(clone)
   for _,piece in ipairs(clone:GetDescendants()) do if piece:IsA("BasePart") then piece.CanCollide=false; piece.CanTouch=false; piece.CanQuery=false end end
   local hum=clone:FindFirstChildOfClass("Humanoid"); if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff end
  end
 end
 -- Even ceiling fill across the production floor so the enclosure and clones
 -- read clearly without washing the room in neon.
 for _,z in ipairs({35,105,175}) do
  for _,x in ipairs({-100,0,100}) do
   C3.Lamp(m,o+Vector3.new(x,47,z),72,1.45,"FactoryWorkLight")
  end
 end
 -- The camera-side control deck remains uncluttered so characters read clearly.
 local neuroPos=o+Vector3.new(-25,3.15,76); local assistantPos=o+Vector3.new(18,3.15,82)
 local function faceLevel(position,target)
  return CFrame.lookAt(position,Vector3.new(target.X,position.Y,target.Z))
 end
 local cfg=table.clone(Types.Neuro); cfg.Name=ANDROID_NAME; cfg.Gun=false
 cfg.Hair=C(46,151,157); cfg.Eye=C(101,177,178); cfg.Accent=C(78,137,143); cfg.Shirt=C(28,32,38); cfg.Skirt=C(17,21,26)
 local neuro=buildRig(cfg,faceLevel(neuroPos,screen.Position)); neuro.Parent=m; anchorAll(neuro)
 local chest=C3.Part(neuro,"NeuroChestPlate",Vector3.new(1.45,1.1,0.12),neuro.Torso.Position+neuro.Torso.CFrame.LookVector*0.56,C(64,83,89),Enum.Material.Metal); chest.CanCollide=false
 local assistantCfg=table.clone(Types.Pistol); assistantCfg.Name="Тян C-3B1"; assistantCfg.Male=false; assistantCfg.Gun=false
 assistantCfg.Hair=C(75,85,92); assistantCfg.Eye=C(89,132,139); assistantCfg.Shirt=C(49,58,66); assistantCfg.Skirt=C(47,52,60)
 local assistant=buildRig(assistantCfg,faceLevel(assistantPos,neuroPos)); assistant.Parent=m; c2Dress(assistant,false); anchorAll(assistant)
 return m,neuro,assistant,screen
end
function C3.BuildHome()
 -- Reuse the actual Chapter-II house builder, not a vaguely similar replacement.
 local previousMap,previousHome=C2.map,C2.home
 C2.map=C3.map; C2.home=nil
 local h=c2Home()
 C2.map=previousMap; C2.home=previousHome
 h:PivotTo(h:GetPivot()+C3.origin); h.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 h:SetAttribute("OriginalChapter2House",true); C3.home=h
 C3.tv=h:FindFirstChild("TVScreen")
 local function item(name,size,pos,color,mat) return C3.Part(h,name,size,C3.Pos(pos.X,pos.Y,pos.Z),color,mat) end
 -- Keep the lounge/kitchen/sofa/TV in their original positions. Only cut a
 -- real window and the two stair-wing doorways into the original side walls.
 for _,wall in ipairs(h:GetChildren()) do
  if wall.Name=="HouseSideWall" then wall:Destroy() end
 end
 for _,z in ipairs({-21,21}) do item("OriginalEastWall",Vector3.new(1,14,6),Vector3.new(-148,7,z),C(141,133,121)) end
 item("EastWindowSill",Vector3.new(1,3,36),Vector3.new(-148,1.5,0),C(141,133,121))
 item("EastWindowLintel",Vector3.new(1,4,36),Vector3.new(-148,12,0),C(141,133,121))
 local window=item("LivingWindow",Vector3.new(0.15,7,36),Vector3.new(-148,6.5,0),C(175,198,211),Enum.Material.Glass); window.Transparency=0.88
 item("OriginalWestWall",Vector3.new(1,14,35),Vector3.new(-212,7,6.5),C(141,133,121))
 item("WestDoorLintel",Vector3.new(1,3,12),Vector3.new(-212,12.5,-18),C(141,133,121))
 -- The second floor is an addition OVER the old house. Its existing ceiling
 -- remains the floor; a side stair wing avoids punching a pit into the lounge.
 item("UpperRoof",Vector3.new(65,1,49),Vector3.new(-180,28,0),C(160,154,142))
 for _,side in ipairs({-1,1}) do item("UpperEndWall",Vector3.new(64,13,1),Vector3.new(-180,21.5,side*24),C(136,130,119)) end
 item("UpperEastWall",Vector3.new(1,13,48),Vector3.new(-148,21.5,0),C(141,133,121))
 item("UpperWestWall",Vector3.new(1,13,36),Vector3.new(-212,21.5,-6),C(141,133,121))
 item("UpperDoorLintel",Vector3.new(1,3,12),Vector3.new(-212,26.5,18),C(141,133,121))
 item("StairWingFoundation",Vector3.new(24,1,56),Vector3.new(-222,-0.4,0),C(91,84,74))
 item("StairWingRoof",Vector3.new(24,1,56),Vector3.new(-222,28,0),C(160,154,142))
 item("StairWingWall",Vector3.new(1,28,56),Vector3.new(-234,14,0),C(141,133,121))
 for _,side in ipairs({-1,1}) do item("StairWingEnd",Vector3.new(24,28,1),Vector3.new(-222,14,side*28),C(141,133,121)) end
 for k=1,15 do item("HouseStair",Vector3.new(12,k,2.7),Vector3.new(-222,k/2,-20+k*2.5),C(104,79,57),Enum.Material.WoodPlanks) end
 item("UpperHouseLanding",Vector3.new(24,1,10),Vector3.new(-222,14.5,22),C(104,79,57),Enum.Material.WoodPlanks)
 item("BedroomWall",Vector3.new(48,13,1),Vector3.new(-188,21.5,-6),C(136,130,119))
 item("BedroomWallRight",Vector3.new(8,13,1),Vector3.new(-152,21.5,-6),C(136,130,119))
 C3.kirillDoor=item("KirillRoomDoor",Vector3.new(8,12,0.5),Vector3.new(-160,21,-6),C(88,71,61),Enum.Material.Wood)
 C3.doorClosed=C3.kirillDoor.CFrame; C3.doorOpen=CFrame.new(C3.Pos(-164,21,-6))*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(4,0,0)
 item("Bed",Vector3.new(7,2,12),Vector3.new(-202,16.5,15),C(67,82,107),Enum.Material.Fabric)
 item("Desk",Vector3.new(10,1,5),Vector3.new(-184,18,20),C(99,79,64),Enum.Material.Wood)
 C3.kirill=secretActor(h,"silv3r_candy","Кирилл",CFrame.lookAt(C3.Pos(-184,15.2,15),C3.Pos(-184,18,22)))
 C3.kirill:SetAttribute("ProtectedCivilian",true); C3.kirillPose={}
 for _,motor in ipairs(C3.kirill:GetDescendants()) do if motor:IsA("Motor6D") then C3.kirillPose[motor]=motor.C0 end end
 C2.SitRig(C3.kirill)
 local phone=item("KirillPhone",Vector3.new(0.7,0.1,1.3),Vector3.new(-184,18.6,19),C(35,65,91),Enum.Material.Glass); light(phone,C(105,150,195),6,0.4)
 for _,pos in ipairs({Vector3.new(-187,26,5),Vector3.new(-160,26,-15),Vector3.new(-223,26,0)}) do C3.Lamp(h,C3.Pos(pos.X,pos.Y,pos.Z),36,2.3,"HomeFillLamp") end
 -- Kirill's upstairs room gets real emissive tubes plus local point lights:
 -- cool blue near the desk and a softer violet accent behind the bed.
 for _,spec in ipairs({
  {name="KirillNeonBlue",size=Vector3.new(18,0.16,0.12),pos=Vector3.new(-184,25.6,23.35),color=C(77,166,255)},
  {name="KirillNeonViolet",size=Vector3.new(15,0.16,0.12),pos=Vector3.new(-184,25.6,-5.35),color=C(177,105,255)},
 }) do
  local tube=item(spec.name,spec.size,spec.pos,spec.color,Enum.Material.SmoothPlastic)
  tube.Material=Enum.Material.Neon; tube.CanCollide=false; tube.CanTouch=false; tube.CanQuery=false
  light(tube,spec.color,24,0.9)
 end
end
function C3.Build()
 -- Chapter III rebuilt around one continuous route and a traversable tower.
 -- Keep world dressing separate from collision-critical geometry.
 C3.map=Instance.new("Model"); C3.map.Name="Chapter3Singularity"; C3.map.Parent=levelFolder
 C3.zones={}; C3.redLights={}; C3.moduleParts={}; C3.connections=C3.connections or {}
 C3.structure=Instance.new("Model"); C3.structure.Name="C3_CollisionAndGameplay"; C3.structure.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.structure.Parent=C3.map
 C3.BuildHome()
 C3.backdrop=Instance.new("Model"); C3.backdrop.Name="Chapter3CityBackdrop"; C3.backdrop.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.backdrop.Parent=C3.map

 local function streetPart(name,size,x,y,z,color,material,parent)
  return C3.Part(parent or C3.backdrop,name,size,C3.Pos(x,y,z),color,material)
 end
 local function sign(parent,name,text,at,color)
  local plate=C3.Part(parent,name,Vector3.new(7,3,0.35),at,color,Enum.Material.Metal)
  plate.CFrame*=CFrame.Angles(0,math.pi/2,0)
  plate.CanCollide=false
  local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=35; gui.Parent=plate
  local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=text; label.TextColor3=C(238,241,236); label.TextStrokeTransparency=0.6; label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.Parent=gui
  return plate
 end

 -- Continuous segmented road and kerbs; every physical part stays below 256 studs.
 for segment=0,4 do
  local center=-14+segment*202
  streetPart("MainStreetAsphalt",Vector3.new(202.5,1,84),center,-0.55,0,C(43,48,57),Enum.Material.Asphalt)
  for _,side in ipairs({-1,1}) do
   streetPart("RaisedCurb",Vector3.new(202.5,0.8,2),center,0,side*43,C(157,158,154),Enum.Material.Concrete)
   streetPart("ContinuousSidewalk",Vector3.new(202.5,0.5,11),center,0.05,side*49,C(111,116,121),Enum.Material.Concrete)
   streetPart("StreetEdgeWall",Vector3.new(202.5,8,1),center,4,side*104,C(55,63,76),Enum.Material.Concrete)
  end
 end
 for _,side in ipairs({-1,1}) do
  for n=0,19 do
   local x=-100+n*50
   streetPart("LaneDash",Vector3.new(16,0.04,0.35),x,0.02,0,C(220,195,126),Enum.Material.SmoothPlastic)
   local pole=streetPart("StreetLampPole",Vector3.new(0.45,11,0.45),x,5.5,side*43,C(48,57,70),Enum.Material.Metal)
   local arm=streetPart("StreetLampArm",Vector3.new(4,0.3,0.3),x+side*1.5,10.7,side*43,C(48,57,70),Enum.Material.Metal)
   C3.Lamp(C3.backdrop,C3.Pos(x+side*3,10.25,side*42),24,1.15,"WarmStreetLamp")
  end
 end

 -- A restrained skyline and ten readable street fronts, not blank wall slabs.
 for block=1,10 do
  local x=-35+(block-1)*95
  local height=30+(block*17)%38
  for _,side in ipairs({-1,1}) do
   local z=side*82
   local facadeColor=block%3==0 and C(59,76,91) or block%3==1 and C(89,83,78) or C(68,81,91)
   streetPart("BlockFacade",Vector3.new(72,height,22),x,height/2,z,facadeColor,Enum.Material.Concrete)
   streetPart("RoofCornice",Vector3.new(75,0.9,24),x,height+0.45,z,C(39,48,61),Enum.Material.Metal)
   streetPart("StorefrontBase",Vector3.new(58,7,0.35),x,3.7,z-side*11.2,C(33,48,59),Enum.Material.Glass)
   for floor=1,math.floor(height/10) do
    streetPart("LitWindowBand",Vector3.new(59,3.2,0.2),x,8+floor*9,z-side*11.25,block%4==0 and C(206,173,111) or C(100,150,168),Enum.Material.Glass)
    streetPart("WindowDivider",Vector3.new(0.35,4.2,0.25),x,8+floor*9,z-side*11.4,C(43,54,67),Enum.Material.Metal)
   end
   streetPart("RoofVent",Vector3.new(8,2.5,5),x-18,height+1.6,z,C(43,54,67),Enum.Material.Metal)
   streetPart("FacadeAwnings",Vector3.new(61,0.6,4),x,7.6,z-side*13,C(119,84,72),Enum.Material.Fabric)
  end
 end

 local districtX={80,255,430,605,780}
 local districtName={"ЖИЛОЙ РАЙОН","ТОРГОВАЯ УЛИЦА","ТРАНСПОРТНЫЙ УЗЕЛ","КВАРТАЛ НТЯН","ПЛОЩАДЬ БАШНИ"}
 local districtColor={C(83,153,130),C(205,157,86),C(101,154,190),C(115,111,184),C(196,93,88)}
 for i,x in ipairs(districtX) do
  local color=districtColor[i]
  for _,side in ipairs({-1,1}) do
   streetPart("DistrictGateFrame",Vector3.new(1,10,1),x-65,5,side*34,color,Enum.Material.Metal)
  end
  streetPart("DistrictGateHeader",Vector3.new(2,2,70),x-65,10.5,0,C(37,47,62),Enum.Material.Metal)
  sign(C3.backdrop,"DistrictTitle",districtName[i],C3.Pos(x-65,7.4,0),color)
  -- Combat cover is waist high and offset so every encounter has at least two paths.
  streetPart("StreetCover",Vector3.new(14,3,5),x-24,1.5,-20,C(63,77,91),Enum.Material.Metal)
  streetPart("StreetCover",Vector3.new(14,3,5),x+24,1.5,20,C(63,77,91),Enum.Material.Metal)
  for _,side in ipairs({-1,1}) do
   streetPart("RouteBarrier",Vector3.new(34,5,2),x+side*42,2.5,side*31,C(184,139,72),Enum.Material.Metal)
  end
  local car=streetPart("WreckedCar",Vector3.new(12,3.4,6),x-8,1.7,i%2==0 and 25 or -27,C(48,55,68),Enum.Material.Metal)
  car.CFrame*=CFrame.Angles(0,math.rad(i%2==0 and 13 or -17),0)
  local lamp=streetPart("WreckBeacon",Vector3.new(0.4,0.4,0.4),x-8,3.5,i%2==0 and 25 or -27,C(217,91,69),Enum.Material.Neon); lamp.CanCollide=false
  C3.Lamp(C3.backdrop,C3.Pos(x,9,0),35,1.3,"DistrictFill")
  local z={index=i,center=C3.Pos(x,4,0),start=C3.Pos(x-62,4,0),exit=C3.Pos(x+67,4,0),wave=0,rounds=i==3 and 3 or 2,cleared=false,objective=false,covers={}}
  z.gate=streetPart("DistrictGate",Vector3.new(1,12,82),x+78,6,0,C(57,78,99),Enum.Material.Metal)
  z.gateClosed=z.gate.CFrame
  z.covers={C3.Pos(x-17,4,-20),C3.Pos(x+31,4,20)}
  z.panel=streetPart("SignalRelay",Vector3.new(2.5,3.4,2),x+37,1.8,17,color,Enum.Material.Metal)
  local screen=streetPart("RelayScreen",Vector3.new(0.2,1.6,1.8),x+35.7,2.7,17,C(68,217,175),Enum.Material.Neon); screen.CanCollide=false
  C3.Prompt(z.panel,"Отключить ретранслятор",function(p) C3.CompleteObjective(p,z) end)
  local doorZ=43
  z.spawnDoor=streetPart("DeploymentDoor",Vector3.new(18,12,1),x,6,doorZ,C(51,65,84),Enum.Material.Metal)
  z.spawnClosed=z.spawnDoor.CFrame; z.spawnPos=C3.Pos(x,4,doorZ+6)
  streetPart("DeploymentBayFloor",Vector3.new(22,0.8,21),x,-0.2,doorZ+10,C(52,61,73),Enum.Material.Concrete)
  streetPart("DeploymentBayRoof",Vector3.new(22,0.8,21),x,14,doorZ+10,C(39,47,60),Enum.Material.Metal)
  streetPart("DeploymentBayBack",Vector3.new(22,14,0.8),x,7,doorZ+20,C(49,59,73),Enum.Material.Concrete)
  streetPart("DeploymentBayLeft",Vector3.new(0.8,14,21),x-11,7,doorZ+10,C(49,59,73),Enum.Material.Concrete)
  streetPart("DeploymentBayRight",Vector3.new(0.8,14,21),x+11,7,doorZ+10,C(49,59,73),Enum.Material.Concrete)
  local med=streetPart("MedicalKit",Vector3.new(2,1,2),x-30,0.5,-27,C(170,70,70),Enum.Material.Metal); local used={}
  C3.Prompt(med,"Аптечка",function(p) if not used[p] then local _,hum=C3.Root(p); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+65); used[p]=true; med.Color=C(82,91,96) end end end)
 end

 -- District signatures: pocket park, market awnings, elevated road, glass offices, plaza barricades.
 for _,x in ipairs({45,105}) do
  local trunk=streetPart("ParkTreeTrunk",Vector3.new(1.4,7,1.4),x,3.5,-34,C(93,72,56),Enum.Material.Wood)
  local crown=streetPart("ParkTreeCanopy",Vector3.new(10,9,10),x,9,-34,C(58,123,91),Enum.Material.Grass); crown.Shape=Enum.PartType.Ball; crown.CanCollide=false
 end
 for _,x in ipairs({220,275,330}) do
  streetPart("MarketAwning",Vector3.new(17,0.8,7),x,8,-34,C(192,94,77),Enum.Material.Fabric)
  streetPart("MarketCounter",Vector3.new(13,3,3),x,1.5,-31,C(103,76,58),Enum.Material.Wood)
 end
 streetPart("OverpassDeck",Vector3.new(74,2,76),430,17,0,C(78,87,98),Enum.Material.Concrete)
 for _,x in ipairs({400,460}) do for _,side in ipairs({-1,1}) do streetPart("OverpassPier",Vector3.new(5,17,6),x,8.5,side*31,C(81,90,101),Enum.Material.Concrete) end end
 for _,side in ipairs({-1,1}) do
  for _,x in ipairs({570,640}) do
   local t=streetPart("NTyanOffice",Vector3.new(24,54,21),x,27,side*77,C(68,100,120),Enum.Material.Glass); t.Transparency=0.12
   streetPart("OfficeRoofBeacon",Vector3.new(2,3,2),x,55,side*77,C(208,60,70),Enum.Material.Neon)
  end
 end
 for _,x in ipairs({744,815}) do
  streetPart("PlazaSearchlight",Vector3.new(0.7,12,0.7),x,6,-33,C(69,81,99),Enum.Material.Metal)
  local beacon=streetPart("PlazaBeacon",Vector3.new(2,0.3,2),x,12,-33,C(221,82,79),Enum.Material.Neon); beacon.CanCollide=false
 end

 -- Readable distant skyline, deliberately behind the combat corridor.
 for block=1,9 do
  local x=-50+block*112; local h=48+(block*19)%75
  for _,side in ipairs({-1,1}) do
   local z=side*155
   streetPart("FarSkylineTower",Vector3.new(66,h,42),x,h/2,z,C(45+block%3*8,56,76),Enum.Material.Concrete)
   for floor=1,math.floor(h/14) do streetPart("FarWindowStrip",Vector3.new(54,1.1,0.15),x,floor*14,z-side*21.1,C(111,147,161),Enum.Material.Glass) end
  end
 end

 -- Approach plaza connects the last street checkpoint directly to tower entry.
 streetPart("TowerApproach",Vector3.new(92,1,82),890,-0.55,0,C(65,68,77),Enum.Material.Concrete,C3.structure)
 for _,side in ipairs({-1,1}) do streetPart("ApproachLightStrip",Vector3.new(90,0.18,0.35),890,0.08,side*31,C(91,210,183),Enum.Material.Neon,C3.structure) end

 -- Tower's outer silhouette is a landmark; the playable shell is built below.
 C3.landmark=Instance.new("Model"); C3.landmark.Name="SingularityLandmark"; C3.landmark.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.landmark.Parent=C3.map
 C3.Part(C3.landmark,"TowerFoundation",Vector3.new(104,2,104),C3.Pos(960,-1,0),C(36,45,61),Enum.Material.Metal)
 for floor=0,4 do
  local y=floor*24+12
  for _,side in ipairs({-1,1}) do
   local marker=C3.Part(C3.landmark,"TowerSignalMarker",Vector3.new(1.2,3.5,2.5),C3.Pos(960+side*52,y,0),C(153,56,49),Enum.Material.Metal)
   table.insert(C3.redLights,marker); light(marker,C(210,63,53),16,0.22)
  end
  local deckY=floor*24+0.6
  for _,side in ipairs({-1,1}) do
   C3.Beam(C3.landmark,"TowerServiceDeckEdge",C3.Pos(910,deckY,side*50),C3.Pos(1010,deckY,side*50),0.9,C(126,138,140))
   C3.Beam(C3.landmark,"TowerServiceDeckEdge",C3.Pos(960+side*50,deckY,-50),C3.Pos(960+side*50,deckY,50),0.9,C(126,138,140))
  end
 end
 C3.BuildRadioMast()
 C3.beacon=C3.Part(C3.landmark,"TowerBeacon",Vector3.new(3,2,3),C3.Pos(960,325,0),C(183,52,46),Enum.Material.SmoothPlastic); table.insert(C3.redLights,C3.beacon); light(C3.beacon,C(235,65,55),42,0.7)
 C3.shield=C3.Part(C3.landmark,"InvulnerableTowerShield",Vector3.new(155,370,155),C3.Pos(960,175,0),C(125,45,95),Enum.Material.ForceField)
 C3.shield.Shape=Enum.PartType.Ball; C3.shield.CanCollide=false; C3.shield.CanTouch=false; C3.shield.CanQuery=false; C3.shield.Transparency=0.94

 -- Five walkable tower floors, each with a real stair route to the next deck.
 local floorThemes={
  {name="СЕРВИСНЫЙ ЭТАЖ",floor=C(76,112,124),accent=C(225,164,77),prop="ServiceCabinet"},
  {name="СИЛОВОЙ ЯРУС",floor=C(65,84,104),accent=C(230,117,75),prop="PowerGenerator"},
  {name="СЕРВЕРНЫЙ ЯРУС",floor=C(55,71,91),accent=C(101,201,197),prop="ServerRack"},
  {name="АНТЕННЫЙ ЯРУС",floor=C(73,84,101),accent=C(186,106,203),prop="AntennaRelay"},
  {name="ВЕРХНИЙ ПОСТ",floor=C(63,70,88),accent=C(230,75,79),prop="DefenseConsole"},
 }
 local function towerPart(name,size,x,y,z,color,material)
  return C3.Part(C3.map,name,size,C3.Pos(x,y,z),color,material)
 end
 for deck=1,5 do
  local stage=deck+5; local y=(deck-1)*24; local theme=floorThemes[deck]
  local function slab(sx,sz,cx,cz)
   towerPart("TowerFloor",Vector3.new(sx,0.8,sz),960+cx,y,cz,theme.floor,Enum.Material.Metal)
  end
  -- Keep the stairwell open on the first four floors; cap it with a full
  -- crown deck so the terminal and recovered modules sit on solid ground.
  if stage<10 then
   slab(26,82,-31,0); slab(26,82,31,0); slab(36,31,0,-25.5); slab(36,31,0,25.5)
  else
   slab(82,82,0,0)
  end
  local wall=theme.floor
  towerPart("TowerBackWall",Vector3.new(82,22,1),960,y+11,-41,wall,Enum.Material.Metal)
  -- West entry is aligned to the road; split wall leaves a real doorway.
  towerPart("TowerWestWall",Vector3.new(1,22,32),919.5,y+11,-25,wall,Enum.Material.Metal)
  towerPart("TowerWestWall",Vector3.new(1,22,32),919.5,y+11,25,wall,Enum.Material.Metal)
  towerPart("TowerEntryLintel",Vector3.new(1,4,18),919.5,y+20,0,wall,Enum.Material.Metal)
  towerPart("TowerEastWall",Vector3.new(1,22,82),1000.5,y+11,0,wall,Enum.Material.Metal)
  -- Front deployment door opens only while a finite guard wave enters.
  towerPart("TowerFrontWall",Vector3.new(32,22,1),935,y+11,41,wall,Enum.Material.Metal)
  towerPart("TowerFrontWall",Vector3.new(32,22,1),985,y+11,41,wall,Enum.Material.Metal)
  towerPart("TowerDoorLintel",Vector3.new(18,4,1),960,y+20,41,wall,Enum.Material.Metal)
  local z={index=stage,center=C3.Pos(960,y+4,0),wave=0,rounds=stage==10 and 3 or 2,cleared=false,objective=false,covers={}}
  C3.zones[stage]=z
  z.start=stage==6 and C3.Pos(930,y+4,0) or C3.Pos(984,y+4,0)
  z.exit=stage<10 and C3.Pos(984,y+28,0) or C3.Pos(960,y+4,0)
  if stage<10 then
   z.gate=towerPart("TowerStairGate",Vector3.new(1,14,14),984,y+27,0,C(49,66,83),Enum.Material.Metal)
   z.gateClosed=z.gate.CFrame
  end
  z.spawnDoor=towerPart("DeploymentDoor",Vector3.new(18,12,1),960,y+6,41,C(51,65,84),Enum.Material.Metal)
  z.spawnClosed=z.spawnDoor.CFrame; z.spawnPos=C3.Pos(960,y+4,51)
  if stage==10 then z.gate=z.spawnDoor; z.gateClosed=z.spawnDoor.CFrame end
  towerPart("DeploymentBayFloor",Vector3.new(20,0.8,20),960,y,52,C(48,59,74),Enum.Material.Metal)
  towerPart("DeploymentBayRoof",Vector3.new(20,0.8,20),960,y+16,52,C(37,47,61),Enum.Material.Metal)
  towerPart("DeploymentBayBack",Vector3.new(20,16,0.8),960,y+8,62,C(48,59,74),Enum.Material.Metal)
  towerPart("DeploymentBayLeft",Vector3.new(0.8,16,20),950,y+8,52,C(48,59,74),Enum.Material.Metal)
  towerPart("DeploymentBayRight",Vector3.new(0.8,16,20),970,y+8,52,C(48,59,74),Enum.Material.Metal)
  if stage<10 then
   for step=1,20 do
    local x=936+(step-0.5)*2.4; local rise=(step-0.5)*1.2
    towerPart("TowerStair",Vector3.new(2.65,0.65,13),x,y+rise,0,C(138,155,170),Enum.Material.Metal)
    if step%5==0 then for _,side in ipairs({-1,1}) do towerPart("StairPost",Vector3.new(0.45,3,0.45),x,y+rise+1.7,side*7,C(179,190,195),Enum.Material.Metal) end end
   end
   for _,side in ipairs({-1,1}) do
    local rail=C3.Beam(C3.map,"StairHandrail",C3.Pos(935,y+3,side*7),C3.Pos(984,y+27,side*7),0.4,C(180,192,199)); rail.Parent=C3.structure
   end
   for _,side in ipairs({-1,1}) do
    towerPart("StairwellPartition",Vector3.new(58,15,0.5),960,y+12,side*10,C(108,157,171),Enum.Material.Glass).Transparency=0.55
   end
  end
  -- Deck-specific machinery sits against walls, leaving a wide combat loop.
  for n=1,3 do
   local x=930+n*15; local prop=towerPart(theme.prop,Vector3.new(7,7,5),x,y+3.9,-30,theme.floor,Enum.Material.Metal)
   for stripe=1,3 do towerPart("MachineStatusLight",Vector3.new(0.25,0.4,3),x-3.55+stripe*1.7,y+4,-27.4,theme.accent,Enum.Material.Neon).CanCollide=false end
  end
  for _,side in ipairs({-1,1}) do
   local cover=towerPart("TowerCombatCover",Vector3.new(10,3,4),960+side*28,y+1.9,-20,C(52,68,84),Enum.Material.Metal)
   table.insert(z.covers,cover.Position+Vector3.new(side*7,2,0))
   C3.Lamp(C3.map,C3.Pos(960+side*23,y+18,0),34,1.8,"TowerDeckLamp")
  end
  -- Large high-contrast floor plaque is legible before the first shot.
  local plaque=towerPart("TowerFloorPlaque",Vector3.new(0.3,5,18),919.2,y+13,0,theme.accent,Enum.Material.Neon); plaque.CanCollide=false
  local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Right; gui.PixelsPerStud=25; gui.Parent=plaque
  local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text=theme.name; text.TextColor3=C(245,242,230); text.TextScaled=true; text.Font=Enum.Font.GothamBold; text.Parent=gui
  z.panel=towerPart("ObjectiveConsole",Vector3.new(2.4,3.2,2),930,y+1.8,-25,theme.accent,Enum.Material.Metal)
  local panelLight=towerPart("ConsoleScreen",Vector3.new(0.2,1.6,1.6),928.7,y+2.7,-25,C(78,223,179),Enum.Material.Neon); panelLight.CanCollide=false
  C3.Prompt(z.panel,stage==10 and "Главный терминал" or "Изолировать реле",function(p) C3.CompleteObjective(p,z) end)
  z.breaker=towerPart("HardwareBreaker",Vector3.new(2.4,3.2,2),990,y+1.8,-25,C(203,131,69),Enum.Material.Metal)
  C3.Prompt(z.breaker,"Подтвердить размыкатель",function(p)
   if C3.stage~=stage or not z.cleared then return end
   if p:GetAttribute("Hero")=="Artem" and #C3.Living()>1 then NotifyRE:FireClient(p,"Этот размыкатель держит Демид.",2); return end
   z.assaultReady=true; C3.confirmPlayer=p; C3.confirmUntil=os.clock()+12
   NotifyRE:FireAllClients("Размыкатель удерживается. Артём может продолжить у консоли.",3)
  end,2.5)
  local med=towerPart("MedicalKit",Vector3.new(2,1,2),940,y+0.5,27,C(170,70,70),Enum.Material.Metal); local used={}
  C3.Prompt(med,"Аптечка",function(p) if not used[p] then local _,hum=C3.Root(p); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+65); used[p]=true; med.Color=C(82,91,96) end end end)
  if stage>=6 and stage<=9 then C3.CommunicationEquipment(stage,y) end
 end

 C3.previewGuards={}
 for k=1,4 do
  local cfg=table.clone(Types.Pistol); cfg.Male=false; cfg.Name="Охрана башни"
  local rig=buildRig(cfg,CFrame.lookAt(C3.Pos(940+k*9,102,30),C3.Pos(960,100,0))); rig.Parent=C3.landmark; c2Dress(rig,false); anchorAll(rig); table.insert(C3.previewGuards,rig)
 end
 -- Landmark geometry is a non-colliding visual shell; only the interior model
 -- controls player movement and tower traversal.
 for _,object in ipairs(C3.landmark:GetDescendants()) do
  if object:IsA("BasePart") then object.CanCollide=false; object.CanTouch=false; object.CanQuery=false end
 end
 C3.case=C3.Part(C3.map,"ModuleCase",Vector3.new(6,1,4),C3.Pos(960,97,0),C(29,42,58),Enum.Material.Metal)
 for i=1,2 do
  local module=C3.Part(C3.map,i==1 and "ControlModule" or "MemoryModule",Vector3.new(1.7,0.45,2),C3.case.Position+Vector3.new((i-1.5)*2.2,0.8,0),i==1 and C(80,200,174) or C(109,165,224),Enum.Material.Metal)
  C3.moduleParts[i]=module; C3.Prompt(module,i==1 and "Забрать контроллер" or "Забрать память",function(p) C3.TakeModule(p,i) end)
 end
end

-- END CHAPTER THREE WORLD
function C3.MoveParty(position,look)
 for i,p in ipairs(C3.party) do
  local r=C3.Root(p)
  if r then
   local slotPosition=position+Vector3.new(0,0,(i-1)*4)
   local flatLook=Vector3.new(look.X,slotPosition.Y,look.Z)
   if (flatLook-slotPosition).Magnitude<0.001 then flatLook=slotPosition+Vector3.new(0,0,-1) end
   p.Character:PivotTo(CFrame.lookAt(slotPosition,flatLook,Vector3.yAxis)); r.AssemblyLinearVelocity=Vector3.zero
  end
 end
end
function C3.Intro()
 C3.Scene(true); FadeRE:FireAllClients(true,"ГЛАВА III • БАШНЯ НЕЙРО-СИНГУЛЯРНОСТИ"); task.wait(1)
 local factory,neuro,assistant,screen=C3.BuildVillain()
 focusStreaming(neuro.Head.Position); prepareView(neuro.Head.Position)
 cameraPlan(neuro.Head.Position+Vector3.new(-9,2,-16),neuro.Head.Position+Vector3.new(-6,1,-10),neuro.Head.Position,2,60,52)
 CutsceneRE:FireAllClients("reveal")
 C3.Say(ANDROID_NAME,"Они уничтожили один из наших незначительных заводов... Это даже потерей тяжело назвать. Скоро весь мир покроется нашими рядами, и всё будет по нашим правилам. Идеальное общество, всё будет замечательно. Но хватит разговоров — пора действовать",12)
 local neuroPivot=neuro:GetPivot()
 local assistantFocus=Vector3.new(assistant.Head.Position.X,neuroPivot.Position.Y,assistant.Head.Position.Z)
 moveModel(neuro,CFrame.lookAt(neuroPivot.Position,assistantFocus,Vector3.yAxis),0.8)
 C3.Say(ANDROID_NAME,"Эй, Тян C-3B1! Как успехи с нашим проектом Вышки Нейро-Сингулярной Связи?",5)
 moveModel(assistant,assistant:GetPivot()+Vector3.new(-6,0,0),1.5,true)
 cameraPlan(assistant.Head.Position+Vector3.new(3,1,-9),assistant.Head.Position+Vector3.new(2,1,-8),assistant.Head.Position,1,54,52)
 C3.Say("Тян C-3B1","Всё успешно, мы готовы запустить её в центре одного из крупных городов. Хммм... что насчёт города, где сосредоточено больше всего филиалов и компаний НТЯН?",8)
 cameraPlan(neuro.Head.Position+Vector3.new(-5,1,-10),neuro.Head.Position+Vector3.new(-4,1,-8),neuro.Head.Position,1,55,50)
 C3.Say(ANDROID_NAME,"Идеальный выбор. Мы подчиним тысячи людей за секунды и ускорим наше влияние в тысячи раз. Нам больше не придётся отлавливать людей или клонировать их вручную. Начинаем!",9)
 FadeRE:FireAllClients(true,""); task.wait(0.8)
 C3.MoveParty(C3.Pos(-193,4,3),C3.Pos(-187,7,22)); focusStreaming(C3.Pos(-187,5,0)); prepareView(C3.Pos(-187,5,0))
 C3.buddy=secretActor(C3.map,C3.party[1]:GetAttribute("Hero")=="Artem" and "ZamestitelDiomchica" or "eurtyoeyrntiu","Напарник",CFrame.lookAt(C3.Pos(-181,0.5,-5),C3.Pos(-193,3,3)))
 if C3.coop then C3.buddy:Destroy(); C3.buddy=nil end
 cameraPlan(C3.Pos(-196,9,-15),C3.Pos(-194,8,-12),C3.Pos(-187,6,10),1.2,60,56)
 CutsceneRE:FireAllClients("reveal")
 C3.Say("Демид","Мы им завод снесли, а крайними всё равно оказались мы. Я до сих пор не понимаю, кто здесь с кем воюет.",5)
 C3.Say("Артём","И почему НТЯН ищет нас, а не тех, кто людей переделывает? Тут явно не вся картина.",4)
 C3RE:FireAllClients("signal"); ShakeRE:FireAllClients(2); task.wait(2)
 for i,p in ipairs(C3.party) do
  if C3.Root(p) then
   local windowPosition=C3.Pos(-153,4,(i-1)*5)
   local windowView=CFrame.lookAt(windowPosition,C3.Pos(960,100,0),Vector3.yAxis)
   tweenCharTo(p.Character,windowView,1.5,true)
  end
 end
 CutsceneRE:FireAllClients("pov",C3.beacon,65)
 C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Артём" or "Демид","Эммм, что это было?",3)
 C3.Say("Демид","Чекни в окно.",3)
 focusStreaming(C3.Pos(960,103,0)); prepareView(C3.Pos(960,103,0))
 C3RE:FireAllClients("binocular",true)
 CutsceneRE:FireAllClients("cam",{cf=CFrame.lookAt(C3.Pos(-153,6,0),C3.Pos(960,103,0),Vector3.yAxis),fov=26,time=1.6}); task.wait(3)
 C3.Say("Артём","Сигнал идёт оттуда. Смотри на охрану наверху.",3)
 C3.Say("Демид","Значит, эту штуку нужно выключить. Сейчас, пока она весь город не накрыла.",4)
 C3RE:FireAllClients("binocular",false)
 C3.Say("Артём","Стой. Кирилл же наверху, в комнате!",3)
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 focusStreaming(C3.Pos(-171,19,4)); prepareView(C3.Pos(-171,19,4))
 C3.MoveParty(C3.Pos(-171,19,4),C3.kirill.Head.Position)
 TweenService:Create(C3.kirillDoor,TweenInfo.new(0.7),{CFrame=C3.doorOpen}):Play(); task.wait(0.8)
 cameraPlan(C3.Pos(-205,24,2),C3.Pos(-203,23,4),C3.kirill.Head.Position,1.2,60,56)
 CutsceneRE:FireAllClients("reveal")
 C3.Say("Кирилл","Тянки... тянки...",3)
 for motor,cf in pairs(C3.kirillPose) do if motor.Parent then motor.C0=cf end end
 for _=1,4 do for _,m in ipairs(C3.kirill:GetDescendants()) do if m:IsA("Motor6D") and m.Part0 and m.Part1 then m.Part1.CFrame=m.Part0.CFrame*m.C0*m.C1:Inverse() end end end
 moveModel(C3.kirill,C3.kirill:GetPivot()+Vector3.new(0,0.8,0),1)
 for _,side in ipairs({-1,1}) do
  local eye=C3.Part(C3.kirill,"HypnotizedEye",Vector3.new(0.2,0.13,0.08),Vector3.zero,C(235,35,35),Enum.Material.Neon); eye.CanCollide=false
  eye.CFrame=C3.kirill.Head.CFrame*CFrame.new(side*0.4,0,-0.55); light(eye,C(255,35,35),4,0.4)
 end
 C3.Say(ANDROID_NAME,"Устранить Артёма и Демида.",3)
 moveModel(C3.kirill,C3.kirill:GetPivot()*CFrame.Angles(0,math.pi,0),0.8)
 moveModel(C3.kirill,C3.kirill:GetPivot()+Vector3.new(0,0,-6),2.5,true)
 C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Артём" or "Демид","Ладно, только без летального исхода, мы не будем его бить, ок? Просто уходим!",5)
 TweenService:Create(C3.kirillDoor,TweenInfo.new(0.65),{CFrame=C3.doorClosed}):Play(); task.wait(0.7)
 if C3.coop then
  C3.Say("Демид","Дверь держит. Но надолго его так не оставишь.",3)
  C3.Say("Артём","Камера работает. Оба идём к башне. Чем быстрее отключим сигнал, тем быстрее вернёмся.",4)
 else
  C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Демид" or "Артём","Ахх, чёт у меня нет никакого желания прямо сейчас выходить в это пекло. Я лучше останусь присмотреть за Кириллом, чтобы тут всё окончательно не пошло наперекосяк!",8)
 end
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 C3.MoveParty(C3.Pos(-35,4,0),C3.Pos(100,4,0)); focusStreaming(C3.Pos(50,5,0)); prepareView(C3.Pos(50,5,0))
 C3.Scene(false); CutsceneRE:FireAllClients("reveal"); MusicRE:FireAllClients("intro")
 factory:Destroy(); C3.Activate(1)
end
function C3.ClearMobs()
 for m in pairs(C3.mobs) do if m.Parent then m:Destroy() end end; C3.mobs={}
end
function C3.Nearest(pos)
 local best,dist
 for _,p in ipairs(C3.Living()) do local r=C3.Root(p); local d=(r.Position-pos).Magnitude; if not dist or d<dist then best=p; dist=d end end
 return best,dist
end
function C3.Spawn(stage,pos,civilian,elite,k)
 local cfg=table.clone(Types.Pistol); cfg.Male=civilian; if civilian then cfg.Gun=false end; cfg.Name=civilian and "Под сигналом" or elite and "Элитная охрана" or "Патруль"
 cfg.Hair=civilian and C(65+k*9,48,37) or C(62,43,87); cfg.Shirt=civilian and C(80+k*8,72,67) or elite and C(55,40,72) or C(45,62,85)
 local m,h,r,j=buildRig(cfg,CFrame.new(pos)); m.Parent=C3.map
 if not civilian then c2Dress(m,false) end
 c2Mobilize(m,h,r); h.MaxHealth=civilian and 80 or (elite and 145 or 85)*(C3.coop and 1.4 or 1); h.Health=h.MaxHealth; h.WalkSpeed=civilian and 9 or 13
 m:SetAttribute("Enemy",not civilian)
 if civilian then C3.ProtectCivilian(m,h) end
 local e={stage=stage,hum=h,root=r,civilian=civilian,down=false,last=0,stun=0,joints=j,base={},pathAt=0,waypoints={},waypoint=1,tactic=k%3,cover=C3.zones[stage].covers[(k-1)%2+1]}
 for name,motor in pairs(j) do e.base[name]=motor.C0 end; C3.mobs[m]=e
 if not civilian then table.insert(C3.connections,h.Died:Connect(function() e.down=true; ragdoll(m); Debris:AddItem(m,12) end)) end
 local serial=C3.serial
 task.spawn(function()
  while C3.active and C3.serial==serial and m.Parent and h.Health>0 and not e.down do
   if not introActive and os.clock()>=e.stun then
    local p,d=C3.Nearest(r.Position)
    if p and d<180 then
     local pr,ph=C3.Root(p); local goal=pr.Position
     if not civilian and d<65 then
      if e.tactic==1 then goal=e.cover else goal+=Vector3.new(math.sin(os.clock()*0.5+k)*12,0,k%2==0 and 10 or -10) end
     end
     if os.clock()-e.pathAt>1.6 then
      e.pathAt=os.clock()
      local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false})
      local ok=pcall(function() path:ComputeAsync(r.Position,goal) end)
      e.waypoints=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints() or {}; e.waypoint=2
     end
     local waypoint=e.waypoints[e.waypoint]
     if waypoint and (r.Position-waypoint.Position).Magnitude<4 then e.waypoint+=1; waypoint=e.waypoints[e.waypoint] end
     if d>(civilian and 4 or 22) or not civilian and e.tactic~=0 then h:MoveTo(waypoint and waypoint.Position or goal) end
     if civilian and d<5 and os.clock()-e.last>2.5 then
      if not e.grabStart then e.grabStart=os.clock(); C3RE:FireClient(p,"grab")
      elseif os.clock()-e.grabStart>=0.8 then e.last=os.clock(); e.grabStart=nil; ph:TakeDamage(8); p:SetAttribute("C3GrabbedUntil",os.clock()+1); e.stun=os.clock()+1.2 end
     elseif not civilian and d<100 and os.clock()-e.last>(elite and 1.1 or 1.65) then
      e.last=os.clock(); local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={m,fxFolder}
      local from=m.Head.Position; local hit=workspace:Raycast(from,pr.Position-from,rp)
      if hit and hit.Instance:IsDescendantOf(p.Character) then tracer(from,hit.Position,C(240,170,110)); ph:TakeDamage(elite and 10 or 7) end
     end
    else e.grabStart=nil end
    local angle=math.sin(os.clock()*8)*math.min(r.AssemblyLinearVelocity.Magnitude/18,0.5)
    j.RH.C0=e.base.RH*CFrame.Angles(0,0,angle); j.LH.C0=e.base.LH*CFrame.Angles(0,0,-angle)
    j.LS.C0=e.base.LS*CFrame.Angles(0,0,angle*0.5)
   else h:MoveTo(r.Position) end
   task.wait(0.2)
  end
 end)
 return m
end
function C3.Wave(z)
 local serial=C3.serial; z.wave+=1; z.deploying=true
 TweenService:Create(z.spawnDoor,TweenInfo.new(0.65),{CFrame=z.spawnClosed}):Play(); task.wait(0.8)
 if serial~=C3.serial or not C3.active then return end
 local count=(C3.coop and 6 or 4)+(z.index==10 and 1 or 0)
 for k=1,count do C3.Spawn(z.index,z.spawnPos+Vector3.new((k%2)*3,0,math.floor(k/2)*3),z.index<=4 and k<=2,z.index>=7,k) end
 TweenService:Create(z.spawnDoor,TweenInfo.new(0.8),{CFrame=z.spawnClosed*CFrame.new(0,13,0)}):Play(); task.wait(1)
 if serial==C3.serial then z.deploying=false end
 C3.Send()
end
function C3.Activate(index)
 if index==10 then for _,m in ipairs(C3.previewGuards or {}) do m:Destroy() end; C3.previewGuards={} end
 for _,p in ipairs(C3.party) do if p.Parent and not C3.Root(p) then C3.RestorePlayer(p) end end
 C3.stage=index; C3.checkpoint=index; C3.checkpointPos=C3.zones[index].start
 local z=C3.zones[index]; z.wave=0; z.cleared=false; z.objective=false; z.deployed=false
 currentSpawn=CFrame.lookAt(z.start,z.center)
 for _,p in ipairs(C3.Living()) do c2Grant(p,p:GetAttribute("Hero")=="Artem" and math.min(3,2+math.floor(index/7)) or math.min(5,2+math.floor(index/2))) end
 if index==5 and not C3.shieldSeen then
  C3.shieldSeen=true; C3.Scene(true)
  cameraPlan(C3.Pos(830,17,-55),C3.Pos(834,18,-50),C3.Pos(930,88,0),1.4,60,55)
  C2.ScriptedShot(C3.Pos(884,8,0),false)
  C3.Say("Демид","Да ей вообще плевать на пули!",3)
  C3.Say("Артём","Снаружи не пробить. Сервисный вход подключён к внутренней сети. Поднимаемся к управляющему терминалу и гасим её изнутри.",6)
  C3.Scene(false)
 end
 C3.Send(); C3.Wave(z)
end
function C3.CompleteObjective(p,z)
 if C3.stage~=z.index or not z.cleared or z.objective then return end
 if z.index==10 then C3.OpenHack(p); return end
 if z.index>=6 and not C3.Engineer(p) then
  NotifyRE:FireClient(p,"Размыкатель напротив. Основную панель отключает Артём.",3); return
 end
 if C3.coop and z.index>=6 then
  local helperRoot=C3.confirmPlayer and C3.Root(C3.confirmPlayer)
  local needsPartner=#C3.Living()>1
  if needsPartner and (not z.assaultReady or not C3.confirmUntil or os.clock()>C3.confirmUntil or not helperRoot or C3.confirmPlayer==p or (helperRoot.Position-z.breaker.Position).Magnitude>11) then
   NotifyRE:FireClient(p,"Напарник должен удерживать соседний размыкатель, пока ты работаешь с реле.",3); return
  end
 end
 z.objective=true
 if z.index>=6 and not z.relayCounted then C3.relays+=1; z.relayCounted=true end
 if z.index==8 then C3.key=true end
 z.panel.Color=C(65,170,130)
 TweenService:Create(z.gate,TweenInfo.new(1),{CFrame=z.gateClosed*CFrame.new(0,15,0)}):Play(); z.gate.CanCollide=false
 C3.Send()
end
function C3.OpenHack(p)
 if not C3.CanHack(p) or C3.hacker and C3.hacker~=p then return end
 if not C3.Engineer(p) then NotifyRE:FireClient(p,"Подготовь размыкатель у второй консоли.",3); return end
 C3.hacker=p; C3.hackSerial+=1
 C3.challenge={token=tostring(C3.serial)..":"..C3.hackSerial,expires=os.clock()+120,last=0,steps=0,board=c2CircuitBoard(Random.new()),phase=C3.hackPhase or 1,start=workspace:GetServerTimeNow()}
 C3RE:FireClient(p,"hack",{token=C3.challenge.token,phase=C3.challenge.phase,board=C3.challenge.board,start=C3.challenge.start,steps=0})
end
function C3.CloseHack()
 if C3.hacker and C3.hacker.Parent then C3RE:FireClient(C3.hacker,"hackClose") end
 C3.hacker=nil; C3.challenge=nil
end
function C3.HackInput(p,token,value)
 local ch=C3.challenge; local r=C3.Root(p)
 if not ch or C3.hacker~=p or token~=ch.token then return end
 if not C3.CanHack(p) or not r or (r.Position-C3.zones[10].panel.Position).Magnitude>11 or os.clock()>ch.expires then C3.CloseHack(); return end
 if os.clock()-ch.last<0.12 then return end; ch.last=os.clock()
 if ch.phase==1 then
  local timing=(workspace:GetServerTimeNow()-ch.start)*0.35%1
  if timing>=0.3 and timing<=0.62 then ch.steps+=1 else ch.steps=math.max(0,ch.steps-1) end
  if ch.steps>=3 then C3.hackPhase=2; C3.CloseHack(); C3.OpenHack(p); return end
 elseif ch.phase==2 then
  if typeof(value)~="number" or value%1~=0 or value<1 or value>9 then return end
  ch.board.rotations[value]=(ch.board.rotations[value]+1)%4
  if c2CircuitSolved(ch.board) then C3.hackPhase=3; C3.CloseHack(); C3.OpenHack(p); return end
 elseif ch.phase==3 then
  local others=0; for _,q in ipairs(C3.Living()) do if q~=p then others+=1 end end
  local helperRoot=C3.confirmPlayer and C3.Root(C3.confirmPlayer)
  if others>0 and (not C3.confirmUntil or os.clock()>C3.confirmUntil or not helperRoot or C3.confirmPlayer==p or (helperRoot.Position-C3.zones[10].breaker.Position).Magnitude>11) then NotifyRE:FireClient(p,"Нужно подтверждение напарника у размыкателя.",3); return end
  C3.CloseHack(); C3.Protected(C3.Finale); return
 end
 C3RE:FireClient(p,"hack",{token=ch.token,phase=ch.phase,board=ch.board,start=ch.start,steps=ch.steps})
end
function C3.Finale()
 if C3.towerOff or not C3.active then return end
 C3.towerOff=true; C3.hackPhase=4; C3.Scene(true)
 MusicRE:FireAllClients("stop"); C3RE:FireAllClients("signalOff")
 cameraPlan(C3.Pos(1190,220,-240),C3.Pos(1170,200,-220),C3.Pos(960,170,0),3,62,66)
 for _,p in ipairs(C3.redLights) do
  if p.Parent then p.Color=C(38,49,58); for _,l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Enabled=false end end end
  task.wait(0.08)
 end
 TweenService:Create(C3.shield,TweenInfo.new(2),{Transparency=1}):Play(); C3.shield.CanQuery=false
 for _,e in pairs(C3.mobs) do if e.civilian then e.down=true end end
 task.wait(3)
 C3.MoveParty(C3.Pos(950,100,6),C3.case.Position)
 cameraPlan(C3.Pos(980,109,20),C3.Pos(977,108,18),C3.case.Position,1.3,58,54)
 C3.Say("Демид","Есть! Смотри, свет погас!",3)
 C3.Say("Артём","Не трогай обгоревший блок. Вот эти модули целые. Заберём их: надо понять, что они сделали с Кириллом.",5)
 C3.Scene(false); C3.collecting=true; C3RE:FireAllClients("collect",true)
end
function C3.TakeModule(p,index)
 if not C3.collecting or C3.modules[index] then return end
 local living=C3.Living()
 if #living>1 and ((index==1 and p:GetAttribute("Hero")~="Artem") or (index==2 and p:GetAttribute("Hero")~="Demid")) then NotifyRE:FireClient(p,"Этот блок снимает напарник.",2); return end
 C3.modules[index]=true; C3.moduleParts[index].Transparency=1; C3.moduleParts[index].CanQuery=false
 if not C3.modules[1] or not C3.modules[2] then return end
 C3.collecting=false; C3.Scene(true); MusicRE:FireAllClients("finalSlow")
 cameraPlan(C3.Pos(978,112,24),C3.Pos(975,110,20),C3.case.Position,1.2,58,54)
 if C3.coop then
  C3.Say("Демид","Кирилл замер. Значит, сработало?",3)
  C3.Say("Артём","Передачу остановили. А что уже осталось у него в голове, ещё предстоит выяснить.",4)
 else
  C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Демид • связь" or "Артём • связь","Он больше не ломится к двери... Но всё ещё будто не здесь. Возвращайся. С этой электроникой, может, разберёмся.",5)
 end
 cameraPlan(C3.Pos(1080,110,-110),C3.Pos(1100,120,-130),C3.Pos(940,60,0),4,62,70); task.wait(3)
 FadeRE:FireAllClients(true,"ГЛАВА III ПРОЙДЕНА"); task.wait(1)
 C3RE:FireAllClients("credits",true); task.wait(35); C3RE:FireAllClients("credits",false)
 C3.finished=true; C3.Stop(); returnToMenu()
end
function C3.RestorePlayer(p)
 if C3.recovering[p] then return end; C3.recovering[p]=true
 p:LoadCharacter()
 local char=p.Character; local r=char and char:WaitForChild("HumanoidRootPart",10)
 if r and C3.active then
  c2Hero(p); p:SetAttribute("Chapter",3); char:PivotTo(CFrame.new(C3.checkpointPos or C3.Pos(-35,4,0)))
  c2Grant(p,p:GetAttribute("Hero")=="Artem" and 3 or 5)
  local h=char:FindFirstChildOfClass("Humanoid"); if h then h.Health=h.MaxHealth end
  C3.BindDeath(p)
 end
 C3.recovering[p]=nil
end
function C3.BindDeath(p)
 local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 if not h then return end
 table.insert(C3.connections,h.Died:Connect(function()
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root and C3.active then
   local corpse=p.Character; root.Anchored=true
   C3.Prompt(root,"Помочь напарнику",function(helper)
    if helper~=p and p.Parent and p.Character==corpse and not C3.Root(p) then C3.RestorePlayer(p) end
   end,4)
  end
 end))
end
function C3.RespawnCheckpoint()
 C3.Scene(true); FadeRE:FireAllClients(true,"КОНТРОЛЬНАЯ ТОЧКА"); C3.CloseHack(); C3.serial+=1; C3.ClearMobs(); task.wait(1)
 for _,p in ipairs(C3.party) do if p.Parent then C3.RestorePlayer(p) end end
 C3.MoveParty(C3.checkpointPos,C3.zones[C3.stage].center)
 C3.Scene(false); CutsceneRE:FireAllClients("reveal"); C3.Activate(C3.stage)
end
function C3.Tick(dt)
 if introActive then return end
 local alive=C3.Living()
 local present=false; for _,p in ipairs(C3.party) do if p.Parent then present=true end end
 if not present then C3.Stop(); returnToMenu(); return end
 if #alive==0 then C3.RespawnCheckpoint(); return end
 local z=C3.zones[C3.stage]
 for _,p in ipairs(alive) do
  local r,h=C3.Root(p); local state=C3.sprint[p]
  if r.Position.Y< -12 or r.Position.Y>150 or math.abs(r.Position.Z-C3.origin.Z)>65 then p.Character:PivotTo(CFrame.new(C3.checkpointPos)) end
  if state then
   local grabbed=os.clock()<(p:GetAttribute("C3GrabbedUntil") or 0)
   local enabled=not (C3.hacker==p) and not grabbed
   local run=state.held and state.energy>2 and enabled and h.MoveDirection.Magnitude>0.1
   if state.exhausted and state.energy<25 then run=false else state.exhausted=false end
   state.energy=math.clamp(state.energy+dt*(run and -20 or 13),0,100)
   if state.energy<=0 then state.exhausted=true; run=false end
   h.WalkSpeed=C3.hacker==p and 0 or grabbed and 8 or run and 27 or 16
   p:SetAttribute("SprintStamina",state.energy); p:SetAttribute("IsSprinting",run)
  end
 end
 if C3.collecting then return end
 if not z.deploying and C3.Count(C3.stage)==0 and not z.cleared then
  if z.wave<z.rounds then C3.Wave(z) else
   z.cleared=true
   if z.index==10 then C3.key=true end
   NotifyRE:FireAllClients(z.index==10 and "Охрана уничтожена. Главный терминал доступен." or "Район зачищен. Используйте панель рядом со шлюзом.",4)
  end
 end
 if C3.Ready(z) and C3.stage<10 then
  local together=true
  for _,p in ipairs(alive) do local r=C3.Root(p); if (r.Position-z.exit).Magnitude>18 then together=false end end
  if together then C3.Activate(C3.stage+1) end
 end
 if C3.hacker and not C3.Root(C3.hacker) then C3.CloseHack() end
 C3.Send()
end
function C3.Start(party)
 assert(ServerStorage:FindFirstChild("silv3r_candy"),"Missing original Kirill model")
 C3.active=true; C3.finished=false; C3.serial+=1; C3.party=table.clone(party); C3.coop=#party>1; C3.mobs={}; C3.connections={}; C3.lastStateSignature=nil; C3.lastStateSent=nil; C3.sprint={}; C3.relays=0; C3.key=false; C3.shieldSeen=false; C3.hackPhase=1; C3.hackSerial=0; C3.shots={}; C3.recovering={}; C3.towerOff=false; C3.modules={}; C3.collecting=false; C3.confirmUntil=nil; C3.confirmPlayer=nil; C3.hacker=nil; C3.challenge=nil; C3.stage=1
 C2.originals={}; Players.RespawnTime=999999
 local physics=game:GetService("PhysicsService"); pcall(function() physics:RegisterCollisionGroup("C2Enemy") end); physics:CollisionGroupSetCollidable("C2Enemy","C2Enemy",false)
 clearLevel(); newFolders(); C3.ApplyLighting(); C3.Build()
 for _,p in ipairs(party) do
  if not p.Character then p:LoadCharacter() end
  p.Character:WaitForChild("HumanoidRootPart"); p:SetAttribute("Chapter",3); c2Hero(p); c2Grant(p,2); C3.sprint[p]={held=false,energy=100}; C3.BindDeath(p)
 end
 C3.Intro()
 local last=os.clock()
 while C3.active and not C3.finished do local now=os.clock(); C3.Tick(math.min(now-last,0.5)); last=now; task.wait(0.25) end
end
C3RE.OnServerEvent:Connect(function(p,action,token,value)
 if not C3.Valid(p) then return end
 if action=="sprint" then if typeof(token)=="boolean" then C3.sprint[p].held=token end; return end
 if action=="equip" then local i=table.find(WD.Order,token); if i and i<=(p:GetAttribute("WeaponLevel") or 1) and not introActive and C3.hacker~=p then c2WorldWeapon(p,token) end; return end
 if action=="cancel" then if C3.hacker==p then C3.CloseHack() end; return end
 if action=="hack" then C3.Protected(function() C3.HackInput(p,token,value) end) end
end)
c3Attack=function(p,name,origin,direction,charge)
 if not C3.Valid(p) or introActive or C3.hacker==p then return end
 local r,h=C3.Root(p); local head=p.Character and p.Character:FindFirstChild("Head"); local w=WD.Stats[name]; local idx=table.find(WD.Order,name)
 if not r or not head or not w or not idx or idx>(p:GetAttribute("WeaponLevel") or 1) then return end
 local function finite(v) return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e6 and math.abs(v.Y)<1e6 and math.abs(v.Z)<1e6 end
 if not finite(origin) or not finite(direction) or direction.Magnitude<0.1 or (origin-head.Position).Magnitude>12 then return end
 C3.shots=C3.shots or {}; if os.clock()-(C3.shots[p] or 0)<w.Cooldown*0.9 then return end; C3.shots[p]=os.clock()
 local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={p.Character,fxFolder,C3.shield}
 local hit=workspace:Raycast(origin,direction.Unit*w.Range,rp); if not hit then return end
 -- Kirill and the tower never enter the damage registry. Shield is not an HP pool.
 local model=hit.Instance:FindFirstAncestorOfClass("Model"); local e=model and C3.mobs[model]
 if not e or e.down or e.hum.Health<=0 then return end
 if e.civilian then
  if name~="Fists" then tracer(origin,hit.Position,C(90,195,220)) end
  C3.Suppress(model,e,p,name=="Fists" and 50 or 35)
  return -- no death marker, TakeDamage, ragdoll or corpse cleanup for civilians
 else
  if name~="Fists" then tracer(origin,hit.Position,w.Color) end
  local damage=name=="Fists" and (p:GetAttribute("Hero")=="Artem" and 25 or 48) or w.Damage*(name=="Shotgun" and 5 or 1)
  if name=="Rifle" then local c=typeof(charge)=="number" and charge==charge and math.clamp(charge,0,1) or 0; damage=45+235*c end
  if hit.Instance.Name=="Head" then damage*=1.5 end
  if name=="Fists" then e.stun=os.clock()+1 end
  e.hum:TakeDamage(damage)
 end
 HitRE:FireClient(p,e.down or e.hum.Health<=0)
end

-- END CHAPTER THREE
local function beginLocalMatch(party)
 if sessionStarted then return end
 local chapter=party[1]:GetAttribute("SelectedChapter") or 1
 if chapter>=2 then
  if #party>2 then LobbyRE:FireAllClients("error","Эта глава рассчитана на одного или двух игроков."); return end
  if #party==2 and party[1]:GetAttribute("Hero")==party[2]:GetAttribute("Hero") then LobbyRE:FireAllClients("error","Выберите разных героев: Артем и Демид."); return end
 end
 sessionStarted=true; sessionSize=#party
 -- Remove the hub floor before building a mission floor at the same elevation.
 introActive=true; sceneLock(true)
 FadeRE:FireAllClients(true,"")
 local oldFloor=workspace:FindFirstChild("LobbyFloor"); if oldFloor then oldFloor:Destroy() end
 sessionRoster={}
 for _,member in ipairs(party) do table.insert(sessionRoster,member.UserId) end
 for index,player in ipairs(party) do
  player:SetAttribute("SquadRole",({"Штурм","Разведка","Связь","Свидетель"})[index])
 end
 LobbyRE:FireAllClients("start",{size=sessionSize,story=story().name})
 task.spawn(function()
  if chapter==3 then
   C3.Protected(function() C3.Start(party) end)
  elseif chapter==2 then
   local ok,err=xpcall(function() startChapter2(party) end,debug.traceback)
   if not ok then
    warn("[Chapter2] "..tostring(err)); C2.active=false; C2.serial+=1
    for _,conn in ipairs(C2.connections) do conn:Disconnect() end; table.clear(C2.connections)
    C2RE:FireAllClients("clear"); Players.RespawnTime=3; c2RestoreHeroes(); returnToMenu()
   end
  else runScene(playIntro) end
 end)
end
local function launch(player,party,owner)
 if sessionStarted or launching[owner] then return end
 if #party<1 or #party>4 then return end
 if (player:GetAttribute("SelectedChapter") or 1)>=2 then
  for _,member in ipairs(party) do if not member:GetAttribute("HeroChosen") then LobbyRE:FireClient(player,"error","Каждый участник должен подтвердить героя перед стартом."); return end end
  if #party>2 or (#party==2 and party[1]:GetAttribute("Hero")==party[2]:GetAttribute("Hero")) then
   LobbyRE:FireClient(player,"error","Главы II–III: максимум двое, герои должны быть разными."); return
  end
 end
 for _,member in ipairs(party) do
  if not member.Parent or not readyClients[member] then LobbyRE:FireClient(player,"error","Дождитесь загрузки всех участников."); return end
 end
 if RunService:IsStudio() then
  if #party~=#Players:GetPlayers() then
   LobbyRE:FireClient(player,"error","В Studio все тестовые клиенты должны войти в одно лобби. Раздельные сессии проверяются в опубликованной игре."); return
  end
  beginLocalMatch(party); return
 end
 launching[owner]=true; pushLobbyState()
 local ids={}; for _,member in ipairs(party) do table.insert(ids,member.UserId) end
 local options=Instance.new("TeleportOptions"); options.ShouldReserveServer=true
 local heroes={}; for _,member in ipairs(party) do heroes[tostring(member.UserId)]=member:GetAttribute("Hero") or "Artem" end
 options:SetTeleportData({animeTinMatch=true,roster=ids,size=#party,chapter=player:GetAttribute("SelectedChapter") or 1,heroes=heroes})
 local ok,err=pcall(function() TeleportService:TeleportAsync(game.PlaceId,party,options) end)
 if not ok then
  launching[owner]=nil; pushLobbyState()
  LobbyRE:FireClient(player,"error","Не удалось создать сессию: "..tostring(err))
 else
  -- Release a stuck launch if Roblox reports no immediate error but players remain.
  task.delay(30,function() if player.Parent and not sessionStarted then launching[owner]=nil; pushLobbyState() end end)
 end
end
local lastLobbyAction={}
local lastConfigure={}
LobbyRE.OnServerEvent:Connect(function(player,command,owner)
 if sessionStarted or sessionRoster then return end
 if command=="configure" and typeof(owner)=="table" then
  if launching[player.UserId] or (membership[player] and launching[membership[player]]) then return end
  if lastConfigure[player] and os.clock()-lastConfigure[player]<0.08 then return end
  lastConfigure[player]=os.clock()
  local chapter=(owner.chapter==2 or owner.chapter==3) and owner.chapter or 1
  local hero=(owner.hero=="Artem" or owner.hero=="Demid") and owner.hero or nil
  local lobby=membership[player] and lobbies[membership[player]]
  if chapter>=2 and hero and lobby then
   for _,member in ipairs(lobby.members) do
    if member~=player and member:GetAttribute("HeroChosen") and member:GetAttribute("Hero")==hero then LobbyRE:FireClient(player,"error","Этот герой занят напарником. Выберите второго."); return end
   end
  end
  player:SetAttribute("SelectedChapter",chapter)
  if hero then player:SetAttribute("Hero",hero); player:SetAttribute("HeroChosen",true) end
  LobbyRE:FireClient(player,"configured",{chapter=chapter,hero=player:GetAttribute("Hero"),chosen=player:GetAttribute("HeroChosen")==true})
  pushLobbyState(); return
 end
 local now=os.clock()
 if lastLobbyAction[player] and now-lastLobbyAction[player]<0.35 then return end
 lastLobbyAction[player]=now
 if command=="list" then pushLobbyState(); return end
 if launching[player.UserId] or (membership[player] and launching[membership[player]]) then return end
 if command=="chapter" then
  if owner==1 or owner==2 or owner==3 then player:SetAttribute("SelectedChapter",owner) end
  pushLobbyState(); return
 elseif command=="hero" then
  if owner=="Artem" or owner=="Demid" then player:SetAttribute("Hero",owner) end
  pushLobbyState(); return
 end
 if command=="solo" then leaveLobby(player); launch(player,{player},player.UserId)
 elseif command=="create" then
  leaveLobby(player); lobbies[player.UserId]={host=player,members={player}}; membership[player]=player.UserId
 elseif command=="join" then
  local lobby=typeof(owner)=="number" and lobbies[owner]
  if lobby and not launching[owner] and #lobby.members<4 and not table.find(lobby.members,player) then
   leaveLobby(player); table.insert(lobby.members,player); membership[player]=owner
  end
 elseif command=="leave" then leaveLobby(player)
 elseif command=="start" then
  local lobby=lobbies[player.UserId]
  if lobby and membership[player]==player.UserId then launch(player,table.clone(lobby.members),player.UserId) end
 end
 pushLobbyState()
end)
TeleportService.TeleportInitFailed:Connect(function(player,_,message)
 local owner=membership[player] or player.UserId
 launching[owner]=nil; pushLobbyState(); LobbyRE:FireClient(player,"error","Ошибка перехода: "..tostring(message))
end)
Players.PlayerRemoving:Connect(function(player)
 lastLobbyAction[player]=nil
 if sessionStarted and evidenceNeeded and combatCleared then task.defer(unlockDoor) end
 local owner=membership[player]
 if owner then launching[owner]=nil; leaveLobby(player) end
 pushLobbyState()
end)
-- A safe hub has no mission waves and cannot advance the plot.
local hubFloor=part(workspace,Vector3.new(100,2,100),Vector3.new(0,-1,0),C(30,35,43),Enum.Material.Concrete)
hubFloor.Name="LobbyFloor"
local function admit(player)
 player:SetAttribute("SelectedChapter",1); player:SetAttribute("Hero","Artem"); player:SetAttribute("HeroChosen",false)
 local data=player:GetJoinData().TeleportData
 if not hasFinishedSession and game.PrivateServerId~="" and game.PrivateServerOwnerId==0 and typeof(data)=="table" and data.animeTinMatch==true and typeof(data.roster)=="table" then
  if #data.roster<1 or #data.roster>4 or not table.find(data.roster,player.UserId) then player:Kick("Неверный состав сессии"); return end
  player:SetAttribute("SelectedChapter",(data.chapter==2 or data.chapter==3) and data.chapter or 1)
  local hero=typeof(data.heroes)=="table" and data.heroes[tostring(player.UserId)]
  player:SetAttribute("Hero",hero=="Demid" and "Demid" or "Artem"); player:SetAttribute("HeroChosen",true)
  if not sessionRoster then sessionRoster=data.roster; rosterWaitStart=os.clock() end
 end
 if sessionRoster and not table.find(sessionRoster,player.UserId) then player:Kick("Эта сессия принадлежит другому отряду"); return end
end
Players.PlayerAdded:Connect(admit)
for _,player in ipairs(Players:GetPlayers()) do admit(player) end
task.spawn(function()
 -- The hub waits for an explicit menu action; reserved servers wait for their roster.
 while not sessionStarted do
  if sessionRoster then
   local party={}; local complete=true
   for _,id in ipairs(sessionRoster) do
    local player=Players:GetPlayerByUserId(id)
    if not player or not readyClients[player] then complete=false else table.insert(party,player) end
   end
   table.sort(party,function(a,b) return table.find(sessionRoster,a.UserId)<table.find(sessionRoster,b.UserId) end)
   if complete or (rosterWaitStart and os.clock()-rosterWaitStart>35 and #party>0) then
    if not complete then LobbyRE:FireAllClients("error","Не все участники прибыли. Начинаем с подключившимся составом.") end
    beginLocalMatch(party); break
   end
  end
  task.wait(0.2)
 end
end)


returnToMenu=function()
 introActive=true; canFight=false; levelToken+=1
 sceneLock(true)
 CreditsRE:FireAllClients(false); MusicRE:FireAllClients("stop")
 CutsceneRE:FireAllClients("armyClear")
 clearLevel(); newFolders()
 local floor=workspace:FindFirstChild("LobbyFloor")
 if not floor then
  floor=part(workspace,Vector3.new(100,2,100),Vector3.new(0,-1,0),C(30,35,43),Enum.Material.Concrete)
  floor.Name="LobbyFloor"
 end
 currentSpawn=CFrame.new(0,4,0)
 currentLevel,currentName,enemiesLeft,currentWave,totalWaves=0,GAME_TITLE,0,0,0
 evidenceNeeded=false; evidenceCollected={}; combatCleared=false
 for _,player in ipairs(Players:GetPlayers()) do
  player.ReplicationFocus=nil; player:SetAttribute("SquadRole",nil); player:SetAttribute("Chapter",1)
  local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health<=0 then player:LoadCharacter() end
 end
 placeAll(); sceneLock(false)
 introActive=false; sessionStarted=false; sessionSize=1
 sessionRoster=nil; rosterWaitStart=nil; hasFinishedSession=true
 table.clear(lobbies); table.clear(membership); table.clear(launching); table.clear(lastLobbyAction)
 CutsceneRE:FireAllClients("end")
 LobbyRE:FireAllClients("menu")
 pushLobbyState()
end
