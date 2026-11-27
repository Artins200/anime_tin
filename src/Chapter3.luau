-- Chapter III: authoritative campaign. Embedded after Chapter II helpers.
local C3={active=false,serial=0,party={},mobs={},connections={}}
local C3RE=newRemote("Chapter3")
C3.origin=Vector3.new(0,0,12000)
C3.names={"ЖИЛОЙ КВАРТАЛ","ТОРГОВАЯ УЛИЦА","РАЗВЯЗКА","КВАРТАЛ НТЯН","ПЛОЩАДЬ БАШНИ","СЕРВИСНЫЙ ЭТАЖ","СИЛОВОЙ ЯРУС","СЕРВЕРНЫЙ ЯРУС","АНТЕННЫЙ ЯРУС","ВЕРХНИЙ ПОСТ"}
function C3.Pos(x,y,z) return C3.origin+Vector3.new(x,y,z or 0) end
function C3.Part(parent,name,size,pos,color,mat)
 local p=part(parent,size,pos,color,mat or Enum.Material.Concrete); p.Name=name; return p
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
function C3.Send()
 local z=C3.zones and C3.zones[C3.stage]; if not z then return end
 for _,p in ipairs(C3.party) do if p.Parent then C3RE:FireClient(p,"state",{stage=C3.stage,name=C3.names[C3.stage],wave=z.wave,rounds=z.rounds,enemies=C3.Count(C3.stage),cleared=z.cleared,objective=z.objective,relays=C3.relays,phase=C3.hackPhase,shield=not C3.towerOff,coop=C3.coop}) end end
end
function C3.Protected(fn)
 local ok,err=xpcall(fn,debug.traceback)
 if not ok then warn("[Chapter3] "..tostring(err)); C3.Stop(); returnToMenu() end
end
function C3.Stop()
 C3.active=false; C3.serial+=1
 for _,c in ipairs(C3.connections) do c:Disconnect() end; C3.connections={}
 for _,p in ipairs(C3.party) do if p.Parent then p:SetAttribute("IsSprinting",false); p:SetAttribute("Chapter",1); p:SetAttribute("SprintStamina",100); p:SetAttribute("C3GrabbedUntil",nil) end end
 C3RE:FireAllClients("clear"); C2RE:FireAllClients("clear"); CreditsRE:FireAllClients(false)
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
  table.insert(C3.connections,prompt.PromptButtonHoldEnded:Connect(function(p) task.defer(function() held[p]=nil end) end))
 end
 table.insert(C3.connections,prompt.Triggered:Connect(function(p)
  local root=C3.Root(p)
  if C3.Valid(p) and root and not introActive and (not hold or held[p] and os.clock()-held[p]>=hold-0.25) and (root.Position-part_.Position).Magnitude<=11 then C3.Protected(function() callback(p) end) end
 end))
 return prompt
end
-- BEGIN CHAPTER THREE WORLD
-- Geometry and physical interactions for Chapter III; embedded into Chapter3.
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
 C3.Part(m,"ObservationFloor",Vector3.new(140,1,70),o,C(37,43,53),Enum.Material.Metal)
 C3.Part(m,"ObservationRoof",Vector3.new(140,1,70),o+Vector3.new(0,26,0),C(26,30,40))
 local screen=C3.Part(m,"RuinsBroadcast",Vector3.new(30,17,1),o+Vector3.new(-20,11,20),C(12,20,31))
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(800,450); gui.Parent=screen
 local view=Instance.new("ViewportFrame"); view.Size=UDim2.fromScale(1,1); view.BackgroundColor3=C(20,29,43); view.Ambient=C(170,175,185); view.Parent=gui
 local world=Instance.new("WorldModel"); world.Parent=view
 for k=1,18 do local p=C3.Part(world,"MiniBaseRuin",Vector3.new(4+k%3,2+k%5,9),Vector3.new((k%5-2)*9,0,math.floor(k/5)*9),C(63,65,70)); p.CFrame*=CFrame.Angles(0,k,0.15*k) end
 local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(45,40,-45),Vector3.new(0,3,10)); camera.Parent=view; view.CurrentCamera=camera
 for row=0,5 do
  C3.Part(m,"MegafactoryConveyor",Vector3.new(360,2,9),o+Vector3.new(0,-8,70+row*24),C(44,53,65),Enum.Material.Metal)
  for k=0,23 do
   local pos=o+Vector3.new(-170+k*15,-3,70+row*24)
   local shell=C3.Part(m,"TransformationCapsule",Vector3.new(5,11,5),pos,C(53,99,109),Enum.Material.Glass); shell.Transparency=0.6
   C3.Part(m,"SuspendedFigure",Vector3.new(2,4,1),pos,C(104,111,133))
   local head=C3.Part(m,"FigureHead",Vector3.new(1.5,1.4,1.4),pos+Vector3.new(0,2.8,0),C(177,167,165)); head.Shape=Enum.PartType.Ball
  end
 end
 for k=0,11 do C3.Part(m,"DistantProductionBlock",Vector3.new(95,80,100),o+Vector3.new(-400+k*80,20,350+k%2*80),C(35,46,61)) end
 local cfg=table.clone(Types.Neuro); cfg.Name=ANDROID_NAME
 local neuro=buildRig(cfg,CFrame.new(o+Vector3.new(-15,3.5,5))); neuro.Parent=m; enhanceNeuroCyber(neuro); anchorAll(neuro)
 cfg=table.clone(Types.Pistol); cfg.Name="Тян C-3B1"; cfg.Male=false
 local assistant=buildRig(cfg,CFrame.lookAt(o+Vector3.new(9,3.5,2),o+Vector3.new(-15,3.5,5))); assistant.Parent=m; c2Dress(assistant,false); anchorAll(assistant)
 return m,neuro,assistant,screen
end
function C3.BuildHome()
 local h=Instance.new("Model"); h.Name="HeroesHouse"; h.Parent=C3.map
 C3.Part(h,"HouseFoundation",Vector3.new(90,1,70),C3.Pos(-170,-0.3,0),C(78,74,69))
 C3.Part(h,"HouseRoof",Vector3.new(90,1,70),C3.Pos(-170,25,0),C(43,49,60))
 for _,side in ipairs({-1,1}) do C3.Part(h,"HouseSideWall",Vector3.new(90,25,1),C3.Pos(-170,12.5,side*35),C(94,88,85)) end
 C3.Part(h,"HouseBack",Vector3.new(1,25,70),C3.Pos(-215,12.5,0),C(91,86,82))
 -- East facade leaves a real window and front doorway, with frames, not a missing wall.
 C3.Part(h,"FacadeBottom",Vector3.new(1,2,70),C3.Pos(-125,1,0),C(91,86,82))
 C3.Part(h,"FacadeTop",Vector3.new(1,15,70),C3.Pos(-125,17.5,0),C(91,86,82))
 for _,side in ipairs({-1,1}) do C3.Part(h,"WindowFrame",Vector3.new(1,8,20),C3.Pos(-125,6,side*25),C(91,86,82)) end
 local glass=C3.Part(h,"LivingWindow",Vector3.new(0.15,7,20),C3.Pos(-125,6,0),C(130,160,175),Enum.Material.Glass); glass.Transparency=0.75; glass.CanCollide=true
 -- Upstairs floor has a staircase opening at the south side.
 C3.Part(h,"UpperFloor",Vector3.new(88,0.7,48),C3.Pos(-170,12,10),C(103,89,78),Enum.Material.WoodPlanks)
 for k=1,12 do C3.Part(h,"HouseStair",Vector3.new(4,1,12),C3.Pos(-207+k*4,k-0.5,-23),C(94,80,69),Enum.Material.WoodPlanks) end
 C3.Part(h,"StairLanding",Vector3.new(16,0.7,18),C3.Pos(-153,12,-23),C(94,80,69))
 C3.Part(h,"Sofa",Vector3.new(5,2,13),C3.Pos(-184,1.5,1),C(60,77,89),Enum.Material.Fabric)
 C3.Part(h,"CoffeeTable",Vector3.new(9,1.5,6),C3.Pos(-174,1,1),C(81,67,58),Enum.Material.Wood)
 C3.tv=C3.Part(h,"NewsTV",Vector3.new(0.4,5,8),C3.Pos(-157,5,0),C(18,28,42),Enum.Material.Glass)
 C3.Part(h,"BedroomWall",Vector3.new(38,12,1),C3.Pos(-183,18,-6),C(90,86,90))
 C3.Part(h,"BedroomWallRight",Vector3.new(20,12,1),C3.Pos(-146,18,-6),C(90,86,90))
 C3.kirillDoor=C3.Part(h,"KirillRoomDoor",Vector3.new(8,12,0.5),C3.Pos(-160,18,-6),C(88,71,61),Enum.Material.Wood)
 C3.doorClosed=C3.kirillDoor.CFrame
 C3.doorOpen=CFrame.new(C3.Pos(-164,18,-6))*CFrame.Angles(0,-math.pi/2,0)*CFrame.new(4,0,0)
 C3.Part(h,"Bed",Vector3.new(7,2,12),C3.Pos(-202,13.5,22),C(67,82,107),Enum.Material.Fabric)
 C3.Part(h,"Desk",Vector3.new(10,1,5),C3.Pos(-184,15,25),C(99,79,64),Enum.Material.Wood)
 C3.kirill=secretActor(h,"silv3r_candy","Кирилл",CFrame.lookAt(C3.Pos(-184,12.5,19),C3.Pos(-184,14,25)))
 C3.kirill:SetAttribute("ProtectedCivilian",true); C3.kirillPose={}
 for _,motor in ipairs(C3.kirill:GetDescendants()) do if motor:IsA("Motor6D") then C3.kirillPose[motor]=motor.C0 end end
 C2.SitRig(C3.kirill)
 local phone=C3.Part(h,"KirillPhone",Vector3.new(0.7,0.1,1.3),C3.Pos(-184,15.6,23),C(35,65,91),Enum.Material.Glass)
 light(phone,C(105,150,195),6,0.4)
end
function C3.Build()
 C3.map=Instance.new("Model"); C3.map.Name="Chapter3Singularity"; C3.map.Parent=levelFolder
 C3.zones={}; C3.redLights={}; C3.moduleParts={}
 C3.BuildHome()
 for segment=0,10 do
  C3.Part(C3.map,"CityRoad",Vector3.new(130,1,86),C3.Pos(-155+segment*128,-0.3,0),C(40,44,52),Enum.Material.Asphalt)
  for _,side in ipairs({-1,1}) do
   C3.Part(C3.map,"RouteBoundary",Vector3.new(130,18,2),C3.Pos(-155+segment*128,9,side*65),C(58,65,77))
   C3.Part(C3.map,"Sidewalk",Vector3.new(130,0.5,9),C3.Pos(-155+segment*128,0.4,side*37),C(104,108,118))
   local height=28+(segment*7)%40
   C3.Part(C3.map,"CityBlock",Vector3.new(90,height,30),C3.Pos(-160+segment*128,height/2,side*72),C(70+segment*3,78,96))
   for floor=1,math.floor(height/8) do for k=-3,3 do C3.Part(C3.map,"CityWindow",Vector3.new(5,3,0.2),C3.Pos(-160+segment*128+k*11,floor*7,side*56.8),C(163,164,146),Enum.Material.Glass) end end
  end
 end
 for i=1,4 do
  local x=80+(i-1)*175
  for _,side in ipairs({-1,1}) do C3.Part(C3.map,"StreetDeploymentWall",Vector3.new(70,18,1),C3.Pos(x+side*45,9,44),C(58,65,77)) end
  local car=C3.Part(C3.map,"BurningCar",Vector3.new(12,3,6),C3.Pos(x-25,2,19),C(49,52,60),Enum.Material.Metal)
  local fire=Instance.new("Fire"); fire.Size=8; fire.Heat=5; fire.Parent=car
  local smoke=Instance.new("Smoke"); smoke.Size=12; smoke.Opacity=0.2; smoke.Parent=car
  local siren=Instance.new("Sound"); siren.Name="CityEmergencyAlert"; siren.SoundId="rbxasset://sounds/electronicpingshort.wav"; siren.Volume=0.12; siren.PlaybackSpeed=0.65; siren.Looped=true; siren.RollOffMaxDistance=95; siren.Parent=car; siren:Play()
  if i==2 then C3.Part(C3.map,"BusCover",Vector3.new(24,7,8),C3.Pos(x,3.8,-22),C(55,76,95)) end
  if i==3 then
   C3.Part(C3.map,"Overpass",Vector3.new(100,2,84),C3.Pos(x,16,0),C(76,80,91))
   for _,side in ipairs({-1,1}) do C3.Part(C3.map,"BridgePillar",Vector3.new(7,16,7),C3.Pos(x,8,side*30),C(72,78,90)) end
  end
 end
 -- Tower silhouette, actual interior and an invulnerable visual field.
 C3.Part(C3.map,"TowerFoundation",Vector3.new(110,2,110),C3.Pos(960,-0.8,0),C(47,54,68),Enum.Material.Metal)
 for _,side in ipairs({-1,1}) do
  C3.Part(C3.map,"TowerSideWall",Vector3.new(2,side==-1 and 96 or 112,104),C3.Pos(960+side*52,side==-1 and 64 or 56,0),C(40,50,68),Enum.Material.Metal)
  local stripe=C3.Part(C3.map,"SignalSpine",Vector3.new(2.3,108,1.5),C3.Pos(960+side*53,55,0),C(190,40,59),Enum.Material.Neon); table.insert(C3.redLights,stripe)
 end
 -- Entry opening in west wall at ground level.
 for _,side in ipairs({-1,1}) do C3.Part(C3.map,"TowerEntrancePier",Vector3.new(3,16,40),C3.Pos(908,8,side*32),C(44,55,70)) end
 C3.Part(C3.map,"TowerRoof",Vector3.new(106,1,106),C3.Pos(960,113,0),C(35,46,62))
 C3.beacon=C3.Part(C3.map,"TowerBeacon",Vector3.new(8,35,8),C3.Pos(960,130,0),C(230,45,65),Enum.Material.Neon); table.insert(C3.redLights,C3.beacon); light(C3.beacon,C(235,55,65),100,1)
 C3.shield=C3.Part(C3.map,"InvulnerableTowerShield",Vector3.new(150,150,150),C3.Pos(960,65,0),C(125,45,95),Enum.Material.ForceField)
 C3.shield.Shape=Enum.PartType.Ball; C3.shield.CanCollide=false; C3.shield.CanTouch=false; C3.shield.CanQuery=false; C3.shield.Transparency=0.84
 for i=1,10 do
  local floor=i>=6 and (i-6)*24 or 0
  local x=i<=5 and 80+(i-1)*175 or 960
  local z={index=i,center=C3.Pos(x,floor+4,0),wave=0,rounds=(i==3 or i==10) and 3 or 2,cleared=false,objective=false}
  C3.zones[i]=z
  if i<=5 then
   z.start=C3.Pos(x-65,4,0); z.exit=C3.Pos(x+70,4,0)
   z.gate=C3.Part(C3.map,"DistrictGate",Vector3.new(1,14,130),C3.Pos(x+78,7,0),C(57,78,99),Enum.Material.Metal)
  else
   z.start=C3.Pos(960+(i%2==0 and -42 or 42),floor+4,-23)
   z.exit=C3.Pos(960+(i%2==0 and -42 or 42),floor+4,-40)
   -- Main floor deliberately leaves a 20-stud-wide stairwell slot.
   C3.Part(C3.map,"TowerFloor",Vector3.new(100,0.7,80),C3.Pos(960,floor,10),C(61,67,80),Enum.Material.Metal)
   for _,side in ipairs({-1,1}) do C3.Part(C3.map,"StairLanding",Vector3.new(16,0.7,20),C3.Pos(960+side*42,floor,-40),C(64,73,87)) end
   C3.Part(C3.map,"TowerBackWall",Vector3.new(100,24,1),C3.Pos(960,floor+12,-50),C(47,58,74))
   for _,side in ipairs({-1,1}) do C3.Part(C3.map,"TowerFrontWall",Vector3.new(40,24,1),C3.Pos(960+side*30,floor+12,50),C(47,58,74)) end
   if i<10 then
    local sign=i%2==0 and 1 or -1
    for step=1,24 do C3.Part(C3.map,"TowerStair",Vector3.new(3.4,1,13),C3.Pos(960-sign*39+sign*step*3.25,floor+step-0.5,-40),C(75,85,102),Enum.Material.Metal) end
    z.gate=C3.Part(C3.map,"StairGate",Vector3.new(1,14,18),C3.Pos(960-sign*32,floor+7,-40),C(67,86,111),Enum.Material.Metal)
   else z.gate=C3.Part(C3.map,"FinalShutter",Vector3.new(1,14,10),C3.Pos(1004,floor+7,-40),C(67,86,111)) end
   C3.Part(C3.map,"StairwellPartition",Vector3.new(64,14,1),C3.Pos(960,floor+7,-30),C(48,58,74))
   local lamp=C3.Part(C3.map,"TowerCeilingLamp",Vector3.new(8,0.2,3),C3.Pos(960,floor+(i==10 and 15 or 21),0),C(180,190,210),Enum.Material.Neon); light(lamp,C(190,205,225),52,1.2)
   for k=1,3 do C3.Part(C3.map,i==8 and "ServerRack" or "PowerCabinet",Vector3.new(5,7,4),C3.Pos(932+k*13,floor+3.8,-10),C(42,54,72),Enum.Material.Metal) end
  end
  z.covers={}
  for _,side in ipairs({-1,1}) do
   C3.Part(C3.map,"CombatCover",Vector3.new(9,3.4,5),C3.Pos(x+side*20,floor+2,side*18),C(68,77,90),Enum.Material.Metal)
   table.insert(z.covers,C3.Pos(x+side*20+7,floor+4,side*18))
  end
  z.gateClosed=z.gate.CFrame
  z.panel=C3.Part(C3.map,"ObjectiveConsole",Vector3.new(2,3,2),C3.Pos(x+30,floor+1.8,19),C(60,115,135),Enum.Material.Metal)
  C3.Prompt(z.panel,i==10 and "Главный терминал" or i>=6 and "Изолировать реле" or "Отключить ретранслятор",function(p) C3.CompleteObjective(p,z) end)
  local second=C3.Part(C3.map,"HardwareBreaker",Vector3.new(2,3,2),C3.Pos(x+30,floor+1.8,-20),C(115,80,65),Enum.Material.Metal)
  z.breaker=second
  C3.Prompt(second,"Подтвердить размыкатель",function(p)
   if C3.stage~=i or not z.cleared then return end
   if p:GetAttribute("Hero")=="Artem" and #C3.Living()>1 then NotifyRE:FireClient(p,"Этот размыкатель держит Демид.",2); return end
   z.assaultReady=true; C3.confirmPlayer=p; C3.confirmUntil=os.clock()+12; NotifyRE:FireAllClients("Размыкатель готов. Подтверждайте терминал.",3)
  end)
  -- Spawn vestibule is outside the playable wall, with a real opening/door.
  if i==5 then for _,side in ipairs({-1,1}) do C3.Part(C3.map,"StreetDeploymentWall",Vector3.new(70,18,1),C3.Pos(x+side*45,9,44),C(58,65,77)) end end
  local doorZ=i>=6 and 50 or 44
  z.spawnDoor=C3.Part(C3.map,"DeploymentDoor",Vector3.new(18,12,1),C3.Pos(x, floor+6,doorZ),C(51,65,84),Enum.Material.Metal); z.spawnClosed=z.spawnDoor.CFrame
  z.spawnPos=C3.Pos(x-4,floor+4,doorZ+7)
  C3.Part(C3.map,"VestibuleFloor",Vector3.new(20,0.7,26),C3.Pos(x,floor,doorZ+12),C(58,65,76))
  C3.Part(C3.map,"VestibuleRoof",Vector3.new(20,1,26),C3.Pos(x,floor+16,doorZ+12),C(38,46,60))
  C3.Part(C3.map,"VestibuleBack",Vector3.new(20,16,1),C3.Pos(x,floor+8,doorZ+25),C(48,57,73))
  for _,side in ipairs({-1,1}) do C3.Part(C3.map,"VestibuleWall",Vector3.new(1,16,26),C3.Pos(x+side*10,floor+8,doorZ+12),C(48,57,73)) end
  local med=C3.Part(C3.map,"MedicalKit",Vector3.new(2,1,2),C3.Pos(x-20,floor+1,-20),C(170,70,70)); local used={}
  C3.Prompt(med,"Аптечка",function(p) if not used[p] then local _,hum=C3.Root(p); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+65); used[p]=true end end end)
 end
 C3.previewGuards={}
 for k=1,4 do
  local cfg=table.clone(Types.Pistol); cfg.Male=false
  local rig=buildRig(cfg,CFrame.lookAt(C3.Pos(920+k*16,100,28),C3.Pos(800,100,0))); rig.Parent=C3.map; c2Dress(rig,false); anchorAll(rig); table.insert(C3.previewGuards,rig)
 end
 C3.case=C3.Part(C3.map,"ModuleCase",Vector3.new(5,0.6,3),C3.Pos(973,97,8),C(27,37,51),Enum.Material.Metal)
 for i=1,2 do
  local module=C3.Part(C3.map,i==1 and "ControlModule" or "MemoryModule",Vector3.new(1.3,0.35,1.8),C3.case.Position+Vector3.new((i-1.5)*2,0.6,0),C(64,150,137),Enum.Material.Metal)
  C3.moduleParts[i]=module; C3.Prompt(module,i==1 and "Забрать контроллер" or "Забрать память",function(p) C3.TakeModule(p,i) end)
 end
end

-- END CHAPTER THREE WORLD
function C3.MoveParty(position,look)
 for i,p in ipairs(C3.party) do
  local r=C3.Root(p); if r then p.Character:PivotTo(CFrame.lookAt(position+Vector3.new(0,0,(i-1)*4),look)); r.AssemblyLinearVelocity=Vector3.zero end
 end
end
function C3.Intro()
 C3.Scene(true); FadeRE:FireAllClients(true,"ГЛАВА III • БАШНЯ НЕЙРО-СИНГУЛЯРНОСТИ"); task.wait(1)
 local factory,neuro,assistant,screen=C3.BuildVillain()
 focusStreaming(neuro.Head.Position); prepareView(neuro.Head.Position)
 cameraPlan(neuro.Head.Position+Vector3.new(-9,2,-16),neuro.Head.Position+Vector3.new(-6,1,-10),neuro.Head.Position,2,60,52)
 CutsceneRE:FireAllClients("reveal")
 C3.Say(ANDROID_NAME,"Они уничтожили один из наших незначительных заводов... Это даже потерей тяжело назвать. Скоро весь мир покроется нашими рядами, и всё будет по нашим правилам. Идеальное общество, всё будет замечательно. Но хватит разговоров — пора действовать",12)
 moveModel(neuro,neuro:GetPivot()*CFrame.Angles(0,-0.8,0),0.8)
 C3.Say(ANDROID_NAME,"Эй, Тян C-3B1! Как успехи с нашим проектом Вышки Нейро-Сингулярной Связи?",5)
 moveModel(assistant,assistant:GetPivot()+Vector3.new(-6,0,0),1.5,true)
 cameraPlan(assistant.Head.Position+Vector3.new(3,1,-9),assistant.Head.Position+Vector3.new(2,1,-8),assistant.Head.Position,1,54,52)
 C3.Say("Тян C-3B1","Всё успешно, мы готовы запустить её в центре одного из крупных городов. Хммм... что насчёт города, где сосредоточено больше всего филиалов и компаний НТЯН?",8)
 cameraPlan(neuro.Head.Position+Vector3.new(-5,1,-10),neuro.Head.Position+Vector3.new(-4,1,-8),neuro.Head.Position,1,55,50)
 C3.Say(ANDROID_NAME,"Идеальный выбор. Мы подчиним тысячи людей за секунды и ускорим наше влияние в тысячи раз. Нам больше не придётся отлавливать людей или клонировать их вручную. Начинаем!",9)
 FadeRE:FireAllClients(true,""); task.wait(0.8)
 C3.MoveParty(C3.Pos(-174,4,2),C3.Pos(-150,4,0)); focusStreaming(C3.Pos(-170,5,0)); prepareView(C3.Pos(-170,5,0))
 C3.buddy=secretActor(C3.map,C3.party[1]:GetAttribute("Hero")=="Artem" and "ZamestitelDiomchica" or "eurtyoeyrntiu","Напарник",CFrame.lookAt(C3.Pos(-168,0.5,-7),C3.Pos(-174,3,2)))
 if C3.coop then C3.buddy:Destroy(); C3.buddy=nil end
 CutsceneRE:FireAllClients("pov",C3.tv,65); CutsceneRE:FireAllClients("reveal")
 C3.Say("Демид","Мы им завод снесли, а крайними всё равно оказались мы. Я до сих пор не понимаю, кто здесь с кем воюет.",5)
 C3.Say("Артём","И почему НТЯН ищет нас, а не тех, кто людей переделывает? Тут явно не вся картина.",4)
 C3RE:FireAllClients("signal"); ShakeRE:FireAllClients(2); task.wait(2)
 for i,p in ipairs(C3.party) do if C3.Root(p) then tweenCharTo(p.Character,CFrame.lookAt(C3.Pos(-143,4,(i-1)*5),C3.Pos(960,100,0)),1.5) end end
 CutsceneRE:FireAllClients("pov",C3.beacon,65)
 C3.Say("Демид","Ты это слышал?! Что там происходит?",3)
 C3RE:FireAllClients("binocular",true)
 CutsceneRE:FireAllClients("cam",{cf=CFrame.lookAt(C3.Pos(-142,6,0),C3.Pos(960,103,0)),fov=7,time=1.4}); task.wait(3)
 C3.Say("Артём","Сигнал идёт оттуда. Смотри на охрану наверху.",3)
 C3.Say("Демид","Значит, эту штуку нужно выключить. Сейчас, пока она весь город не накрыла.",4)
 C3RE:FireAllClients("binocular",false)
 C3.Say("Артём","Стой. Кирилл же наверху, в комнате!",3)
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 C3.MoveParty(C3.Pos(-171,16,8),C3.kirill.Head.Position)
 TweenService:Create(C3.kirillDoor,TweenInfo.new(0.7),{CFrame=C3.doorOpen}):Play(); task.wait(0.8)
 CutsceneRE:FireAllClients("pov",C3.kirill.Head,58); CutsceneRE:FireAllClients("reveal")
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
 m:SetAttribute("Enemy",true)
 local e={stage=stage,hum=h,root=r,civilian=civilian,down=false,last=0,stun=0,joints=j,base={},pathAt=0,waypoints={},waypoint=1,tactic=k%3,cover=C3.zones[stage].covers[(k-1)%2+1]}
 for name,motor in pairs(j) do e.base[name]=motor.C0 end; C3.mobs[m]=e
 table.insert(C3.connections,h.Died:Connect(function() e.down=true; ragdoll(m); Debris:AddItem(m,12) end))
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
  C3.shieldSeen=true; C3.Scene(true); CutsceneRE:FireAllClients("pov",C3.shield,63)
  C2.ScriptedShot(C3.shield.Position-Vector3.new(74,0,0),false)
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
 if C3.coop and z.index>=6 and not z.assaultReady then
  local assault=false; for _,q in ipairs(C3.Living()) do if q~=p then assault=true end end
  if assault then NotifyRE:FireClient(p,"Напарник должен подтвердить соседний размыкатель.",3); return end
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
 cameraPlan(C3.Pos(1080,115,-110),C3.Pos(1070,108,-100),C3.Pos(960,60,0),3,62,66)
 for _,p in ipairs(C3.redLights) do
  if p.Parent then p.Color=C(38,49,58); for _,l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Enabled=false end end end
  task.wait(0.08)
 end
 TweenService:Create(C3.shield,TweenInfo.new(2),{Transparency=1}):Play(); C3.shield.CanQuery=false
 for _,e in pairs(C3.mobs) do if e.civilian then e.down=true end end
 task.wait(3)
 C3.MoveParty(C3.Pos(942,100,8),C3.case.Position)
 CutsceneRE:FireAllClients("pov",C3.case,58)
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
 CutsceneRE:FireAllClients("pov",C3.case,57)
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
 C3.active=true; C3.finished=false; C3.serial+=1; C3.party=table.clone(party); C3.coop=#party>1; C3.mobs={}; C3.connections={}; C3.sprint={}; C3.relays=0; C3.key=false; C3.shieldSeen=false; C3.hackPhase=1; C3.hackSerial=0; C3.shots={}; C3.recovering={}; C3.towerOff=false; C3.modules={}; C3.collecting=false; C3.confirmUntil=nil; C3.confirmPlayer=nil; C3.hacker=nil; C3.challenge=nil; C3.stage=1
 C2.originals={}; Players.RespawnTime=999999
 local physics=game:GetService("PhysicsService"); pcall(function() physics:RegisterCollisionGroup("C2Enemy") end); physics:CollisionGroupSetCollidable("C2Enemy","C2Enemy",false)
 clearLevel(); newFolders(); applyPreset("Base",0.2); C3.Build()
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
 if name~="Fists" then tracer(origin,hit.Position,w.Color) end
 -- Kirill and the tower never enter the damage registry. Shield is not an HP pool.
 local model=hit.Instance:FindFirstAncestorOfClass("Model"); local e=model and C3.mobs[model]
 if not e or e.down or e.hum.Health<=0 then return end
 if e.civilian then
  e.suppression=(e.suppression or 0)+(name=="Fists" and 50 or 35)
  e.stun=os.clock()+2
  if e.suppression>=80 then e.down=true; e.hum.WalkSpeed=0; e.hum.Sit=true; model:SetAttribute("Enemy",false); NotifyRE:FireClient(p,"Гражданин обезврежен без летального исхода",2) end
 else
  local damage=name=="Fists" and (p:GetAttribute("Hero")=="Artem" and 25 or 48) or w.Damage*(name=="Shotgun" and 5 or 1)
  if name=="Rifle" then local c=typeof(charge)=="number" and charge==charge and math.clamp(charge,0,1) or 0; damage=45+235*c end
  if hit.Instance.Name=="Head" then damage*=1.5 end
  if name=="Fists" then e.stun=os.clock()+1 end
  e.hum:TakeDamage(damage)
 end
 HitRE:FireClient(p,e.down or e.hum.Health<=0)
end
