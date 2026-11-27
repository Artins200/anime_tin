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
 for m,e in pairs(C2.mobs) do if m.Parent and e.hum.Health>0 and not e.defeated and e.zone==zone then n+=1 end end
 return n
end
c2Send=function()
 local z=C2.zones and C2.zones[C2.stage]
 for _,p in ipairs(C2.party) do if p.Parent then
  local displayStage=C2.stage
  local root=c2Root(p)
  if C2.escaping and root then displayStage=math.clamp(math.floor((root.Position.X-c2Origin.X+75)/160)+1,1,10) end
  C2RE:FireClient(p,"state",{stage=displayStage,name=C2_ZONES[displayStage].name,weaponLevel=p:GetAttribute("WeaponLevel") or 2,role=p:GetAttribute("Hero"),escaping=C2.escaping,deadline=C2.deadline,alarm=C2.alarm,enemies=c2Count(displayStage)})
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
 if not C2.active or C2.serial~=serial then return end
 rocket:Destroy(); marker:Destroy()
 local flash=c2Part(C2.map,"Blast",Vector3.new(10,10,10),goal,C(245,125,55),Enum.Material.Neon); flash.Shape=Enum.PartType.Ball; flash.CanCollide=false; Debris:AddItem(flash,0.25)
 for _,p in ipairs(C2.party) do local r,h=c2Root(p); if r and (r.Position-goal).Magnitude<11 then h:TakeDamage(48) end end
end
local function c2Mobilize(model,hum,root)
 for _,body in ipairs(model:GetDescendants()) do
  if body:IsA("BasePart") then body.Anchored=false; body.CanCollide=body.Name=="Torso" end
 end
 hum.PlatformStand=false; hum.AutoRotate=true; hum:ChangeState(Enum.HumanoidStateType.Running)
 root:SetNetworkOwner(nil)
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
 if not boss then c2Dress(m,mech) end
 c2Mobilize(m,h,r)
 local e={hum=h,root=r,zone=zone,mech=mech,boss=boss,blind=0,last=0,patrol=pos,alertUntil=0,pathAt=0,waypoints=nil,waypoint=1,stuckAt=os.clock(),lastPosition=pos,joints=j,base={RH=j.RH.C0,LH=j.LH.C0,LS=j.LS.C0,RS=j.RS.C0}}; C2.mobs[m]=e
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
    local delta=target.Position-r.Position
    local facing=delta.Magnitude<0.1 or r.CFrame.LookVector:Dot(delta.Unit)>-0.15
    if dist<110 and visible and (C2.alarm or facing or dist<12) then
     e.alertUntil=os.clock()+12; e.lastSeen=target.Position
     if not C2.alarm then C2.alarm=true; c2Send() end
    end
    local pursuing=os.clock()<e.alertUntil or (C2.alarm and dist<140)
    if pursuing then
     local goal=visible and target.Position or e.lastSeen or target.Position
     if not visible or dist>18 then
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
 C2RE:FireClient(player,"engineering",{token=ch.token,kind=ch.zone.kind,board=ch.board,connected=connected,progress=ch.progress,expires=ch.expires,start=ch.start,target=ch.target})
end
local function c2Engineering(player,z)
 if C2.challenges[player] or (z.owner and z.owner~=player) or introActive then return end
 local r,h=c2Root(player); if not r or (r.Position-z.panel.Position).Magnitude>10 then return end
 C2.challengeSerial+=1
 local ch={zone=z,token=tostring(C2.serial)..":"..tostring(C2.challengeSerial),progress=0,expires=workspace:GetServerTimeNow()+90,last=0,start=workspace:GetServerTimeNow(),target=0.3+math.random()*0.4}
 if z.kind=="hack" then ch.board=c2CircuitBoard(Random.new()) end
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
 if action=="equip" then
  local index=table.find(WD.Order,token)
  if index and index<=(player:GetAttribute("WeaponLevel") or 1) and not introActive and not C2.challenges[player] then c2WorldWeapon(player,token) end
  return
 end
 local ch=C2.challenges[player]; if not ch or ch.token~=token then return end
 if action=="cancel" then c2EndEngineering(player); return end
 local root=c2Root(player)
 if not root or not c2Allowed(player,"engineering") or C2.stage~=ch.zone.index or C2.escaping or ch.expires<workspace:GetServerTimeNow() or (root.Position-ch.zone.panel.Position).Magnitude>12 then c2EndEngineering(player); return end
 if os.clock()-ch.last<0.14 then return end; ch.last=os.clock()
 local solved=false
 if action=="rotate" and ch.board and typeof(value)=="number" and value%1==0 and value>=1 and value<=9 then
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
  local x=(i-1)*160; local indoor=i>=3
  local halfDepth,height=table.unpack(C2_LAYOUT[i])
  local z={model=room,x=x,done=false,entered=false,machines={}}; C2.zones[i]=z
  prop(room,"Floor",Vector3.new(150,0.35,halfDepth*2),Vector3.new(x,0.18,0),i%2==0 and C(62,68,73) or C(53,59,66),Enum.Material.Concrete)
  for _,s in ipairs({-1,1}) do
   prop(room,"SideWall",Vector3.new(150,height,2),Vector3.new(x,height/2,s*halfDepth),C(57,65,74),Enum.Material.Metal)
   prop(room,"GateWall",Vector3.new(2,height,halfDepth-10),Vector3.new(x+75,height/2,s*(halfDepth+10)/2),C(55,63,72),Enum.Material.Metal)
   if i>1 then prop(room,"EntryWall",Vector3.new(2,height,halfDepth-10),Vector3.new(x-75,height/2,s*(halfDepth+10)/2),C(57,65,74),Enum.Material.Metal) end
  end
  prop(room,"ExitLintel",Vector3.new(2,height-14,20),Vector3.new(x+75,14+(height-14)/2,0),C(57,65,74),Enum.Material.Metal)
  if i>1 then prop(room,"EntryLintel",Vector3.new(2,height-14,20),Vector3.new(x-75,14+(height-14)/2,0),C(57,65,74),Enum.Material.Metal) end
  if indoor then prop(room,"Ceiling",Vector3.new(150,1,halfDepth*2),Vector3.new(x,height+0.5,0),C(42,48,57),Enum.Material.Metal) end
  z.gate=prop(room,"CheckpointGate",Vector3.new(1,14,20),Vector3.new(x+75,7,0),C(95,110,120),Enum.Material.DiamondPlate)
  -- Ten-stud connectors have tall side rails, so locked gates cannot be bypassed outside.
  prop(room,"Connector",Vector3.new(10,0.35,20),Vector3.new(x+80,0.18,0),C(60,67,73))
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
  if i==10 then prop(room,"BossDesk",Vector3.new(15,3,6),Vector3.new(x+30,1.7,23),C(65,43,39),Enum.Material.Wood) end
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
  z.complete=function()
   local prompt=z.prompt
   z.done=true; prompt.Enabled=false
   z.gate.CanCollide=false; TweenService:Create(z.gate,TweenInfo.new(1.2),{Position=z.gate.Position+Vector3.new(0,15,0)}):Play()
   for _,object in ipairs(room:GetDescendants()) do if object:IsA("BasePart") and object.Name=="PressHead" then object.Color=C(40,48,53) end end
   if i==10 then c2Escape() end
   c2Send()
  end
  z.prompt=c2Prompt(panel,"Подключиться",0,function(player)
   if C2.escaping or C2.stage~=i or z.done then return end
   if not c2Allowed(player,"engineering") then return end
   if i==10 and c2Count(10)>0 then return end
   c2Engineering(player,z)
  end)
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
  c2Grant(p,artem and math.min(3,2+math.floor((index-1)/5)) or math.min(5,2+math.floor((index-1)/2)))
 end
 local count=index==1 and 2 or math.min(5,2+math.floor(index/3))
 for k=1,count do c2Spawn(index,c2Origin+Vector3.new(z.x-12+k*10,3.5,(k%2==0 and 1 or -1)*math.min(17,C2_LAYOUT[index][1]-8)),index>=7 and k==1,false) end
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
 MusicRE:FireAllClients("stop")
 for player in pairs(C2.challenges) do c2EndEngineering(player) end
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
 C2.challenges={}; C2.safe={}; C2.challengeSerial=0; C2.originals={}; C2.bossDefeated=false; C2.escapeStarting=false; C2.shots={}; C2.active=true; C2.finished=false; C2.escaping=false; C2.alarm=false; C2.stage=1; C2.serial+=1; C2.party=table.clone(party); C2.mobs={}
 local serial=C2.serial
 levelToken+=1; canFight=false; introActive=true; sceneLock(true)
 FadeRE:FireAllClients(true,"ГЛАВА II • НЕ СКРЫТАЯ БАЗА ТЯНОК"); task.wait(1)
 clearLevel(); newFolders(); applyPreset("Base",0.1); c2Build(); c2Home()
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
  CutsceneRE:FireClient(p,"pov",c2Origin+Vector3.new(600,65,-83),65)
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
