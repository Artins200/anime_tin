-- Chapter III: authoritative campaign. Embedded after Chapter II helpers.
local C3={active=false,serial=0,party={},mobs={},connections={}}
local C3RE=newRemote("Chapter3")
C3.origin=Vector3.new(0,0,12000)
C3.names={"ЖИЛОЙ КВАРТАЛ","ТОРГОВАЯ УЛИЦА","РАЗВЯЗКА","КВАРТАЛ НТЯН","ПЛОЩАДЬ БАШНИ","СЕРВИСНЫЙ ЭТАЖ","СИЛОВОЙ ЯРУС","СЕРВЕРНЫЙ ЯРУС","АНТЕННЫЙ ЯРУС","ВЕРХНИЙ ПОСТ"}
function C3.Pos(x,y,z) return C3.origin+Vector3.new(x,y,z or 0) end
function C3.Part(parent,name,size,pos,color,mat)
 if parent==C3.map and C3.structure and C3.structure.Parent==C3.map then parent=C3.structure end
 local p=part(parent,size,pos,color,mat or Enum.Material.Concrete); p.Name=name
 if name=="SignalSpine" then p.Material=Enum.Material.Neon end
 return p
end
function C3.ApplyLighting()
 C3.lightingSaved={}
 for _,key in ipairs({"Ambient","OutdoorAmbient","Brightness","ClockTime","ExposureCompensation","FogStart","FogEnd","EnvironmentDiffuseScale","EnvironmentSpecularScale"}) do C3.lightingSaved[key]=Lighting[key] end
 C3.effectsSaved={density=atm.Density,haze=atm.Haze,color=atm.Color,contrast=cc.Contrast,saturation=cc.Saturation,tint=cc.TintColor,brightness=cc.Brightness,bloom=bloom.Intensity}
 Lighting.Ambient=C(60,70,90); Lighting.OutdoorAmbient=C(44,56,75); Lighting.Brightness=1.65; Lighting.ClockTime=22.15; Lighting.ExposureCompensation=-0.01
 Lighting.FogStart=500; Lighting.FogEnd=5000; Lighting.EnvironmentDiffuseScale=0.42; Lighting.EnvironmentSpecularScale=0.44
 atm.Density=0.09; atm.Haze=0.5; atm.Color=C(104,128,163)
 cc.Contrast=0.06; cc.Saturation=-0.08; cc.TintColor=C(219,226,244); cc.Brightness=0.015; bloom.Intensity=0.16
end
function C3.RestoreLighting()
 if not C3.lightingSaved then return end
 for key,value in pairs(C3.lightingSaved) do Lighting[key]=value end
 local e=C3.effectsSaved
 atm.Density=e.density; atm.Haze=e.haze; atm.Color=e.color; cc.Contrast=e.contrast; cc.Saturation=e.saturation; cc.TintColor=e.tint; cc.Brightness=e.brightness; bloom.Intensity=e.bloom
 C3.lightingSaved=nil; C3.effectsSaved=nil
end
function C3.PrepareCapturedCivilian(model,hum)
 model:SetAttribute("Enemy",true); model:SetAttribute("CapturedCivilian",true)
 hum.BreakJointsOnDeath=false; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true)
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
function C3.Send(force)
 local z=C3.zones and C3.zones[C3.stage]; if not z then return end
 local payload={stage=C3.stage,name=C3.names[C3.stage],wave=z.wave,rounds=z.rounds,enemies=C3.Count(C3.stage),cleared=z.cleared,objective=z.objective,relays=C3.relays,phase=C3.hackPhase,shield=not C3.towerOff,coop=C3.coop}
 local signature=("%d:%d:%d:%d:%d:%d:%d:%d"):format(payload.stage,payload.wave,payload.enemies,payload.cleared and 1 or 0,payload.objective and 1 or 0,payload.relays,payload.phase,payload.shield and 1 or 0)
 local now=os.clock()
 if not force and signature==C3.lastStateSignature and now-(C3.lastStateSent or 0)<1 then return end
 C3.lastStateSignature=signature; C3.lastStateSent=now
 for _,p in ipairs(C3.party) do if p.Parent then C3RE:FireClient(p,"state",payload) end end
end
function C3.Protected(fn)
 local ok,err=xpcall(fn,debug.traceback)
 if not ok then
  warn("[Chapter3] "..tostring(err))
  local detail=tostring(err):match("^[^\n]+") or "Unknown server error"
  NotifyRE:FireAllClients("Сбой главы III: "..detail,12)
  task.wait(4) -- Keep the exact server error visible before the fallback menu loads.
  C3.Stop(); returnToMenu()
 end
end
function C3.Stop()
 C3.active=false; C3.serial+=1; C3.RestoreLighting()
 for _,c in ipairs(C3.connections) do c:Disconnect() end; C3.connections={}
 for _,p in ipairs(C3.party) do if p.Parent then p:SetAttribute("IsSprinting",false); p:SetAttribute("Chapter",1); p:SetAttribute("SprintStamina",100); p:SetAttribute("C3GrabbedUntil",nil) end end
 C3RE:FireAllClients("clear"); C2RE:FireAllClients("clear"); CreditsRE:FireAllClients(false)
 if C3.map and C3.map.Parent then C3.map:Destroy() end; C3.map=nil; C3.landmark=nil; C3.home=nil; C3.zones=nil
 C3.lastStateSignature=nil; C3.lastStateSent=nil
 Players.RespawnTime=3; c2RestoreHeroes(); MusicRE:FireAllClients("stop")
end
function C3.Scene(on)
 introActive=on; canFight=not on
 C3.sceneCollision=C3.sceneCollision or setmetatable({}, {__mode="k"})
 for _,player in ipairs(C3.party) do
  local character=player.Character
  if character then
   character:SetAttribute("CinematicIgnoreObstacles",on)
   for _,piece in ipairs(character:GetDescendants()) do
    if piece:IsA("BasePart") then
     if on then
      if C3.sceneCollision[piece]==nil then C3.sceneCollision[piece]=piece.CanCollide end
      piece.CanCollide=false
     elseif C3.sceneCollision[piece]~=nil then
      piece.CanCollide=C3.sceneCollision[piece]; C3.sceneCollision[piece]=nil
     end
    end
   end
  end
 end
 sceneLock(on)
 CutsceneRE:FireAllClients(on and "start" or "end")
end
function C3.Say(name,text,time) C2.Literal(name,text,time) end
function C3.Prompt(part_,text,callback,hold)
 local labels={SignalRelay="Ретранслятор сигнала",ObjectiveConsole="Панель управления",HardwareBreaker="Размыкатель",DeploymentDoor="Дверь подкрепления",KirillRoomDoor="Дверь комнаты Кирилла",MedicalKit="Аптечка",ControlModule="Модуль управления",MemoryModule="Модуль памяти"}
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=text; prompt.ObjectText=labels[part_.Name] or part_.Name:gsub("([a-z])([A-Z])","%1 %2"); prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX; prompt.MaxActivationDistance=9; prompt.RequiresLineOfSight=true; prompt.HoldDuration=hold or 0; prompt.Parent=part_
 local held={}
 if hold then
  table.insert(C3.connections,prompt.PromptButtonHoldBegan:Connect(function(p) held[p]=os.clock() end))
  table.insert(C3.connections,prompt.PromptButtonHoldEnded:Connect(function(p)
   local started=held[p]
   task.delay(0.4,function() if held[p]==started then held[p]=nil end end)
  end))
 end
 table.insert(C3.connections,prompt.Triggered:Connect(function(p)
  local root=C3.Root(p); local started=held[p]
  local holdValid=not hold or started and os.clock()-started>=hold-0.25
  held[p]=nil -- every activation consumes its own hold; no replay window
  if C3.Valid(p) and root and not introActive and holdValid and (root.Position-part_.Position).Magnitude<=11 then C3.Protected(function() callback(p) end) end
 end))
 return prompt
end
-- BEGIN CHAPTER THREE WORLD
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
 local m=Instance.new("Model"); m.Name="NeuroMegafactory"; m.Parent=C3.map; C3.factory=m
 local o=C3.Pos(0,0,2200)
 -- Separate, distant urban skyline behind the factory establishes that the plant stands in a real city.
 local skyline=Instance.new("Model"); skyline.Name="NeuroFactoryCityBackdrop"; skyline.Parent=C3.map
 local asphalt=C3.Part(skyline,"FactoryDistrictRoad",Vector3.new(980,1,150),C3.Pos(0,-0.7,2200),C(37,44,55),Enum.Material.Asphalt); asphalt.CanCollide=false
 for block=-5,5 do
  local x=block*112
  if math.abs(x)>190 then
   local height=52+((block*block+block*13)%7)*13
   for _,z in ipairs({1920,2495}) do
    local building=C3.Part(skyline,"DistantCityTower",Vector3.new(76,height,44),C3.Pos(x,height/2,z),C(39+math.abs(block)%3*7,52,70),Enum.Material.Concrete)
    building.CanCollide=false
    for floor=1,math.floor(height/12) do
     local window=C3.Part(skyline,"DistantLitWindow",Vector3.new(62,1.6,0.18),C3.Pos(x,floor*12,z-22),floor%3==0 and C(218,176,111) or C(87,133,163),Enum.Material.Glass)
     window.CanCollide=false; window.CanTouch=false; window.CanQuery=false
    end
    local crown=C3.Part(skyline,"DistantRoofBeacon",Vector3.new(1.4,2.4,1.4),C3.Pos(x,height+1.2,z),C(224,66,72),Enum.Material.Neon)
    crown.CanCollide=false; light(crown,C(244,75,72),18,0.35)
   end
  end
 end
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
 -- Keep authored cutscene paths clear: the low sofa and coffee table are visible props, not blockers.
 for _,part in ipairs(h:GetDescendants()) do
  if part.Name=="SofaSeat" or part.Name=="SofaBack" or part.Name=="SofaArm" or part.Name=="CoffeeTable" then part.CanCollide=false end
 end
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
 local function buildSedan(x,z,paint,heading)
  local model=Instance.new("Model"); model.Name="CitySedan"; model.Parent=C3.backdrop
  local basis=CFrame.new(C3.Pos(x,0,z))*CFrame.Angles(0,math.rad(heading or 0),0)
  local function part(name,size,offset,color,material,rotation)
   local p=C3.Part(model,name,size,C3.Pos(x,0,z)+Vector3.zero,color,material)
   p.CFrame=basis*CFrame.new(offset)*(rotation or CFrame.new())
   p.CanTouch=false; return p
  end
  part("SedanLowerBody",Vector3.new(11.8,1.45,5.3),Vector3.new(0,1.35,0),paint,Enum.Material.Metal)
  part("SedanHood",Vector3.new(3.9,0.5,5.15),Vector3.new(-3.7,2.05,0),paint,Enum.Material.Metal)
  part("SedanTrunk",Vector3.new(2.7,0.55,5.1),Vector3.new(4.25,1.95,0),paint,Enum.Material.Metal)
  part("SedanCabin",Vector3.new(5.4,1.65,4.25),Vector3.new(-0.25,2.63,0),paint,Enum.Material.Metal)
  part("FrontWindshield",Vector3.new(0.16,1.35,4.05),Vector3.new(-2.8,2.65,0),C(63,104,123),Enum.Material.Glass,CFrame.Angles(0,0,math.rad(-13))).Transparency=0.16
  part("RearWindshield",Vector3.new(0.16,1.2,4.0),Vector3.new(2.15,2.65,0),C(59,96,113),Enum.Material.Glass,CFrame.Angles(0,0,math.rad(13))).Transparency=0.18
  for _,side in ipairs({-1,1}) do
   part("SedanSideGlass",Vector3.new(3.7,1.1,0.1),Vector3.new(-0.3,2.68,side*2.15),C(66,110,129),Enum.Material.Glass).Transparency=0.2
   part("SedanDoorHandle",Vector3.new(0.55,0.1,0.08),Vector3.new(0.75,1.85,side*2.68),C(174,179,178),Enum.Material.Metal)
   for _,wheelX in ipairs({-3.7,3.65}) do
    local wheel=part("SedanTire",Vector3.new(0.72,1.48,1.48),Vector3.new(wheelX,0.78,side*2.45),C(27,31,36),Enum.Material.Rubber,CFrame.Angles(math.pi/2,0,0)); wheel.Shape=Enum.PartType.Cylinder
    local hub=part("SedanWheelHub",Vector3.new(0.22,0.8,0.8),Vector3.new(wheelX,0.78,side*2.47),C(149,159,164),Enum.Material.Metal,CFrame.Angles(math.pi/2,0,0)); hub.Shape=Enum.PartType.Cylinder
   end
   local headlamp=part("SedanHeadlamp",Vector3.new(0.2,0.5,0.75),Vector3.new(-5.92,1.65,side*1.65),C(250,224,167),Enum.Material.Neon)
   light(headlamp,C(255,226,177),10,0.4)
   part("SedanTailLamp",Vector3.new(0.2,0.58,0.72),Vector3.new(5.92,1.62,side*1.65),C(197,54,56),Enum.Material.Neon)
  end
  part("SedanFrontBumper",Vector3.new(0.35,0.35,5.6),Vector3.new(-6.05,0.85,0),C(113,122,127),Enum.Material.Metal)
  part("SedanRearBumper",Vector3.new(0.35,0.35,5.6),Vector3.new(6.05,0.85,0),C(113,122,127),Enum.Material.Metal)
  return model
 end

 -- Continuous segmented road and kerbs; every physical part stays below 256 studs.
 for segment=0,4 do
  local center=-14+segment*202
  streetPart("MainStreetAsphalt",Vector3.new(202.5,1,112),center,-0.55,0,C(43,48,57),Enum.Material.Asphalt)
  for _,side in ipairs({-1,1}) do
   streetPart("RaisedCurb",Vector3.new(202.5,0.8,2),center,0,side*56,C(157,158,154),Enum.Material.Concrete)
   streetPart("ContinuousSidewalk",Vector3.new(202.5,0.5,12),center,0.05,side*62,C(111,116,121),Enum.Material.Concrete)
   streetPart("StreetEdgeKerb",Vector3.new(202.5,3,1),center,1.5,side*69,C(55,63,76),Enum.Material.Concrete)
  end
 end
 for _,side in ipairs({-1,1}) do
  for n=0,31 do
   local x=-100+n*32
   streetPart("LaneDash",Vector3.new(16,0.04,0.35),x,0.02,0,C(220,195,126),Enum.Material.SmoothPlastic)
   local pole=streetPart("StreetLampPole",Vector3.new(0.45,11,0.45),x,6.5,side*57,C(48,57,70),Enum.Material.Metal)
   local arm=streetPart("StreetLampArm",Vector3.new(4,0.3,0.3),x+side*1.5,12.7,side*57,C(48,57,70),Enum.Material.Metal)
   local head=streetPart("LEDStreetLampHead",Vector3.new(3.6,0.35,1.15),x+side*3.5,12.35,side*56,C(72,83,98),Enum.Material.Metal)
   head.CFrame*=CFrame.Angles(0,math.rad(side*8),0)
   local lens=streetPart("LEDStreetLampLens",Vector3.new(2.8,0.08,0.8),x+side*3.5,12.12,side*56,C(255,228,174),Enum.Material.Neon); lens.CanCollide=false
   C3.Lamp(C3.backdrop,C3.Pos(x+side*3.5,11.98,side*56),48,3.1,"WarmStreetLamp")
  end
 end

 -- Close-packed street fronts. Wide connected façades replace isolated slabs and gaps.
 for block=1,19 do
  local x=-361+(block-1)*89
  local height=86+(block*29)%54
  for _,side in ipairs({-1,1}) do
   local z=side*98
   local facadeColor=block%3==0 and C(59,76,91) or block%3==1 and C(79,75,72) or C(68,81,91)
   streetPart("BlockFacade",Vector3.new(97,height,28),x,height/2,z,facadeColor,Enum.Material.Concrete)
   streetPart("RoofCornice",Vector3.new(99,1.2,29),x,height+0.4,z,C(39,48,61),Enum.Material.Metal)
   streetPart("StorefrontBase",Vector3.new(82,9,0.3),x,4.7,z-side*14.2,C(33,48,59),Enum.Material.Glass)
   for floor=1,math.floor((height-14)/15) do
    streetPart("LitWindowBand",Vector3.new(78,4.2,0.18),x,11+floor*14,z-side*14.25,block%4==0 and C(206,173,111) or C(100,150,168),Enum.Material.Glass)
   end
  end
 end

 -- Two orderly rear rows and a continuous urban ground plane close the horizon without prop clutter.
 local groundX={{-410,90},{90,590},{590,1090},{1090,1290}}
 local groundZ={{-625,-125},{-125,375},{375,625}}
 for _,xb in ipairs(groundX) do for _,zb in ipairs(groundZ) do
  local outerGround=C3.Part(C3.backdrop,"OuterCityGround",Vector3.new(xb[2]-xb[1],1,zb[2]-zb[1]),C3.Pos((xb[1]+xb[2])*0.5,-0.55,(zb[1]+zb[2])*0.5),C(47,55,62),Enum.Material.Concrete)
  outerGround.CanCollide=true; outerGround.CanTouch=false
 end end
 -- Quiet, tall perimeter barriers sit behind the skyline so there is no reachable map edge or fall into void.
 for _,xEdge in ipairs({-409,1289}) do for _,zb in ipairs(groundZ) do
  local wall=C3.Part(C3.backdrop,"CitySafetyPerimeter",Vector3.new(2,360,zb[2]-zb[1]),C3.Pos(xEdge,179.5,(zb[1]+zb[2])*0.5),C(37,48,64),Enum.Material.Concrete)
  wall.Transparency=1; wall.CanCollide=true; wall.CanTouch=false; wall.CanQuery=false
 end end
 for _,zEdge in ipairs({-624,624}) do for _,xb in ipairs(groundX) do
  local endWall=C3.Part(C3.backdrop,"CitySafetyPerimeter",Vector3.new(xb[2]-xb[1],360,2),C3.Pos((xb[1]+xb[2])*0.5,179.5,zEdge),C(37,48,64),Enum.Material.Concrete)
  endWall.Transparency=1; endWall.CanCollide=true; endWall.CanTouch=false; endWall.CanQuery=false
 end end
 for row=1,2 do
  local sideDepth=row==1 and 164 or 274
  local stride=row==1 and 112 or 132
  local width=row==1 and 116 or 136
  local firstX=row==1 and -90 or -120
  local index=0
  for x=firstX,970,stride do
   index+=1
   local h= row==1 and (88+(index*23)%62) or (140+(index*37)%100)
   for _,side in ipairs({-1,1}) do
    local z=side*sideDepth
    local shell=C3.Part(C3.backdrop,row==1 and "MidgroundBuilding" or "FarNeighborhoodBuilding",Vector3.new(width,h,row==1 and 34 or 46),C3.Pos(x,h/2,z),row==1 and C(51+index%3*5,63,78) or C(39+index%3*5,50,67),Enum.Material.Concrete)
    shell.CanCollide=false
    for floor=1,math.floor(h/15) do
     local band=C3.Part(C3.backdrop,"BackgroundWindowBand",Vector3.new(width-12,2.1,0.16),C3.Pos(x,floor*15,z-side*(row==1 and 17.1 or 23.1)),floor%4==0 and C(203,168,107) or C(83,128,151),Enum.Material.Glass)
     band.CanCollide=false; band.CanTouch=false; band.CanQuery=false
    end
   end
  end
 end
 -- A restrained line of trees sits in the setback between the foreground blocks and rear streets.
 for _,side in ipairs({-1,1}) do
  for n=0,19 do
   local x=-92+n*52; local z=side*136
   local trunk=C3.Part(C3.backdrop,"BoulevardTreeTrunk",Vector3.new(1.1,7,1.1),C3.Pos(x,3.5,z),C(92,72,56),Enum.Material.Wood); trunk.CanCollide=false
   local crown=C3.Part(C3.backdrop,"BoulevardTreeCanopy",Vector3.new(10,12,10),C3.Pos(x,14,z),n%3==0 and C(49,90,75) or C(58,105,83),Enum.Material.Grass)
   crown.Shape=Enum.PartType.Ball; crown.CanCollide=false; crown.CanTouch=false; crown.CanQuery=false
  end
 end
 -- Wrap the distant skyline around both street ends and both sides: looking back still reads as a city.
 for _,side in ipairs({-1,1}) do
  for index=0,10 do
   local x=-255+index*130
   local height=190+(index*43)%120
   local skyline=C3.Part(C3.backdrop,"HorizonHighrise",Vector3.new(150,height,64),C3.Pos(x,height/2,side*520),C(37+index%4*5,49+index%3*5,69+index%2*6),Enum.Material.Concrete)
   skyline.CanCollide=false; skyline.CanTouch=false; skyline.CanQuery=false
   for floor=1,math.floor(height/18) do
    local band=C3.Part(C3.backdrop,"HorizonWindowBand",Vector3.new(132,1.7,0.16),C3.Pos(x,floor*18,side*487),floor%4==0 and C(220,178,111) or C(90,135,159),Enum.Material.Glass)
    band.CanCollide=false; band.CanTouch=false; band.CanQuery=false
   end
  end
  for index=0,9 do
   local z=-500+index*112
   local height=200+(index*47)%125
   local skyline=C3.Part(C3.backdrop,"HorizonEndcap",Vector3.new(64,height,122),C3.Pos(side==-1 and -340 or 1220,height/2,z),C(40+index%3*5,50,68+index%2*5),Enum.Material.Concrete)
   skyline.CanCollide=false; skyline.CanTouch=false; skyline.CanQuery=false
  end
 end

 local districtX={80,255,430,605,780}
 local districtColor={C(83,153,130),C(205,157,86),C(101,154,190),C(115,111,184),C(196,93,88)}
 for i,x in ipairs(districtX) do
  local color=districtColor[i]
  -- Combat cover is waist high and offset so every encounter has at least two paths.
  streetPart("StreetCover",Vector3.new(14,3,5),x-24,1.5,-20,C(63,77,91),Enum.Material.Metal)
  streetPart("StreetCover",Vector3.new(14,3,5),x+24,1.5,20,C(63,77,91),Enum.Material.Metal)
  for _,side in ipairs({-1,1}) do
   streetPart("RouteBarrier",Vector3.new(34,5,2),x+side*42,2.5,side*31,C(184,139,72),Enum.Material.Metal)
  end
  buildSedan(x-8,i%2==0 and 25 or -27,({C(55,88,117),C(102,83,68),C(73,103,91),C(114,64,65),C(79,87,103)})[i],i%2==0 and 4 or -7)
  local z={index=i,center=C3.Pos(x,4,0),start=C3.Pos(x-62,4,0),exit=C3.Pos(x+67,4,0),wave=0,rounds=i==3 and 3 or 2,cleared=false,objective=false,covers={}}
  C3.zones[i]=z -- Register the five street stages before the tower's stages 6-10.
  z.gate=streetPart("DistrictGate",Vector3.new(1.5,16,174),x+78,8,0,C(57,78,99),Enum.Material.Metal)
  z.gateClosed=z.gate.CFrame
  z.covers={C3.Pos(x-17,4,-20),C3.Pos(x+31,4,20)}
  z.panel=streetPart("SignalRelay",Vector3.new(2.5,3.4,2),x+37,1.8,17,color,Enum.Material.Metal)
  local screen=streetPart("RelayScreen",Vector3.new(0.2,1.6,1.8),x+35.7,2.7,17,C(68,217,175),Enum.Material.Neon); screen.CanCollide=false
  C3.Prompt(z.panel,"Отключить ретранслятор",function(p) C3.CompleteObjective(p,z) end)
  local doorZ=43
  z.spawnDoor=streetPart("DeploymentDoor",Vector3.new(21.2,12,1),x,6,doorZ,C(51,65,84),Enum.Material.Metal)
  z.spawnClosed=z.spawnDoor.CFrame; z.spawnPos=C3.Pos(x,4,doorZ+6)
  streetPart("DeploymentBayFloor",Vector3.new(22,0.8,21),x,-0.2,doorZ+10,C(52,61,73),Enum.Material.Concrete)
  streetPart("DeploymentBayRoof",Vector3.new(22,0.8,21),x,14,doorZ+10,C(39,47,60),Enum.Material.Metal)
  streetPart("DeploymentBayBack",Vector3.new(22,14,0.8),x,7,doorZ+20,C(49,59,73),Enum.Material.Concrete)
  streetPart("DeploymentBayLeft",Vector3.new(0.8,14,21),x-11,7,doorZ+10,C(49,59,73),Enum.Material.Concrete)
  streetPart("DeploymentBayRight",Vector3.new(0.8,14,21),x+11,7,doorZ+10,C(49,59,73),Enum.Material.Concrete)
  local med=streetPart("MedicalKit",Vector3.new(2,1,2),x-30,0.5,-27,C(170,70,70),Enum.Material.Metal); local used={}
  C3.Prompt(med,"Аптечка",function(p) if not used[p] then local _,hum=C3.Root(p); if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+65); used[p]=true; med.Color=C(82,91,96) end end end)
 end

 -- A restrained glass office frontage anchors the corporate district; the other blocks stay clean and readable.
 for _,side in ipairs({-1,1}) do
  for _,x in ipairs({570,640}) do
   local t=streetPart("NTyanOffice",Vector3.new(34,60,26),x,30,side*119,C(68,100,120),Enum.Material.Glass); t.Transparency=0.12; t.CanCollide=false
   streetPart("OfficeRoofBeacon",Vector3.new(1.4,2,1.4),x,61,side*119,C(208,60,70),Enum.Material.Neon)
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
  -- A narrow, walled stair corridor is the only shaft opening; every surrounding combat deck is solid.
  if stage<10 then
   slab(82,31,0,-25.5); slab(82,31,0,25.5)
   towerPart("TowerStairLanding",Vector3.new(17,0.8,20.8),927.5,y,0,C(103,121,137),Enum.Material.Metal)
   towerPart("TowerStairLanding",Vector3.new(17,0.8,20.8),992.5,y,0,C(103,121,137),Enum.Material.Metal)
   for _,side in ipairs({-1,1}) do
    for _,segment in ipairs({{x=926.5,length=15},{x=960,length=44},{x=993.5,length=15}}) do
     local partition=towerPart("StairwellPartition",Vector3.new(segment.length,24,0.7),segment.x,y+12,side*10,C(91,121,139),Enum.Material.Glass)
     partition.Transparency=0.38
    end
   end
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
   z.gate=towerPart("TowerStairGate",Vector3.new(1.5,16,20.2),984,y+27,0,C(49,66,83),Enum.Material.Metal)
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
    towerPart("TowerStair",Vector3.new(2.65,0.65,18.5),x,y+rise,0,C(138,155,170),Enum.Material.Metal)
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
   C3.Lamp(C3.map,C3.Pos(960+side*23,y+18,0),48,3.0,"TowerDeckLamp")
  end
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
 for stage=1,10 do assert(C3.zones[stage],"Chapter III build missed zone "..stage) end
end

-- END CHAPTER THREE WORLD
function C3.MoveParty(position,look)
 for i,p in ipairs(C3.party) do
  local r=C3.Root(p)
  if r then
   local slotPosition=position+Vector3.new(0,0,(i-1)*4)
   local flatLook=Vector3.new(look.X,slotPosition.Y,look.Z)
   if (flatLook-slotPosition).Magnitude<0.001 then flatLook=slotPosition+Vector3.new(0,0,-1) end
   p.Character:PivotTo(CFrame.lookAt(slotPosition,flatLook,Vector3.yAxis)); r.AssemblyLinearVelocity=Vector3.zero
  end
 end
end
function C3.Intro()
 C3.Scene(true); FadeRE:FireAllClients(true,"ГЛАВА III • БАШНЯ НЕЙРО-СИНГУЛЯРНОСТИ"); task.wait(1)
 -- Establish the night-city setting before cutting into the villains' lab.
 cameraPlan(C3.Pos(620,72,-230),C3.Pos(620,64,-220),C3.Pos(960,155,0),2.8,74,66)
 CutsceneRE:FireAllClients("reveal"); task.wait(1.1)
 local factory,neuro,assistant,screen=C3.BuildVillain()
 focusStreaming(neuro.Head.Position); prepareView(neuro.Head.Position)
 -- Begin at eye level with Neuro already speaking; the first frame also reads the clone floor and control dais.
 cameraPlan(neuro.Head.Position+Vector3.new(-27,9,-34),neuro.Head.Position+Vector3.new(-20,7,-28),neuro.Head.Position+Vector3.new(12,3,27),1.25,70,62)
 CutsceneRE:FireAllClients("reveal")
 C3.Say(ANDROID_NAME,"Они уничтожили один из наших незначительных заводов... Это даже потерей тяжело назвать. Скоро весь мир покроется нашими рядами, и всё будет по нашим правилам. Идеальное общество, всё будет замечательно. Но хватит разговоров — пора действовать",12)
 cameraPlan(neuro.Head.Position+Vector3.new(-8,2,-15),neuro.Head.Position+Vector3.new(-5,1,-11),neuro.Head.Position,1.1,58,52)
 local neuroPivot=neuro:GetPivot()
 local assistantFocus=Vector3.new(assistant.Head.Position.X,neuroPivot.Position.Y,assistant.Head.Position.Z)
 moveModel(neuro,CFrame.lookAt(neuroPivot.Position,assistantFocus,Vector3.yAxis),0.8)
 C3.Say(ANDROID_NAME,"Эй, Тян C-3B1! Как успехи с нашим проектом Вышки Нейро-Сингулярной Связи?",5)
 moveModel(assistant,assistant:GetPivot()+Vector3.new(-6,0,0),1.5,true)
 cameraPlan(assistant.Head.Position+Vector3.new(3,1,-9),assistant.Head.Position+Vector3.new(2,1,-8),assistant.Head.Position,1,54,52)
 C3.Say("Тян C-3B1","Всё успешно, мы готовы запустить её в центре одного из крупных городов. Хммм... что насчёт города, где сосредоточено больше всего филиалов и компаний НТЯН?",8)
 cameraPlan(neuro.Head.Position+Vector3.new(-5,1,-10),neuro.Head.Position+Vector3.new(-4,1,-8),neuro.Head.Position,1,55,50)
 C3.Say(ANDROID_NAME,"Идеальный выбор. Мы подчиним тысячи людей за секунды и ускорим наше влияние в тысячи раз. Нам больше не придётся отлавливать людей или клонировать их вручную. Начинаем!",9)
 FadeRE:FireAllClients(true,""); task.wait(0.8)
 C3.MoveParty(C3.Pos(-193,4,3),C3.Pos(-187,7,22)); focusStreaming(C3.Pos(-187,5,0)); prepareView(C3.Pos(-187,5,0))
 local chosenHero=C3.party[1]:GetAttribute("Hero")
 local companionHero=chosenHero=="Artem" and "Demid" or "Artem"
 local companionName=companionHero=="Demid" and "Демид" or "Артём"
 local companionSource=companionHero=="Demid" and "ZamestitelDiomchica" or "eurtyoeyrntiu"
 C3.buddy=secretActor(C3.map,companionSource,companionName,CFrame.lookAt(C3.Pos(-201,0.5,-1),C3.Pos(-187,7,22)))
 C3.buddy:SetAttribute("Hero",companionHero)
 if C3.coop then C3.buddy:Destroy(); C3.buddy=nil end
 if C3.buddy then
  for _,piece in ipairs(C3.buddy:GetDescendants()) do
   if piece:IsA("BasePart") then
    piece.Anchored=true; piece.CanCollide=false; piece.CanTouch=false; piece.CanQuery=false
    if piece.Name=="HumanoidRootPart" then piece.Transparency=1 elseif piece.Transparency>=0.95 then piece.Transparency=0 end
   end
  end
  local buddyHum=C3.buddy:FindFirstChildOfClass("Humanoid")
  if buddyHum then buddyHum.DisplayName=companionName; buddyHum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer; buddyHum.NameDisplayDistance=50 end
 end
 cameraPlan(C3.Pos(-196,9,-15),C3.Pos(-194,8,-12),C3.Pos(-187,6,10),1.2,60,56)
 CutsceneRE:FireAllClients("reveal")
 C3.Say("Демид","Мы им завод снесли, а крайними всё равно оказались мы. Я до сих пор не понимаю, кто здесь с кем воюет.",5)
 C3.Say("Артём","И почему НТЯН ищет нас, а не тех, кто людей переделывает? Тут явно не вся картина.",4)
 C3RE:FireAllClients("signal"); ShakeRE:FireAllClients(2); task.wait(2)
 -- Third-person view from inside the living room: both heroes cross toward
 -- the glass; the skyline and tower remain visible through the opening behind them.
 -- Camera stays west of the actors, and its sightline crosses
 -- the center of the actual window opening before reaching the skyline.
 cameraPlan(C3.Pos(-204,10,-18),C3.Pos(-201,9,-15),C3.Pos(-60,0,0),1.4,64,58)
 local buddyWindowTarget=CFrame.lookAt(C3.Pos(-153,4,5),C3.Pos(960,100,0),Vector3.yAxis)
 local windowDuration=0
 for i,p in ipairs(C3.party) do
  local root=C3.Root(p)
  if root then
   local zOffset=C3.coop and (i==1 and -5 or 5) or -5
   local windowPosition=C3.Pos(-153,4,zOffset)
   local windowView=CFrame.lookAt(windowPosition,C3.Pos(960,100,0),Vector3.yAxis)
   local character=p.Character; local windowTarget=windowView
   local entry=C3.Pos(-174,4,zOffset)
   local distance=((entry-root.Position)*Vector3.new(1,0,1)).Magnitude+((windowPosition-entry)*Vector3.new(1,0,1)).Magnitude
   windowDuration=math.max(windowDuration,distance/12)
   task.spawn(function()
    tweenCharTo(character,CFrame.lookAt(entry,windowPosition,Vector3.yAxis),1.5,false,12,false,false)
    if character.Parent then tweenCharTo(character,windowTarget,1.5,false,12,false,false) end
   end)
  end
 end
 if C3.buddy then
  task.spawn(function() moveModel(C3.buddy,buddyWindowTarget,4,true) end)
  windowDuration=math.max(windowDuration,4)
 end
 task.wait(windowDuration+0.12)
 if C3.buddy then task.wait(0.45) end
 -- First stage over the heroes' shoulders: we see both backs, the open glass,
 -- city street and tower in one readable composition.
 cameraPlan(C3.Pos(-178,9,0),C3.Pos(-175,8,0),C3.Pos(-50,3,0),1.1,68,60)
 C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Артём" or "Демид","Эммм, что это было?",3)
 local windowGuide=C3.coop and "Демид" or (C3.party[1]:GetAttribute("Hero")=="Artem" and "Демид" or "Артём")
 C3.Say(windowGuide,"Чекни в окно.",3)
 -- Then a true eye-level shot from each hero, aimed at the mast's center rather
 -- than a distant camera position; the transparent reticle will not darken it.
 focusStreaming(C3.Pos(960,150,0)); prepareView(C3.Pos(960,150,0))
 C3RE:FireAllClients("binocular",true)
 CutsceneRE:FireAllClients("pov",C3.Pos(960,150,0),54); task.wait(0.6)
 C3.Say("Артём","Сигнал идёт оттуда. Смотри на охрану наверху.",3)
 C3.Say("Демид","Значит, эту штуку нужно выключить. Сейчас, пока она весь город не накрыла.",4)
 C3RE:FireAllClients("binocular",false)
 -- Return behind both heroes before the upstairs rush to Kirill.
 cameraPlan(C3.Pos(-178,9,0),C3.Pos(-175,8,0),C3.Pos(-50,3,0),0.9,60,58)
 C3.Say("Артём","Стой. Кирилл же наверху, в комнате!",3)
 focusStreaming(C3.Pos(-184,18,-14)); prepareView(C3.Pos(-184,18,-14))
 -- Keep the camera third-person and behind the heroes while they climb the
 -- real stair wing, cross the landing, and queue at Kirill's bedroom doorway.
 CutsceneRE:FireAllClients("followRig",C3.party[1].Character,Vector3.new(0,8,13),Vector3.new(0,2,0))
 local mainRoute={
  C3.Pos(-153,4,-5),C3.Pos(-170,4,-5),C3.Pos(-186,4,-5),C3.Pos(-204,4,-5),
  C3.Pos(-204,4,-20),C3.Pos(-216,4,-20),C3.Pos(-222,4,-20),
 }
 local buddyRoute={
  C3.Pos(-153,4,5),C3.Pos(-165,4,9),C3.Pos(-171,4,5),C3.Pos(-186,4,9),
  C3.Pos(-204,4,9),C3.Pos(-204,4,-20),C3.Pos(-219,4,-20),
 }
 -- Follow every real tread in sequence. A single diagonal tween made the
 -- companion slide through the stairwell instead of looking like he climbed it.
 for stair=1,15 do
  local z=-20+stair*2.5; local y=stair+3
  table.insert(mainRoute,C3.Pos(-222,y,z))
  table.insert(buddyRoute,C3.Pos(-219,y,z))
 end
 for _,point in ipairs({C3.Pos(-212,18,18),C3.Pos(-205,18,0),C3.Pos(-160,18,2),C3.Pos(-160,18,0)}) do table.insert(mainRoute,point) end
 for _,point in ipairs({C3.Pos(-209,18,21),C3.Pos(-205,18,4),C3.Pos(-160,18,4),C3.Pos(-160,18,0)}) do table.insert(buddyRoute,point) end
 local function directed(position,nextPosition)
  local target=nextPosition or C3.kirill.Head.Position
  return CFrame.lookAt(position,Vector3.new(target.X,position.Y,target.Z),Vector3.yAxis)
 end
 local function walkRoutes(routeA,routeB)
  for waypoint=1,#routeA do
   local longest=0
   local onStairs=waypoint>=8 and waypoint<=22
   local pace=onStairs and 9 or 12
   for index,p in ipairs(C3.party) do
    local route=index==1 and routeA or routeB
    local root=C3.Root(p)
    if root then
     local target=directed(route[waypoint],route[waypoint+1])
     local duration=math.max(((target.Position-root.Position)*Vector3.new(1,0,1)).Magnitude/pace,0.15)
     local character=p.Character; local moveTarget=target; local movePace=pace; local skipSteps=onStairs
     longest=math.max(longest,duration)
     task.spawn(function() tweenCharTo(character,moveTarget,1.2,true,movePace,skipSteps,false) end)
    end
   end
   if C3.buddy and C3.buddy.Parent then
    local target=directed(routeB[waypoint],routeB[waypoint+1])
    local duration=math.max(((target.Position-C3.buddy:GetPivot().Position)*Vector3.new(1,0,1)).Magnitude/pace,0.15)
    local buddy=C3.buddy; local moveTarget=target; local moveDuration=duration
    longest=math.max(longest,duration)
    task.spawn(function() if buddy and buddy.Parent then moveModel(buddy,moveTarget,moveDuration,true) end end)
   end
   task.wait(longest+0.08)
  end
 end
 walkRoutes(mainRoute,buddyRoute)
 cameraPlan(C3.Pos(-193,12,20),C3.Pos(-190,11,18),C3.Pos(-160,18,0),1.1,62,56)
 TweenService:Create(C3.kirillDoor,TweenInfo.new(0.75,Enum.EasingStyle.Sine),{CFrame=C3.doorOpen}):Play(); task.wait(0.85)
 -- The doorway is now visibly open. Both heroes cross the threshold and take
 -- positions inside the bedroom, close enough to protect Kirill.
 cameraPlan(C3.Pos(-204,24,-22),C3.Pos(-200,23,-21),C3.Pos(-183,18,-14),1.2,64,58)
 walkRoutes(
  {C3.Pos(-160,18,-10),C3.Pos(-190,18,-10),C3.Pos(-193,18,-12)},
  {C3.Pos(-160,18,-10),C3.Pos(-178,18,-10),C3.Pos(-178,18,-13)}
 )
 focusStreaming(C3.Pos(-184,18,-14)); prepareView(C3.Pos(-184,18,-14))
 local kirillRevealFocus=C3.kirill.Head.Position+Vector3.new(2,0,2)
 cameraPlan(C3.Pos(-205,22,-23),C3.Pos(-201,21,-20),kirillRevealFocus,1.8,62,54)
 CutsceneRE:FireAllClients("reveal")
 C3.Say("Кирилл","Тянки... тянки...",3)
 for motor,cf in pairs(C3.kirillPose) do if motor.Parent then motor.C0=cf end end
 for _=1,4 do for _,motor in ipairs(C3.kirill:GetDescendants()) do if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then motor.Part1.CFrame=motor.Part0.CFrame*motor.C0*motor.C1:Inverse() end end end
 local kirillNeck=C3.kirill:FindFirstChild("Neck",true)
 if kirillNeck and C3.kirillPose[kirillNeck] then
  TweenService:Create(kirillNeck,TweenInfo.new(0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{C0=C3.kirillPose[kirillNeck]*CFrame.Angles(math.rad(-10),0,0)}):Play()
 end
 moveModel(C3.kirill,C3.kirill:GetPivot()+Vector3.new(0,0.45,0),1.2)
 local hypnoticLights={}
 for _,side in ipairs({-1,1}) do
  local eye=C3.Part(C3.kirill,"HypnotizedEye",Vector3.new(0.2,0.13,0.08),C3.kirill.Head.Position,C(235,35,35),Enum.Material.Neon)
  eye.CanCollide=false; eye.CanTouch=false; eye.CanQuery=false; eye.Anchored=false
  eye.CFrame=C3.kirill.Head.CFrame*CFrame.new(side*0.4,0,-0.55)
  local weld=Instance.new("WeldConstraint"); weld.Part0=C3.kirill.Head; weld.Part1=eye; weld.Parent=eye
  local glow=light(eye,C(255,35,48),5,0.8); table.insert(hypnoticLights,glow)
 end
 cameraPlan(C3.kirill.Head.Position+Vector3.new(-1,0.4,-2),C3.kirill.Head.Position+Vector3.new(-0.5,0.2,-1.4),C3.kirill.Head.Position,0.8,42,38)
 for _,glow in ipairs(hypnoticLights) do TweenService:Create(glow,TweenInfo.new(0.55,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,3,true),{Brightness=2.2,Range=8}):Play() end
 C3.Say(ANDROID_NAME,"Устранить Артёма и Демида.",3)
 local kirillPivot=C3.kirill:GetPivot()
 local heroRoot=C3.Root(C3.party[1])
 local threatPosition=heroRoot and heroRoot.Position or C3.Pos(-190,18,-12)
 cameraPlan(C3.Pos(-178,22,-21),C3.Pos(-181,21,-18),C3.kirill.Head.Position,1.1,58,50)
 moveModel(C3.kirill,CFrame.lookAt(kirillPivot.Position,Vector3.new(threatPosition.X,kirillPivot.Position.Y,threatPosition.Z),Vector3.yAxis),1.05)
 cameraPlan(C3.Pos(-194,20,-6),C3.Pos(-191,19,-8),C3.Pos(-185,18,-12),1.2,58,52)
 moveModel(C3.kirill,C3.kirill:GetPivot()+Vector3.new(0,0,4),2.5,true)
 C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Артём" or "Демид","Ладно, только без летального исхода, мы не будем его бить, ок? Просто уходим!",5)
 TweenService:Create(C3.kirillDoor,TweenInfo.new(0.65),{CFrame=C3.doorClosed}):Play(); task.wait(0.7)
 if C3.coop then
  C3.Say("Демид","Дверь держит. Но надолго его так не оставишь.",3)
  C3.Say("Артём","Камера работает. Оба идём к башне. Чем быстрее отключим сигнал, тем быстрее вернёмся.",4)
 else
  C3.Say(C3.party[1]:GetAttribute("Hero")=="Artem" and "Демид" or "Артём","Ахх, чёт у меня нет никакого желания прямо сейчас выходить в это пекло. Я лучше останусь присмотреть за Кириллом, чтобы тут всё окончательно не пошло наперекосяк!",8)
  if C3.buddy and C3.buddy.Parent then
   C3.buddy:SetAttribute("StayingWithKirill",true)
   moveModel(C3.buddy,CFrame.lookAt(C3.Pos(-178,18,-13),C3.kirill.Head.Position,Vector3.yAxis),0.8,true)
  end
 end
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 C3.MoveParty(C3.Pos(-35,4,0),C3.Pos(100,4,0)); focusStreaming(C3.Pos(50,5,0)); prepareView(C3.Pos(50,5,0))
 C3.Scene(false); CutsceneRE:FireAllClients("reveal"); MusicRE:FireAllClients("intro")
 factory:Destroy(); C3.factory=nil; C3.Activate(1)
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
 local cfg=table.clone(Types.Pistol)
 local citizenStyles={
  {male=false,skin=C(238,198,172),hair=C(92,54,48),shirt=C(169,103,88),skirt=C(52,62,83),legs=C(38,43,55),accent=C(219,184,128)},
  {male=true,skin=C(204,160,128),hair=C(58,43,38),shirt=C(72,112,139),skirt=C(42,53,66),legs=C(36,42,50),accent=C(196,151,101)},
  {male=false,skin=C(230,187,158),hair=C(60,72,96),shirt=C(105,139,121),skirt=C(67,53,77),legs=C(49,54,62),accent=C(218,197,159)},
  {male=true,skin=C(187,143,115),hair=C(111,80,54),shirt=C(160,133,91),skirt=C(55,57,63),legs=C(44,47,53),accent=C(191,180,151)},
  {male=false,skin=C(245,207,183),hair=C(151,107,70),shirt=C(143,106,151),skirt=C(70,53,86),legs=C(51,47,64),accent=C(224,190,153)},
  {male=true,skin=C(214,177,145),hair=C(40,43,47),shirt=C(131,85,80),skirt=C(53,48,48),legs=C(38,42,48),accent=C(201,175,143)},
 }
 local style=civilian and citizenStyles[(k-1)%#citizenStyles+1] or nil
 cfg.Male=style and style.male or false; cfg.Gun=not civilian
 cfg.Name=civilian and (style.male and "Захваченный житель" or "Захваченная жительница") or elite and "Элитная охрана" or "Патруль"
 cfg.Skin=style and style.skin or cfg.Skin
 cfg.Hair=style and style.hair or C(62,43,87); cfg.Shirt=style and style.shirt or elite and C(55,40,72) or C(45,62,85)
 cfg.Skirt=style and style.skirt or cfg.Skirt; cfg.Legs=style and style.legs or cfg.Legs; cfg.Accent=style and style.accent or cfg.Accent
 cfg.Eye=civilian and C(235,74,83) or cfg.Eye; cfg.HP=civilian and 92 or cfg.HP
 local m,h,r,j=buildRig(cfg,CFrame.new(pos)); m.Parent=C3.map
 if not civilian then c2Dress(m,false) end
 c2Mobilize(m,h,r); h.MaxHealth=civilian and 92 or (elite and 310 or 85)*(C3.coop and 1.4 or 1); h.Health=h.MaxHealth; h.WalkSpeed=civilian and 9 or elite and 11 or 13
 if civilian then
  C3.PrepareCapturedCivilian(m,h)
  local torso=m:FindFirstChild("Torso"); local head=m:FindFirstChild("Head")
  local function citizenDetail(base,name,size,offset,color,material)
   local part=Instance.new("Part"); part.Name=name; part.Size=size; part.Color=color; part.Material=material or Enum.Material.SmoothPlastic
   part.Anchored=false; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Massless=true; part.CFrame=base.CFrame*offset; part.Parent=m
   local weld=Instance.new("WeldConstraint"); weld.Part0=base; weld.Part1=part; weld.Parent=part
   return part
  end
  citizenDetail(torso,"EverydayJacketCollar",Vector3.new(1.35,0.24,0.16),CFrame.new(0,0.72,-0.54),style.accent)
  citizenDetail(torso,"EverydayJacketPlacket",Vector3.new(0.12,1.25,0.12),CFrame.new(0,0.05,-0.57),style.accent)
  citizenDetail(torso,"CitizenIDTag",Vector3.new(0.32,0.25,0.08),CFrame.new(0.58,0.35,-0.56),C(210,198,157),Enum.Material.Metal)
  if k%2==0 then citizenDetail(torso,"EverydayShoulderBag",Vector3.new(0.8,1.05,0.45),CFrame.new(-0.7,-0.2,0.52),C(59,73,82),Enum.Material.Fabric) end
  for _,side in ipairs({-1,1}) do
   local eye=citizenDetail(head,"HypnoticRedEye",Vector3.new(0.12,0.16,0.07),CFrame.new(side*0.4,0.04,-0.55),C(255,71,79),Enum.Material.Neon)
   light(eye,C(255,58,68),3,0.35)
  end
 end
 if elite then
  cfg.Armor=C(56,67,80)
  local function armor(name,size,offset,color,material)
   local part=Instance.new("Part"); part.Name=name; part.Size=size; part.Color=color or cfg.Armor; part.Material=material or Enum.Material.Metal
   part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Massless=true; part.Parent=m
   local weld=Instance.new("WeldConstraint"); weld.Part0=r; weld.Part1=part; weld.Parent=part
   part.CFrame=r.CFrame*offset
  end
  armor("NTyanBallisticPlate",Vector3.new(2.35,1.6,0.44),CFrame.new(0,0.1,-0.64),C(60,76,92))
  armor("NTyanArmoredHelmet",Vector3.new(1.7,0.55,1.35),CFrame.new(0,1.48,0),C(47,60,73))
  armor("NTyanRedVisor",Vector3.new(1.25,0.18,0.12),CFrame.new(0,1.55,-0.68),C(236,76,75),Enum.Material.Neon)
  for _,side in ipairs({-1,1}) do armor("NTyanShoulderGuard",Vector3.new(0.5,0.65,1.1),CFrame.new(side*1.15,0.35,0),C(71,86,99)) end
 end
 m:SetAttribute("Enemy",true)
 local e={stage=stage,hum=h,root=r,civilian=civilian,down=false,last=0,stun=0,joints=j,base={},pathAt=0,waypoints={},waypoint=1,tactic=k%3,cover=C3.zones[stage].covers[(k-1)%2+1]}
 for name,motor in pairs(j) do e.base[name]=motor.C0 end; C3.mobs[m]=e
 table.insert(C3.connections,h.Died:Connect(function()
  if e.down then return end
  e.down=true; h.WalkSpeed=0
  if civilian then for _,piece in ipairs(m:GetDescendants()) do if piece:IsA("BasePart") and piece.Name~="HumanoidRootPart" then piece.CanCollide=true end end end
  ragdoll(m,not civilian); Debris:AddItem(m,12)
 end))
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
     elseif not civilian and d<100 and os.clock()-e.last>(elite and 0.95 or 1.65) then
      e.last=os.clock(); local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={m,fxFolder}
      local from=m.Head.Position; local hit=workspace:Raycast(from,pr.Position-from,rp)
      if hit and hit.Instance:IsDescendantOf(p.Character) then tracer(from,hit.Position,C(240,170,110)); ph:TakeDamage(elite and 14 or 7) end
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
function C3.TowerReinforcement()
 C3.Scene(true)
 cameraPlan(C3.Pos(836,54,-104),C3.Pos(852,50,-92),C3.Pos(938,8,0),2.2,68,60)
 local operatorCfg=table.clone(Types.Pistol); operatorCfg.Name="Связистка НТЯН"; operatorCfg.Male=false
 operatorCfg.Shirt=C(58,74,86); operatorCfg.Skirt=C(42,51,66); operatorCfg.Hair=C(84,101,118)
 local operator=buildRig(operatorCfg,CFrame.lookAt(C3.Pos(876,0.5,-32),C3.Pos(920,0.5,0)))
 operator.Parent=C3.map; c2Dress(operator,false); anchorAll(operator)
 local phone=C3.Part(operator,"FieldRadio",Vector3.new(0.22,0.7,0.18),operator.Head.Position+Vector3.new(0.72,0.05,0),C(38,50,58),Enum.Material.Metal)
 phone.CanCollide=false; phone.CFrame*=CFrame.Angles(0,0,math.rad(-15))
 cameraPlan(C3.Pos(883,5,-41),C3.Pos(885,4,-38),operator.Head.Position,1.4,54,50)
 C3.Say("Связистка НТЯН","Главная, Артём и Демид уже у башни. Приближаются быстрее прогноза. Повторяю: они почти у периметра!",6)
 cameraPlan(C3.Pos(914,176,-190),C3.Pos(918,166,-178),C3.Pos(960,175,0),1.4,66,62)
 C3.Say(ANDROID_NAME,"Поднимайте захваченный отряд НТЯН. Два борта идут к башне. Не дайте им войти!",5)
 -- Two visibly constructed transports descend from above the shield perimeter.
 local helicopters={}
 local function buildHelicopter(startPosition)
  local model=Instance.new("Model"); model.Name="NTyanArmoredTransport"; model.Parent=C3.map
  local function piece(name,size,offset,color,material)
   local part=Instance.new("Part"); part.Name=name; part.Size=size; part.Color=color; part.Material=material or Enum.Material.Metal
   part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Parent=model
   part.CFrame=CFrame.new(startPosition+offset); return part
  end
  piece("ArmoredCabin",Vector3.new(12,5.2,8),Vector3.new(0,0,0),C(42,53,67))
  local canopy=piece("CockpitGlass",Vector3.new(7.8,3.7,0.3),Vector3.new(0,0.35,-4.15),C(65,155,173),Enum.Material.Glass); canopy.Transparency=0.28
  piece("TailBoom",Vector3.new(2.1,2.2,17),Vector3.new(0,0,12),C(49,61,73))
  piece("TailFin",Vector3.new(1,5.2,3.4),Vector3.new(0,3,19),C(58,70,84))
  piece("SkidLeft",Vector3.new(0.45,0.45,13),Vector3.new(-5,-3.7,0),C(100,110,117))
  piece("SkidRight",Vector3.new(0.45,0.45,13),Vector3.new(5,-3.7,0),C(100,110,117))
  piece("SkidSupportLeft",Vector3.new(0.4,2.2,0.4),Vector3.new(-4.3,-2.5,-2),C(100,110,117))
  piece("SkidSupportRight",Vector3.new(0.4,2.2,0.4),Vector3.new(4.3,-2.5,-2),C(100,110,117))
  local rotor=piece("MainRotorHub",Vector3.new(1.4,0.8,1.4),Vector3.new(0,3.2,0),C(160,172,178))
  for blade=0,3 do
   local angle=blade*math.pi/2
   local b=piece("MainRotorBlade",Vector3.new(1,0.18,19),Vector3.new(math.sin(angle)*9,3.55,math.cos(angle)*9),C(40,48,56))
   b.CFrame=CFrame.new(startPosition+Vector3.new(math.sin(angle)*9,3.55,math.cos(angle)*9))*CFrame.Angles(0,angle,0)
  end
  for side=-1,1,2 do
   local lamp=piece("LandingSearchLamp",Vector3.new(1,0.45,0.45),Vector3.new(side*3,-2.5,-4),C(246,225,178),Enum.Material.Neon)
   light(lamp,C(255,226,171),36,2.2)
   local stripe=piece("NTyanUnitMark",Vector3.new(0.25,3.2,5),Vector3.new(side*6.12,0,0),C(183,57,69),Enum.Material.Neon)
   stripe.Transparency=0.12
  end
  model.PrimaryPart=rotor
  return model
 end
 local left=buildHelicopter(C3.Pos(804,72,-47)); local right=buildHelicopter(C3.Pos(834,82,47))
 table.insert(helicopters,left); table.insert(helicopters,right)
 local function fly(model,target,duration)
  local start=model:GetPivot(); local began=os.clock()
  while os.clock()-began<duration and model.Parent do
   local alpha=math.clamp((os.clock()-began)/duration,0,1)
   local position=start.Position:Lerp(target,alpha)+Vector3.new(0,math.sin(alpha*math.pi)*9,0)
   model:PivotTo(CFrame.lookAt(position,position+Vector3.new(1,0,0))*CFrame.Angles(0,0,math.rad(-4*(1-alpha))))
   for _,blade in ipairs(model:GetChildren()) do if blade.Name=="MainRotorBlade" then blade.CFrame*=CFrame.Angles(0,math.rad(34),0) end end
   task.wait()
  end
  if model.Parent then model:PivotTo(CFrame.new(target)*CFrame.Angles(0,math.pi/2,0)) end
 end
 cameraPlan(C3.Pos(812,50,-92),C3.Pos(826,43,-80),C3.Pos(908,9,-22),2.3,70,62)
 task.spawn(function() fly(left,C3.Pos(902,7,-26),4.2) end)
 task.spawn(function() fly(right,C3.Pos(924,7,24),4.6) end)
 task.wait(4.8)
 C3.Say("Демид","Вертолёты! И броня не похожа на обычную охрану.",3)
 for _,model in ipairs(helicopters) do model:Destroy() end
 -- The captured unit is a genuine elite wave: heavy armor, a larger health pool,
 -- stronger accurate fire, and a distinct field silhouette.
 for k=1,4 do
  C3.Spawn(5,C3.Pos(900+(k%2)*17,4,(k<3 and -1 or 1)*24),false,true,k)
 end
 cameraPlan(C3.Pos(890,11,-45),C3.Pos(894,10,-38),C3.Pos(916,5,0),1.5,60,56)
 C3.Say(ANDROID_NAME,"Захваченный отряд, открыть огонь!",3)
 operator:Destroy()
 C3.Scene(false)
end
function C3.Activate(index)
 if index==10 then for _,m in ipairs(C3.previewGuards or {}) do m:Destroy() end; C3.previewGuards={} end
 if index==5 and not C3.reinforcementSeen then C3.reinforcementSeen=true; C3.TowerReinforcement() end
 for _,p in ipairs(C3.party) do if p.Parent and not C3.Root(p) then C3.RestorePlayer(p) end end
 C3.stage=index; C3.checkpoint=index; C3.checkpointPos=C3.zones[index].start
 local z=C3.zones[index]; z.wave=0; z.cleared=false; z.objective=false; z.deployed=false
 currentSpawn=CFrame.lookAt(z.start,z.center)
 for _,p in ipairs(C3.Living()) do
  local level=index>=5 and 6 or (p:GetAttribute("Hero")=="Artem" and math.min(3,2+math.floor(index/7)) or math.min(5,2+math.floor(index/2)))
  c2Grant(p,level)
 end
 if index==5 then NotifyRE:FireAllClients("Подкрепление НТЯН захвачено. Дуговой карабин добавлен в арсенал. Клавиша 6.",5) end
 if index==5 and not C3.shieldSeen then
  C3.shieldSeen=true; C3.Scene(true)
  cameraPlan(C3.Pos(830,17,-55),C3.Pos(834,18,-50),C3.Pos(930,88,0),1.4,60,55)
  C2.ScriptedShot(C3.Pos(884,8,0),false)
  C3.Say("Демид","Да ей вообще плевать на пули!",3)
  C3.Say("Артём","Снаружи не пробить. Сервисный вход подключён к внутренней сети. Поднимаемся к управляющему терминалу и гасим её изнутри.",6)
  C3.Scene(false)
 end
 C3.Send(); C3.Wave(z); C3.gameplayStarted=true
end
function C3.CompleteObjective(p,z)
 if C3.stage~=z.index or not z.cleared or z.objective then return end
 if z.index==10 then C3.OpenHack(p); return end
 if z.index>=6 and not C3.Engineer(p) then
  NotifyRE:FireClient(p,"Размыкатель напротив. Основную панель отключает Артём.",3); return
 end
 if C3.coop and z.index>=6 then
  local helperRoot=C3.confirmPlayer and C3.Root(C3.confirmPlayer)
  local needsPartner=#C3.Living()>1
  if needsPartner and (not z.assaultReady or not C3.confirmUntil or os.clock()>C3.confirmUntil or not helperRoot or C3.confirmPlayer==p or (helperRoot.Position-z.breaker.Position).Magnitude>11) then
   NotifyRE:FireClient(p,"Напарник должен удерживать соседний размыкатель, пока ты работаешь с реле.",3); return
  end
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
 cameraPlan(C3.Pos(1190,220,-240),C3.Pos(1170,200,-220),C3.Pos(960,170,0),3,62,66)
 for _,p in ipairs(C3.redLights) do
  if p.Parent then p.Color=C(38,49,58); for _,l in ipairs(p:GetChildren()) do if l:IsA("Light") then l.Enabled=false end end end
  task.wait(0.08)
 end
 for _,part in ipairs(C3.shieldParts or {C3.shield}) do
  if part.Parent then TweenService:Create(part,TweenInfo.new(2),{Transparency=1}):Play(); part.CanQuery=false end
 end
 for _,e in pairs(C3.mobs) do if e.civilian then e.down=true end end
 task.wait(3)
 C3.MoveParty(C3.Pos(950,100,6),C3.case.Position)
 cameraPlan(C3.Pos(980,109,20),C3.Pos(977,108,18),C3.case.Position,1.3,58,54)
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
 cameraPlan(C3.Pos(978,112,24),C3.Pos(975,110,20),C3.case.Position,1.2,58,54)
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
 C3.active=true; C3.finished=false; C3.serial+=1; C3.party=table.clone(party); C3.coop=#party>1; C3.mobs={}; C3.connections={}; C3.lastStateSignature=nil; C3.lastStateSent=nil; C3.sprint={}; C3.relays=0; C3.key=false; C3.shieldSeen=false; C3.hackPhase=1; C3.hackSerial=0; C3.shots={}; C3.recovering={}; C3.towerOff=false; C3.reinforcementSeen=false; C3.gameplayStarted=false; C3.recoveryAttempts=0; C3.modules={}; C3.collecting=false; C3.confirmUntil=nil; C3.confirmPlayer=nil; C3.hacker=nil; C3.challenge=nil; C3.stage=1
 C2.originals={}; Players.RespawnTime=999999
 local physics=game:GetService("PhysicsService"); pcall(function() physics:RegisterCollisionGroup("C2Enemy") end); physics:CollisionGroupSetCollidable("C2Enemy","C2Enemy",false)
 clearLevel(); newFolders(); C3.ApplyLighting(); C3.Build()
 for _,p in ipairs(party) do
  if not p.Character then p:LoadCharacter() end
  p.Character:WaitForChild("HumanoidRootPart"); p:SetAttribute("Chapter",3); c2Hero(p); c2Grant(p,2); C3.sprint[p]={held=false,energy=100}; C3.BindDeath(p)
 end
 local function recoverChapter(reason)
  C3.recoveryAttempts+=1
  warn("[Chapter3] Recovering playable chapter after scene/tick error #"..C3.recoveryAttempts..": "..tostring(reason))
  if C3.recoveryAttempts>2 then error(reason) end
  NotifyRE:FireAllClients("Сбой сценического перехода устранён. Глава продолжается с контрольной точки.",5)
  C3.Scene(false); C3.CloseHack(); C3.ClearMobs()
  if C3.factory and C3.factory.Parent then C3.factory:Destroy() end; C3.factory=nil
  if C3.buddy and C3.buddy.Parent then C3.buddy:Destroy() end; C3.buddy=nil
  FadeRE:FireAllClients(false,""); CutsceneRE:FireAllClients("reveal")
  local resume=C3.gameplayStarted and (C3.checkpoint or C3.stage) or 1
  resume=math.clamp(resume or 1,1,10)
  C3.MoveParty(C3.zones[resume].start,C3.zones[resume].center)
  C3.Activate(resume)
 end
 local introOk,introError=xpcall(C3.Intro,debug.traceback)
 if not introOk then recoverChapter(introError)
 elseif not C3.gameplayStarted then recoverChapter("intro ended without activating the first playable wave") end
 local last=os.clock()
 while C3.active and not C3.finished do
  local now=os.clock(); local ok,err=xpcall(function() C3.Tick(math.min(now-last,0.5)) end,debug.traceback); last=now
  if not ok then recoverChapter(err) end
  task.wait(0.25)
 end
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
 -- Kirill and the tower never enter the damage registry. Shield is not an HP pool.
 local model=hit.Instance:FindFirstAncestorOfClass("Model"); local e=model and C3.mobs[model]
 if not e or e.down or e.hum.Health<=0 then return end
 if name~="Fists" then tracer(origin,hit.Position,w.Color) end
 local damage=name=="Fists" and (p:GetAttribute("Hero")=="Artem" and 25 or 48) or w.Damage*(name=="Shotgun" and 5 or 1)
 if name=="Rifle" then local c=typeof(charge)=="number" and charge==charge and math.clamp(charge,0,1) or 0; damage=45+235*c end
 if hit.Instance.Name=="Head" then damage*=1.5 end
 if name=="Fists" then e.stun=os.clock()+1 end
 e.hum:TakeDamage(damage)
 HitRE:FireClient(p,e.down or e.hum.Health<=0)
end
