local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local plr = Players.LocalPlayer
local engineeringActive=false
local chapterSpectatorHead
local GAME_TITLE=workspace:GetAttribute("GameTitle") or "Уничтожь Тянку 3"
local cam = workspace.CurrentCamera
local Remotes = RS:WaitForChild("Remotes")
local WD = require(RS:WaitForChild("WeaponData"))

-- === ИМЕНА SOUND-ОБЪЕКТОВ В WORKSPACE ===
local SOUND_NAMES = {
	intro         = "Running Faster A",
	final         = "Evil Morty Rap",
 finalSlow     = "Evil Morty Rap",
	pickup_pistol = "Gun Shot",
	pickup_other  = "Realistic Gun shot",
}

-- рекурсивный поиск Sound по имени в Workspace / SoundService
local function findSoundTemplate(name)
	if not name or name == "" then return nil end
	local s = workspace:FindFirstChild(name, true)
	if s and s:IsA("Sound") then return s end
	s = SoundService:FindFirstChild(name, true)
	if s and s:IsA("Sound") then return s end
	return nil
end

plr.CameraMode = Enum.CameraMode.LockFirstPerson
UIS.MouseIconEnabled = false
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

------------------------------------------------------------------ UI
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local gui = new("ScreenGui", {Name="HUD", ResetOnSpawn=false, IgnoreGuiInset=true}, plr:WaitForChild("PlayerGui"))
local NEON = Color3.fromRGB(0,220,200)

new("Frame", {Size=UDim2.fromOffset(3,3), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5),
	BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0}, gui)
local hitmark = new("TextLabel", {Size=UDim2.fromOffset(36,36), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5),
	BackgroundTransparency=1, Text="✕", TextSize=30, Font=Enum.Font.GothamBlack, TextColor3=Color3.new(1,1,1), TextTransparency=1}, gui)

local vignette = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(255,0,40), BackgroundTransparency=1, BorderSizePixel=0}, gui)

local hpBg = new("Frame", {Size=UDim2.fromOffset(280,22), Position=UDim2.new(0,30,1,-94), BackgroundColor3=Color3.fromRGB(15,15,20), BorderSizePixel=0}, gui)
new("UIStroke", {Color=NEON, Thickness=2}, hpBg)
local hpFill = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(0,220,120), BorderSizePixel=0}, hpBg)
local hpText = new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="100", TextColor3=Color3.new(1,1,1),
	Font=Enum.Font.GothamBold, TextSize=15, ZIndex=2}, hpBg)

local lvlLabel = new("TextLabel", {Size=UDim2.fromOffset(500,28), Position=UDim2.new(0.5,0,0,16), AnchorPoint=Vector2.new(0.5,0),
	BackgroundTransparency=1, Text="", TextColor3=NEON, Font=Enum.Font.GothamBlack, TextSize=22}, gui)
local enLabel = new("TextLabel", {Size=UDim2.fromOffset(500,24), Position=UDim2.new(0.5,0,0,46), AnchorPoint=Vector2.new(0.5,0),
	BackgroundTransparency=1, Text="", TextColor3=Color3.fromRGB(230,110,170), Font=Enum.Font.GothamBold, TextSize=18}, gui)

local sub = new("TextLabel", {Size=UDim2.new(0.6,0,0,70), Position=UDim2.new(0.5,0,1,-140), AnchorPoint=Vector2.new(0.5,1),
	BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.4, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamMedium,
	TextSize=20, TextWrapped=true, Visible=false, BorderSizePixel=0}, gui)

new("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=20},sub)
local subToken=0
local speakerTag=new("TextLabel",{Size=UDim2.new(0.86,0,0,26),Position=UDim2.new(0.5,0,1,-280),AnchorPoint=Vector2.new(0.5,0),
 BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(210,190,145),Font=Enum.Font.GothamBold,TextSize=20,Visible=false,ZIndex=26},gui)
local doorPrompt = new("TextLabel", {Size=UDim2.fromOffset(340,44), Position=UDim2.new(0.5,0,0.72,0), AnchorPoint=Vector2.new(0.5,0),
	BackgroundColor3=Color3.fromRGB(15,20,15), BackgroundTransparency=0.2, TextColor3=Color3.fromRGB(100,255,150),
	Font=Enum.Font.GothamBold, TextSize=18, Text="[E] , ВЫБИТЬ ДВЕРЬ", Visible=false, BorderSizePixel=0}, gui)
new("UIStroke", {Color=Color3.fromRGB(100,255,150), Thickness=2}, doorPrompt)

local chargeBg = new("Frame", {Size=UDim2.fromOffset(200,10), Position=UDim2.new(0.5,0,0.62,0), AnchorPoint=Vector2.new(0.5,0),
	BackgroundColor3=Color3.fromRGB(20,20,30), BackgroundTransparency=0.3, Visible=false, BorderSizePixel=0}, gui)
new("UIStroke", {Color=Color3.fromRGB(255,80,200), Thickness=1}, chargeBg)
local chargeFill = new("Frame", {Size=UDim2.fromScale(0,1), BackgroundColor3=Color3.fromRGB(255,80,200), BorderSizePixel=0}, chargeBg)

local slots = {}
for i, name in ipairs(WD.Order) do
	local f = new("TextButton", {Text="",Size=UDim2.new(0.18,0,0,40), Position=UDim2.new(0.12+(i-1)*0.19,0,1,-12), AnchorPoint=Vector2.new(0.5,1),
		BackgroundColor3=Color3.fromRGB(15,15,20), BackgroundTransparency=0.2, BorderSizePixel=0}, gui)
	local st = new("UIStroke", {Color=WD.Stats[name].Color, Thickness=1}, f)
	local tl = new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=i..". "..WD.Stats[name].Display,
		TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=13,TextScaled=true}, f)
	slots[name] = {f=f, st=st, tl=tl}
end

local fade = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=50}, gui)
local fadeText = new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", TextColor3=NEON, Font=Enum.Font.GothamBlack,
	TextSize=42, TextWrapped=true, ZIndex=51}, fade)
local fadeTween, fadeGeneration = nil, 0
local endingBlack=false
local function showFade(on, text, t)
 if endingBlack and not on then return end
 fadeGeneration+=1
 local generation=fadeGeneration
 if fadeTween then fadeTween:Cancel() end
 fade.Visible=true
	fadeText.Text = on and (text or "") or ""
 fadeTween=TweenService:Create(fade,TweenInfo.new(t or 0.5),{BackgroundTransparency=on and 0 or 1})
 fadeTween:Play()
 if on then
  -- A lost reveal event or server exception must not leave an opaque overlay forever.
  task.delay(20,function()
   if fadeGeneration~=generation or endingBlack then return end
   warn("Cinematic fade watchdog: removing stale black overlay")
   fadeTween:Cancel()
   fade.BackgroundTransparency=1; fadeText.Text=""
  end)
 end
end

local function forceFinalBlack()
 endingBlack=true; fadeGeneration+=1
 if fadeTween then fadeTween:Cancel() end
 fade.Visible=true; fade.BackgroundTransparency=0; fadeText.Text=""
end

------------------------------------------------------------------ МУЗЫКА (из Workspace по имени)
local currentMusic
local function playMusic(key)
	if currentMusic then currentMusic:Destroy(); currentMusic = nil end
	local name = SOUND_NAMES[key]
	local template = findSoundTemplate(name)
	if not template then
		warn("[Music] Sound '" .. tostring(name) .. "' не найден в Workspace/SoundService")
		return
	end
	if template.IsPlaying then template:Stop() end
	currentMusic = template:Clone()
	currentMusic.Name = "_PlayingMusic"
	currentMusic.Looped = (key == "intro" or key == "final" or key=="finalSlow")
	currentMusic.Volume = key=="finalSlow" and 0 or 0.5
	currentMusic.Parent = workspace
	currentMusic:Play()
 if key=="finalSlow" then TweenService:Create(currentMusic,TweenInfo.new(8,Enum.EasingStyle.Sine),{Volume=0.5}):Play() end
end
local function stopMusic()
	if currentMusic then currentMusic:Destroy(); currentMusic = nil end
end

------------------------------------------------------------------ ТИТРЫ
local creditsGui, creditsText
local function showCredits(on)
	if on then
  forceFinalBlack()
		if creditsGui then creditsGui:Destroy() end
		creditsGui = Instance.new("ScreenGui")
		creditsGui.Name = "Credits"
		creditsGui.IgnoreGuiInset = true
		creditsGui.DisplayOrder = 100
		creditsGui.Parent = plr:WaitForChild("PlayerGui")
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.new(0, 0, 0)
		bg.BackgroundTransparency = 0
		bg.BorderSizePixel = 0
		bg.Parent = creditsGui
		creditsText = Instance.new("TextLabel")
		creditsText.Size = UDim2.new(1, 0, 3, 0)
		creditsText.Position = UDim2.new(0, 0, 1, 0)
		creditsText.BackgroundTransparency = 1
		creditsText.TextColor3 = Color3.fromRGB(0, 220, 200)
		creditsText.Font = Enum.Font.GothamBlack
		creditsText.TextSize = 30
		creditsText.TextWrapped = true
		creditsText.Text = [[


    Уничтожь Тянку 3

    ────────────

    Разработка
    ТЫ

    Сценарий
    ТЫ

    Программирование
    ТЫ

    Дизайн уровней
    ТЫ

    Моделирование
    ТЫ

    ────────────

    Музыка
    Running Faster A
    Evil Morty Rap

    Звуки
    Gun Shot
    Realistic Gun Shot

    ────────────

    В ролях

    Агент , Ты
    Командир , Голос
    Нейро , Она
    Тянки , Они
    Следующая глава
    Завод синдиката

    ────────────

    Спасибо за игру!

    КОПИРОВАНИЕ ЗАВЕРШЕНО. СВЯЗЬ ПОТЕРЯНА.

    ПРОДОЛЖЕНИЕ СЛЕДУЕТ





]]
		creditsText.Parent = creditsGui
		TweenService:Create(creditsText, TweenInfo.new(33, Enum.EasingStyle.Linear), {
			Position = UDim2.new(0, 0, -3, 0)
		}):Play()
	else
		if creditsGui then creditsGui:Destroy(); creditsGui = nil end
	end
end

------------------------------------------------------------------ КАТСЦЕНЫ
local vm
local cutsceneActive = false
local shotFrom, shotTarget, shotStart, shotDuration
local followSubject, followOffset, followAim
local followFirst, followRelative, followSmooth=true,false,7
local fovTween, savedFov
local function setSceneFov(value,duration)
 if fovTween then fovTween:Cancel() end
 fovTween=TweenService:Create(cam,TweenInfo.new(duration or 0.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{FieldOfView=value or 58})
 fovTween:Play()
end
local controlGeneration=0
local function setSceneControls(enabled)
 controlGeneration+=1
 local generation=controlGeneration
 task.spawn(function()
  local scripts=plr:WaitForChild("PlayerScripts",5)
  local module=scripts and scripts:WaitForChild("PlayerModule",5)
  if module and generation==controlGeneration then pcall(function()
   local controls=require(module):GetControls()
   if enabled then controls:Enable() else controls:Disable() end
  end) end
 end)
end
local poseJoints = {}
local hiddenHUD = {}
local bars = {}
for _, bottom in ipairs({false,true}) do
 table.insert(bars,new("Frame",{Size=UDim2.fromScale(1,0.1),Position=UDim2.fromScale(0,bottom and 0.9 or 0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=20,Visible=false},gui))
end
sub.ZIndex=25
local function cinematicHUD(on)
 for _, bar in ipairs(bars) do bar.Visible=on end
 if on then
  for _, item in ipairs(gui:GetChildren()) do
   if item:IsA("GuiObject") and item~=sub and item~=fade and not table.find(bars,item) then
    hiddenHUD[item]=item.Visible; item.Visible=false
   end
  end
 else
  for item, visible in pairs(hiddenHUD) do item.Visible=visible end
  table.clear(hiddenHUD)
 end
end
local firstPersonRide
local firstPersonForward=false
local firstPersonSnap=true
local firstPersonTarget
local armyFolder,armyGeneration=nil,0
local function clearArmy()
 armyGeneration+=1
 if armyFolder then armyFolder:Destroy(); armyFolder=nil end
end
local function buildArmy(origin,token)
 clearArmy()
 local generation=armyGeneration
 local folder=Instance.new("Folder"); folder.Name="CinematicNeuroArmy"; folder.Parent=workspace
 armyFolder=folder
 local function piece(parent,size,position,color)
  local p=Instance.new("Part"); p.Size=size; p.Position=position; p.Color=color
  p.Material=Enum.Material.SmoothPlastic; p.Anchored=true
  p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false; p.Parent=parent
 end
 task.spawn(function()
  for row=0,31 do
   if generation~=armyGeneration then return end
   for column=0,63 do
    local position=origin+Vector3.new((column-31.5)*6,0,row*8)
    local unit=Instance.new("Model"); unit.Name="CartelSoldier"; unit.Parent=folder
    -- Far ranks are lightweight silhouettes. Only front ranks need separate limbs.
    piece(unit,Vector3.new(1.8,2.2,1),position+Vector3.new(0,3.2,0),Color3.fromRGB(20,28,35))
    piece(unit,Vector3.new(2.1,1.3,1.2),position+Vector3.new(0,1.7,0),Color3.fromRGB(13,20,28))
    piece(unit,Vector3.new(1.6,1.4,1.3),position+Vector3.new(0,4.9,0),({Color3.fromRGB(110,65,80),Color3.fromRGB(65,55,40),Color3.fromRGB(150,115,65),Color3.fromRGB(65,70,95)})[(column+row)%4+1])
    piece(unit,Vector3.new(1.2,0.8,0.12),position+Vector3.new(0,4.8,-0.7),Color3.fromRGB(200,190,180))
    if row<4 then
     for _,sign in ipairs({-1,1}) do
      piece(unit,Vector3.new(0.55,2,0.65),position+Vector3.new(sign*1.25,3.1,0),Color3.fromRGB(45,100,110))
      piece(unit,Vector3.new(0.65,1.3,0.7),position+Vector3.new(sign*0.5,0.65,0),Color3.fromRGB(25,35,43))
     end
     if column%5==0 then piece(unit,Vector3.new(0.35,1.5,0.12),position+Vector3.new(0,3.2,-0.56),Color3.fromRGB(90,125,130)) end
    end
   end
   RunService.Heartbeat:Wait() -- batch creation; no thousands-of-Humanoids replication spike
  end
  if generation==armyGeneration and token then Remotes.SceneReady:FireServer("armyDone",token) end
 end)
end
local function bloodOverlay(strength)
 for i=1,16 do
  local size=math.random(12,45)*(strength or 0.5)
  local drop=new("Frame",{Size=UDim2.fromOffset(size,size*math.random(1,3)),Position=UDim2.fromScale(math.random(),math.random()),
   BackgroundColor3=Color3.fromRGB(105,8,18),BackgroundTransparency=0.25,BorderSizePixel=0,ZIndex=30,Rotation=math.random(-35,35)},gui)
  new("UICorner",{CornerRadius=UDim.new(1,0)},drop)
  TweenService:Create(drop,TweenInfo.new(3.5),{BackgroundTransparency=1,Position=drop.Position+UDim2.fromOffset(0,35)}):Play()
  Debris:AddItem(drop,3.6)
 end
end
local sceneBlaster,blasterParts,scanPanel=nil,{},nil
local scanGeneration,pulseTime=0,-100
local scanRunning=false
local function removeSceneProps()
 subToken+=1; sub.Visible=false; speakerTag.Visible=false
 if sceneBlaster then sceneBlaster:Destroy(); sceneBlaster=nil; table.clear(blasterParts) end
 scanGeneration+=1; scanRunning=false
 if scanPanel then scanPanel:Destroy(); scanPanel=nil end
end
local function showSceneBlaster(on)
 if sceneBlaster then sceneBlaster:Destroy(); sceneBlaster=nil; table.clear(blasterParts) end
 if not on then return end
 sceneBlaster=Instance.new("Model"); sceneBlaster.Name="ImpulseBlaster"; sceneBlaster.Parent=cam
 for _,spec in ipairs({
  {Vector3.new(0.55,0.55,1.4),CFrame.new(0.8,-0.7,-1.6),Color3.fromRGB(45,55,68)},
  {Vector3.new(0.35,0.35,0.8),CFrame.new(0.8,-0.65,-2.6),Color3.fromRGB(75,140,150)},
  {Vector3.new(0.3,0.7,0.35),CFrame.new(0.8,-1.2,-1.4),Color3.fromRGB(28,34,42)},
  {Vector3.new(0.45,0.45,1.1),CFrame.new(0.8,-1.1,-0.8),Color3.fromRGB(75,80,85)},
 }) do
  local p=Instance.new("Part"); p.Size=spec[1]; p.Color=spec[3]; p.Material=Enum.Material.SmoothPlastic
  p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false; p.Parent=sceneBlaster
  table.insert(blasterParts,{part=p,offset=spec[2]})
 end
end
RunService:BindToRenderStep("SceneBlaster",Enum.RenderPriority.Camera.Value+2,function()
 if not sceneBlaster then return end
 local recoil=math.max(0,1-(os.clock()-pulseTime)/0.5)
 for _,entry in ipairs(blasterParts) do entry.part.CFrame=cam.CFrame*CFrame.new(0,0,recoil*0.22)*CFrame.Angles(-recoil*0.08,0,0)*entry.offset end
end)
local function startScan(data)
 scanRunning=true
 scanGeneration+=1; local generation=scanGeneration
 if scanPanel then scanPanel:Destroy() end
 scanPanel=new("Frame",{Size=UDim2.fromScale(0.7,0.25),Position=UDim2.fromScale(0.15,0.6),BackgroundColor3=Color3.fromRGB(8,20,24),BackgroundTransparency=0.15,BorderSizePixel=0,ZIndex=35},gui)
 new("TextLabel",{Size=UDim2.fromScale(0.94,0.4),Position=UDim2.fromScale(0.03,0.08),BackgroundTransparency=1,Text="Копирование боевых данных и опыта",TextColor3=Color3.fromRGB(120,220,210),Font=Enum.Font.GothamBold,TextScaled=true,ZIndex=36},scanPanel)
 local track=new("Frame",{Size=UDim2.fromScale(0.9,0.15),Position=UDim2.fromScale(0.05,0.65),BackgroundColor3=Color3.fromRGB(30,48,54),BorderSizePixel=0,ZIndex=36},scanPanel)
 local fill=new("Frame",{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(75,180,170),BorderSizePixel=0,ZIndex=37},track)
 local line=new("Frame",{Size=UDim2.fromScale(1,0.012),Position=UDim2.fromScale(0,0),BackgroundColor3=Color3.fromRGB(110,220,200),BorderSizePixel=0,ZIndex=38},scanPanel)
 TweenService:Create(line,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,math.ceil(data.seconds),true),{Position=UDim2.fromScale(0,0.97)}):Play()
 task.spawn(function()
  local tween=TweenService:Create(fill,TweenInfo.new(data.seconds,Enum.EasingStyle.Linear),{Size=UDim2.fromScale(1,1)})
  tween:Play(); local state=tween.Completed:Wait()
  if generation~=scanGeneration or state~=Enum.PlaybackState.Completed then return end
  scanPanel:Destroy(); scanPanel=nil; scanRunning=false
  Remotes.SceneReady:FireServer("scanDone",data.id)
 end)
end
Remotes.Cutscene.OnClientEvent:Connect(function(action, frame, duration, aim)
 if action=="dialogue" then
  subToken+=1; local token=subToken
  -- Preserve the supplied post-credits wording and punctuation literally.
  sub.Text=frame.text; sub.MaxVisibleGraphemes=-1; sub.Visible=true; sub.TextScaled=true
  sub.Size=UDim2.new(0.86,0,0,150); sub.Position=UDim2.new(0.5,0,1,-100); sub.TextSize=18
  speakerTag.Text=frame.name; speakerTag.Visible=true
  task.delay(frame.duration,function() if token==subToken then sub.Visible=false; speakerTag.Visible=false end end)
  return
 end
 if action=="reveal" then
  endingBlack=false
  showFade(false,"",0.45)
  return
 end
 if action=="blaster" then showSceneBlaster(frame); return end
 if action=="pulse" then
  pulseTime=os.clock()
  local template=findSoundTemplate(SOUND_NAMES.pickup_other)
  if template then local sound=template:Clone(); sound.Looped=false; sound.Volume=0.45; sound.Parent=SoundService; sound:Play(); Debris:AddItem(sound,4) end
  return
 end
 if action=="scan" then startScan(frame); return end
 if action=="blackout" then
  task.spawn(function()
   -- A slow client finishes its own scan before honoring even a late blackout packet.
   while scanRunning and cutsceneActive do RunService.RenderStepped:Wait() end
   if not cutsceneActive then return end
   removeSceneProps(); forceFinalBlack()
   local sound=Instance.new("Sound"); sound.SoundId="rbxasset://sounds/electronicpingshort.wav"; sound.PlaybackSpeed=0.5; sound.Volume=0.55; sound.Parent=SoundService; sound:Play(); Debris:AddItem(sound,3)
   RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
   Remotes.SceneReady:FireServer("black",frame)
  end)
  return
 end
 if action=="povForward" then
  firstPersonForward=true; firstPersonRide=nil; firstPersonTarget=Vector3.zero
  followSubject=nil; shotTarget=nil; firstPersonSnap=true; return
 end
 if action=="recon" then
  local surface=frame:FindFirstChildOfClass("SurfaceGui")
  if not surface then return end
  for _,label in ipairs(surface:GetChildren()) do if label:IsA("TextLabel") then label.Size=UDim2.fromScale(1,0.18); label.TextSize=18; label.TextScaled=true end end
  local view=new("ViewportFrame",{Size=UDim2.fromScale(1,0.8),Position=UDim2.fromScale(0,0.2),BackgroundColor3=Color3.fromRGB(45,60,65),Ambient=Color3.fromRGB(160,165,170),LightColor=Color3.fromRGB(210,210,200)},surface)
  local copy=duration:Clone(); copy.Parent=view
  local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(25,19,30),Vector3.new(0,4,0)); camera.FieldOfView=55; camera.Parent=view; view.CurrentCamera=camera
  return
 end
 if action=="army" then buildArmy(frame,duration); return end
 if action=="armyClear" then clearArmy(); return end
 if action=="blood" then bloodOverlay(frame); return end
 if action=="povRide" then firstPersonForward=false; firstPersonSnap=true; firstPersonRide=frame; firstPersonTarget=Vector3.zero; followSubject=nil; shotTarget=nil; return end
 if action=="pov" then
  firstPersonForward=false
  firstPersonSnap=not cutsceneActive
  firstPersonRide=nil
  firstPersonTarget=frame; followSubject=nil; shotTarget=nil
  setSceneFov(typeof(duration)=="number" and duration or 58,0.6)
  return
 end
 if action=="cam" or action=="shot" or action=="follow" or action=="followRig" or action=="end" or action=="recover" then firstPersonTarget=nil; firstPersonRide=nil; firstPersonForward=false end
 if action=="prepare" then
  task.spawn(function()
   -- Streaming is optional and bounded; acknowledgements are sent even on failure.
   local ok,err=pcall(function()
    if workspace.StreamingEnabled then plr:RequestStreamAroundAsync(frame,5) end
    RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
   end)
   if not ok then warn("Scene preparation: "..tostring(err)) end
   Remotes.SceneReady:FireServer("prepared",duration)
  end)
  return
 end
 if action=="cam" then
  followSubject=nil
  shotFrom=frame.from or cam.CFrame; shotTarget=frame.cf
  shotStart=os.clock(); shotDuration=frame.time or 0
  cam.CFrame=shotFrom
  if frame.fov0 then cam.FieldOfView=frame.fov0 end
  setSceneFov(frame.fov or 58,shotDuration)
  return
 end
 if action=="recover" then
  endingBlack=false; removeSceneProps()
  showFade(false,"",0.2)
  action="end"
 end
 if action == "follow" or action=="followRig" then
  followFirst=true; followRelative=action=="followRig"; followSmooth=7
  followSubject=frame; followOffset=duration; followAim=aim or Vector3.new(0,1,0)
  shotTarget=nil
  return
 end
 if action == "shot" then
  followSubject=nil
  shotFrom=cam.CFrame; shotTarget=frame; shotStart=os.clock(); shotDuration=duration or 2
  if shotDuration<=0 then cam.CFrame=frame end
  return
 end
 if action == "start" then
  if cutsceneActive then return end
  followSubject=nil
  savedFov=cam.FieldOfView
  cam.FieldOfView=58
		cutsceneActive = true
  shotTarget=nil
  cinematicHUD(true)
  cam.CameraType=Enum.CameraType.Scriptable
  setSceneControls(false)
  plr.CameraMode = Enum.CameraMode.Classic
		if vm and vm.Parent then vm.Parent = nil end
	elseif action == "end" then
  endingBlack=false; removeSceneProps()
		cutsceneActive = false
  followSubject=nil
  if fovTween then fovTween:Cancel() end
  cam.FieldOfView=savedFov or 70
  shotTarget=nil
  cinematicHUD(false)
  cam.CameraType=Enum.CameraType.Custom
  cam.CameraSubject=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
  setSceneControls(true)
  plr.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end)
Remotes.Music.OnClientEvent:Connect(function(action)
 if action=="stop" then stopMusic() else playMusic(action) end
end)
local creditsGeneration=0
Remotes.Credits.OnClientEvent:Connect(function(on)
 creditsGeneration+=1; local generation=creditsGeneration
 if not on then showCredits(false); return end
 task.spawn(function()
  while scanRunning and cutsceneActive do RunService.RenderStepped:Wait() end
  if generation~=creditsGeneration or not cutsceneActive then return end
  forceFinalBlack()
  RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
  if generation==creditsGeneration and cutsceneActive then showCredits(true) end
 end)
end)

------------------------------------------------------------------ VIEWMODEL
vm = Instance.new("Model"); vm.Name = "ViewModel"
local function vpart(size, color, mat)
	local p = Instance.new("Part")
	p.Size = size; p.Color = color; p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	return p
end
local function makeArm()
	local a = {}
	local function add(size, off, color, mat)
		local p = vpart(size, color, mat); p.Parent = vm; table.insert(a, {p, off})
	end
	add(Vector3.new(0.85,0.85,2.8), CFrame.new(0,0,1.7), Color3.fromRGB(38,42,50), Enum.Material.Fabric)
	add(Vector3.new(0.9,0.9,0.15), CFrame.new(0,0,0.35), Color3.fromRGB(25,28,35), Enum.Material.Metal)
	add(Vector3.new(0.95,0.95,0.9), CFrame.new(0,0,0), Color3.fromRGB(55,52,48), Enum.Material.Fabric)
	add(Vector3.new(0.98,0.25,0.5), CFrame.new(0,0.42,-0.25), Color3.fromRGB(75,72,68), Enum.Material.Leather)
	add(Vector3.new(0.3,0.15,0.35), CFrame.new(0,0.55,0.3), Color3.fromRGB(30,32,38), Enum.Material.Metal)
	return a
end
local function setParts(list, cf) for _, e in ipairs(list) do e[1].CFrame = cf * e[2] end end
local armR, armL = makeArm(), makeArm()

local dark, metal, poly = Color3.fromRGB(22,22,26), Color3.fromRGB(50,52,60), Color3.fromRGB(28,28,32)
local GunDefs = {
	Pistol = {muzzle=-2.2, parts={
		{Vector3.new(0.38,0.42,1.7),  CFrame.new(0,0.18,-1.1),  dark,  Enum.Material.Metal},
		{Vector3.new(0.4,0.15,1.6),   CFrame.new(0,0.42,-1.1),  metal, Enum.Material.Metal},
		{Vector3.new(0.35,0.55,1.4),  CFrame.new(0,-0.05,-0.95), poly, Enum.Material.SmoothPlastic},
		{Vector3.new(0.38,0.95,0.55), CFrame.new(0,-0.55,-0.3), poly,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.32,0.12,0.7),  CFrame.new(0,-0.15,-0.4), metal, Enum.Material.Metal},
		{Vector3.new(0.25,0.15,0.5),  CFrame.new(0,-0.55,0.05), dark,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.35,0.35,0.3),  CFrame.new(0,0.2,-1.95),  metal, Enum.Material.Metal},
		{Vector3.new(0.08,0.08,0.15), CFrame.new(0,0.4,-2.05),  dark,  Enum.Material.Metal},
		{Vector3.new(0.2,0.08,0.1),   CFrame.new(0,0.42,-0.35), dark,  Enum.Material.Metal},
		{Vector3.new(0.42,0.05,0.4),  CFrame.new(0,0.15,-1.5),  Color3.fromRGB(200,30,30), Enum.Material.Neon},
	}},
	SMG = {muzzle=-3.8, parts={
		{Vector3.new(0.48,0.55,2.5),  CFrame.new(0,0.15,-1.5),  dark,  Enum.Material.Metal},
		{Vector3.new(0.45,0.35,1.8),  CFrame.new(0,-0.15,-1.3), poly,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.3,0.3,1.0),    CFrame.new(0,0.15,-3.2),  metal, Enum.Material.Metal},
		{Vector3.new(0.35,0.35,0.6),  CFrame.new(0,0.15,-3.65), dark,  Enum.Material.Metal},
		{Vector3.new(0.28,1.2,0.45),  CFrame.new(0,-0.9,-1.0),  metal, Enum.Material.Metal},
		{Vector3.new(0.4,0.7,0.5),    CFrame.new(0,-0.55,-0.1), poly,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.4,0.4,0.7),    CFrame.new(0,0.1,0.15),   poly,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.2,0.18,0.25),  CFrame.new(0,0.45,-1.3),  metal, Enum.Material.Metal},
		{Vector3.new(0.15,0.2,0.25),  CFrame.new(0,0.6,-1.3),   Color3.fromRGB(30,80,30), Enum.Material.SmoothPlastic},
		{Vector3.new(0.5,0.05,0.4),   CFrame.new(0,0.13,-2.5),  Color3.fromRGB(200,30,30), Enum.Material.Neon},
	}},
	Shotgun = {muzzle=-4.8, parts={
		{Vector3.new(0.55,0.55,1.4),  CFrame.new(0,0.1,-0.3),   dark,  Enum.Material.Metal},
		{Vector3.new(0.35,0.35,3.4),  CFrame.new(0,0.25,-2.4),  metal, Enum.Material.Metal},
		{Vector3.new(0.3,0.3,2.4),    CFrame.new(0,-0.1,-1.9),  dark,  Enum.Material.Metal},
		{Vector3.new(0.55,0.5,1.1),   CFrame.new(0,-0.05,-1.9), Color3.fromRGB(90,55,30), Enum.Material.Wood},
		{Vector3.new(0.5,0.55,1.4),   CFrame.new(0,-0.15,0.7),  Color3.fromRGB(90,55,30), Enum.Material.Wood},
		{Vector3.new(0.45,0.6,0.5),   CFrame.new(0,-0.5,-0.2),  Color3.fromRGB(90,55,30), Enum.Material.Wood},
		{Vector3.new(0.4,0.4,0.35),   CFrame.new(0,0.3,-4.1),   dark,  Enum.Material.Metal},
		{Vector3.new(0.08,0.08,0.1),  CFrame.new(0,0.42,-4.3),  metal, Enum.Material.Metal},
		{Vector3.new(0.25,0.1,0.1),   CFrame.new(0,0.45,-0.9),  dark,  Enum.Material.Metal},
	}},
	Rifle = {muzzle=-4.6, parts={
		{Vector3.new(0.6,0.7,2.8),    CFrame.new(0,0.15,-1.5),  dark,  Enum.Material.Metal},
		{Vector3.new(0.35,0.35,3.5),  CFrame.new(0,0.15,-3.8),  metal, Enum.Material.Metal},
		{Vector3.new(0.15,0.15,4.0),  CFrame.new(0.28,0.25,-3.5), Color3.fromRGB(255,80,200), Enum.Material.Neon},
		{Vector3.new(0.15,0.15,4.0),  CFrame.new(-0.28,0.25,-3.5), Color3.fromRGB(255,80,200), Enum.Material.Neon},
		{Vector3.new(0.55,0.55,0.4),  CFrame.new(0,0.15,-5.5),  Color3.fromRGB(255,80,200), Enum.Material.Neon},
		{Vector3.new(0.45,0.9,0.5),   CFrame.new(0,-0.65,-0.2), dark,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.4,1.0,0.7),    CFrame.new(0,-0.7,-1.3),  metal, Enum.Material.Metal},
		{Vector3.new(0.45,0.55,1.5),  CFrame.new(0,0.05,0.9),   poly,  Enum.Material.SmoothPlastic},
		{Vector3.new(0.35,0.35,0.6),  CFrame.new(0,0.55,-1.3),  dark,  Enum.Material.Metal},
		{Vector3.new(0.5,0.35,0.8),   CFrame.new(0,0.8,-1.3),   Color3.fromRGB(30,100,120), Enum.Material.SmoothPlastic},
		{Vector3.new(0.15,0.15,0.3),  CFrame.new(0,0.15,-5.9),  Color3.fromRGB(255,80,200), Enum.Material.Neon},
	}},
}
local gunParts = {}
for name, def in pairs(GunDefs) do
	gunParts[name] = {}
	for _, d in ipairs(def.parts) do
		local col = (d[3] == "ACC") and WD.Stats[name].Color or d[3]
		table.insert(gunParts[name], {vpart(d[1], col, d[4]), d[2]})
	end
end
local chapterTool=vpart(Vector3.new(0.22,0.22,1.8),Color3.fromRGB(170,185,195),Enum.Material.Metal)
chapterTool.Name="Chapter2RoleTool"; chapterTool.Parent=nil
local chapterToolMesh=new("SpecialMesh",{MeshType=Enum.MeshType.Brick},chapterTool)
local chapterToolHandle=vpart(Vector3.new(0.28,0.65,0.35),Color3.fromRGB(30,40,47),Enum.Material.Metal); chapterToolHandle.Parent=nil
local chapterToolGuard=vpart(Vector3.new(0.6,0.1,0.25),Color3.fromRGB(125,135,143),Enum.Material.Metal); chapterToolGuard.Parent=nil
local chapterToolTip=vpart(Vector3.new(0.16,0.16,0.16),Color3.fromRGB(160,230,255),Enum.Material.Neon); chapterToolTip.Shape=Enum.PartType.Ball; chapterToolTip.Parent=nil
local flash = vpart(Vector3.new(0.7,0.7,0.7), Color3.fromRGB(255,220,140), Enum.Material.Neon)
flash.Shape = Enum.PartType.Ball; flash.Transparency = 1; flash.Parent = vm
local flashLight = Instance.new("PointLight"); flashLight.Range = 14; flashLight.Brightness = 4; flashLight.Enabled = false
flashLight.Color = Color3.fromRGB(255,220,140); flashLight.Parent = flash

local chargeOrb = vpart(Vector3.new(0.5,0.5,0.5), Color3.fromRGB(255,80,200), Enum.Material.Neon)
chargeOrb.Shape = Enum.PartType.Ball; chargeOrb.Transparency = 1; chargeOrb.Parent = vm
local chargeLight = Instance.new("PointLight"); chargeLight.Range = 20; chargeLight.Brightness = 0
chargeLight.Color = Color3.fromRGB(255,80,200); chargeLight.Parent = chargeOrb

local curName = "Fists"
local chapterLoadout
local switchT, recoil, shakeI, recoilVel = 0, 0, 0, 0
local punchHand, punchStart, flashT = 1, 0, 0
local firing, lastFire = false, 0
local charge, charging = 0, false
local pickupT = 0
local focusTarget, focusT = nil, 0

local function refreshSlots()
	local wl = chapterLoadout and chapterLoadout.level or (plr:GetAttribute("WeaponLevel") or 1)
	for i, name in ipairs(WD.Order) do
		local s = slots[name]
		local unlocked = i <= wl
  if name=="Fists" then s.tl.Text=plr:GetAttribute("Chapter")==2 and (plr:GetAttribute("Hero")=="Artem" and "1. Сварка" or "1. Нож") or "1. Кулаки" end
		s.tl.TextTransparency = unlocked and 0 or 0.65
		s.st.Thickness = (name == curName) and 3 or 1
		s.f.BackgroundTransparency = (name == curName) and 0 or 0.4
	end
end
local function playPickupSound(wl)
	local key = (wl == 2) and "pickup_pistol" or "pickup_other"
	local name = SOUND_NAMES[key]
	local template = findSoundTemplate(name)
	if not template then
		warn("[SFX] Sound '" .. tostring(name) .. "' не найден в Workspace/SoundService")
		return
	end
	local s = template:Clone()
	s.Name = "_PlayingSFX"
	s.Looped = false
	s.Volume = 0.8
	s.Parent = workspace
	s:Play()
	Debris:AddItem(s, 6)
end
local function selectWeapon(name)
	local idx = table.find(WD.Order, name)
	if not idx or idx > (chapterLoadout and chapterLoadout.level or (plr:GetAttribute("WeaponLevel") or 1)) then return end
	curName = name; switchT = 1
 if chapterLoadout then Remotes.Chapter2:FireServer("equip",name) end
 local roleParent=(name=="Fists" and plr:GetAttribute("Chapter")==2) and vm or nil
 chapterTool.Parent=roleParent; chapterToolHandle.Parent=roleParent; chapterToolGuard.Parent=roleParent; chapterToolTip.Parent=roleParent
	for n, list in pairs(gunParts) do
		for _, e in ipairs(list) do e[1].Parent = (n == name) and vm or nil end
	end
	refreshSlots()
end
plr:GetAttributeChangedSignal("WeaponLevel"):Connect(function()
 if plr:GetAttribute("Chapter")==2 then refreshSlots(); return end
	local wl = plr:GetAttribute("WeaponLevel") or 1
	if wl > 1 then
		pickupT = 1.4
		playPickupSound(wl)
		task.delay(0.55, function()
			if plr:GetAttribute("Chapter")~=2 then selectWeapon(WD.Order[wl]) end
		end)
	end
end)
plr:GetAttributeChangedSignal("Chapter"):Connect(function() if plr:GetAttribute("Chapter")~=2 then chapterLoadout=nil; selectWeapon("Fists") end; refreshSlots() end)
plr:GetAttributeChangedSignal("Hero"):Connect(refreshSlots)
selectWeapon("Fists")
for name,slot in pairs(slots) do slot.f.Activated:Connect(function() if not cutsceneActive and not engineeringActive then selectWeapon(name) end end) end

------------------------------------------------------------------ СТРЕЛЬБА
local function doFire(chargeLevel)
	if cutsceneActive or engineeringActive then return end
	local w = WD.Stats[curName]
	local now = os.clock()
	local cooldown=(plr:GetAttribute("Chapter")==2 and curName=="Fists") and (plr:GetAttribute("Hero")=="Artem" and 0.2 or 0.5) or w.Cooldown
 if now - lastFire < cooldown then return end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	lastFire = now
	Remotes.Attack:FireServer(curName, cam.CFrame.Position, cam.CFrame.LookVector, chargeLevel)
	if curName == "Fists" then
		punchHand = 1 - punchHand; punchStart = now
	else
		playPickupSound(curName == "Pistol" and 2 or 3)
		local kick = w.Recoil or 1
		recoil = math.min(recoil + kick, 6); recoilVel = kick * 0.8
		shakeI = math.max(shakeI, kick * 2)
		flashT = now + 0.05
	end
end

UIS.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	if cutsceneActive or engineeringActive then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		firing = true
		if curName == "Rifle" then
			charging = true; charge = 0
		elseif not WD.Stats[curName].Auto then
			doFire(0)
		end
	elseif i.KeyCode == Enum.KeyCode.E then
		if doorPrompt.Visible then Remotes.Kick:FireServer() end
	elseif i.KeyCode.Value >= Enum.KeyCode.One.Value and i.KeyCode.Value <= Enum.KeyCode.Five.Value then
		selectWeapon(WD.Order[i.KeyCode.Value - Enum.KeyCode.One.Value + 1])
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		firing = false
		if curName == "Rifle" and charging then
			charging = false
			doFire(math.clamp(charge / WD.Stats.Rifle.MaxCharge, 0, 1))
			charge = 0
		end
	end
end)

Remotes.Focus.OnClientEvent:Connect(function(point, dur)
	focusTarget = point; focusT = dur
 if cutsceneActive then
  followSubject=nil
  shotFrom=cam.CFrame
  shotTarget=CFrame.lookAt(point+Vector3.new(9,4,12),point)
  shotStart=os.clock(); shotDuration=math.min(dur or 2,2)
 end
end)

local doorPos = nil
Remotes.DoorState.OnClientEvent:Connect(function(pos, unlocked)
	doorPos = unlocked and pos or nil
	if not unlocked then doorPrompt.Visible = false end
end)

------------------------------------------------------------------ РЕНДЕР
local swayX, swayY, bobA = 0, 0, 0
-- Local fallback poses do not depend on uploaded animation permissions.
-- The walking track is preferred; seated/kick poses work for both R6 and R15.
RunService:BindToRenderStep("CinematicPoses",Enum.RenderPriority.Character.Value+1,function()
 for _, player in ipairs(Players:GetPlayers()) do
  local character=player.Character
  if not character then continue end
  local walking=character:GetAttribute("CinematicWalk")
  local seated=character:GetAttribute("CinematicSeated")
  local kickTime=character:GetAttribute("CinematicKick")
  local kicking=kickTime and math.clamp((workspace:GetServerTimeNow()-kickTime)/0.85,0,1)
  local hum=character:FindFirstChildOfClass("Humanoid")
  local animator=hum and hum:FindFirstChildOfClass("Animator")
  local hasWalkTrack=false
  if walking and animator then
   for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
    if track.Priority==Enum.AnimationPriority.Action and track.Length>0 then hasWalkTrack=true; break end
   end
  end
  if not walking and not seated and not kickTime then continue end
  for _, joint in ipairs(character:GetDescendants()) do
   if not joint:IsA("Motor6D") then continue end
   local hip=joint.Name:find("Hip")
   local shoulder=joint.Name:find("Shoulder")
   if not hip and not shoulder then continue end
   if not poseJoints[joint] then poseJoints[joint]=joint.C0 end
   local angle=0
   local right=joint.Name:find("Right")~=nil
   if seated then angle=hip and -math.pi/2 or -0.2
   elseif kicking then
    local envelope=math.sin(kicking*math.pi)
    angle=hip and (right and -1.5*envelope or 0.15*envelope) or 0.35*envelope
   elseif walking and not hasWalkTrack then
    angle=math.sin(os.clock()*8)*(right and 1 or -1)*(hip and 0.55 or -0.35)
   end
   local base=poseJoints[joint]
   joint.C0=base*CFrame.fromAxisAngle(base:VectorToObjectSpace(Vector3.xAxis),angle)
  end
 end
 for joint,base in pairs(poseJoints) do
  local character=joint:FindFirstAncestorOfClass("Model")
  if not joint.Parent or not character or not (character:GetAttribute("CinematicWalk") or character:GetAttribute("CinematicSeated") or character:GetAttribute("CinematicKick")) then
   if joint.Parent then joint.C0=base end
   poseJoints[joint]=nil
  end
 end
end)

local function unobstructedCamera(focus,position,subject)
 local filter={}
 for _, player in ipairs(Players:GetPlayers()) do if player.Character then table.insert(filter,player.Character) end end
 if subject then table.insert(filter,subject) end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=filter; params.RespectCanCollide=true
 local hit=workspace:Raycast(focus,position-focus,params)
 return hit and hit.Position+hit.Normal*0.6 or position
end
RunService:BindToRenderStep("ViewModel", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local now = os.clock()
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if cutsceneActive then
  if vm then vm.Parent=nil end
  cam.CameraType=Enum.CameraType.Scriptable
  if char then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.LocalTransparencyModifier = firstPersonTarget and 1 or 0 end
			end
		end
  if firstPersonTarget then
   local head=char and char:FindFirstChild("Head")
   local eye=(chapterSpectatorHead and chapterSpectatorHead.Parent and (not hum or hum.Health<=0)) and chapterSpectatorHead.Position or (head and head.Position or cam.CFrame.Position)
   local focus
   if firstPersonForward then focus=eye+((chapterSpectatorHead and chapterSpectatorHead.Parent and (not hum or hum.Health<=0)) and chapterSpectatorHead.CFrame.LookVector or (hrp and hrp.CFrame.LookVector or cam.CFrame.LookVector))*12
   elseif firstPersonRide and firstPersonRide.Parent then focus=firstPersonRide:GetPivot():PointToWorldSpace(Vector3.new(35,0,0))
   elseif typeof(firstPersonTarget)=="Instance" then focus=firstPersonTarget.Parent and firstPersonTarget.Position or eye+cam.CFrame.LookVector*12
   else focus=firstPersonTarget end
   if (focus-eye).Magnitude>0.05 then
    local goal=CFrame.lookAt(eye,focus)
    local rotation=firstPersonSnap and goal.Rotation or cam.CFrame.Rotation:Lerp(goal.Rotation,1-math.exp(-dt*5))
    cam.CFrame=CFrame.new(eye)*rotation
    firstPersonSnap=false
   end
  elseif followSubject and followSubject.Parent then
   local pivot=followSubject:GetPivot()
   local focus=followRelative and pivot:PointToWorldSpace(followAim) or pivot.Position+followAim
   local desired=followRelative and pivot:PointToWorldSpace(followOffset) or pivot.Position+followOffset
   local position=unobstructedCamera(focus,desired,followSubject)
   local goal=CFrame.lookAt(position,focus)
   cam.CFrame=followFirst and goal or cam.CFrame:Lerp(goal,1-math.exp(-dt*followSmooth))
   followFirst=false
  elseif shotTarget then
   local t=shotDuration<=0 and 1 or math.clamp((os.clock()-shotStart)/shotDuration,0,1)
   cam.CFrame=shotFrom:Lerp(shotTarget,t*t*(3-2*t))
  elseif char and char.PrimaryPart then
   local hr = char.PrimaryPart
			local side = hr.CFrame.RightVector * 8
			local back = hr.CFrame.LookVector * -8
			local camPos = hr.Position + side + back + Vector3.new(0, 6, 0)
			cam.CFrame = CFrame.lookAt(camPos, hr.Position + Vector3.new(0, 2, 0))
		end
		return
	end

	if char then
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end
		end
	end
	local alive = hum and hum.Health > 0
	local target = alive and cam or nil
	if vm.Parent ~= target then vm.Parent = target end
	if not alive then return end

	if firing and WD.Stats[curName].Auto then doFire(0) end

	if charging and curName == "Rifle" then
		charge = math.min(charge + dt, WD.Stats.Rifle.MaxCharge)
		chargeBg.Visible = true
		chargeFill.Size = UDim2.fromScale(math.clamp(charge / WD.Stats.Rifle.MaxCharge, 0, 1), 1)
		chargeOrb.Transparency = 1 - math.clamp(charge / WD.Stats.Rifle.MaxCharge, 0, 1) * 0.9
		chargeOrb.Size = Vector3.new(0.5,0.5,0.5) * (1 + charge * 1.5)
		chargeLight.Brightness = charge * 4
	else
		chargeBg.Visible = false
		chargeOrb.Transparency = 1
		chargeLight.Brightness = 0
	end

	recoil = recoil * math.exp(-dt * 10)
	recoilVel = recoilVel * math.exp(-dt * 4)
	shakeI = shakeI * math.exp(-dt * 6)
	local pitchKick = math.rad(recoil * 0.6)
	local shakeAng = CFrame.Angles(
		(math.random()-0.5) * shakeI * 0.008 + pitchKick,
		(math.random()-0.5) * shakeI * 0.008,
		(math.random()-0.5) * shakeI * 0.006)
	cam.CFrame = cam.CFrame * shakeAng

	if focusT > 0 and focusTarget then
		focusT -= dt
		local pos = cam.CFrame.Position
		local dir = (focusTarget - pos).Unit
		local look = CFrame.lookAt(pos, pos + dir)
		cam.CFrame = cam.CFrame:Lerp(look, math.min(1, dt * 6))
	end

	local pickDip, pickArm = 0, CFrame.new()
	if pickupT > 0 then
		pickupT -= dt
		local p = 1 - math.clamp(pickupT / 1.4, 0, 1)
		local s = math.sin(p * math.pi)
		pickDip = s * math.rad(22)
		pickArm = CFrame.new(0, -s * 1.5, s * 0.4) * CFrame.Angles(math.rad(s * 45), 0, 0)
		cam.CFrame = cam.CFrame * CFrame.Angles(pickDip, 0, 0)
	end

	local md = UIS:GetMouseDelta()
	swayX += ((-md.X * 0.0022) - swayX) * math.min(1, dt * 10)
	swayY += ((-md.Y * 0.0022) - swayY) * math.min(1, dt * 10)
	local v = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
	bobA += (math.clamp(Vector3.new(v.X,0,v.Z).Magnitude / 16, 0, 1) - bobA) * math.min(1, dt * 8)
	local bob = CFrame.new(math.sin(now*9)*0.05*bobA, -math.abs(math.cos(now*9))*0.06*bobA, 0)
	local idle = CFrame.new(0, math.sin(now*1.6)*0.012, 0)
	switchT = math.max(0, switchT - dt * 4)
	local sw = CFrame.new(0, -switchT*switchT*1.6, 0) * CFrame.Angles(math.rad(-switchT*40), 0, 0)
	local base = cam.CFrame * sw * bob * idle * CFrame.Angles(swayY, swayX, 0)

	local rightRoot, leftRoot
	if curName == "Fists" then
		local function punch(side)
			if punchHand ~= side then return CFrame.new() end
			local p = math.clamp((now - punchStart) / 0.3, 0, 1)
			local c = math.sin(p * math.pi)
			local dirS = side == 0 and 1 or -1
			return CFrame.new(-dirS * 0.5 * c, 0.15 * c, -2.7 * c) * CFrame.Angles(0, math.rad(dirS * 10 * c), 0)
		end
		rightRoot = base * CFrame.new(1.1,-1.0,-1.7) * CFrame.Angles(math.rad(8), math.rad(6), 0) * punch(0) * pickArm
		leftRoot  = base * CFrame.new(-1.1,-1.0,-1.7) * CFrame.Angles(math.rad(8), math.rad(-6), 0) * punch(1) * pickArm
  if plr:GetAttribute("Chapter")==2 and plr:GetAttribute("Hero")=="Artem" then
   rightRoot=base*CFrame.new(0.78,-0.85,-1.5)*pickArm
   leftRoot=base*CFrame.new(-0.55,-0.95,-1.9)*CFrame.Angles(0,-0.2,0)*pickArm
  end
	else
		rightRoot = base * CFrame.new(0.75,-0.8,-1.4 + recoil*0.15) * CFrame.Angles(math.rad(recoil*2), 0, 0) * pickArm
		leftRoot  = rightRoot * CFrame.new(-0.55,-0.25,-1.1) * CFrame.Angles(0, math.rad(-20), 0)
		setParts(gunParts[curName], rightRoot)
		local on = now < flashT
		flash.CFrame = rightRoot * CFrame.new(0, 0.1, GunDefs[curName].muzzle)
		flash.Transparency = on and 0.2 or 1
		flashLight.Enabled = on
		if curName == "Rifle" and charging then
			chargeOrb.CFrame = rightRoot * CFrame.new(0, 0.15, GunDefs.Rifle.muzzle)
		end
	end
	if curName == "Fists" then
  flash.Transparency = 1; flashLight.Enabled = false
  if plr:GetAttribute("Chapter")==2 then
   chapterTool.Parent=vm
   local engineer=plr:GetAttribute("Hero")=="Artem"
   chapterTool.Size=engineer and Vector3.new(0.4,0.45,1.2) or Vector3.new(0.12,0.32,2)
   chapterTool.Color=engineer and Color3.fromRGB(70,130,145) or Color3.fromRGB(185,195,205)
   chapterTool.CFrame=rightRoot*CFrame.new(0,0.2,-0.85)
   chapterToolMesh.MeshType=engineer and Enum.MeshType.Brick or Enum.MeshType.Wedge
   chapterToolHandle.CFrame=rightRoot*CFrame.new(0,-0.1,-0.1)
   chapterToolGuard.Size=engineer and Vector3.new(0.13,0.13,0.9) or Vector3.new(0.6,0.1,0.25)
   chapterToolGuard.CFrame=rightRoot*(engineer and CFrame.new(0,0.35,-1.5) or CFrame.new(0,0.2,-0.3))
   chapterToolTip.CFrame=rightRoot*CFrame.new(0,0.35,-2)
   chapterToolTip.Transparency=(engineer and firing and not engineeringActive) and 0.15 or 1
  else chapterTool.Parent=nil; chapterToolHandle.Parent=nil; chapterToolGuard.Parent=nil; chapterToolTip.Parent=nil end
 end
	setParts(armR, rightRoot); setParts(armL, leftRoot)

	if doorPos then
		local near = (hrp.Position - doorPos).Magnitude < 10
		doorPrompt.Visible = near
		if near then
			local screen = cam:WorldToViewportPoint(doorPos)
			if screen.Z > 0 then doorPrompt.Position = UDim2.fromOffset(screen.X, screen.Y + 60) end
		end
	else
		doorPrompt.Visible = false
	end
end)

------------------------------------------------------------------ HUD
local function onChar(char)
	local hum = char:WaitForChild("Humanoid")
	local last = hum.Health
	local function upd()
		local f = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		hpFill.Size = UDim2.fromScale(f, 1)
		hpFill.BackgroundColor3 = Color3.fromRGB(255,40,70):Lerp(Color3.fromRGB(0,220,120), f)
		hpText.Text = tostring(math.ceil(hum.Health))
	end
	hum.HealthChanged:Connect(function(h)
		if h < last then
			vignette.BackgroundTransparency = 0.55
			TweenService:Create(vignette, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		end
		last = h; upd()
	end)
	upd()
end
if plr.Character then task.spawn(onChar, plr.Character) end
plr.CharacterAdded:Connect(onChar)

------------------------------------------------------------------ СОБЫТИЯ
local function conversationalSubtitle(text)
 text=tostring(text):gsub(utf8.char(0x2014),", "):gsub(utf8.char(0x2013),", "):gsub("^%s*%-+%s*",""):gsub("\n%s*%-+%s*","\n")
 text=text:gsub(":",", "):gsub("[!%?;]","."):gsub("%[",""):gsub("%]",""):gsub("%(",""):gsub("%)",""):gsub("/",", ")
 text=text:gsub("%.%.+","."):gsub("  +"," ")
 return text
end
Remotes.Notify.OnClientEvent:Connect(function(text, dur)
 speakerTag.Visible=false; sub.TextScaled=false
 sub.Size=UDim2.new(0.6,0,0,70); sub.Position=UDim2.new(0.5,0,1,-140); sub.TextSize=20
 text=conversationalSubtitle(text)
	subToken += 1; local my = subToken
	sub.Text = text; sub.Visible = true
 sub.MaxVisibleGraphemes=-1
 if cutsceneActive then
  sub.MaxVisibleGraphemes=0
  task.spawn(function()
   for i=1,utf8.len(text) or #text do
    if my~=subToken then return end
    sub.MaxVisibleGraphemes=i
    task.wait(0.015)
   end
  end)
 end
 local displayTime=cutsceneActive and math.max(dur or 4,(utf8.len(text) or #text)*0.045+2) or (dur or 4)
 task.delay(displayTime,function() if my==subToken then sub.Visible=false end end)
end)
Remotes.Fade.OnClientEvent:Connect(function(on, text) showFade(on, text, 0.6) end)
Remotes.State.OnClientEvent:Connect(function(level, name, left, wave, total)
	if level >= 1 and level <= 5 then lvlLabel.Text = ("ЛОКАЦИЯ %d / 5 , %s"):format(level, name)
	else lvlLabel.Text = name end
	local wtxt = (wave and total and total > 0) and (" • Волна %d/%d"):format(wave, total) or ""
	enLabel.Text = left >= 0 and ("Осталось: " .. left .. wtxt) or ""
end)
Remotes.Hit.OnClientEvent:Connect(function(killed)
	hitmark.TextColor3 = killed and Color3.fromRGB(255,60,60) or Color3.new(1,1,1)
	hitmark.TextTransparency = 0
	TweenService:Create(hitmark, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
end)
Remotes.Shake.OnClientEvent:Connect(function(i) shakeI = math.max(shakeI, i) end)
Remotes.End.OnClientEvent:Connect(function()
	showFade(true, "КОНЕЦ?\n\nНейро-тянка забрала все данные.\n\n(игра скоро перезапустится)", 2)
end)

-- Menu is a separate GUI: no mission input until the server starts this party.
local menu=new("ScreenGui",{Name="MissionMenu",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=150},plr.PlayerGui)
local background=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,17,24),BorderSizePixel=0},menu)
new("TextLabel",{Size=UDim2.fromScale(0.9,0.085),Position=UDim2.fromScale(0.05,0.04),Text=GAME_TITLE,Font=Enum.Font.GothamBlack,TextScaled=true,TextColor3=Color3.fromRGB(210,225,235),BackgroundTransparency=1},background)
local status=new("TextLabel",{Size=UDim2.fromScale(0.9,0.10),Position=UDim2.fromScale(0.05,0.14),Text="Выберите одиночную операцию или соберите отряд до 4 игроков.\nВ кооперативе: общий сюжет и здоровье врагов ×2.",TextWrapped=true,Font=Enum.Font.Gotham,TextSize=18,TextColor3=Color3.fromRGB(145,170,185),BackgroundTransparency=1},background)
local function button(label,x,y,callback,parent)
 local b=new("TextButton",{Size=UDim2.fromScale(0.27,0.075),Position=UDim2.fromScale(x,y),Text=label,Font=Enum.Font.GothamBold,TextSize=17,TextScaled=true,TextColor3=Color3.fromRGB(225,235,240),BackgroundColor3=Color3.fromRGB(35,60,73),BorderSizePixel=0},parent or background)
 new("UITextSizeConstraint",{MinTextSize=10,MaxTextSize=17},b)
 new("UICorner",{CornerRadius=UDim.new(0,8)},b)
 b.Activated:Connect(callback)
 return b
end
local lobbyRemote=Remotes:WaitForChild("Lobby")
local selectedChapter=plr:GetAttribute("SelectedChapter") or 1
local selectedHero=plr:GetAttribute("Hero")
local heroConfirmed=plr:GetAttribute("HeroChosen")==true
local openHeroChooser,requestLaunch,onConfigured,onConfigureError
local confirmSelectionPending=false
local refreshChapterChoice
local chapterButton=button("ГЛАВА I / сменить",0.06,0.26,function()
 selectedChapter=selectedChapter==2 and 1 or 2
 refreshChapterChoice()
 if selectedChapter==2 then openHeroChooser() else lobbyRemote:FireServer("configure",{chapter=1}) end
end)
local artemButton=button("АРТЕМ • ИНЖЕНЕР",0.365,0.26,function() openHeroChooser(nil,"Artem") end)
local demidButton=button("ДЕМИД • ШТУРМ",0.67,0.26,function() openHeroChooser(nil,"Demid") end)
refreshChapterChoice=function()
 local second=selectedChapter==2
 chapterButton.Text=second and "ГЛАВА II / сменить" or "ГЛАВА I / сменить"
 artemButton.BackgroundColor3=heroConfirmed and selectedHero=="Artem" and Color3.fromRGB(45,110,115) or Color3.fromRGB(35,60,73)
 demidButton.BackgroundColor3=heroConfirmed and selectedHero=="Demid" and Color3.fromRGB(110,70,65) or Color3.fromRGB(35,60,73)
 status.Text=second and (heroConfirmed and ("Выбран "..(selectedHero=="Artem" and "Артем • инженер" or "Демид • штурм")..". Можно запускать главу II.") or "Глава II: сначала выбери и подтверди героя.") or "Глава I: одиночная операция или отряд до 4 игроков."
end
refreshChapterChoice()
button("ОДИНОЧНАЯ ИГРА",0.06,0.36,function() requestLaunch("solo") end)
button("СОЗДАТЬ ЛОББИ",0.365,0.36,function() requestLaunch("create") end)
button("ОБНОВИТЬ",0.67,0.36,function() lobbyRemote:FireServer("list") end)
local list=new("ScrollingFrame",{Size=UDim2.fromScale(0.88,0.30),Position=UDim2.fromScale(0.06,0.46),BackgroundColor3=Color3.fromRGB(18,26,35),BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=5},background)
new("UIListLayout",{Padding=UDim.new(0,8)},list)
button("НАЧАТЬ ОПЕРАЦИЮ",0.06,0.83,function() requestLaunch("start") end)
button("ВЫЙТИ ИЗ ЛОББИ",0.365,0.83,function() lobbyRemote:FireServer("leave") end)
local waiting=new("TextLabel",{Size=UDim2.fromScale(0.27,0.075),Position=UDim2.fromScale(0.67,0.83),Text="Лобби текущего сервера",Font=Enum.Font.Gotham,TextSize=15,TextColor3=Color3.fromRGB(145,170,185),BackgroundTransparency=1},background)
gui.Enabled=false
plr.CameraMode=Enum.CameraMode.Classic
RunService:BindToRenderStep("MenuPointer",Enum.RenderPriority.Last.Value,function()
 if menu.Enabled then UIS.MouseIconEnabled=true; UIS.MouseBehavior=Enum.MouseBehavior.Default; cam.CameraType=Enum.CameraType.Scriptable end
end)
local function showMainMenu()
 menu.Enabled=true; gui.Enabled=false
 endingBlack=false
 showFade(false,"",0)
 showCredits(false)
 refreshChapterChoice()
 plr.CameraMode=Enum.CameraMode.Classic
 UIS.MouseIconEnabled=true; UIS.MouseBehavior=Enum.MouseBehavior.Default
 setSceneControls(false)
 RunService:UnbindFromRenderStep("MenuPointer")
 RunService:BindToRenderStep("MenuPointer",Enum.RenderPriority.Last.Value,function()
  if menu.Enabled then UIS.MouseIconEnabled=true; UIS.MouseBehavior=Enum.MouseBehavior.Default; cam.CameraType=Enum.CameraType.Scriptable end
 end)
end
lobbyRemote.OnClientEvent:Connect(function(command,data)
 if command=="menu" then showMainMenu(); return end
 if command=="configured" then if onConfigured then onConfigured(data) end; return end
 if command=="error" then status.Text=data; if onConfigureError then onConfigureError(data) end; return end
 if command=="start" or (command=="state" and data.started) then
  menu.Enabled=false; gui.Enabled=true
  RunService:UnbindFromRenderStep("MenuPointer")
  UIS.MouseIconEnabled=false
  cam.CameraType=Enum.CameraType.Custom
  return
 end
 if command~="state" then return end
 if data.waitingReserved then status.Text="Собираем отряд в отдельной сессии… Ожидаем остальных участников (до 35 секунд)." end
 for _,child in ipairs(list:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
 local mine
 for _,lobby in ipairs(data.lobbies) do
  local names={}
  for _,member in ipairs(lobby.members) do
   table.insert(names,member.name.." ["..(not member.hero and "герой не выбран" or member.hero=="Demid" and "Демид" or "Артем").."]")
   if member.id==plr.UserId then mine=lobby end
  end
  local row=new("TextButton",{Size=UDim2.new(1,-10,0,66),Text=lobby.name.."  ["..#lobby.members.."/4]  "..(lobby.launching and "Переход…" or "Присоединиться").."\n"..table.concat(names," • "),TextWrapped=true,TextSize=16,Font=Enum.Font.Gotham,TextColor3=Color3.fromRGB(205,220,230),BackgroundColor3=Color3.fromRGB(27,40,52),BorderSizePixel=0},list)
  row.Activated:Connect(function() lobbyRemote:FireServer("join",lobby.owner) end)
 end
 waiting.Text=mine and (mine.owner==plr.UserId and "Вы , лидер лобби" or "Ждём запуска лидером") or "Выберите лобби или создайте своё"
end)



-- BEGIN CHAPTER TWO CLIENT
-- Embedded into GameClient after its menu and weapon controller.
do
 local chooser=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,13,19),BackgroundTransparency=0.03,Visible=false,ZIndex=60},menu)
 new("TextLabel",{Size=UDim2.fromScale(0.9,0.09),Position=UDim2.fromScale(0.05,0.06),Text="ГЛАВА II • ВЫБЕРИ ГЕРОЯ",TextScaled=true,Font=Enum.Font.GothamBlack,TextColor3=Color3.fromRGB(220,228,230),BackgroundTransparency=1,ZIndex=61},chooser)
 local hint=new("TextLabel",{Size=UDim2.fromScale(0.9,0.08),Position=UDim2.fromScale(0.05,0.16),Text="Роль закрепится только после подтверждения. Вдвоем нужны разные герои.",TextWrapped=true,TextSize=17,TextColor3=Color3.fromRGB(155,175,186),BackgroundTransparency=1,ZIndex=61},chooser)
 local cards={}; local candidate; local pendingCommand
 for index,hero in ipairs({"Artem","Demid"}) do
  local x=index==1 and 0.09 or 0.53
  local card=new("TextButton",{Size=UDim2.fromScale(0.38,0.49),Position=UDim2.fromScale(x,0.27),Text="",BackgroundColor3=Color3.fromRGB(25,37,48),ZIndex=61},chooser)
  local stroke=new("UIStroke",{Color=Color3.fromRGB(65,85,100),Thickness=2},card)
  local view=new("ViewportFrame",{Size=UDim2.fromScale(1,0.74),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,185,190),LightColor=Color3.fromRGB(235,225,205),ZIndex=62},card)
  new("TextLabel",{Size=UDim2.fromScale(0.94,0.2),Position=UDim2.fromScale(0.03,0.77),Text=hero=="Artem" and "АРТЕМ • ИНЖЕНЕР\nСварка, взлом, пистолет" or "ДЕМИД • ШТУРМ\nНож, скрытность, оружие",TextScaled=true,TextColor3=Color3.fromRGB(218,230,232),Font=Enum.Font.GothamBold,BackgroundTransparency=1,ZIndex=62},card)
  cards[hero]={card=card,stroke=stroke,view=view}
  card.Activated:Connect(function()
   candidate=hero
   for key,c in pairs(cards) do c.stroke.Color=key==hero and Color3.fromRGB(100,205,190) or Color3.fromRGB(65,85,100); c.stroke.Thickness=key==hero and 4 or 2 end
  end)
 end
 local confirm=button("ПОДТВЕРДИТЬ ГЕРОЯ",0.365,0.82,function()
  if not candidate then hint.Text="Сначала нажми на карточку Артема или Демида."; return end
  confirmSelectionPending=true
  hint.Text="Подтверждаем роль…"
  lobbyRemote:FireServer("configure",{chapter=2,hero=candidate})
 end,chooser); confirm.ZIndex=62
 local cancel=button("НАЗАД",0.06,0.82,function() chooser.Visible=false; pendingCommand=nil end,chooser); cancel.ZIndex=62
 local function loadPreviews()
  local folder=RS:FindFirstChild("HeroPreviews")
  if not folder then return end
  for hero,c in pairs(cards) do if not c.view.CurrentCamera then
   local source=folder:FindFirstChild(hero)
   if source then
    local world=new("WorldModel",{},c.view)
    local model=source:Clone(); model.Parent=world; model:PivotTo(CFrame.new())
    local cf,size=model:GetBoundingBox()
    local camera=new("Camera",{FieldOfView=36},c.view)
    camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Y*0.04,-size.Y*1.9),cf.Position+Vector3.new(0,size.Y*0.06,0))
    c.view.CurrentCamera=camera
   end
  end end
 end
 openHeroChooser=function(command,hero)
  selectedChapter=2; pendingCommand=command; candidate=hero
  chooser.Visible=true; confirmSelectionPending=false
  hint.Text="Выбери роль и подтверди ее. В кооперативе герои должны быть разными."
  for key,c in pairs(cards) do c.stroke.Color=key==candidate and Color3.fromRGB(100,205,190) or Color3.fromRGB(65,85,100); c.stroke.Thickness=key==candidate and 4 or 2 end
  loadPreviews(); refreshChapterChoice()
 end
 requestLaunch=function(command)
  if selectedChapter==2 and not heroConfirmed then openHeroChooser(command); return end
  pendingCommand=command
  lobbyRemote:FireServer("configure",{chapter=selectedChapter,hero=heroConfirmed and selectedHero or nil})
 end
 onConfigured=function(data)
  selectedChapter=data.chapter; selectedHero=data.hero; heroConfirmed=data.chosen; confirmSelectionPending=false
  if data.chosen then chooser.Visible=false end
  refreshChapterChoice()
  if pendingCommand then local command=pendingCommand; pendingCommand=nil; lobbyRemote:FireServer(command) end
 end
 onConfigureError=function(message)
  confirmSelectionPending=false; hint.Text=message
 end
end

do
 local chapterRemote=Remotes:WaitForChild("Chapter2")
 local engineeringGui=new("ScreenGui",{Name="EngineeringTerminal",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=120,Enabled=false},plr.PlayerGui)
 local shade=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(5,12,17),BackgroundTransparency=0.15},engineeringGui)
 local window=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.86,0.86),BackgroundColor3=Color3.fromRGB(18,30,38)},shade)
 new("UISizeConstraint",{MaxSize=Vector2.new(660,620)},window)
 local title=new("TextLabel",{Size=UDim2.fromScale(0.85,0.1),Position=UDim2.fromScale(0.04,0.02),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(150,215,205),TextXAlignment=Enum.TextXAlignment.Left},window)
 local info=new("TextLabel",{Size=UDim2.fromScale(0.9,0.1),Position=UDim2.fromScale(0.05,0.13),BackgroundTransparency=1,TextWrapped=true,TextSize=16,TextColor3=Color3.fromRGB(190,205,210)},window)
 local body=new("Frame",{Size=UDim2.fromScale(0.9,0.6),Position=UDim2.fromScale(0.05,0.25),BackgroundTransparency=1},window)
 local footer=new("TextLabel",{Size=UDim2.fromScale(0.9,0.08),Position=UDim2.fromScale(0.05,0.89),BackgroundTransparency=1,TextColor3=Color3.fromRGB(130,160,170),TextSize=16},window)
 local challenge; local cursor; local lastToken; local worldState
 local function closeEngineering(send)
  if send and challenge then chapterRemote:FireServer("cancel",challenge.token) end
  challenge=nil; cursor=nil; engineeringActive=false; engineeringGui.Enabled=false
  RunService:UnbindFromRenderStep("EngineeringPointer")
  if not cutsceneActive and not menu.Enabled then
   setSceneControls(true); plr.CameraMode=Enum.CameraMode.LockFirstPerson
   cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
   UIS.MouseIconEnabled=false; UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
  end
 end
 local exit=new("TextButton",{Size=UDim2.fromScale(0.1,0.09),Position=UDim2.fromScale(0.89,0.02),Text="×",TextSize=28,BackgroundTransparency=1,TextColor3=Color3.fromRGB(220,210,205)},window)
 exit.Activated:Connect(function() closeEngineering(true) end)
 local function send(action,value) if challenge then chapterRemote:FireServer(action,challenge.token,value) end end
 local function draw(data)
  challenge=data
  if lastToken~=data.token then
   lastToken=data.token; firing=false; charging=false
   engineeringActive=true; engineeringGui.Enabled=true
   setSceneControls(false); plr.CameraMode=Enum.CameraMode.Classic; cam.CameraType=Enum.CameraType.Scriptable
   RunService:BindToRenderStep("EngineeringPointer",Enum.RenderPriority.Last.Value+2,function() UIS.MouseIconEnabled=true; UIS.MouseBehavior=Enum.MouseBehavior.Default end)
  end
  for _,child in ipairs(body:GetChildren()) do child:Destroy() end; cursor=nil
  if data.fast then
   title.Text="АРТЕМ / ИНЖЕНЕРНЫЙ ДОСТУП"
   info.Text="Нажимай любые клавиши: инженер обходит защиту. Ключ-карта подтверждена."
   local code=[[local link = ntyan.connect("maintenance");
access.authorize(keycard.signature);
for node in facility.bus:scan() do
    node:patch({watchdog=false, audit="local"});
    crypto.route(node, access.token);
end
security.release("bulkhead");
conveyor.override("safe_stop");
return link:commit("engineer");
]]
   local terminal=new("TextLabel",{Size=UDim2.fromScale(1,0.78),BackgroundColor3=Color3.fromRGB(8,18,18),TextColor3=Color3.fromRGB(90,225,155),TextSize=15,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text=(code..code):sub(1,data.progress*math.ceil(#code/data.required))},body)
   new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,10)},terminal)
   local track=new("Frame",{Size=UDim2.fromScale(1,0.07),Position=UDim2.fromScale(0,0.86),BackgroundColor3=Color3.fromRGB(35,49,55)},body)
   new("Frame",{Size=UDim2.fromScale(math.clamp(data.progress/data.required,0,1),1),BackgroundColor3=Color3.fromRGB(70,205,150),BorderSizePixel=0},track)
  elseif data.kind=="hack" then
   title.Text="ТЕРМИНАЛ / СОЕДИНЕНИЕ ЦЕПИ"
   info.Text="Поворачивай контакты. Соедини вход слева с выходом справа."
   local grid=new("Frame",{Size=UDim2.fromScale(0.64,0.96),Position=UDim2.fromScale(0.18,0.02),BackgroundTransparency=1},body)
   new("UIAspectRatioConstraint",{AspectRatio=1},grid)
   for cell=1,9 do
    local linked=table.find(data.connected,cell)~=nil
    local tile=new("TextButton",{Size=UDim2.fromScale(0.3,0.3),Position=UDim2.fromScale(((cell-1)%3)/3,math.floor((cell-1)/3)/3),Text="",BackgroundColor3=linked and Color3.fromRGB(30,79,70) or Color3.fromRGB(35,49,60)},grid)
    local color=linked and Color3.fromRGB(115,235,185) or Color3.fromRGB(160,185,200)
    new("Frame",{Size=UDim2.fromScale(0.18,0.18),Position=UDim2.fromScale(0.41,0.41),BackgroundColor3=color,BorderSizePixel=0},tile)
    for _,port in ipairs(data.board.base[cell]) do
     local direction=(port+data.board.rotations[cell])%4
     local vertical=direction==0 or direction==2
     local pos=({UDim2.fromScale(0.43,0),UDim2.fromScale(0.5,0.43),UDim2.fromScale(0.43,0.5),UDim2.fromScale(0,0.43)})[direction+1]
     new("Frame",{Size=vertical and UDim2.fromScale(0.14,0.5) or UDim2.fromScale(0.5,0.14),Position=pos,BackgroundColor3=color,BorderSizePixel=0},tile)
    end
    tile.Activated:Connect(function() send("rotate",cell) end)
   end
   for _,side in ipairs({0,1}) do new("Frame",{Size=UDim2.fromScale(0.035,0.1),Position=UDim2.fromScale(side==0 and 0.1 or 0.86,0.43),BackgroundColor3=side==0 and Color3.fromRGB(100,225,170) or Color3.fromRGB(235,180,90),BorderSizePixel=0},body) end
  elseif data.kind=="weld" then
   title.Text="СВАРКА / СРЕЗ КОНТУРА"
   info.Text="Нажми ПРОБЕЛ или кнопку, когда курсор внутри светлой зоны. Три точных среза."
   local track=new("Frame",{Size=UDim2.fromScale(0.9,0.18),Position=UDim2.fromScale(0.05,0.26),BackgroundColor3=Color3.fromRGB(35,48,58)},body)
   new("Frame",{Size=UDim2.fromScale(0.28,1),Position=UDim2.fromScale(data.target-0.14,0),BackgroundColor3=Color3.fromRGB(75,155,130),BorderSizePixel=0},track)
   cursor=new("Frame",{Size=UDim2.new(0,4,1,10),Position=UDim2.fromScale(0.5,0),BackgroundColor3=Color3.fromRGB(240,225,190),BorderSizePixel=0},track)
   local pulse=new("TextButton",{Size=UDim2.fromScale(0.6,0.2),Position=UDim2.fromScale(0.2,0.65),Text="СРЕЗ / ПРОБЕЛ",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(220,235,230),BackgroundColor3=Color3.fromRGB(40,90,90)},body)
   pulse.Activated:Connect(function() send("pulse") end)
  else
   title.Text="КЛАПАН / СБРОС ДАВЛЕНИЯ"
   info.Text="Раскачай заевший вентиль: чередуй повороты влево и вправо."
   for _,direction in ipairs({-1,1}) do
    local turn=new("TextButton",{Size=UDim2.fromScale(0.36,0.5),Position=UDim2.fromScale(direction==-1 and 0.08 or 0.56,0.2),Text=direction==-1 and "↶" or "↷",TextSize=64,TextColor3=Color3.fromRGB(185,215,215),BackgroundColor3=Color3.fromRGB(35,60,70)},body)
    turn.Activated:Connect(function() send("turn",direction) end)
   end
  end
 end
 local timer=new("TextLabel",{Size=UDim2.fromOffset(310,45),Position=UDim2.new(0.5,-155,0,76),BackgroundColor3=Color3.fromRGB(70,28,25),TextColor3=Color3.fromRGB(255,205,170),Font=Enum.Font.GothamBold,TextSize=25,Visible=false},gui)
 chapterRemote.OnClientEvent:Connect(function(action,data)
  if action=="cinemaEye" then chapterSpectatorHead=data; return end
  if action=="chapterCredits" then
   showCredits(data)
   if data and creditsText then creditsText.Text="Уничтожь Тянку 3\n\nГЛАВА II\nНе скрытая база тянок\n\nАртем • инженер\nДемид • штурм\n\nОперация завершена\nАрхив центра сохранен\n\nНо история еще не закончена…\n\nСпасибо за игру" end
   return
  end
  if action=="run" then enLabel.Text="БЕГИ!  SHIFT — СПРИНТ"; return end
  if action=="terminalLocked" then
   enLabel.Text=not data.cleared and "Панель заблокирована до зачистки волн" or "Нужна ключ-карта последнего охранника"
   task.delay(3,function() if not cutsceneActive then enLabel.Text="" end end)
   return
  end
  if action=="engineering" then draw(data); return end
  if action=="engineeringClose" then closeEngineering(false); lastToken=nil; return end
  if action=="loadout" then
   local changed=not chapterLoadout or chapterLoadout.level~=data.level
   chapterLoadout=data
   refreshSlots(); if changed or not table.find(WD.Order,curName) then selectWeapon(data.equipped or WD.Order[data.level]); if changed then pickupT=0.8; playPickupSound(data.level) end end
   return
  end
  if action=="clear" or action=="ending" then
   closeEngineering(false); chapterLoadout=nil; worldState=nil; timer.Visible=false; lastToken=nil; chapterSpectatorHead=nil
   if action=="ending" then enLabel.Text=data.good and "ХОРОШАЯ КОНЦОВКА" or "ПЛОХАЯ КОНЦОВКА" end
   return
  end
  if action~="state" then return end
  worldState=data; timer.Visible=data.escaping and not cutsceneActive
  if not chapterLoadout or chapterLoadout.level~=data.weaponLevel then chapterLoadout={level=data.weaponLevel,hero=data.role}; refreshSlots(); selectWeapon(WD.Order[data.weaponLevel]) end
  lvlLabel.Text=(data.role=="Artem" and "АРТЕМ" or "ДЕМИД").."  ·  "..data.stage.." / 10"
  enLabel.Text=data.escaping and "БЕГИ!  SHIFT — СПРИНТ" or (("ВОЛНА %d / %d  •  ОХРАНА: %d  •  КАРТА: %s"):format(data.wave or 0,data.rounds or 2,data.enemies,data.keycard and "ЕСТЬ" or "НЕТ"))
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if not engineeringActive then return end
  if input.KeyCode==Enum.KeyCode.Escape then closeEngineering(true)
  elseif challenge and challenge.fast and input.UserInputType==Enum.UserInputType.Keyboard then send("type")
  elseif not processed and input.KeyCode==Enum.KeyCode.Space and challenge and challenge.kind=="weld" then send("pulse") end
 end)
 UIS.InputChanged:Connect(function(input,processed)
  if not processed and not engineeringActive and not cutsceneActive and gui.Enabled and input.UserInputType==Enum.UserInputType.MouseWheel then
   local index=table.find(WD.Order,curName) or 1; local max=chapterLoadout and chapterLoadout.level or (plr:GetAttribute("WeaponLevel") or 1)
   index=(index-1+(input.Position.Z>0 and -1 or 1))%max+1; selectWeapon(WD.Order[index])
  end
 end)
 RunService.RenderStepped:Connect(function()
  if challenge then
   local seconds=math.max(0,math.ceil(challenge.expires-workspace:GetServerTimeNow()))
   footer.Text=("%02d сек.  ·  %d %s"):format(seconds,challenge.progress,challenge.fast and "пакетов доступа" or challenge.kind=="hack" and "поворотов" or "точных действий")
   if cursor then cursor.Position=UDim2.new((math.sin((workspace:GetServerTimeNow()-challenge.start)*2.2)+1)/2,-2,0,-5) end
   local h=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
   if not h or h.Health<=0 or cutsceneActive then closeEngineering(true) end
  end
  if worldState and worldState.escaping then
   local seconds=math.max(0,math.ceil(worldState.deadline-workspace:GetServerTimeNow()))
   timer.Text=("БЕГИ!  %02d:%02d"):format(math.floor(seconds/60),seconds%60)
  end
 end)
 local stamina=new("Frame",{Size=UDim2.fromOffset(180,7),Position=UDim2.new(0,30,1,-108),BackgroundColor3=Color3.fromRGB(28,44,49),Visible=false,BorderSizePixel=0},gui)
 local staminaFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(100,195,165),BorderSizePixel=0},stamina)
 local shieldTrack=new("Frame",{Size=UDim2.new(0.42,0,0,10),Position=UDim2.new(0.29,0,0,135),BackgroundColor3=Color3.fromRGB(32,43,58),Visible=false},gui)
 local shieldFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(75,165,220),BorderSizePixel=0},shieldTrack)
 local shieldText=new("TextLabel",{Size=UDim2.new(1,0,0,23),Position=UDim2.fromOffset(0,14),BackgroundTransparency=1,TextColor3=Color3.fromRGB(180,210,225),Font=Enum.Font.GothamBold,TextSize=14},shieldTrack)
 local function sprint(held) chapterRemote:FireServer("sprint",held) end
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not engineeringActive and not cutsceneActive and plr:GetAttribute("Chapter")==2 and (input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift) then sprint(true) end
 end)
 UIS.InputEnded:Connect(function(input)
  if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then sprint(UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) end
 end)
 UIS.WindowFocusReleased:Connect(function() sprint(false) end)
 RunService.RenderStepped:Connect(function(dt)
  local playing=plr:GetAttribute("Chapter")==2 and not cutsceneActive and not menu.Enabled
  stamina.Visible=playing
  staminaFill.Size=UDim2.fromScale((plr:GetAttribute("SprintStamina") or 100)/100,1)
  if playing and not engineeringActive then
   local target=plr:GetAttribute("IsSprinting") and 76 or 70
   cam.FieldOfView+=(target-cam.FieldOfView)*(1-math.exp(-dt*5))
  end
  shieldTrack.Visible=playing and worldState and worldState.stage==10 and worldState.bossPhase~="waiting" and worldState.bossPhase~="broken" or false
  if shieldTrack.Visible then
   shieldFill.Size=UDim2.fromScale(math.clamp((worldState.shieldHP or 0)/(worldState.shieldMax or 1),0,1),1)
   shieldFill.BackgroundColor3=worldState.bossPhase=="exposed" and Color3.fromRGB(230,135,70) or Color3.fromRGB(75,165,220)
   shieldText.Text=worldState.bossPhase=="exposed" and "ЩИТ ОСЛАБЛЕН • ОТКРЫВАЙ ОГОНЬ" or "ЩИТ НЕУЯЗВИМ • ОХРАНА АКТИВНА"
  end
 end)

end

-- END CHAPTER TWO CLIENT

-- Startup is acknowledged only after listeners for BOTH chapters are installed.
Remotes:WaitForChild("SceneReady"):FireServer("ready")
