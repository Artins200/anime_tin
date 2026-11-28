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
 local base=C3.Part(C3.landmark,"TowerFoundation",Vector3.new(104,2,104),C3.Pos(960,-1,0),C(36,45,61),Enum.Material.Metal)
 for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
  C3.Part(C3.landmark,"TowerPylon",Vector3.new(3.5,116,3.5),C3.Pos(960+sx*46,58,sz*46),C(88,104,119),Enum.Material.Metal)
 end end
 for floor=0,4 do
  local y=floor*24+12
  for _,side in ipairs({-1,1}) do
   local panel=C3.Part(C3.landmark,"TowerSignalFin",Vector3.new(1.4,22,30),C3.Pos(960+side*49,y,0),C(183,53,66),Enum.Material.Neon); panel.Transparency=0.12; table.insert(C3.redLights,panel)
  end
  local rim=C3.Part(C3.landmark,"TowerFloorRim",Vector3.new(100,1,100),C3.Pos(960,floor*24,0),C(53,64,81),Enum.Material.Metal); rim.Transparency=0.15
 end
 C3.BuildRadioMast()
 C3.beacon=C3.Part(C3.landmark,"TowerBeacon",Vector3.new(10,7,10),C3.Pos(960,324,0),C(231,55,68),Enum.Material.Neon); table.insert(C3.redLights,C3.beacon); light(C3.beacon,C(235,55,65),90,1)
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
