-- Geometry and physical interactions for Chapter III; embedded into Chapter3.
function C3.Lamp(parent,pos,range,brightness,name)
 local fixture=C3.Part(parent,name or "AreaLamp",Vector3.new(3,0.25,2),pos,C(244,217,163),Enum.Material.Neon)
 fixture.CanCollide=false; fixture.CanQuery=false; fixture.CastShadow=false
 local lamp=light(fixture,C(255,220,158),range,brightness); lamp.Shadows=false
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

 -- Wall-mounted process monitors, readable from inside the bay rather than
 -- decorative blank slabs. Their restrained UI gives the lab a real control-room rhythm.
 local function monitor(name,size,position,heading,accent,normal,face)
  local frame=C3.Part(m,name,size,position,C(21,30,38),Enum.Material.Metal)
  if normal then frame.CFrame=CFrame.lookAt(position,position+normal,Vector3.yAxis) end
  local gui=Instance.new("SurfaceGui"); gui.Face=face or Enum.NormalId.Front; gui.CanvasSize=Vector2.new(480,260); gui.LightInfluence=0.35; gui.Parent=frame
  local bg=Instance.new("Frame"); bg.Size=UDim2.fromScale(1,1); bg.BackgroundColor3=C(12,23,31); bg.BorderSizePixel=0; bg.Parent=gui
  local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(0.92,0.22); title.Position=UDim2.fromScale(0.04,0.04); title.BackgroundTransparency=1; title.Text=heading; title.TextColor3=accent; title.TextScaled=true; title.Font=Enum.Font.GothamBold; title.Parent=bg
  for row=1,4 do
   local bar=Instance.new("Frame"); bar.Size=UDim2.fromScale(0.72+(row%2)*0.12,0.045); bar.Position=UDim2.fromScale(0.08,0.32+row*0.13); bar.BackgroundColor3=row==1 and accent or C(58,83,94); bar.BorderSizePixel=0; bar.Parent=bg
   local led=Instance.new("Frame"); led.Size=UDim2.fromScale(0.055,0.055); led.Position=UDim2.fromScale(0.86,0.31+row*0.13); led.BackgroundColor3=accent; led.BorderSizePixel=0; led.Parent=bg
  end
  return frame
 end
 for _,side in ipairs({-1,1}) do
  for index,z in ipairs({28,82,136,190,224}) do
   local position=o+Vector3.new(side*148.8,18+(index%2)*10,z)
   monitor("FactoryWallProcessMonitor",Vector3.new(12,7,0.45),position,"NEURO / LINE "..string.format("%02d",index),index%2==0 and C(107,185,186) or C(200,157,92),Vector3.new(-side,0,0))
  end
  local cable=C3.Part(m,"WallCableTrunk",Vector3.new(1.2,1.2,250),o+Vector3.new(side*144,48,105),C(85,96,101),Enum.Material.Metal)
  cable.CanCollide=false
 end
 for _,offset in ipairs({-42,0,42}) do
  local duct=C3.Part(m,"CeilingCoolantDuct",Vector3.new(1.1,1.1,250),o+Vector3.new(offset,49,105),C(91,101,104),Enum.Material.Metal)
  duct.Shape=Enum.PartType.Cylinder; duct.CFrame*=CFrame.Angles(0,math.rad(90),0); duct.CanCollide=false
  for z=0,210,30 do C3.Part(m,"CoolantDuctCoupler",Vector3.new(1.7,1.7,0.8),o+Vector3.new(offset,49,z),C(128,133,128),Enum.Material.Metal) end
 end
 -- Dramatic command dais: five distinct stations, angled screens, keypads,
 -- status LEDs and cable drops, all placed in front of the villain actors.
 local commandDais=C3.Part(m,"CommandDais",Vector3.new(82,0.8,28),o+Vector3.new(-2,0.4,56),C(38,46,52),Enum.Material.Metal)
 commandDais.CanCollide=false
 for _,edge in ipairs({-1,1}) do
  local stripe=C3.Part(m,"DaisSafetyStripe",Vector3.new(82,0.08,0.45),o+Vector3.new(-2,0.86,56+edge*13),C(174,132,68),Enum.Material.Metal); stripe.CanCollide=false
 end
 for station=1,5 do
  local x=-32+(station-1)*16
  C3.Part(m,"CommandStationPedestal",Vector3.new(13,2.3,7),o+Vector3.new(x,1.9,63),C(48,59,67),Enum.Material.Metal)
  C3.Part(m,"CommandStationSurface",Vector3.new(13.5,0.35,7.5),o+Vector3.new(x,3.15,63),C(75,85,88),Enum.Material.Metal)
  for key=1,6 do
   local button=C3.Part(m,"ConsoleKey",Vector3.new(0.48,0.16,0.48),o+Vector3.new(x-4.2+(key-1)*1.65,3.42,64.5),key%3==0 and C(177,86,59) or C(93,135,139),Enum.Material.Metal)
   button.CanCollide=false
  end
  local accent=station%2==0 and C(115,195,190) or C(216,166,96)
  local screenHeight=station==3 and 5.8 or 4.2
  monitor("CommandStationMonitor",Vector3.new(10,screenHeight,0.55),o+Vector3.new(x,5.7,58.9),station==3 and "NEURO CORE / CONTROL" or "CLONE ARRAY / STATUS",accent,nil,Enum.NormalId.Back)
  local cable=C3.Part(m,"ConsoleCableDrop",Vector3.new(0.25,0.25,12),o+Vector3.new(x,1.2,69),C(25,32,37),Enum.Material.Rubber); cable.CanCollide=false
 end
 -- Raised gantry rails and a central robotic service carriage over the vats.
 for _,x in ipairs({-132,132}) do C3.Part(m,"GantryRunway",Vector3.new(2.4,1.4,215),o+Vector3.new(x,33,128),C(75,85,91),Enum.Material.Metal) end
 C3.Part(m,"GantryBridge",Vector3.new(270,1.7,3),o+Vector3.new(0,33,128),C(95,104,106),Enum.Material.Metal)
 C3.Part(m,"GantryCarriage",Vector3.new(15,4,12),o+Vector3.new(-12,30,128),C(55,66,72),Enum.Material.Metal)
 C3.Part(m,"GantryManipulator",Vector3.new(1.4,13,1.4),o+Vector3.new(-12,21,128),C(116,128,130),Enum.Material.Metal)
 for _,side in ipairs({-1,1}) do
  C3.Part(m,"ManipulatorShoulder",Vector3.new(5,1,1),o+Vector3.new(-12+side*2.5,15,128),C(102,113,116),Enum.Material.Metal)
  C3.Part(m,"ManipulatorClaw",Vector3.new(0.6,3,0.6),o+Vector3.new(-12+side*4,13,128),C(172,153,105),Enum.Material.Metal)
 end
 -- The villains' operations wall extends beyond the ruin broadcast.
 monitor("NetworkStatusWallLeft",Vector3.new(34,18,0.5),o+Vector3.new(-48,22,244),"CITY GRID / LIVE FEED",C(122,191,184),Vector3.new(0,0,-1))
 monitor("NetworkStatusWallRight",Vector3.new(34,18,0.5),o+Vector3.new(48,22,244),"SUBJECTS / SIGNAL",C(202,144,93),Vector3.new(0,0,-1))

 -- Pod specimens use coordinated anime palettes, layered hair, clean facial
 -- highlights and tailored uniform details so they read as characters, not grey dummies.
 local cloneStyles={
  {hair=C(98,73,151),eye=C(104,207,238),shirt=C(220,217,207),skirt=C(54,63,91),legs=C(53,61,76),accent=C(218,181,103)},
  {hair=C(178,83,116),eye=C(112,201,163),shirt=C(192,143,151),skirt=C(91,48,70),legs=C(63,49,65),accent=C(228,199,159)},
  {hair=C(64,109,151),eye=C(174,149,230),shirt=C(178,198,205),skirt=C(48,76,96),legs=C(44,60,78),accent=C(136,207,213)},
  {hair=C(185,137,73),eye=C(106,177,222),shirt=C(226,209,174),skirt=C(111,76,54),legs=C(65,55,47),accent=C(236,190,95)},
  {hair=C(77,146,131),eye=C(215,153,190),shirt=C(191,206,192),skirt=C(55,91,79),legs=C(46,70,63),accent=C(221,166,185)},
  {hair=C(151,86,174),eye=C(116,207,217),shirt=C(212,190,220),skirt=C(76,57,100),legs=C(59,49,83),accent=C(223,194,116)},
 }
 local function podDetail(parent,base,name,size,offset,color,shape)
  local detail=Instance.new("Part"); detail.Name=name; detail.Size=size; detail.Color=color
  detail.Material=Enum.Material.SmoothPlastic; detail.Anchored=true
  detail.CanCollide=false; detail.CanTouch=false; detail.CanQuery=false
  if shape then detail.Shape=shape end
  detail.CFrame=base.CFrame*offset; detail.Parent=parent
  return detail
 end
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
   local style=cloneStyles[(row*2+col-2)%#cloneStyles+1]
   local cloneCfg=table.clone(Types.Pistol); cloneCfg.Name="Спящая тянка"; cloneCfg.Gun=false; cloneCfg.Male=false
   cloneCfg.Skin=C(205+(col%3)*4,174+(row%2)*5,158+(col%2)*4)
   cloneCfg.Hair=style.hair; cloneCfg.Eye=style.eye; cloneCfg.Shirt=style.shirt
   cloneCfg.Skirt=style.skirt; cloneCfg.Legs=style.legs; cloneCfg.Accent=style.accent
   local clone,hum,_,joints=buildRig(cloneCfg,CFrame.new(o+Vector3.new(x,3.15,z))); clone.Name="SuspendedClone"; clone.Parent=m; anchorAll(clone)
   for _,piece in ipairs(clone:GetDescendants()) do if piece:IsA("BasePart") then piece.CanCollide=false; piece.CanTouch=false; piece.CanQuery=false end end
   if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff end
   local head=clone:FindFirstChild("Head"); local torso=clone:FindFirstChild("Torso")
   if head and torso then
    podDetail(clone,head,"SilkHeadband",Vector3.new(1.55,0.12,0.1),CFrame.new(0,0.48,-0.22),style.accent)
    podDetail(clone,head,"SoftFringeLeft",Vector3.new(0.38,0.28,0.18),CFrame.new(-0.3,0.36,-0.48),style.hair)
    podDetail(clone,head,"SoftFringeRight",Vector3.new(0.38,0.28,0.18),CFrame.new(0.3,0.36,-0.48),style.hair)
    podDetail(clone,head,"LongHairLeft",Vector3.new(0.42,1.35,0.42),CFrame.new(-0.76,-0.52,0.32),style.hair)
    podDetail(clone,head,"LongHairRight",Vector3.new(0.42,1.35,0.42),CFrame.new(0.76,-0.52,0.32),style.hair)
    podDetail(clone,head,"HairPinLeft",Vector3.new(0.28,0.28,0.16),CFrame.new(-0.8,0.38,-0.25),style.accent,Enum.PartType.Ball)
    podDetail(clone,head,"HairPinRight",Vector3.new(0.28,0.28,0.16),CFrame.new(0.8,0.38,-0.25),style.accent,Enum.PartType.Ball)
    podDetail(clone,head,"EyeGlintLeft",Vector3.new(0.09,0.11,0.035),CFrame.new(-0.4,0.13,-0.575),C(245,241,225),Enum.PartType.Ball)
    podDetail(clone,head,"EyeGlintRight",Vector3.new(0.09,0.11,0.035),CFrame.new(0.4,0.13,-0.575),C(245,241,225),Enum.PartType.Ball)
    podDetail(clone,head,"SoftMouth",Vector3.new(0.2,0.045,0.035),CFrame.new(0,-0.29,-0.535),C(150,91,98))
    podDetail(clone,torso,"TailoredCollar",Vector3.new(0.9,0.18,0.08),CFrame.new(0,0.78,-0.53),style.accent)
    podDetail(clone,torso,"UniformBrooch",Vector3.new(0.28,0.32,0.1),CFrame.new(0,0.38,-0.55),style.accent,Enum.PartType.Ball)
    podDetail(clone,torso,"UniformWaistTrim",Vector3.new(1.7,0.11,0.08),CFrame.new(0,-0.68,-0.53),style.accent)
    podDetail(clone,torso,"SkirtHem",Vector3.new(2.25,0.1,1.42),CFrame.new(0,-1.18,0),style.accent)
   end
   if joints and joints.LS and joints.RS then
    joints.LS.C0*=CFrame.Angles(0,0,math.rad(-7)); joints.RS.C0*=CFrame.Angles(0,0,math.rad(7))
    for _=1,3 do for _,motor in ipairs(clone:GetDescendants()) do if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end end end
   end
   local statusColor=col%3==0 and C(195,83,66) or C(93,167,160)
   local status=C3.Part(m,"ClonePodStatus",Vector3.new(1.25,0.32,0.14),o+Vector3.new(x,8.2,z-3.18),statusColor,Enum.Material.SmoothPlastic)
   status.Material=Enum.Material.Neon; status.CanCollide=false; status.CanTouch=false; status.CanQuery=false
   light(status,statusColor,6,0.16)
   C3.Part(m,"ClonePodSerialPlate",Vector3.new(2,0.7,0.12),o+Vector3.new(x,2.9,z-3.25),C(61,73,78),Enum.Material.Metal).CanCollide=false
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
 local window=item("LivingWindow",Vector3.new(0.15,7,36),Vector3.new(-148,6.5,0),C(175,198,211),Enum.Material.Glass); window.Transparency=0.88; window.CanCollide=false; window.CanTouch=false; window.CanQuery=false
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
 item("Bed",Vector3.new(7,2,12),Vector3.new(-202,16.5,-15),C(67,82,107),Enum.Material.Fabric)
 item("BedPillow",Vector3.new(5,0.8,2.6),Vector3.new(-202,17.8,-20),C(174,177,173),Enum.Material.Fabric)
 item("Desk",Vector3.new(10,1,5),Vector3.new(-176,18,-20),C(99,79,64),Enum.Material.Wood)
 -- The shared lower floor has two unmistakable personal corners: Artem's
 -- electronics bench and Demid's field-kit rack/duffel.
 local artemDesk=item("ArtemElectronicsBench",Vector3.new(12,1,6),Vector3.new(-204,1.35,14),C(75,61,48),Enum.Material.Wood)
 artemDesk:SetAttribute("OwnerHero","Artem")
 item("ArtemKeyboard",Vector3.new(5,0.16,1.3),Vector3.new(-203,1.98,11.8),C(35,42,48),Enum.Material.Metal)
 item("ArtemLaptopBase",Vector3.new(5,0.3,3.5),Vector3.new(-203,2.15,15.2),C(42,51,58),Enum.Material.Metal)
 local artemScreen=item("ArtemHackingDisplay",Vector3.new(0.35,4.4,7.5),Vector3.new(-197.6,4.25,14),C(22,35,42),Enum.Material.Metal)
 artemScreen.CFrame=CFrame.lookAt(artemScreen.Position,artemScreen.Position+Vector3.new(1,0,0),Vector3.yAxis)
 local artemGui=Instance.new("SurfaceGui"); artemGui.Face=Enum.NormalId.Right; artemGui.CanvasSize=Vector2.new(440,280); artemGui.Parent=artemScreen
 local artemBg=Instance.new("Frame"); artemBg.Size=UDim2.fromScale(1,1); artemBg.BackgroundColor3=C(12,25,32); artemBg.BorderSizePixel=0; artemBg.Parent=artemGui
 local artemTitle=Instance.new("TextLabel"); artemTitle.Size=UDim2.fromScale(0.9,0.22); artemTitle.Position=UDim2.fromScale(0.05,0.05); artemTitle.BackgroundTransparency=1; artemTitle.Text="ARTEM / NETWORK MAP"; artemTitle.TextColor3=C(103,205,191); artemTitle.TextScaled=true; artemTitle.Font=Enum.Font.GothamBold; artemTitle.Parent=artemBg
 for row=1,5 do
  local trace=Instance.new("Frame"); trace.Size=UDim2.fromScale(0.14+(row%3)*0.13,0.035); trace.Position=UDim2.fromScale(0.12+(row%2)*0.35,0.32+row*0.1); trace.BackgroundColor3=row%2==0 and C(93,169,177) or C(170,141,83); trace.BorderSizePixel=0; trace.Parent=artemBg
 end
 local demidRack=item("DemidFieldKitRack",Vector3.new(1.2,8,10),Vector3.new(-151.5,4,-16),C(50,62,69),Enum.Material.Metal)
 demidRack:SetAttribute("OwnerHero","Demid")
 for level=1,3 do item("DemidRackShelf",Vector3.new(4.5,0.35,9),Vector3.new(-154.2,level*2.1,-16),C(104,112,111),Enum.Material.Metal) end
 item("DemidFieldDuffel",Vector3.new(7,1.6,4),Vector3.new(-160,0.9,-18),C(60,77,67),Enum.Material.Fabric)
 item("DemidShoulderRadio",Vector3.new(1.5,0.75,0.55),Vector3.new(-156.5,1.55,-16),C(49,65,70),Enum.Material.Metal)
 item("DemidTrainingGloveLeft",Vector3.new(1.4,1.7,1.1),Vector3.new(-156,3.5,-13),C(127,54,46),Enum.Material.Fabric)
 item("DemidTrainingGloveRight",Vector3.new(1.4,1.7,1.1),Vector3.new(-156,3.5,-18),C(127,54,46),Enum.Material.Fabric)
 -- Kirill's room shows that it is lived in: books, charging cables, a work
 -- monitor, first-aid supplies and a small lamp around his existing desk/bed.
 item("KirillBookshelf",Vector3.new(6,7,2.5),Vector3.new(-208,18.5,-12),C(86,67,53),Enum.Material.Wood)
 for row=1,2 do
  item("KirillBookshelf",Vector3.new(5.5,0.3,2.2),Vector3.new(-208,16.5+row*2.2,-12),C(122,91,66),Enum.Material.Wood)
  for book=1,4 do item("KirillBook",Vector3.new(0.55,1.45,1.6),Vector3.new(-210.1+book*0.95,16.9+row*2.2,-12),book%2==0 and C(61,94,105) or C(128,71,61),Enum.Material.SmoothPlastic) end
 end
 local kirillMonitor=item("KirillDeskMonitor",Vector3.new(8,4.6,0.35),Vector3.new(-176,21.3,-22.15),C(22,33,40),Enum.Material.Metal)
 kirillMonitor.CFrame*=CFrame.Angles(0,math.pi,0)
 local kirillGui=Instance.new("SurfaceGui"); kirillGui.Face=Enum.NormalId.Front; kirillGui.CanvasSize=Vector2.new(520,300); kirillGui.Parent=kirillMonitor
 local kirillLabel=Instance.new("TextLabel"); kirillLabel.Size=UDim2.fromScale(1,1); kirillLabel.BackgroundColor3=C(19,31,38); kirillLabel.Text="KIRILL / AUDIO LOGS"; kirillLabel.TextColor3=C(117,176,195); kirillLabel.TextScaled=true; kirillLabel.Font=Enum.Font.GothamBold; kirillLabel.Parent=kirillGui
 item("KirillDeskChair",Vector3.new(3.2,2,3.2),Vector3.new(-176,16.2,-14.8),C(61,70,75),Enum.Material.Fabric)
 item("KirillNightstand",Vector3.new(4,2.5,4),Vector3.new(-194,16.1,-14),C(91,70,53),Enum.Material.Wood)
 item("KirillFirstAidCase",Vector3.new(2.4,1,1.7),Vector3.new(-194,17.85,-14),C(170,73,67),Enum.Material.Metal)
 item("KirillNotebook",Vector3.new(2.5,0.18,3),Vector3.new(-171,18.62,-16),C(177,166,139),Enum.Material.SmoothPlastic)
 item("KirillHeadphones",Vector3.new(2,0.55,2),Vector3.new(-168,18.9,-16),C(38,45,50),Enum.Material.Metal)
 C3.kirill=secretActor(h,"silv3r_candy","Кирилл",CFrame.lookAt(C3.Pos(-184,15.2,-15),C3.Pos(-184,18,-8)))
 C3.kirill:SetAttribute("ProtectedCivilian",true); C3.kirillPose={}
 for _,motor in ipairs(C3.kirill:GetDescendants()) do if motor:IsA("Motor6D") then C3.kirillPose[motor]=motor.C0 end end
 C2.SitRig(C3.kirill)
 local phone=item("KirillPhone",Vector3.new(0.7,0.1,1.3),Vector3.new(-176,18.6,-18.5),C(35,65,91),Enum.Material.Glass); light(phone,C(105,150,195),6,0.4)
 for _,pos in ipairs({Vector3.new(-187,26,5),Vector3.new(-160,26,-15),Vector3.new(-223,26,0)}) do C3.Lamp(h,C3.Pos(pos.X,pos.Y,pos.Z),28,0.8,"HomeFillLamp") end
 -- Kirill's upstairs room gets real emissive tubes plus local point lights:
 -- cool blue near the desk and a softer violet accent behind the bed.
 for _,spec in ipairs({
  {name="KirillNeonBlue",size=Vector3.new(18,0.16,0.12),pos=Vector3.new(-176,25.6,-23.35),color=C(77,166,255)},
  {name="KirillNeonViolet",size=Vector3.new(15,0.16,0.12),pos=Vector3.new(-202,25.6,-22.8),color=C(177,105,255)},
 }) do
  local tube=item(spec.name,spec.size,spec.pos,spec.color,Enum.Material.SmoothPlastic)
  tube.Material=Enum.Material.Neon; tube.CanCollide=false; tube.CanTouch=false; tube.CanQuery=false
  light(tube,spec.color,18,0.45)
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
   local head=streetPart("LEDStreetLampHead",Vector3.new(3.6,0.35,1.15),x+side*3.5,10.35,side*42,C(72,83,98),Enum.Material.Metal)
   head.CFrame*=CFrame.Angles(0,math.rad(side*8),0)
   local lens=streetPart("LEDStreetLampLens",Vector3.new(2.8,0.08,0.8),x+side*3.5,10.12,side*42,C(255,228,174),Enum.Material.Neon); lens.CanCollide=false
   C3.Lamp(C3.backdrop,C3.Pos(x+side*3.5,9.98,side*42),29,1.45,"WarmStreetLamp")
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
 C3.shieldParts={}
 C3.shield=C3.Part(C3.landmark,"InvulnerableTowerShield",Vector3.new(166,382,166),C3.Pos(960,175,0),C(83,167,219),Enum.Material.ForceField)
 C3.shield.Shape=Enum.PartType.Ball; C3.shield.CanCollide=false; C3.shield.CanTouch=false; C3.shield.CanQuery=false; C3.shield.Transparency=0.965
 table.insert(C3.shieldParts,C3.shield)
 for layer=1,2 do
  local shell=C3.Part(C3.landmark,"ShieldResonanceShell",Vector3.new(166+layer*8,382+layer*8,166+layer*8),C3.Pos(960,175,0),layer==1 and C(75,177,225) or C(224,97,111),Enum.Material.ForceField)
  shell.Shape=Enum.PartType.Ball; shell.CanCollide=false; shell.CanTouch=false; shell.CanQuery=false; shell.Transparency=layer==1 and 0.976 or 0.986
  table.insert(C3.shieldParts,shell)
 end
 -- Three luminous, broken equatorial bands make the dome read at night as an active barrier.
 for band,y in ipairs({48,175,302}) do
  local radius=band==1 and 63 or band==2 and 83 or 63
  for segment=0,47 do
   local a=segment*math.pi*2/48; local b=(segment+1)*math.pi*2/48
   local color=segment%6==0 and C(245,194,121) or band==2 and C(79,211,235) or C(108,156,235)
   local beam=C3.Beam(C3.landmark,"ShieldEnergyArc",C3.Pos(960+math.cos(a)*radius,y,math.sin(a)*radius),C3.Pos(960+math.cos(b)*radius,y,math.sin(b)*radius),0.65,color)
   beam.Material=Enum.Material.Neon; beam.Transparency=0.12; beam.CanCollide=false; beam.CanTouch=false; beam.CanQuery=false
   table.insert(C3.shieldParts,beam)
  end
 end
 -- Four vertical energy filaments converge around the lattice mast.
 for quadrant=0,3 do
  local angle=quadrant*math.pi/2+math.pi/4
  local arc=C3.Beam(C3.landmark,"ShieldMeridian",C3.Pos(960+math.cos(angle)*72,12,math.sin(angle)*72),C3.Pos(960+math.cos(angle)*72,338,math.sin(angle)*72),0.42,C(105,215,239))
  arc.Material=Enum.Material.Neon; arc.Transparency=0.16; arc.CanCollide=false; arc.CanTouch=false; arc.CanQuery=false
  table.insert(C3.shieldParts,arc)
 end
 task.spawn(function()
  local phase=0
  while C3.active and C3.shield and C3.shield.Parent and not C3.towerOff do
   phase+=0.1
   for index,part in ipairs(C3.shieldParts) do
    if part.Parent and part~=C3.shield and part.Name~="ShieldResonanceShell" then part.Transparency=0.08+0.18*(0.5+0.5*math.sin(phase+index*0.35)) end
   end
   task.wait(0.12)
  end
 end)

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
  C3.Prompt(z.panel,stage==10 and "Главный терминал" or "Изолировать реле",function(p)
   if stage==10 and p:GetAttribute("Hero")=="Artem" then
    if not C3.CanHack(p) then NotifyRE:FireClient(p,"До терминала нужно отключить четыре реле и получить ключ.",3); return end
    NotifyRE:FireAllClients("Артём обходит защиту напрямую.",3)
    C3.CloseHack(); C3.Finale()
    return
   end
   C3.CompleteObjective(p,z)
  end,stage==10 and 1.2 or nil)
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
