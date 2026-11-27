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
 if action=="debugJump" then C2.DebugJump(player,token); return end
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
 C2.deployEpoch=0; C2.debugBusy=false
 for _,p in ipairs(C2.party) do p:SetAttribute("Chapter2Debug",C2.DebugAllowed(p)) end
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
 for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and (p.Name=="Hair" or p.Name=="Eye") then p:Destroy() end end
 local root=model.HumanoidRootPart
 local function armor(name,size,offset,color,material)
  local p=c2Part(model,name,size,root.CFrame:PointToWorldSpace(offset),color,material or Enum.Material.Metal); p.CFrame=root.CFrame*CFrame.new(offset); p.CanCollide=false; return p
 end
 armor("SilverFringe",Vector3.new(2.1,0.55,0.65),Vector3.new(0,2.05,-0.45),C(180,186,205),Enum.Material.SmoothPlastic)
 for _,side in ipairs({-1,1}) do
  armor("LongSilverHair",Vector3.new(0.48,2.7,0.75),Vector3.new(side*0.95,1.05,0.25),C(152,160,185),Enum.Material.SmoothPlastic)
  armor("CrimsonRibbon",Vector3.new(0.6,0.3,0.35),Vector3.new(side*1.12,1.65,0.1),C(135,25,55),Enum.Material.Fabric)
 end
 armor("CrimsonTie",Vector3.new(0.3,1.3,0.12),Vector3.new(0,0.25,-0.78),C(155,30,57),Enum.Material.Fabric)
 armor("BallisticChest",Vector3.new(2.6,2.1,1.4),Vector3.new(0,0,0),C(24,28,35))
 armor("DarkCloak",Vector3.new(2.9,4.5,0.35),Vector3.new(0,-0.7,0.8),C(13,16,23),Enum.Material.Fabric)
 armor("MechanicalFaceplate",Vector3.new(1.1,1.05,0.24),Vector3.new(0.48,1.5,-0.55),C(71,80,90))
 local visor=armor("CyborgVisor",Vector3.new(1.9,0.2,0.18),Vector3.new(0,1.65,-0.7),C(225,60,55),Enum.Material.Neon); light(visor,C(220,55,50),9,0.7)
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
function C2.CarScene()
 local survivors={}; for _,p in ipairs(C2.party) do if c2Root(p) then table.insert(survivors,p) end end
 local lead=survivors[1] or C2.party[1]
 local other=lead:GetAttribute("Hero")=="Artem" and "Демид" or "Артем"
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 local car=Instance.new("Model"); car.Name="GetawayCar"; car.Parent=C2.map
 local origin=Vector3.new(-70,0,100)
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
 for k=0,50 do
  c2Part(C2.map,"RoadMarking",Vector3.new(14,0.03,0.2),origin+Vector3.new(60-k*42,0.35,0),C(190,180,145))
 end
 c2Part(C2.map,"EscapeRoad",Vector3.new(2500,1,32),origin+Vector3.new(-1100,-0.2,0),C(30,33,38),Enum.Material.Asphalt)
 for _,side in ipairs({-1,1}) do
  c2Part(C2.map,"EscapeRouteWall",Vector3.new(2500,9,2),origin+Vector3.new(-1100,4,side*19),C(48,53,61),Enum.Material.Concrete)
  for k=0,30 do local lamp=c2Part(C2.map,"RoadLamp",Vector3.new(1,0.3,3),origin+Vector3.new(40-k*70,8,side*17),C(240,195,125),Enum.Material.Neon); light(lamp,C(245,200,140),28,1.1) end
 end
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
 local start=os.clock(); local connection
 connection=RunService.Heartbeat:Connect(function()
  if not car.Parent then connection:Disconnect(); return end
  local t=os.clock()-start
  local distance=18*t+0.65*t*t
  local cf=pivot+Vector3.new(-distance,0,0); car:PivotTo(cf)
  for rig,offset in pairs(offsets) do if rig.Parent then rig:PivotTo(cf*offset) end end
 end)
 table.insert(C2.connections,connection)
 for _,p in ipairs(C2.party) do p.ReplicationFocus=car:FindFirstChild("Chassis") end
 CutsceneRE:FireAllClients("follow",car,Vector3.new(20,11,-20),Vector3.new(-6,2,0))
 CutsceneRE:FireAllClients("reveal"); MusicRE:FireAllClients("finalSlow")
 task.spawn(function() for i=2,10 do C2.Collapse(C2.zones[i],true); task.wait(0.15) end end)
 C2.Literal(other,"На самом деле это было неплохо, отличная работа. Но скажу тебе так — всё довольно плачевно. В плане, это же их мини-центр, мы даже и половину не уничтожили",10)
 C2.Literal(lead:GetAttribute("Hero")=="Artem" and "Артем" or "Демид","Это было легко, но если бы мне кто-то помогал...",4)
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

-- Never trust a client-visible flag for authorization.
function C2.DebugAllowed(player)
 return RunService:IsStudio() or (game.PrivateServerOwnerId~=0 and player.UserId==game.PrivateServerOwnerId)
end
function C2.DebugJump(player,command)
 if not C2.DebugAllowed(player) or C2.debugBusy or introActive then return end
 local actions={wave9=true,boss=true,shield=true,escape=true,finale=true}
 if not actions[command] then return end
 C2.debugBusy=true
 task.spawn(function()
  C2.RunProtected(function()
   for p in pairs(C2.challenges) do c2EndEngineering(p) end
   C2.deployEpoch=(C2.deployEpoch or 0)+1
   -- Invalidate delayed wave callbacks without invalidating the mission heartbeat.
   for _,z in ipairs(C2.zones) do z.waveActive=false; z.wave+=100; z.done=true; z.field.CanCollide=false; z.field.Transparency=1; z.gate.CanCollide=false; C2.Door(z,true) end
   for model in pairs(C2.mobs) do if model.Parent then model:Destroy() end end
   table.clear(C2.mobs); C2.boss=nil; C2.escaping=false; C2.escapeStarting=false
   local index=command=="wave9" and 9 or 10
   local z=C2.zones[index]; C2.stage=index
   for i,p in ipairs(C2.party) do local root,h=c2Root(p); if root then h.Health=h.MaxHealth; p.Character:PivotTo(CFrame.lookAt(c2Origin+Vector3.new(z.x-40,4,i*3),c2Origin+Vector3.new(z.x+43,4,0))); c2Grant(p,5) end end
   if command=="finale" then c2Finish(true); return end
   z.done=false; z.wave=0; z.cleared=false; z.keyCollected=false; z.hacked=false; z.deploying=false
   z.field.CanCollide=true; z.field.Transparency=0.82
   if command=="wave9" then z.wave=z.rounds-1; C2.BeginWave(9)
   elseif command=="boss" then C2.BossIntro()
   else
    C2.CreateBoss(); z.cleared=true; C2.bossPhase="exposed"; C2.shield.Transparency=0.45
    C2.shieldHP=C2.shieldMax
    if command=="escape" then C2.bossPhase="broken"; C2.shield.Transparency=1; C2.shield.CanQuery=false; C2.mobs[C2.boss].defeated=true; C2.DefeatSequence() end
   end
   c2Send()
  end)
  C2.debugBusy=false
 end)
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
   if C2.escapeStarting or C2.debugBusy then task.wait(0.5); continue end
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
