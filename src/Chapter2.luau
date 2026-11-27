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
local c2Origin=Vector3.new(16000,0,0)
local c2Send,c2Finish,c2Activate,c2Escape
local function c2Part(parent,name,size,pos,color,material)
 local p=part(parent,size,pos,color,material or Enum.Material.SmoothPlastic); p.Name=name; return p
end
local function c2Label(p,text)
 local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(310,70); g.StudsOffset=Vector3.new(0,4,0); g.MaxDistance=100; g.AlwaysOnTop=true; g.Parent=p
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=0.3; t.BackgroundColor3=C(12,20,28); t.TextColor3=C(205,230,235); t.Font=Enum.Font.GothamBold; t.TextSize=16; t.TextWrapped=true; t.Text=text; t.Parent=g
 return t
end
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
 for m,e in pairs(C2.mobs) do if m.Parent and e.hum.Health>0 and not e.defeated and e.zone==zone then n+=1 end end
 return n
end
c2Send=function()
 local z=C2.zones and C2.zones[C2.stage]
 for _,p in ipairs(C2.party) do if p.Parent then
  local displayStage=C2.stage
  local root=c2Root(p)
  if C2.escaping and root then displayStage=math.clamp(math.floor((root.Position.X-c2Origin.X+75)/160)+1,1,10) end
  C2RE:FireClient(p,"state",{stage=displayStage,name=C2_ZONES[displayStage].name,objective=C2.escaping and "БЕГИТЕ К МАШИНЕ У ВЪЕЗДА • все выжившие должны добраться до выхода" or (z and z.done and "Панель готова. Пройдите через открытый шлюз." or C2_ZONES[C2.stage].task),role=p:GetAttribute("Hero"),escaping=C2.escaping,deadline=C2.deadline,alarm=C2.alarm,enemies=c2Count(displayStage)})
 end end
end
local function c2Dress(m,mech)
 -- Layered hair, uniform, face and trim, rather than recolored combat blocks.
 local head=m:FindFirstChild("Head"); local torso=m:FindFirstChild("Torso")
 if not head or not torso then return end
 local face=head:FindFirstChildWhichIsA("Decal")
 if not face then face=Instance.new("Decal"); face.Face=Enum.NormalId.Front; face.Texture="rbxasset://textures/face.png"; face.Parent=head end
 local function trim(name,size,offset,color,base,shape)
  local p=c2Part(m,name,size,Vector3.zero,color); p.CanCollide=false; p.Massless=true; p.CFrame=base.CFrame*offset
  if shape then p.Shape=shape end
  local w=Instance.new("WeldConstraint"); w.Part0=base; w.Part1=p; w.Parent=p
 end
 for _,side in ipairs({-1,1}) do
  trim("HairRibbon",Vector3.new(0.65,0.4,0.35),CFrame.new(side*1.12,0.5,0),C(165,65,95),head)
  trim("UniformCuff",Vector3.new(0.18,1.7,1.1),CFrame.new(side*1.05,0,0),C(220,220,225),torso)
 end
 trim("Collar",Vector3.new(1.8,0.18,1.08),CFrame.new(0,0.85,0),C(225,225,230),torso)
 trim("Tie",Vector3.new(0.3,0.85,0.12),CFrame.new(0,0.35,-0.58),C(170,65,95),torso)
 if mech then
  trim("MechArmor",Vector3.new(2.6,2.3,1.5),CFrame.new(),C(55,65,80),torso)
  for _,s in ipairs({-1,1}) do trim("RocketPod",Vector3.new(1,1,2.3),CFrame.new(s*1.8,0.8,0),C(90,100,115),torso) end
 end
end
local function c2Rocket(e,target,serial)
 local from=e.root.Position+Vector3.new(0,2,0); local goal=target.Position
 local marker=c2Part(C2.map,"RocketWarning",Vector3.new(9,0.08,9),Vector3.new(goal.X,0.28,goal.Z),C(245,80,40),Enum.Material.Neon); marker.CanCollide=false
 c2Label(marker,"РАКЕТА • УХОДИ!")
 task.wait(1.15)
 if not C2.active or C2.serial~=serial or e.hum.Health<=0 then marker:Destroy(); return end
 local rocket=c2Part(C2.map,"Rocket",Vector3.new(0.7,0.7,2.3),from,C(230,145,65),Enum.Material.Neon); rocket.CanCollide=false
 TweenService:Create(rocket,TweenInfo.new(0.65),{Position=goal}):Play(); task.wait(0.65)
 if not C2.active or C2.serial~=serial then return end
 rocket:Destroy(); marker:Destroy()
 local flash=c2Part(C2.map,"Blast",Vector3.new(10,10,10),goal,C(245,125,55),Enum.Material.Neon); flash.Shape=Enum.PartType.Ball; flash.CanCollide=false; Debris:AddItem(flash,0.25)
 for _,p in ipairs(C2.party) do local r,h=c2Root(p); if r and (r.Position-goal).Magnitude<11 then h:TakeDamage(48) end end
end
local function c2Spawn(zone,pos,mech,boss)
 local cfg=table.clone(boss and Types.Mafiozi or Types.Pistol)
 if not boss then
  cfg.Male=false; cfg.Name=mech and "Меха-тян • ракетчица" or "Охрана мини-завода"
  cfg.Hair=C(75+zone*7,45,95+zone*4); cfg.Shirt=C(45,55,85); cfg.Skirt=C(35,40,65); cfg.Legs=C(55,50,65)
 end
 local m,h,r,j=buildRig(cfg,CFrame.new(pos)); m.Parent=C2.map; m:SetAttribute("Enemy",true); m:SetAttribute("Chapter2Enemy",true)
 h.HealthDisplayType=Enum.HumanoidHealthDisplayType.DisplayWhenDamaged; h.HealthDisplayDistance=80
 h.MaxHealth=(boss and 750 or mech and 180 or 85)*(#C2.party>1 and 1.6 or 1); h.Health=h.MaxHealth; h.WalkSpeed=boss and 9 or 12
 r:SetNetworkOwner(nil); if not boss then c2Dress(m,mech) end
 local e={hum=h,root=r,zone=zone,mech=mech,boss=boss,blind=0,last=0,patrol=pos,joints=j,base={RH=j.RH.C0,LH=j.LH.C0,LS=j.LS.C0,RS=j.RS.C0}}; C2.mobs[m]=e
 h.Died:Connect(function() if C2.active then c2Send() end; ragdoll(m); Debris:AddItem(m,boss and 60 or 12) end)
 local serial=C2.serial
 task.spawn(function()
  while C2.active and serial==C2.serial and m.Parent and h.Health>0 and not e.defeated do
   local target,dist=nil,math.huge
   for _,p in ipairs(C2.party) do local root=c2Root(p); if root then local d=(root.Position-r.Position).Magnitude; if d<dist then target=root; dist=d end end end
   if target and workspace:GetServerTimeNow()>e.blind then
    local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={m}
    local hit=workspace:Raycast(r.Position,target.Position-r.Position,rp)
    local visible=hit and hit.Instance:IsDescendantOf(target.Parent)
    local facing=r.CFrame.LookVector:Dot((target.Position-r.Position).Unit)>0.1
    if dist<90 and visible and (C2.alarm or facing or dist<9) then
     if not C2.alarm then C2.alarm=true; c2Send() end
     if dist>14 then h:MoveTo(target.Position) else h:MoveTo(r.Position) end
     if os.clock()-e.last>(mech and 5 or 1.6) then
      e.last=os.clock()
      if mech then task.spawn(c2Rocket,e,target,serial)
      else
       tracer(r.Position+Vector3.new(0,1,0),target.Position,C(245,170,90))
       local th=target.Parent:FindFirstChildOfClass("Humanoid"); if th then th:TakeDamage(boss and 16 or 9) end
      end
     end
    else
     -- Predictable patrols allow rear knife takedowns without forced combat.
     local offset=math.sin(os.clock()*0.32+zone)*12
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
local function c2Build()
 C2.map=Instance.new("Model"); C2.map.Name="Chapter2Factory"; C2.map.Parent=levelFolder; C2.zones={}
 local function prop(parent,name,size,offset,color,mat) return c2Part(parent,name,size,c2Origin+offset,color,mat) end
 -- The entire retreat is real contiguous geometry, not ten teleporting arenas.
 prop(C2.map,"Ground",Vector3.new(1740,2,260),Vector3.new(780,-1,0),C(36,43,42),Enum.Material.Asphalt)
 prop(C2.map,"ApproachRearFence",Vector3.new(1,18,100),Vector3.new(-75,9,0),C(55,63,72),Enum.Material.Metal)
 local facade=prop(C2.map,"MainFactoryFacade",Vector3.new(1050,40,25),Vector3.new(860,20,-83),C(58,68,79),Enum.Material.CorrodedMetal)
 local sg=Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Back; sg.CanvasSize=Vector2.new(2048,160); sg.Parent=facade
 local nameplate=Instance.new("TextLabel"); nameplate.Size=UDim2.fromScale(1,1); nameplate.BackgroundTransparency=1; nameplate.Text="НЕ СКРЫТАЯ БАЗА ТЯНОК   /   ПРОИЗВОДСТВЕННЫЙ КОМПЛЕКС 02"; nameplate.TextScaled=true; nameplate.TextColor3=C(200,210,215); nameplate.Font=Enum.Font.GothamBlack; nameplate.Parent=sg
 for i,def in ipairs(C2_ZONES) do
  local room=Instance.new("Model"); room.Name=def.name; room.Parent=C2.map
  local x=(i-1)*160; local indoor=i>=3
  local z={model=room,x=x,done=false,entered=false,machines={}}; C2.zones[i]=z
  prop(room,"Floor",Vector3.new(150,0.35,100),Vector3.new(x,0.18,0),i%2==0 and C(62,68,73) or C(53,59,66),Enum.Material.Concrete)
  for _,s in ipairs({-1,1}) do
   prop(room,"SideWall",Vector3.new(150,18,1),Vector3.new(x,9,s*50),C(57,65,74),Enum.Material.Metal)
   prop(room,"GateWall",Vector3.new(1,18,40),Vector3.new(x+75,9,s*30),C(55,63,72),Enum.Material.Metal)
  end
  if indoor then prop(room,"Ceiling",Vector3.new(150,1,100),Vector3.new(x,18.5,0),C(42,48,57),Enum.Material.Metal) end
  z.gate=prop(room,"CheckpointGate",Vector3.new(1,14,20),Vector3.new(x+75,7,0),C(95,110,120),Enum.Material.DiamondPlate)
  -- Ten-stud connectors have tall side rails, so locked gates cannot be bypassed outside.
  prop(room,"Connector",Vector3.new(10,0.35,20),Vector3.new(x+80,0.18,0),C(60,67,73))
  for _,s in ipairs({-1,1}) do prop(room,"ConnectorWall",Vector3.new(10,18,1),Vector3.new(x+80,9,s*10),C(50,58,65)) end
  local sign=prop(room,"ZoneSign",Vector3.new(1,1,1),Vector3.new(x-52,7,0),C(90,125,145)); sign.Transparency=1; sign.CanCollide=false; c2Label(sign,def.name)
  for k=-2,2 do
   local lamp=prop(room,"IndustrialLight",Vector3.new(5,0.3,3),Vector3.new(x+k*26,indoor and 17 or 12,0),C(205,215,220)); light(lamp,C(205,220,230),43,1.1)
  end
  -- A long separating partition creates distinct engineering and assault lanes.
  if i>=3 and i<=9 then
   prop(room,"RoutePartition",Vector3.new(65,10,1),Vector3.new(x-4,5,0),C(62,73,82),Enum.Material.Metal)
   local route=prop(room,"RouteSign",Vector3.new(1,1,1),Vector3.new(x-44,5,0),C(120,180,190)); route.CanCollide=false; route.Transparency=1
   c2Label(route,"← СЕРВИС: АРТЕМ   |   ДЕМИД: ОХРАНА →")
  end
  for k=1,7 do
   local px=x-52+(k-1)*16; local sz=k%2==0 and -1 or 1
   if def.theme=="forest" then
    prop(room,"PineTrunk",Vector3.new(2,16,2),Vector3.new(px,8,sz*35),C(73,57,43),Enum.Material.Wood)
    local crown=prop(room,"PineCrown",Vector3.new(10,16,10),Vector3.new(px,19,sz*35),C(35,65,51)); crown.Shape=Enum.PartType.Ball
   elseif def.theme=="cargo" then
    prop(room,"FreightContainer",Vector3.new(11,9,16),Vector3.new(px,4.7,sz*32),k%2==0 and C(72,100,112) or C(115,85,67),Enum.Material.CorrodedMetal)
   elseif def.theme=="pipes" or def.theme=="reactor" then
    local pipe=prop(room,"CoolingPipe",Vector3.new(4,4,62),Vector3.new(px,12,0),C(90,115,125),Enum.Material.Metal); pipe.Shape=Enum.PartType.Cylinder
    if def.theme=="reactor" then local core=prop(room,"ReactorCore",Vector3.new(9,12,9),Vector3.new(px,6,sz*32),C(55,125,150),Enum.Material.Glass); core.Transparency=0.35; light(core,C(70,150,180),16,0.5) end
   elseif def.theme=="press" or def.theme=="mech" then
    prop(room,"Conveyor",Vector3.new(13,2,9),Vector3.new(px,1.2,sz*32),C(34,39,46),Enum.Material.DiamondPlate)
    prop(room,"PressFrame",Vector3.new(2,12,9),Vector3.new(px+6,6,sz*32),C(93,108,120),Enum.Material.Metal)
    prop(room,"PressHead",Vector3.new(10,2,8),Vector3.new(px,10,sz*32),C(120,127,132),Enum.Material.Metal)
   elseif def.theme=="servers" or def.theme=="command" then
    prop(room,"ServerRack",Vector3.new(9,11,5),Vector3.new(px,5.7,sz*35),C(30,37,47),Enum.Material.Metal)
    for row=1,4 do prop(room,"RackDisplay",Vector3.new(7,0.3,0.1),Vector3.new(px,row*2,sz*35-2.6),C(70,160,170),Enum.Material.Neon) end
   elseif def.theme=="lab" then
    local glass=prop(room,"CloneCapsule",Vector3.new(7,11,7),Vector3.new(px,5.7,sz*33),C(95,160,175),Enum.Material.Glass); glass.Transparency=0.55
    local cfg=table.clone(Types.Commander); cfg.Male=false; cfg.Name="Копия в капсуле"
    local doll=buildRig(cfg,CFrame.new(c2Origin+Vector3.new(px,3.4,sz*33))); doll.Parent=room; anchorAll(doll); c2Dress(doll,false)
   else
    prop(room,"MarbleColumn",Vector3.new(4,17,4),Vector3.new(px,8.5,sz*35),C(115,118,127),Enum.Material.Marble)
   end
  end
  for _,machine in ipairs(room:GetChildren()) do
   if machine:IsA("BasePart") and machine.Name=="PressHead" then
    machine.CanCollide=false; table.insert(z.machines,{part=machine,origin=machine.Position})
   end
  end
  if i==10 then prop(room,"BossDesk",Vector3.new(15,3,6),Vector3.new(x+30,1.7,23),C(65,43,39),Enum.Material.Wood) end
  -- Service panel sits at the far end of the engineering lane.
  local med=prop(room,"MedicalStation",Vector3.new(2,2,2),Vector3.new(x-48,1.3,17),C(70,145,115))
  local used={}; c2Label(med,"АПТЕЧКА • +70 HP / один раз")
  c2Prompt(med,"Перевязаться",1,function(player)
   if used[player] then return end
   local _,hum=c2Root(player); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+70); used[player]=true end
  end)
  local panel=prop(room,"EngineeringPanel",Vector3.new(3,4,2),Vector3.new(x+45,2.3,-23),C(45,115,125),Enum.Material.Metal)
  c2Label(panel,def.task.."\n"..(def.kind=="weld" and "СВАРКА" or def.kind=="hack" and "ВЗЛОМ" or "КЛАПАН"))
  z.prompt=c2Prompt(panel,def.task,def.kind=="hack" and 5 or 3,function(player,prompt)
   if C2.escaping or C2.stage~=i or z.done then return end
   if not c2Allowed(player,"engineering") then NotifyRE:FireClient(player,"Нужен Артем. Прикрой его с боевого маршрута.",4); return end
   if i==10 and c2Count(10)>0 then NotifyRE:FireClient(player,"Сначала разберитесь с личной охраной и мафией.",4); return end
   z.done=true; prompt.Enabled=false
   z.gate.CanCollide=false; TweenService:Create(z.gate,TweenInfo.new(1.2),{Position=z.gate.Position+Vector3.new(0,15,0)}):Play()
   for _,object in ipairs(room:GetDescendants()) do if object:IsA("BasePart") and object.Name=="PressHead" then object.Color=C(40,48,53) end end
   NotifyRE:FireAllClients(def.kind=="weld" and "Контур перерезан. Конвейер остановлен, шлюз открыт." or "Система отключена. Шлюз открыт.",4)
   if i==10 then c2Escape() end
   c2Send()
  end)
 end
 -- Big factory silhouette can be read from the approach, behind playable buildings.
 for k=1,5 do
  local chimney=prop(C2.map,"FactoryChimney",Vector3.new(11,95+k*5,11),Vector3.new(350+k*150,45,-100),C(63,69,75),Enum.Material.Concrete)
  local smoke=Instance.new("Smoke"); smoke.Opacity=0.2; smoke.Size=18; smoke.RiseVelocity=9; smoke.Color=C(90,95,100); smoke.Parent=chimney
 end
 local car=prop(C2.map,"EscapeVan",Vector3.new(13,5,7),Vector3.new(-58,2.7,24),C(42,65,83),Enum.Material.Metal); c2Label(car,"ЭВАКУАЦИЯ • ВЕРНИТЕСЬ СЮДА")
end
c2Escape=function()
 if C2.escaping or C2.finished then return end
 C2.escaping=true; C2.escapeStarting=true
 C2.deadline=workspace:GetServerTimeNow()+330
 -- Discard the old garrison. Retreat contains only sparse newly spawned pursuers.
 for model,e in pairs(C2.mobs) do if not e.defeated then model:Destroy(); C2.mobs[model]=nil end end
 task.spawn(function()
  introActive=true; canFight=false; sceneLock(true)
  CutsceneRE:FireAllClients("start")
  if C2.boss and C2.boss.Parent then CutsceneRE:FireAllClients("pov",C2.boss.Head,55) end
  sceneLine("Мафия: Это не конец. Через пять минут от завода ничего не останется. Вы останетесь здесь вместе со мной.",9)
  C2.deadline=workspace:GetServerTimeNow()+300; C2.escapeStarting=false
  MusicRE:FireAllClients("finalSlow")
  CutsceneRE:FireAllClients("end"); sceneLock(false); introActive=false; canFight=true
  NotifyRE:FireAllClients("САМОУНИЧТОЖЕНИЕ • 05:00. Вернитесь через все десять зон к машине у въезда. Шлюзы открыты.",7)
  c2Send()
 end)
end
c2Activate=function(index)
 C2.stage=index; local z=C2.zones[index]; if z.entered then return end; z.entered=true
 C2.alarm=false
 for _,p in ipairs(C2.party) do
  local artem=p:GetAttribute("Hero")=="Artem"
  p:SetAttribute("WeaponLevel",artem and 2 or math.min(5,2+math.floor((index-1)/2)))
 end
 local count=index==1 and 2 or math.min(5,2+math.floor(index/3))
 for k=1,count do c2Spawn(index,c2Origin+Vector3.new(z.x-12+k*10,3.5,20+(k%2)*14),index>=7 and k==1,false) end
 if index==10 then C2.boss=c2Spawn(index,c2Origin+Vector3.new(z.x+30,3.5,18),false,true) end
 currentSpawn=CFrame.lookAt(c2Origin+Vector3.new(z.x-60,4,10),c2Origin+Vector3.new(z.x,4,10))
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
  if ok then pcall(function() target:ApplyDescription(description) end) end
 end
 if target then target.DisplayName=player:GetAttribute("Hero")=="Artem" and "Артем • инженер" or "Демид • штурм"; target.MaxHealth=180; target.Health=180 end
end
local function c2RestoreHeroes()
 for player,state in pairs(C2.originals or {}) do
  local target=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if target and target.Health>0 then
   if state.description then pcall(function() target:ApplyDescription(state.description) end) end
   target.MaxHealth=state.health; target.Health=state.health; target.DisplayName=state.name
  end
  if state.description then state.description:Destroy() end
 end
 C2.originals={}
end
c2Finish=function(good)
 if C2.finished then return end
 MusicRE:FireAllClients("stop")
 C2.finished=true; C2.escaping=false; C2.serial+=1
 canFight=false; sceneLock(true); introActive=true
 C2RE:FireAllClients("ending",{good=good})
 task.wait(1)
 CutsceneRE:FireAllClients("start")
 CutsceneRE:FireAllClients("pov",c2Origin+Vector3.new(230,22,0))
 if good then
  -- Visible distant blast from the survivor's eyes, not a detached ending camera.
  task.wait(1)
  local blast=c2Part(C2.map,"FactoryDetonation",Vector3.new(8,8,8),c2Origin+Vector3.new(280,14,0),C(255,150,65),Enum.Material.Neon)
  blast.Shape=Enum.PartType.Ball; blast.CanCollide=false; blast.CanQuery=false; light(blast,C(255,140,65),140,4)
  TweenService:Create(blast,TweenInfo.new(2.5),{Size=Vector3.new(100,100,100),Transparency=1}):Play(); Debris:AddItem(blast,3)
  ShakeRE:FireAllClients(7)
  say("Артем: Успели. Архив у нас, а их мини-завода больше нет.",6)
  say("Демид: Вот теперь можно и в Blade Ball. Только сначала поспим.",6)
 else
  ShakeRE:FireAllClients(16)
  local deathFlash=c2Part(C2.map,"FinalReactorFlash",Vector3.new(20,20,20),c2Origin+Vector3.new((C2.stage-1)*160,9,0),C(255,180,95),Enum.Material.Neon)
  deathFlash.Shape=Enum.PartType.Ball; deathFlash.CanCollide=false; deathFlash.CanQuery=false
  TweenService:Create(deathFlash,TweenInfo.new(1.5),{Size=Vector3.new(160,160,160),Transparency=0.5}):Play()
  say("Связь оборвалась. Завод уничтожил и доказательства, и тех, кто пришел за ними.",7) end
 FadeRE:FireAllClients(true,good and "ГЛАВА II ПРОЙДЕНА • ХОРОШАЯ КОНЦОВКА" or "ГЛАВА II • ПЛОХАЯ КОНЦОВКА")
 task.wait(6)
 C2.active=false
 for _,conn in ipairs(C2.connections) do conn:Disconnect() end
 table.clear(C2.connections); table.clear(C2.mobs)
 for _,p in ipairs(C2.party) do p:SetAttribute("Chapter",1) end
 C2RE:FireAllClients("clear")
 Players.RespawnTime=3
 c2RestoreHeroes()
 returnToMenu()
end
local function startChapter2(party)
 C2.originals={}; C2.bossDefeated=false; C2.escapeStarting=false; C2.shots={}; C2.active=true; C2.finished=false; C2.escaping=false; C2.alarm=false; C2.stage=1; C2.serial+=1; C2.party=table.clone(party); C2.mobs={}
 local serial=C2.serial
 levelToken+=1; canFight=false; introActive=true; sceneLock(true)
 FadeRE:FireAllClients(true,"ГЛАВА II • НЕ СКРЫТАЯ БАЗА ТЯНОК"); task.wait(1)
 clearLevel(); newFolders(); applyPreset("Base",0.1); c2Build()
 local animTime=0
 table.insert(C2.connections,RunService.Heartbeat:Connect(function(dt)
  if not C2.active or C2.finished then return end
  animTime+=dt; if animTime<0.05 then return end; animTime=0
  local z=C2.zones[C2.stage]
  if z and not z.done then for _,machine in ipairs(z.machines) do
   if machine.part.Parent then machine.part.Position=machine.origin+Vector3.new(0,-math.abs(math.sin(os.clock()*1.2))*5,0) end
  end end
  for model,e in pairs(C2.mobs) do
   if model.Parent and e.hum.Health>0 then
    local speed=e.root.AssemblyLinearVelocity.Magnitude
    local swing=math.sin(os.clock()*9)*math.clamp(speed/12,0,1)*0.45
    e.joints.RH.C0=e.base.RH*CFrame.Angles(swing,0,0); e.joints.LH.C0=e.base.LH*CFrame.Angles(-swing,0,0)
    e.joints.LS.C0=e.base.LS*CFrame.Angles(swing*0.5,0,0)
   end
  end
 end))
 currentLevel=0; currentName="Глава II"; currentSpawn=CFrame.new(c2Origin+Vector3.new(-60,4,0)); placeAll(); sceneLock(true)
 Players.RespawnTime=1000000
 for _,p in ipairs(party) do p:SetAttribute("Chapter",2); c2Hero(p) end
 CutsceneRE:FireAllClients("start")
 -- Third-person opening: the returning protagonists plan the operation beside the van.
 local opening=Instance.new("Model"); opening.Name="Chapter2OpeningCast"; opening.Parent=C2.map
 secretActor(opening,"eurtyoeyrntiu","Артем",CFrame.lookAt(c2Origin+Vector3.new(-51,0.4,18),c2Origin+Vector3.new(-48,0.4,22)))
 secretActor(opening,"ZamestitelDiomchica","Демид",CFrame.lookAt(c2Origin+Vector3.new(-44,0.4,18),c2Origin+Vector3.new(-48,0.4,22)))
 focusStreaming(c2Origin)
 cameraPlan(c2Origin+Vector3.new(-62,8,32),c2Origin+Vector3.new(-60,7,29),c2Origin+Vector3.new(-48,4,18),6,60,55)
 prepareView(c2Origin); CutsceneRE:FireAllClients("reveal")
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
 -- From the approach onwards camera remains at the player's eye position.
 for _,p in ipairs(party) do local root=c2Root(p); local head=p.Character and p.Character:FindFirstChild("Head"); if root and head then
  CutsceneRE:FireClient(p,"pov",c2Origin+Vector3.new(600,65,-83),65)
 end end
 prepareView(c2Origin); CutsceneRE:FireAllClients("reveal")
 sceneLine("Артем: Вон он, за терминалом. Я иду по сервисным проходам, ты забираешь охрану. Панель открывает общий шлюз.",7)
 CutsceneRE:FireAllClients("end"); sceneLock(false); introActive=false; canFight=true
 c2Activate(1); MusicRE:FireAllClients("intro")
 NotifyRE:FireAllClients("1: нож (Демид) / сварка (Артем). 2–5: оружие. E: удерживать у панели. В одиночку панели доступны обоим.",9)
 task.spawn(function()
  local lastEscape=0
  while C2.active and serial==C2.serial and not C2.finished do
   if not c2Alive() then c2Finish(false); break end
   if C2.escapeStarting then task.wait(0.5); continue end
   if C2.escaping then
    if workspace:GetServerTimeNow()>=C2.deadline then c2Finish(false); break end
    local allSafe=true; local survivors=0
    for _,p in ipairs(party) do local r=c2Root(p); if r then survivors+=1; if (r.Position-(c2Origin+Vector3.new(-58,3,24))).Magnitude>22 then allSafe=false end end end
    if allSafe and survivors>0 then c2Finish(true); break end
    if os.clock()-lastEscape>18 then
     lastEscape=os.clock()
     for _,p in ipairs(party) do local r=c2Root(p); if r then
      local zone=math.clamp(math.floor((r.Position.X-c2Origin.X+75)/160)+1,1,10)
      if c2Count(zone)<2 then c2Spawn(zone,c2Origin+Vector3.new((zone-1)*160-15,3.5,28),false,false) end
      break
     end end
    end
   else
    local z=C2.zones[C2.stage]
    if C2.stage==10 and C2.bossDefeated and c2Count(10)==0 and not z.done then
     z.done=true; z.prompt.Enabled=false; z.gate.CanCollide=false
     TweenService:Create(z.gate,TweenInfo.new(1.2),{Position=z.gate.Position+Vector3.new(0,15,0)}):Play()
     c2Escape()
    end
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
 if not C2.active or C2.finished or introActive or not table.find(C2.party,player) then return end
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
 if weld and not e.mech and not e.boss then e.blind=workspace:GetServerTimeNow()+2.5; e.hum:MoveTo(e.root.Position) end
 if weld and e.mech then damage=4; NotifyRE:FireClient(player,"Меха-тян не ослепляется сваркой. Уходи из зоны ракеты!",2) end
 if e.defeated then return end
 if e.boss and e.hum.Health-damage<=30 then
  e.hum.Health=30; e.defeated=true; C2.bossDefeated=true
  e.hum.WalkSpeed=0; anchorAll(model)
  local cf=model:GetPivot()
  -- Use the existing rigid-model mover so limbs stay with the anchored root.
  task.spawn(function() moveModel(model,cf*CFrame.new(0,-1.8,0)*CFrame.Angles(math.rad(78),0,0),0.8) end)
  NotifyRE:FireAllClients("Мафия повержен. Добейте его личную охрану!",5)
 else e.hum:TakeDamage(damage) end
 HitRE:FireClient(player,e.hum.Health<=0 or e.defeated==true)
end
