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
 C3.backdrop=Instance.new("Model"); C3.backdrop.Name="Chapter3CityBackdrop"; C3.backdrop.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.backdrop.Parent=C3.map
 for segment=0,10 do
  C3.Part(C3.backdrop,"CityRoad",Vector3.new(130,1,86),C3.Pos(-155+segment*128,-0.3,0),C(40,44,52),Enum.Material.Asphalt)
  for _,side in ipairs({-1,1}) do
   C3.Part(C3.backdrop,"RouteBoundary",Vector3.new(130,18,2),C3.Pos(-155+segment*128,9,side*65),C(58,65,77))
   C3.Part(C3.backdrop,"Sidewalk",Vector3.new(130,0.5,9),C3.Pos(-155+segment*128,0.4,side*37),C(104,108,118))
   local height=28+(segment*7)%40
   C3.Part(C3.backdrop,"CityBlock",Vector3.new(90,height,30),C3.Pos(-160+segment*128,height/2,side*72),C(70+segment*3,78,96))
   for floor=1,math.floor(height/8) do for k=-3,3 do C3.Part(C3.backdrop,"CityWindow",Vector3.new(5,3,0.2),C3.Pos(-160+segment*128+k*11,floor*7,side*56.8),C(163,164,146),Enum.Material.Glass) end end
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
 -- Persistent landmark stays visible from the home window and binoculars;
 -- actual combat floors remain separately streamable around the players.
 C3.landmark=Instance.new("Model"); C3.landmark.Name="SingularityLandmark"; C3.landmark.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.landmark.Parent=C3.map
 -- Tower silhouette, actual interior and an invulnerable visual field.
 C3.Part(C3.landmark,"TowerFoundation",Vector3.new(110,2,110),C3.Pos(960,-0.8,0),C(47,54,68),Enum.Material.Metal)
 for _,side in ipairs({-1,1}) do
  C3.Part(C3.landmark,"TowerSideWall",Vector3.new(2,side==-1 and 96 or 112,104),C3.Pos(960+side*52,side==-1 and 64 or 56,0),C(40,50,68),Enum.Material.Metal)
  local stripe=C3.Part(C3.landmark,"SignalSpine",Vector3.new(2.3,108,1.5),C3.Pos(960+side*53,55,0),C(190,40,59),Enum.Material.Neon); table.insert(C3.redLights,stripe)
 end
 -- Entry opening in west wall at ground level.
 for _,side in ipairs({-1,1}) do C3.Part(C3.landmark,"TowerEntrancePier",Vector3.new(3,16,40),C3.Pos(908,8,side*32),C(44,55,70)) end
 C3.Part(C3.landmark,"TowerRoof",Vector3.new(106,1,106),C3.Pos(960,113,0),C(35,46,62))
 C3.beacon=C3.Part(C3.landmark,"TowerBeacon",Vector3.new(8,35,8),C3.Pos(960,130,0),C(230,45,65),Enum.Material.Neon); table.insert(C3.redLights,C3.beacon); light(C3.beacon,C(235,55,65),100,1)
 C3.shield=C3.Part(C3.landmark,"InvulnerableTowerShield",Vector3.new(150,150,150),C3.Pos(960,65,0),C(125,45,95),Enum.Material.ForceField)
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
  local rig=buildRig(cfg,CFrame.lookAt(C3.Pos(920+k*16,100,28),C3.Pos(800,100,0))); rig.Parent=C3.landmark; c2Dress(rig,false); anchorAll(rig); table.insert(C3.previewGuards,rig)
 end
 C3.case=C3.Part(C3.map,"ModuleCase",Vector3.new(5,0.6,3),C3.Pos(973,97,8),C(27,37,51),Enum.Material.Metal)
 for i=1,2 do
  local module=C3.Part(C3.map,i==1 and "ControlModule" or "MemoryModule",Vector3.new(1.3,0.35,1.8),C3.case.Position+Vector3.new((i-1.5)*2,0.6,0),C(64,150,137),Enum.Material.Metal)
  C3.moduleParts[i]=module; C3.Prompt(module,i==1 and "Забрать контроллер" or "Забрать память",function(p) C3.TakeModule(p,i) end)
 end
end
