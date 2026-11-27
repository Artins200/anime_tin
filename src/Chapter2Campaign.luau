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
