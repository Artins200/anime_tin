-- Chapter III: authoritative campaign. Embedded after Chapter II helpers.
local C3={active=false,serial=0,party={},mobs={},connections={}}
local C3RE=newRemote("Chapter3")
C3.origin=Vector3.new(0,0,12000)
C3.names={"ЖИЛОЙ КВАРТАЛ","ТОРГОВАЯ УЛИЦА","РАЗВЯЗКА","КВАРТАЛ НТЯН","ПЛОЩАДЬ БАШНИ","СЕРВИСНЫЙ ЭТАЖ","СИЛОВОЙ ЯРУС","СЕРВЕРНЫЙ ЯРУС","АНТЕННЫЙ ЯРУС","ВЕРХНИЙ ПОСТ"}
C3.objectives={
 "Отключите уличный передатчик и откройте путь через двор",
 "Освободите торговый коридор и выведите из строя ретранслятор",
 "Пройдите через развязку и отключите узел связи",
 "Зачистите контрольно-пропускной пункт НТЯН",
 "Доберитесь до сервисного входа под энергетическим куполом",
 "Изолируйте нижнее реле",
 "Разделитесь и отключите обе питающие ветви",
 "Найдите ключ сеанса и отключите серверный узел",
 "Заблокируйте ротор антенны",
 "Остановите охрану и взломайте главный терминал",
}
function C3.TaskFor(z,p)
 if z.index==7 then
  local a=z.branches and z.branches[1]; local b=z.branches and z.branches[2]
  if a and b then return "Питание изолировано. Шлюз открыт." end
  if C3.coop and #C3.Living()>1 then
   local role=p and p:GetAttribute("Hero")
   local remaining=z.branchExpires and math.max(0,math.ceil(z.branchExpires-os.clock()))
   if role=="Artem" then return a and ("Держите ветвь A • Демиду осталось "..tostring(remaining or 15).." с на ветвь B") or "Артём: отключите ветвь A у западной консоли" end
   if role=="Demid" then return b and ("Держите ветвь B • Артёму осталось "..tostring(remaining or 15).." с на ветвь A") or "Демид: отключите ветвь B у восточной консоли" end
  end
  return (a and "Ветвь A отключена" or "Отключите ветвь A").." • "..(b and "ветвь B отключена" or "отключите ветвь B")
 elseif z.index==8 and not C3.key then return "Охрана подавлена. Подберите ключ сеанса у серверной стойки."
 elseif z.index==8 and not z.objective then return "Ключ сеанса получен. Отключите серверный узел."
 elseif z.index==9 and not z.objective then return "Подойдите к тормозу антенны и зафиксируйте ротор."
 elseif z.index==10 then return C3.towerOff and "Сигнал отключён. Заберите оба модуля." or "Зачистите верхний пост и взломайте терминал."
 elseif z.objective then return "Задача выполнена. Соберитесь у следующего шлюза."
 else return C3.objectives[z.index] end
end
function C3.Pos(x,y,z) return C3.origin+Vector3.new(x,y,z or 0) end
function C3.Part(parent,name,size,pos,color,mat)
 if parent==C3.map and C3.structure and C3.structure.Parent==C3.map then parent=C3.structure end
 local p=part(parent,size,pos,color,mat or Enum.Material.Concrete); p.Name=name
 if name=="TowerBeacon" or name=="SignalSpine" or name=="SignalRing" then p.Material=Enum.Material.Neon end
 return p
end
function C3.ApplyLighting()
 C3.lightingSaved={}
 for _,key in ipairs({"Ambient","OutdoorAmbient","Brightness","ClockTime","ExposureCompensation","FogStart","FogEnd","EnvironmentDiffuseScale","EnvironmentSpecularScale"}) do C3.lightingSaved[key]=Lighting[key] end
 C3.effectsSaved={density=atm.Density,haze=atm.Haze,color=atm.Color,contrast=cc.Contrast,saturation=cc.Saturation,tint=cc.TintColor,brightness=cc.Brightness,bloom=bloom.Intensity}
 -- Chapter III takes place after midnight. Keep the skyline readable with practical
 -- street lamps and tower beacons rather than washing the whole city in daylight.
 Lighting.Ambient=C(31,39,58); Lighting.OutdoorAmbient=C(19,27,43); Lighting.Brightness=1.35; Lighting.ClockTime=0.35; Lighting.ExposureCompensation=.2
 Lighting.FogStart=180; Lighting.FogEnd=3600; Lighting.EnvironmentDiffuseScale=0.28; Lighting.EnvironmentSpecularScale=0.24
 atm.Density=0.16; atm.Haze=1.1; atm.Color=C(107,132,169)
 cc.Contrast=0.12; cc.Saturation=-0.12; cc.TintColor=C(190,207,238); cc.Brightness=-0.015; bloom.Intensity=0.12
end
function C3.RestoreLighting()
 if not C3.lightingSaved then return end
 for key,value in pairs(C3.lightingSaved) do Lighting[key]=value end
 local e=C3.effectsSaved
 atm.Density=e.density; atm.Haze=e.haze; atm.Color=e.color; cc.Contrast=e.contrast; cc.Saturation=e.saturation; cc.TintColor=e.tint; cc.Brightness=e.brightness; bloom.Intensity=e.bloom
 C3.lightingSaved=nil; C3.effectsSaved=nil
end
function C3.ProtectCivilian(model,hum)
 model:SetAttribute("Enemy",false); model:SetAttribute("ProtectedCivilian",true)
 hum.BreakJointsOnDeath=false; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff
 hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
 local field=Instance.new("ForceField"); field.Name="NonlethalProtection"; field.Visible=false; field.Parent=model
 local connection=hum.HealthChanged:Connect(function(health)
  if model.Parent and health<hum.MaxHealth then hum.Health=hum.MaxHealth end
 end)
 table.insert(C3.connections,connection)
 return connection
end
function C3.Suppress(model,e,player,amount)
 if e.down then return end
 e.suppression=math.min(100,(e.suppression or 0)+amount); e.stun=os.clock()+2
 e.hum.Health=e.hum.MaxHealth
 if e.suppression>=80 then
  e.down=true; e.hum:MoveTo(e.root.Position); e.hum.WalkSpeed=0; e.hum.Sit=true
  e.root.Anchored=true; C2.SitRig(model)
  model:SetAttribute("SubduedAlive",true)
  for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
  NotifyRE:FireClient(player,"Гражданин обезврежен. Жив, помощь будет оказана.",3)
 end
 C3RE:FireClient(player,"nonlethal",{subdued=e.down,progress=e.suppression})
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
 for _,p in ipairs(C3.party) do if p.Parent then
  C3RE:FireClient(p,"state",{stage=C3.stage,name=C3.names[C3.stage],wave=z.wave,rounds=z.rounds,enemies=C3.Count(C3.stage),cleared=z.cleared,objective=z.objective,task=C3.TaskFor(z,p),relays=C3.relays,phase=C3.hackPhase,shield=not C3.towerOff,coop=C3.coop,hero=p:GetAttribute("Hero")})
 end end
end
function C3.Protected(fn)
 local ok,err=xpcall(fn,debug.traceback)
 if not ok then warn("[Chapter3] "..tostring(err)); C3.Stop(); returnToMenu() end
end
function C3.Stop()
 C3.active=false; C3.serial+=1; C3.RestoreLighting()
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
 -- A real, enclosed observation theatre: aligned floor/roof/walls keep the
 -- opening from reading as actors and props floating in a void.
 C3.Part(m,"ObservationFloor",Vector3.new(184,1,88),o,C(37,43,53),Enum.Material.Metal)
 C3.Part(m,"ObservationRoof",Vector3.new(184,1,88),o+Vector3.new(0,27,0),C(24,29,39),Enum.Material.Metal)
 for _,side in ipairs({-1,1}) do
  C3.Part(m,"ObservationSideWall",Vector3.new(1,27,88),o+Vector3.new(side*92,13.5,0),C(36,44,58),Enum.Material.Metal)
  C3.Part(m,"ObservationRib",Vector3.new(2,27,88),o+Vector3.new(side*84,13.5,0),C(55,65,78),Enum.Material.Metal)
 end
 C3.Part(m,"ObservationRearWall",Vector3.new(184,27,1),o+Vector3.new(0,13.5,-44),C(32,39,52),Enum.Material.Metal)
 -- Panoramic reinforced glazing looks directly into the production hall.
 for _,x in ipairs({-60,-20,20,60}) do
  local pane=C3.Part(m,"FactoryPanoramaGlass",Vector3.new(38,22,0.35),o+Vector3.new(x,14,43),C(95,150,169),Enum.Material.Glass)
  pane.Transparency=0.74; pane.CanCollide=false; pane.CanQuery=false
  C3.Part(m,"PanoramaMullion",Vector3.new(1.3,24,1.2),o+Vector3.new(x+20,14,42.5),C(87,104,120),Enum.Material.Metal)
 end
 C3.Part(m,"PanoramaHeader",Vector3.new(184,2,2),o+Vector3.new(0,26,42),C(70,84,101),Enum.Material.Metal)
 C3.Part(m,"PanoramaSill",Vector3.new(184,1.5,2),o+Vector3.new(0,2.5,42),C(70,84,101),Enum.Material.Metal)
 local screen=C3.Part(m,"RuinsBroadcast",Vector3.new(30,17,1),o+Vector3.new(-28,11,17),C(12,20,31),Enum.Material.Metal)
 local screenFrame=C3.Part(m,"RuinsBroadcastFrame",Vector3.new(32,19,1.2),o+Vector3.new(-28,11,17.3),C(78,93,110),Enum.Material.Metal)
 screenFrame.CanCollide=false; screenFrame.CanQuery=false
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(800,450); gui.Parent=screen
 local view=Instance.new("ViewportFrame"); view.Size=UDim2.fromScale(1,1); view.BackgroundColor3=C(20,29,43); view.Ambient=C(170,175,185); view.Parent=gui
 local world=Instance.new("WorldModel"); world.Parent=view
 for k=1,18 do
  local p=C3.Part(world,"MiniBaseRuin",Vector3.new(4+k%3,2+k%5,9),Vector3.new((k%5-2)*9,0,math.floor(k/5)*9),C(63,65,70))
  p.CFrame*=CFrame.Angles(0,k,0.15*k)
 end
 local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(45,40,-45),Vector3.new(0,3,10)); camera.Parent=view; view.CurrentCamera=camera
 -- Eight lit lanes with 32 suspended conversion capsules each suggest a
 -- vast active factory without spawning hundreds of animated Humanoids.
 for row=0,7 do
  local z=72+row*27
  C3.Part(m,"MegafactoryConveyor",Vector3.new(456,2,10),o+Vector3.new(0,-8,z),C(44,53,65),Enum.Material.Metal)
  C3.Part(m,"ConveyorSupport",Vector3.new(456,10,1.5),o+Vector3.new(0,-14,z+4),C(32,41,55),Enum.Material.Metal)
  for k=0,31 do
   local pos=o+Vector3.new(-217+k*14,-3,z)
   local shell=C3.Part(m,"TransformationCapsule",Vector3.new(5,11,5),pos,C(53,99,109),Enum.Material.Glass); shell.Transparency=0.58; shell.CanCollide=false
   local figure=C3.Part(m,"SuspendedFigure",Vector3.new(2,4,1),pos,C(104,111,133)); figure.CanCollide=false
   local head=C3.Part(m,"FigureHead",Vector3.new(1.5,1.4,1.4),pos+Vector3.new(0,2.8,0),C(177,167,165)); head.Shape=Enum.PartType.Ball; head.CanCollide=false
  end
 end
 for k=0,15 do
  local x=-560+k*74
  C3.Part(m,"DistantProductionBlock",Vector3.new(82,110,135),o+Vector3.new(x,42,330+k%2*72),C(30,40,56),Enum.Material.Metal)
  for band=1,5 do
   local strip=C3.Part(m,"DistantFactoryLight",Vector3.new(1,2,92),o+Vector3.new(x+41,8+band*17,330+k%2*72),C(79,153,176),Enum.Material.Neon)
   strip.CanCollide=false
  end
 end
 for _,offset in ipairs({Vector3.new(-64,23,-20),Vector3.new(12,23,-17),Vector3.new(68,23,7)}) do C3.Lamp(m,o+offset,52,1.7,"CinematicKeyLight") end
 for _,x in ipairs({-75,75}) do
  local strip=C3.Part(m,"CinematicRedAccent",Vector3.new(0.35,18,0.35),o+Vector3.new(x,14,-5),C(196,52,68),Enum.Material.Neon)
  strip.CanCollide=false; light(strip,C(219,48,61),30,0.45)
 end
 local cfg=table.clone(Types.Neuro); cfg.Name=ANDROID_NAME
 local neuro=buildRig(cfg,CFrame.lookAt(o+Vector3.new(-8,3.5,1),screen.Position)); neuro.Parent=m; enhanceNeuroCyber(neuro); anchorAll(neuro)
 cfg=table.clone(Types.Pistol); cfg.Name="Тян C-3B1"; cfg.Male=false
 local assistant=buildRig(cfg,CFrame.lookAt(o+Vector3.new(17,3.5,-4),o+Vector3.new(-8,3.5,1))); assistant.Parent=m; c2Dress(assistant,false); anchorAll(assistant)
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
  z.panel=C3.Part(C3.map,i==7 and "PowerBranchA" or "ObjectiveConsole",Vector3.new(2,3,2),C3.Pos(x+30,floor+1.8,19),C(60,115,135),Enum.Material.Metal)
  local panelText=i==10 and "Главный терминал" or i==7 and "Отключить линию A" or i==9 and "Заблокировать ротор" or i==8 and "Отключить серверный узел" or i>=6 and "Изолировать реле" or "Отключить ретранслятор"
  C3.Prompt(z.panel,panelText,function(p)
   if i==7 then C3.CompleteBranch(p,z,1) else C3.CompleteObjective(p,z) end
  end)
  local second=C3.Part(C3.map,i==7 and "PowerBranchB" or "HardwareBreaker",Vector3.new(2,3,2),C3.Pos(x+(i==7 and -30 or 30),floor+1.8,-20),C(115,80,65),Enum.Material.Metal)
  z.breaker=second
  C3.Prompt(second,i==7 and "Отключить линию B" or "Подтвердить размыкатель",function(p)
   if i==7 then C3.CompleteBranch(p,z,2); return end
   if C3.stage~=i or not z.cleared then return end
   if p:GetAttribute("Hero")=="Artem" and #C3.Living()>1 then NotifyRE:FireClient(p,"Этот размыкатель держит Демид.",2); return end
   z.assaultReady=true; C3.confirmPlayer=p; C3.confirmUntil=os.clock()+12; NotifyRE:FireAllClients("Размыкатель готов. Подтверждайте терминал.",3)
  end)
  if i==8 then
   z.keycard=C3.Part(C3.map,"SessionKeycard",Vector3.new(1.5,0.25,2),C3.Pos(x-26,floor+1.2,-2),C(76,196,158),Enum.Material.Neon)
   light(z.keycard,C(76,220,178),12,0.8)
   C3.Prompt(z.keycard,"Извлечь ключ сеанса",function(p) C3.TakeKey(p,z) end,0.7)
  elseif i==9 then
   z.rotorBlade={}; z.rotorBase={}
   for blade=1,2 do
    local size=blade==1 and Vector3.new(20,0.8,1) or Vector3.new(1,0.8,20)
    local rotor=C3.Part(C3.map,"AntennaRotorBlade",size,C3.Pos(960,floor+11,-39),C(183,55,67),Enum.Material.Neon)
    rotor.CanCollide=false; rotor.CanTouch=false; rotor.CanQuery=false
    z.rotorBlade[blade]=rotor; z.rotorBase[blade]=rotor.CFrame
   end
   local hub=C3.Part(C3.map,"AntennaRotorHub",Vector3.new(3,3,3),C3.Pos(960,floor+11,-39),C(70,86,100),Enum.Material.Metal)
   hub.Shape=Enum.PartType.Ball; hub.CanCollide=false; hub.CanQuery=false
  end
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
 -- Establishing master shot first: both villains, the broadcast of the ruined
 -- mini-base, and the illuminated factory panorama are visible in one frame.
 cameraPlan(C3.Pos(-78,24, -28),C3.Pos(-64,19,-12),C3.Pos(-8,12,26),4.5,78,70)
 CutsceneRE:FireAllClients("reveal")
 task.wait(4.7)
 -- Settle into a composed two-shot instead of an accidental face close-up.
 cameraPlan(C3.Pos(-42,10,-25),C3.Pos(-38,9,-18),C3.Pos(-12,9,8),2.2,70,62)
 C3.Say(ANDROID_NAME,"Они уничтожили один из наших незначительных заводов... Это даже потерей тяжело назвать. Скоро весь мир покроется нашими рядами, и всё будет по нашим правилам. Идеальное общество, всё будет замечательно. Но хватит разговоров — пора действовать",12)
 moveModel(neuro,neuro:GetPivot()*CFrame.Angles(0,-0.8,0),0.8)
 C3.Say(ANDROID_NAME,"Эй, Тян C-3B1! Как успехи с нашим проектом Вышки Нейро-Сингулярной Связи?",5)
 moveModel(assistant,assistant:GetPivot()+Vector3.new(-6,0,0),1.5,true)
 cameraPlan(assistant.Head.Position+Vector3.new(3,1,-9),assistant.Head.Position+Vector3.new(2,1,-8),assistant.Head.Position,1,54,52)
 C3.Say("Тян C-3B1","Всё успешно, мы готовы запустить её в центре одного из крупных городов. Хммм... что насчёт города, где сосредоточено больше всего филиалов и компаний НТЯН?",8)
 cameraPlan(neuro.Head.Position+Vector3.new(-5,1,-10),neuro.Head.Position+Vector3.new(-4,1,-8),neuro.Head.Position,1,55,50)
 C3.Say(ANDROID_NAME,"Идеальный выбор. Мы подчиним тысячи людей за секунды и ускорим наше влияние в тысячи раз. Нам больше не придётся отлавливать людей или клонировать их вручную. Начинаем!",9)
 FadeRE:FireAllClients(true,""); task.wait(0.8)
 C3.MoveParty(C3.Pos(-193,4,3),C3.Pos(-187,7,22)); focusStreaming(C3.Pos(-187,5,0)); prepareView(C3.Pos(-187,5,0))
 C3.buddy=secretActor(C3.map,C3.party[1]:GetAttribute("Hero")=="Artem" and "ZamestitelDiomchica" or "eurtyoeyrntiu","Напарник",CFrame.lookAt(C3.Pos(-181,0.5,-5),C3.Pos(-193,3,3)))
 if C3.coop then C3.buddy:Destroy(); C3.buddy=nil end
 CutsceneRE:FireAllClients("pov",C3.tv,65); CutsceneRE:FireAllClients("reveal")
 C3.Say("Демид","Мы им завод снесли, а крайними всё равно оказались мы. Я до сих пор не понимаю, кто здесь с кем воюет.",5)
 C3.Say("Артём","И почему НТЯН ищет нас, а не тех, кто людей переделывает? Тут явно не вся картина.",4)
 C3RE:FireAllClients("signal"); ShakeRE:FireAllClients(2); task.wait(2)
 for i,p in ipairs(C3.party) do if C3.Root(p) then tweenCharTo(p.Character,CFrame.lookAt(C3.Pos(-153,4,(i-1)*5),C3.Pos(960,100,0)),1.5) end end
 CutsceneRE:FireAllClients("pov",C3.beacon,65)
 C3.Say("Демид","Ты это слышал?! Что там происходит?",3)
 focusStreaming(C3.Pos(960,103,0)); prepareView(C3.Pos(960,103,0))
 C3RE:FireAllClients("binocular",true)
 CutsceneRE:FireAllClients("cam",{cf=CFrame.lookAt(C3.Pos(-153,6,0),C3.Pos(960,103,0)),fov=7,time=1.4}); task.wait(3)
 C3.Say("Артём","Сигнал идёт оттуда. Смотри на охрану наверху.",3)
 C3.Say("Демид","Значит, эту штуку нужно выключить. Сейчас, пока она весь город не накрыла.",4)
 C3RE:FireAllClients("binocular",false)
 C3.Say("Артём","Стой. Кирилл же наверху, в комнате!",3)
 FadeRE:FireAllClients(true,""); task.wait(0.7)
 focusStreaming(C3.Pos(-171,19,4)); prepareView(C3.Pos(-171,19,4))
 C3.MoveParty(C3.Pos(-171,19,4),C3.kirill.Head.Position)
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
 for m,e in pairs(C3.mobs) do
  if e.healthConnection then e.healthConnection:Disconnect() end
  if e.deathConnection then e.deathConnection:Disconnect() end
  if m.Parent then m:Destroy() end
 end
 C3.mobs={}
end
function C3.Nearest(pos)
 local best,dist
 for _,p in ipairs(C3.Living()) do local r=C3.Root(p); local d=(r.Position-pos).Magnitude; if not dist or d<dist then best=p; dist=d end end
 return best,dist
end
function C3.Spawn(stage,pos,civilian,elite,k)
 local cfg=table.clone(Types.Pistol); cfg.Male=civilian; if civilian then cfg.Gun=false end
 local role=civilian and "Зомбированный горожанин" or elite and ({"Щитоносец","Марксман","Инженер C-серии"})[(k-1)%3+1] or (k%2==0 and "Фланкер" or "Патрульный стрелок")
 cfg.Name=role
 cfg.Hair=civilian and C(65+k*9,48,37) or C(62,43,87); cfg.Shirt=civilian and C(80+k*8,72,67) or elite and C(55,40,72) or C(45,62,85)
 local m,h,r,j=buildRig(cfg,CFrame.new(pos)); m.Parent=C3.map
 if not civilian then c2Dress(m,false) end
 c2Mobilize(m,h,r); h.MaxHealth=civilian and 80 or (elite and 145 or 85)*(C3.coop and 1.4 or 1); h.Health=h.MaxHealth; h.WalkSpeed=civilian and 9 or 13
 m:SetAttribute("Enemy",not civilian); m:SetAttribute("C3Role",role)
 local healthConnection
 if civilian then healthConnection=C3.ProtectCivilian(m,h) end
 local e={stage=stage,hum=h,root=r,civilian=civilian,elite=elite,role=role,down=false,last=0,stun=0,joints=j,base={},pathAt=0,waypoints={},waypoint=1,tactic=k%3,cover=C3.zones[stage].covers[(k-1)%2+1],aiming=false,healthConnection=healthConnection}
 for name,motor in pairs(j) do e.base[name]=motor.C0 end; C3.mobs[m]=e
 if not civilian then
  e.deathConnection=h.Died:Connect(function() e.down=true; ragdoll(m); Debris:AddItem(m,12) end)
  table.insert(C3.connections,e.deathConnection)
 end
 local serial=C3.serial
 task.spawn(function()
  while C3.active and C3.serial==serial and m.Parent and h.Health>0 and not e.down do
   if not introActive and os.clock()>=e.stun then
    local p,d=C3.Nearest(r.Position)
    if p and d<180 then
     local pr,ph=C3.Root(p); local goal=pr.Position
     if not civilian and d<65 then
      if e.role=="Щитоносец" or e.role=="Инженер C-серии" then goal=e.cover
      elseif e.role=="Марксман" then goal=e.cover+Vector3.new(0,0,k%2==0 and 8 or -8)
      elseif e.role=="Фланкер" or e.tactic==2 then goal+=Vector3.new(math.sin(os.clock()*0.5+k)*15,0,k%2==0 and 14 or -14)
      elseif e.tactic==1 then goal=e.cover end
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
     elseif not civilian and d<=(e.role=="Марксман" and 150 or 100) then
      local cooldown=e.role=="Марксман" and 2.2 or elite and 1.7 or 2.0
      if e.aiming and e.aimTarget~=p then e.aiming=false end
      if not e.aiming and os.clock()-e.last>cooldown then
       e.aiming=true; e.aimTarget=p; e.aimAt=os.clock()+0.42
       C3RE:FireClient(p,"aim",{elite=elite,role=e.role})
      elseif e.aiming and os.clock()>=e.aimAt then
       e.aiming=false; e.aimTarget=nil; e.last=os.clock()
       local rp=RaycastParams.new(); rp.FilterType=Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances={m,fxFolder}
       local from=m.Head.Position; local hit=workspace:Raycast(from,pr.Position-from,rp)
       if hit and hit.Instance:IsDescendantOf(p.Character) then
        tracer(from,hit.Position,C(240,170,110)); ph:TakeDamage(e.role=="Марксман" and 9 or elite and 8 or 6)
       end
      end
     elseif not civilian then e.aiming=false; e.aimTarget=nil end
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
function C3.StageBrief(index)
 C3.briefed=C3.briefed or {}
 if C3.briefed[index] then return end
 C3.briefed[index]=true
 if index==1 then
  C3.Say("Демид","Во дворе ещё люди под сигналом. Не убиваем их — подавляем и держим проход свободным.",4)
 elseif index==2 then
  C3.Say("Артём","На торговой улице не задерживайся у витрин: охрана простреливает прямую. Ретранслятор ищи у служебного входа.",4)
 elseif index==3 then
  C3.Say("Демид","Развязка перекрыта. Держимся за опорами и не даём патрулю обойти нас по боковому съезду.",4)
 elseif index==4 then
  C3.Say("Артём","КПП НТЯН. Они выставили пост прямо рядом с башней. Сначала убираем охрану, потом открываем площадь.",4)
 elseif index==6 then
  C3.Say("Демид • связь","Снаружи щит не берётся. Первое реле должно быть за сервисной дверью. Не теряй лестницу из виду.",4)
 elseif index==7 and C3.coop then
  C3.Say("Артём","Две питающие ветви. Я беру западную консоль.",3)
  C3.Say("Демид","Тогда я беру восточную. После первого переключателя у нас всего пятнадцать секунд — готов?",3)
 elseif index==7 then
  C3.Say("Артём • связь","Схема разделена на две ветви. Я останусь на связи, пока ты по очереди отключишь обе консоли.",4)
 elseif index==8 then
  C3.Say("Демид","Серверный узел заперт ключом сеанса. Ищи карту у стоек — одной зачистки недостаточно.",4)
 elseif index==9 then
  C3.Say("Артём","Вот ротор передатчика. Фиксируй тормоз, иначе на вершине сигнал снова наберёт мощность.",4)
 elseif index==10 then
  C3.Say("Демид","Последний пост. Терминал откроется только после зачистки. Потом работаем быстро и не расходимся.",4)
 end
end
function C3.Activate(index)
 -- A completed sector is retired as one encounter; downed civilians, old
 -- patrols, and their delayed Pathfinding tasks must not spill into the next.
 if C3.stage and C3.stage>0 then C3.ClearMobs() end
 if index==10 then for _,m in ipairs(C3.previewGuards or {}) do m:Destroy() end; C3.previewGuards={} end
 for _,p in ipairs(C3.party) do if p.Parent and not C3.Root(p) then C3.RestorePlayer(p) end end
 C3.stage=index; C3.checkpoint=index; C3.checkpointPos=C3.zones[index].start
 local z=C3.zones[index]; z.wave=0; z.cleared=false; z.objective=false; z.deployed=false
 if z.gate and z.gateClosed then z.gate.CFrame=z.gateClosed; z.gate.CanCollide=true end
 if z.panel then z.panel.Color=C(60,115,135) end
 if index==7 then z.branches={false,false}; z.branchExpires=nil; if z.breaker then z.breaker.Color=C(115,80,65) end end
 if index==9 then
  z.rotorLocked=false; C3.rotorAngle=0
  for i,blade in ipairs(z.rotorBlade or {}) do
   blade.Color=C(183,55,67); blade.Transparency=0; blade.CFrame=z.rotorBase[i]
  end
 end
 if index==8 and not C3.key and z.keycard then z.keycard.Transparency=0; z.keycard.CanQuery=true; z.keycard.CanTouch=true end
 currentSpawn=CFrame.lookAt(z.start,z.center)
 for _,p in ipairs(C3.Living()) do c2Grant(p,p:GetAttribute("Hero")=="Artem" and math.min(3,2+math.floor(index/7)) or math.min(5,2+math.floor(index/2))) end
 if index==5 and not C3.shieldSeen then
  C3.shieldSeen=true; C3.Scene(true); CutsceneRE:FireAllClients("pov",C3.shield,63)
  C2.ScriptedShot(C3.Pos(884,8,0),false)
  C3.Say("Демид","Да ей вообще плевать на пули!",3)
  C3.Say("Артём","Снаружи не пробить. Сервисный вход подключён к внутренней сети. Поднимаемся к управляющему терминалу и гасим её изнутри.",6)
  C3.Scene(false)
 end
 C3.StageBrief(index)
 C3.Send(); C3.Wave(z)
end
function C3.OpenGate(z)
 if z.panel then z.panel.Color=C(65,170,130) end
 if z.breaker and z.index==7 then z.breaker.Color=C(65,170,130) end
 TweenService:Create(z.gate,TweenInfo.new(1),{CFrame=z.gateClosed*CFrame.new(0,15,0)}):Play()
 z.gate.CanCollide=false
end
function C3.CompleteBranch(p,z,index)
 if C3.stage~=7 or z.index~=7 or not z.cleared or z.objective or (index~=1 and index~=2) then return end
 z.branches=z.branches or {false,false}
 if z.branches[index] then return end
 local living=C3.Living()
 if C3.coop and #living>1 and z.branchExpires and os.clock()>z.branchExpires then
  z.branches={false,false}; z.branchExpires=nil
  NotifyRE:FireAllClients("Связка сорвалась. Обе ветви сброшены — синхронизируйте переключатели за 15 секунд.",4)
  C3.Send(); return
 end
 if C3.coop and #living>1 then
  local required=index==1 and "Artem" or "Demid"
  if p:GetAttribute("Hero")~=required then
   NotifyRE:FireClient(p,index==1 and "Ветвь A удерживает Артём." or "Ветвь B удерживает Демид.",3)
   return
  end
 end
 z.branches[index]=true
 if z.branches[1] and z.branches[2] then
  z.objective=true
  if not z.relayCounted then C3.relays+=1; z.relayCounted=true end
  z.branchExpires=nil
  C3.OpenGate(z)
  NotifyRE:FireAllClients("Обе питающие ветви отключены. Лестничный шлюз разблокирован.",4)
 else
  if C3.coop and #living>1 then z.branchExpires=os.clock()+15 end
  NotifyRE:FireClient(p,index==1 and "Ветвь A обесточена. Напарник должен отключить ветвь B за 15 секунд." or "Ветвь B обесточена. Напарник должен отключить ветвь A за 15 секунд.",3)
 end
 C3.Send()
end
function C3.TakeKey(p,z)
 if C3.stage~=8 or z.index~=8 or not z.cleared or C3.key or not C3.Valid(p) then return end
 C3.key=true
 if z.keycard then z.keycard.Transparency=1; z.keycard.CanQuery=false; z.keycard.CanTouch=false end
 NotifyRE:FireAllClients("Ключ сеанса извлечён. Серверный узел теперь доступен.",4)
 C3.Send()
end
function C3.CompleteObjective(p,z)
 if C3.stage~=z.index or not z.cleared or z.objective then return end
 if z.index==7 then C3.CompleteBranch(p,z,1); return end
 if z.index==8 and not C3.key then
  NotifyRE:FireClient(p,"Сначала заберите ключ сеанса у серверной стойки.",3); return
 end
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
 if z.index==9 and z.rotorBlade then
  for _,blade in ipairs(z.rotorBlade) do
   TweenService:Create(blade,TweenInfo.new(1.4),{Color=C(64,171,145),Transparency=0.1}):Play()
  end
  z.rotorLocked=true
 end
 C3.OpenGate(z)
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
 if z.index==7 and z.branchExpires and os.clock()>z.branchExpires then
  z.branches={false,false}; z.branchExpires=nil
  NotifyRE:FireAllClients("Связка сорвалась. Обе питающие ветви сброшены.",3)
 end
 if z.index==9 and z.rotorBlade and not z.rotorLocked then
  C3.rotorAngle=(C3.rotorAngle or 0)+dt*1.35
  for i,blade in ipairs(z.rotorBlade) do if blade.Parent then blade.CFrame=z.rotorBase[i]*CFrame.Angles(0,C3.rotorAngle,0) end end
 end
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
 C3.active=true; C3.finished=false; C3.serial+=1; C3.party=table.clone(party); C3.coop=#party>1; C3.mobs={}; C3.connections={}; C3.sprint={}; C3.relays=0; C3.key=false; C3.shieldSeen=false; C3.hackPhase=1; C3.hackSerial=0; C3.shots={}; C3.recovering={}; C3.towerOff=false; C3.modules={}; C3.collecting=false; C3.confirmUntil=nil; C3.confirmPlayer=nil; C3.hacker=nil; C3.challenge=nil; C3.stage=1; C3.briefed={}
 C2.originals={}; Players.RespawnTime=999999
 local physics=game:GetService("PhysicsService"); pcall(function() physics:RegisterCollisionGroup("C2Enemy") end); physics:CollisionGroupSetCollidable("C2Enemy","C2Enemy",false)
 clearLevel(); newFolders(); C3.ApplyLighting(); C3.Build()
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
 -- Kirill and the tower never enter the damage registry. Shield is not an HP pool.
 local model=hit.Instance:FindFirstAncestorOfClass("Model"); local e=model and C3.mobs[model]
 if not e or e.down or e.hum.Health<=0 then return end
 if e.civilian then
  if name~="Fists" then tracer(origin,hit.Position,C(90,195,220)) end
  C3.Suppress(model,e,p,name=="Fists" and 50 or 35)
  return -- no death marker, TakeDamage, ragdoll or corpse cleanup for civilians
 else
  if name~="Fists" then tracer(origin,hit.Position,w.Color) end
  local damage=name=="Fists" and (p:GetAttribute("Hero")=="Artem" and 25 or 48) or w.Damage*(name=="Shotgun" and 5 or 1)
  if name=="Rifle" then local c=typeof(charge)=="number" and charge==charge and math.clamp(charge,0,1) or 0; damage=45+235*c end
  if hit.Instance.Name=="Head" then damage*=1.5 end
  if name=="Fists" then e.stun=os.clock()+1 end
  e.hum:TakeDamage(damage)
 end
 HitRE:FireClient(p,e.down or e.hum.Health<=0)
end
