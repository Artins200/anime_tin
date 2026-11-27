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
 for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
  C3.Part(C3.landmark,"RadioMastLeg",Vector3.new(2.5,204,2.5),C3.Pos(960+sx*13,216,sz*13),C(170,181,192),Enum.Material.Metal)
 end end
 for level=0,8 do
  local y=114+level*24
  for _,side in ipairs({-1,1}) do
   C3.Beam(C3.landmark,"TrussCrossBrace",C3.Pos(947,y,side*13),C3.Pos(973,y+24,side*13),1.2,C(187,196,206))
   C3.Beam(C3.landmark,"TrussCrossBrace",C3.Pos(960+side*13,y,-13),C3.Pos(960+side*13,y+24,13),1.2,C(187,196,206))
   local ring=C3.Part(C3.landmark,"SignalRing",Vector3.new(29,0.3,0.5),C3.Pos(960,y,side*14),C(220,70,65),Enum.Material.Neon); table.insert(C3.redLights,ring)
  end
 end
 for _,y in ipairs({157,205,253,301}) do
  for _,side in ipairs({-1,1}) do
   C3.Part(C3.landmark,"CellularPanelAntenna",Vector3.new(3,16,7),C3.Pos(960+side*20,y,0),C(214,220,223),Enum.Material.Metal)
   C3.Beam(C3.landmark,"AntennaMount",C3.Pos(960+side*13,y,0),C3.Pos(960+side*20,y,0),1,C(95,111,128))
   local dish=C3.Part(C3.landmark,"MicrowaveDish",Vector3.new(2,14,14),C3.Pos(960+side*19,y,20),C(201,211,220),Enum.Material.SmoothPlastic); dish.Shape=Enum.PartType.Ball
   C3.Beam(C3.landmark,"DishFeed",C3.Pos(960+side*19,y,20),C3.Pos(960+side*27,y,20),0.7,C(70,86,104))
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
 for _,offset in ipairs({Vector3.new(-23,13,-2),Vector3.new(4,13,-4),Vector3.new(-15,17,17)}) do C3.Lamp(m,o+offset,42,2.5,"CinematicKeyLight") end
 local cfg=table.clone(Types.Neuro); cfg.Name=ANDROID_NAME
 local neuro=buildRig(cfg,CFrame.lookAt(o+Vector3.new(-15,3.5,5),screen.Position)); neuro.Parent=m; enhanceNeuroCyber(neuro); anchorAll(neuro)
 cfg=table.clone(Types.Pistol); cfg.Name="Тян C-3B1"; cfg.Male=false
 local assistant=buildRig(cfg,CFrame.lookAt(o+Vector3.new(9,3.5,2),o+Vector3.new(-15,3.5,5))); assistant.Parent=m; c2Dress(assistant,false); anchorAll(assistant)
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
end
function C3.Build()
 C3.map=Instance.new("Model"); C3.map.Name="Chapter3Singularity"; C3.map.Parent=levelFolder
 C3.zones={}; C3.redLights={}; C3.moduleParts={}
 C3.structure=Instance.new("Model"); C3.structure.Name="PersistentWalkableStructure"; C3.structure.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.structure.Parent=C3.map
 C3.BuildHome()
 C3.backdrop=Instance.new("Model"); C3.backdrop.Name="Chapter3CityBackdrop"; C3.backdrop.ModelStreamingMode=Enum.ModelStreamingMode.Persistent; C3.backdrop.Parent=C3.map
 for segment=0,10 do
  C3.Part(C3.backdrop,"CityRoad",Vector3.new(130,1,130),C3.Pos(-155+segment*128,-0.3,0),C(40,44,52),Enum.Material.Asphalt)
  C3.Part(C3.backdrop,"CitySafetyFoundation",Vector3.new(130,2,240),C3.Pos(-155+segment*128,-1.9,0),C(88,91,94))
  for offset=0,1 do C3.Lamp(C3.backdrop,C3.Pos(-155+segment*128+offset*64,12,0),48,2.5,"StreetAreaLamp") end
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
 C3.BuildRadioMast()
 C3.beacon=C3.Part(C3.landmark,"TowerBeacon",Vector3.new(12,8,12),C3.Pos(960,324,0),C(230,45,65),Enum.Material.Neon); table.insert(C3.redLights,C3.beacon); light(C3.beacon,C(235,55,65),100,1)
 C3.shield=C3.Part(C3.landmark,"InvulnerableTowerShield",Vector3.new(155,370,155),C3.Pos(960,175,0),C(125,45,95),Enum.Material.ForceField)
 C3.shield.Shape=Enum.PartType.Ball; C3.shield.CanCollide=false; C3.shield.CanTouch=false; C3.shield.CanQuery=false; C3.shield.Transparency=0.94
 for i=1,10 do
  local floor=i>=6 and (i-6)*24 or 0
  local x=i<=5 and 80+(i-1)*175 or 960
  local z={index=i,center=C3.Pos(x,floor+4,0),wave=0,rounds=(i==3 or i==10) and 3 or 2,cleared=false,objective=false}
  C3.zones[i]=z
  if i<=5 then
   z.start=C3.Pos(x-65,4,0); z.exit=C3.Pos(x+70,4,0)
   z.gate=C3.Part(C3.map,"DistrictGate",Vector3.new(1,14,130),C3.Pos(x+78,7,0),C(57,78,99),Enum.Material.Metal)
  else
   local lane=i%2==0 and -40 or 40
   local arrival=i==6 and -23 or (i%2==0 and 23 or -23)
   z.start=C3.Pos(960+(i%2==0 and -42 or 42),floor+4,arrival)
   z.exit=C3.Pos(960+(i%2==0 and 42 or -42),floor+28,lane)
   -- Main floor deliberately leaves a 20-stud-wide stairwell slot.
   C3.Part(C3.map,"TowerFloor",Vector3.new(100,0.7,60),C3.Pos(960,floor,0),C(61,67,80),Enum.Material.Metal)
   for _,side in ipairs({-1,1}) do for _,edge in ipairs({-1,1}) do
    C3.Part(C3.map,"StairLanding",Vector3.new(10,0.7,20),C3.Pos(960+side*45,floor,edge*40),C(112,124,138))
   end end
   C3.Part(C3.map,"TowerBackWall",Vector3.new(100,24,1),C3.Pos(960,floor+12,-50),C(47,58,74))
   for _,side in ipairs({-1,1}) do C3.Part(C3.map,"TowerFrontWall",Vector3.new(40,24,1),C3.Pos(960+side*30,floor+12,50),C(47,58,74)) end
   if i<10 then
    local sign=i%2==0 and 1 or -1
    for step=1,24 do
     local sx=960-sign*40+sign*(step-0.5)*3.4
     C3.Part(C3.map,"TowerStair",Vector3.new(3.4,1,13),C3.Pos(sx,floor+step-0.5,lane),C(126,141,157),Enum.Material.Metal)
     if step>1 then C3.Part(C3.map,"StairSolidSupport",Vector3.new(3.4,step-1,13),C3.Pos(sx,floor+(step-1)/2,lane),C(91,105,121)) end
     for _,edge in ipairs({-1,1}) do C3.Part(C3.map,"StairSafetyRail",Vector3.new(3.4,3.5,0.35),C3.Pos(sx,floor+step+1.75,lane+edge*7),C(173,187,196),Enum.Material.Metal) end
    end
    z.gate=C3.Part(C3.map,"StairGate",Vector3.new(1,14,18),C3.Pos(960-sign*32,floor+7,lane),C(67,86,111),Enum.Material.Metal)
   else z.gate=C3.Part(C3.map,"FinalShutter",Vector3.new(1,14,10),C3.Pos(1004,floor+7,-40),C(67,86,111)) end
   for _,edge in ipairs({-1,1}) do
    local rail=C3.Part(C3.map,"StairwellPartition",Vector3.new(64,12,0.5),C3.Pos(960,floor+6,edge*30),C(173,197,208),Enum.Material.Glass); rail.Transparency=0.55
   end
   if i==6 or i==10 then
    local safeLane=i==6 and 40 or -40
    C3.Part(C3.map,"ClosedShaftSafetyFloor",Vector3.new(68,0.7,20),C3.Pos(960,floor,safeLane),C(100,115,132))
   end
   for _,lx in ipairs({-32,0,32}) do for _,lz in ipairs({-20,20}) do C3.Lamp(C3.map,C3.Pos(960+lx,floor+14,lz),38,2.2,"TowerCeilingLamp") end end
   for _,edge in ipairs({-1,1}) do C3.Lamp(C3.map,C3.Pos(960,floor+16,edge*40),48,1.8,"StairwellLamp") end
   C3.CommunicationEquipment(i,floor)
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
  local doorZ=i>=6 and 5 or 44
  z.spawnDoor=C3.Part(C3.map,"DeploymentDoor",Vector3.new(18,12,1),C3.Pos(x, floor+6,doorZ),C(51,65,84),Enum.Material.Metal); z.spawnClosed=z.spawnDoor.CFrame
  z.spawnPos=C3.Pos(x-4,floor+4,doorZ+7)
  C3.Lamp(C3.map,C3.Pos(x,floor+11,doorZ+10),26,2,"DeploymentLamp")
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
