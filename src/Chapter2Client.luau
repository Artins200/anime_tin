-- Embedded into GameClient after its menu and weapon controller.
do
 local chooser=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,13,19),BackgroundTransparency=0.03,Visible=false,ZIndex=60},menu)
 new("TextLabel",{Size=UDim2.fromScale(0.9,0.09),Position=UDim2.fromScale(0.05,0.06),Text="ГЛАВА II • ВЫБЕРИ ГЕРОЯ",TextScaled=true,Font=Enum.Font.GothamBlack,TextColor3=Color3.fromRGB(220,228,230),BackgroundTransparency=1,ZIndex=61},chooser)
 local hint=new("TextLabel",{Size=UDim2.fromScale(0.9,0.08),Position=UDim2.fromScale(0.05,0.16),Text="Роль закрепится только после подтверждения. Вдвоем нужны разные герои.",TextWrapped=true,TextSize=17,TextColor3=Color3.fromRGB(155,175,186),BackgroundTransparency=1,ZIndex=61},chooser)
 local cards={}; local candidate; local pendingCommand
 for index,hero in ipairs({"Artem","Demid"}) do
  local x=index==1 and 0.09 or 0.53
  local card=new("TextButton",{Size=UDim2.fromScale(0.38,0.49),Position=UDim2.fromScale(x,0.27),Text="",BackgroundColor3=Color3.fromRGB(25,37,48),ZIndex=61},chooser)
  local stroke=new("UIStroke",{Color=Color3.fromRGB(65,85,100),Thickness=2},card)
  local view=new("ViewportFrame",{Size=UDim2.fromScale(1,0.74),BackgroundTransparency=1,Ambient=Color3.fromRGB(180,185,190),LightColor=Color3.fromRGB(235,225,205),ZIndex=62},card)
  new("TextLabel",{Size=UDim2.fromScale(0.94,0.2),Position=UDim2.fromScale(0.03,0.77),Text=hero=="Artem" and "АРТЕМ • ИНЖЕНЕР\nСварка, взлом, пистолет" or "ДЕМИД • ШТУРМ\nНож, скрытность, оружие",TextScaled=true,TextColor3=Color3.fromRGB(218,230,232),Font=Enum.Font.GothamBold,BackgroundTransparency=1,ZIndex=62},card)
  cards[hero]={card=card,stroke=stroke,view=view}
  card.Activated:Connect(function()
   candidate=hero
   for key,c in pairs(cards) do c.stroke.Color=key==hero and Color3.fromRGB(100,205,190) or Color3.fromRGB(65,85,100); c.stroke.Thickness=key==hero and 4 or 2 end
  end)
 end
 local confirm=button("ПОДТВЕРДИТЬ ГЕРОЯ",0.365,0.82,function()
  if not candidate then hint.Text="Сначала нажми на карточку Артема или Демида."; return end
  confirmSelectionPending=true
  hint.Text="Подтверждаем роль…"
  lobbyRemote:FireServer("configure",{chapter=2,hero=candidate})
 end,chooser); confirm.ZIndex=62
 local cancel=button("НАЗАД",0.06,0.82,function() chooser.Visible=false; pendingCommand=nil end,chooser); cancel.ZIndex=62
 local function loadPreviews()
  local folder=RS:FindFirstChild("HeroPreviews")
  if not folder then return end
  for hero,c in pairs(cards) do if not c.view.CurrentCamera then
   local source=folder:FindFirstChild(hero)
   if source then
    local world=new("WorldModel",{},c.view)
    local model=source:Clone(); model.Parent=world; model:PivotTo(CFrame.new())
    local cf,size=model:GetBoundingBox()
    local camera=new("Camera",{FieldOfView=36},c.view)
    camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(0,size.Y*0.04,-size.Y*1.9),cf.Position+Vector3.new(0,size.Y*0.06,0))
    c.view.CurrentCamera=camera
   end
  end end
 end
 openHeroChooser=function(command,hero)
  selectedChapter=2; pendingCommand=command; candidate=hero
  chooser.Visible=true; confirmSelectionPending=false
  hint.Text="Выбери роль и подтверди ее. В кооперативе герои должны быть разными."
  for key,c in pairs(cards) do c.stroke.Color=key==candidate and Color3.fromRGB(100,205,190) or Color3.fromRGB(65,85,100); c.stroke.Thickness=key==candidate and 4 or 2 end
  loadPreviews(); refreshChapterChoice()
 end
 requestLaunch=function(command)
  if selectedChapter==2 and not heroConfirmed then openHeroChooser(command); return end
  pendingCommand=command
  lobbyRemote:FireServer("configure",{chapter=selectedChapter,hero=heroConfirmed and selectedHero or nil})
 end
 onConfigured=function(data)
  selectedChapter=data.chapter; selectedHero=data.hero; heroConfirmed=data.chosen; confirmSelectionPending=false
  if data.chosen then chooser.Visible=false end
  refreshChapterChoice()
  if pendingCommand then local command=pendingCommand; pendingCommand=nil; lobbyRemote:FireServer(command) end
 end
 onConfigureError=function(message)
  confirmSelectionPending=false; hint.Text=message
 end
end

do
 local chapterRemote=Remotes:WaitForChild("Chapter2")
 local engineeringGui=new("ScreenGui",{Name="EngineeringTerminal",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=120,Enabled=false},plr.PlayerGui)
 local shade=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(5,12,17),BackgroundTransparency=0.15},engineeringGui)
 local window=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.86,0.86),BackgroundColor3=Color3.fromRGB(18,30,38)},shade)
 new("UISizeConstraint",{MaxSize=Vector2.new(660,620)},window)
 local title=new("TextLabel",{Size=UDim2.fromScale(0.85,0.1),Position=UDim2.fromScale(0.04,0.02),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(150,215,205),TextXAlignment=Enum.TextXAlignment.Left},window)
 local info=new("TextLabel",{Size=UDim2.fromScale(0.9,0.1),Position=UDim2.fromScale(0.05,0.13),BackgroundTransparency=1,TextWrapped=true,TextSize=16,TextColor3=Color3.fromRGB(190,205,210)},window)
 local body=new("Frame",{Size=UDim2.fromScale(0.9,0.6),Position=UDim2.fromScale(0.05,0.25),BackgroundTransparency=1},window)
 local footer=new("TextLabel",{Size=UDim2.fromScale(0.9,0.08),Position=UDim2.fromScale(0.05,0.89),BackgroundTransparency=1,TextColor3=Color3.fromRGB(130,160,170),TextSize=16},window)
 local challenge; local cursor; local lastToken; local worldState
 local function closeEngineering(send)
  if send and challenge then chapterRemote:FireServer("cancel",challenge.token) end
  challenge=nil; cursor=nil; engineeringActive=false; engineeringGui.Enabled=false
  RunService:UnbindFromRenderStep("EngineeringPointer")
  if not cutsceneActive and not menu.Enabled then
   setSceneControls(true); plr.CameraMode=Enum.CameraMode.LockFirstPerson
   cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
   UIS.MouseIconEnabled=false; UIS.MouseBehavior=Enum.MouseBehavior.LockCenter
  end
 end
 local exit=new("TextButton",{Size=UDim2.fromScale(0.1,0.09),Position=UDim2.fromScale(0.89,0.02),Text="×",TextSize=28,BackgroundTransparency=1,TextColor3=Color3.fromRGB(220,210,205)},window)
 exit.Activated:Connect(function() closeEngineering(true) end)
 local function send(action,value) if challenge then chapterRemote:FireServer(action,challenge.token,value) end end
 local function draw(data)
  challenge=data
  if lastToken~=data.token then
   lastToken=data.token; firing=false; charging=false
   engineeringActive=true; engineeringGui.Enabled=true
   setSceneControls(false); plr.CameraMode=Enum.CameraMode.Classic; cam.CameraType=Enum.CameraType.Scriptable
   RunService:BindToRenderStep("EngineeringPointer",Enum.RenderPriority.Last.Value+2,function() UIS.MouseIconEnabled=true; UIS.MouseBehavior=Enum.MouseBehavior.Default end)
  end
  for _,child in ipairs(body:GetChildren()) do child:Destroy() end; cursor=nil
  if data.fast then
   title.Text="АРТЕМ / ИНЖЕНЕРНЫЙ ДОСТУП"
   info.Text="Нажимай любые клавиши: инженер обходит защиту. Ключ-карта подтверждена."
   local code=[[local link = ntyan.connect("maintenance");
access.authorize(keycard.signature);
for node in facility.bus:scan() do
    node:patch({watchdog=false, audit="local"});
    crypto.route(node, access.token);
end
security.release("bulkhead");
conveyor.override("safe_stop");
return link:commit("engineer");
]]
   local terminal=new("TextLabel",{Size=UDim2.fromScale(1,0.78),BackgroundColor3=Color3.fromRGB(8,18,18),TextColor3=Color3.fromRGB(90,225,155),TextSize=15,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text=(code..code):sub(1,data.progress*math.ceil(#code/data.required))},body)
   new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,10)},terminal)
   local track=new("Frame",{Size=UDim2.fromScale(1,0.07),Position=UDim2.fromScale(0,0.86),BackgroundColor3=Color3.fromRGB(35,49,55)},body)
   new("Frame",{Size=UDim2.fromScale(math.clamp(data.progress/data.required,0,1),1),BackgroundColor3=Color3.fromRGB(70,205,150),BorderSizePixel=0},track)
  elseif data.kind=="hack" then
   title.Text="ТЕРМИНАЛ / СОЕДИНЕНИЕ ЦЕПИ"
   info.Text="Поворачивай контакты. Соедини вход слева с выходом справа."
   local grid=new("Frame",{Size=UDim2.fromScale(0.64,0.96),Position=UDim2.fromScale(0.18,0.02),BackgroundTransparency=1},body)
   new("UIAspectRatioConstraint",{AspectRatio=1},grid)
   for cell=1,9 do
    local linked=table.find(data.connected,cell)~=nil
    local tile=new("TextButton",{Size=UDim2.fromScale(0.3,0.3),Position=UDim2.fromScale(((cell-1)%3)/3,math.floor((cell-1)/3)/3),Text="",BackgroundColor3=linked and Color3.fromRGB(30,79,70) or Color3.fromRGB(35,49,60)},grid)
    local color=linked and Color3.fromRGB(115,235,185) or Color3.fromRGB(160,185,200)
    new("Frame",{Size=UDim2.fromScale(0.18,0.18),Position=UDim2.fromScale(0.41,0.41),BackgroundColor3=color,BorderSizePixel=0},tile)
    for _,port in ipairs(data.board.base[cell]) do
     local direction=(port+data.board.rotations[cell])%4
     local vertical=direction==0 or direction==2
     local pos=({UDim2.fromScale(0.43,0),UDim2.fromScale(0.5,0.43),UDim2.fromScale(0.43,0.5),UDim2.fromScale(0,0.43)})[direction+1]
     new("Frame",{Size=vertical and UDim2.fromScale(0.14,0.5) or UDim2.fromScale(0.5,0.14),Position=pos,BackgroundColor3=color,BorderSizePixel=0},tile)
    end
    tile.Activated:Connect(function() send("rotate",cell) end)
   end
   for _,side in ipairs({0,1}) do new("Frame",{Size=UDim2.fromScale(0.035,0.1),Position=UDim2.fromScale(side==0 and 0.1 or 0.86,0.43),BackgroundColor3=side==0 and Color3.fromRGB(100,225,170) or Color3.fromRGB(235,180,90),BorderSizePixel=0},body) end
  elseif data.kind=="weld" then
   title.Text="СВАРКА / СРЕЗ КОНТУРА"
   info.Text="Нажми ПРОБЕЛ или кнопку, когда курсор внутри светлой зоны. Три точных среза."
   local track=new("Frame",{Size=UDim2.fromScale(0.9,0.18),Position=UDim2.fromScale(0.05,0.26),BackgroundColor3=Color3.fromRGB(35,48,58)},body)
   new("Frame",{Size=UDim2.fromScale(0.28,1),Position=UDim2.fromScale(data.target-0.14,0),BackgroundColor3=Color3.fromRGB(75,155,130),BorderSizePixel=0},track)
   cursor=new("Frame",{Size=UDim2.new(0,4,1,10),Position=UDim2.fromScale(0.5,0),BackgroundColor3=Color3.fromRGB(240,225,190),BorderSizePixel=0},track)
   local pulse=new("TextButton",{Size=UDim2.fromScale(0.6,0.2),Position=UDim2.fromScale(0.2,0.65),Text="СРЕЗ / ПРОБЕЛ",TextSize=20,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(220,235,230),BackgroundColor3=Color3.fromRGB(40,90,90)},body)
   pulse.Activated:Connect(function() send("pulse") end)
  else
   title.Text="КЛАПАН / СБРОС ДАВЛЕНИЯ"
   info.Text="Раскачай заевший вентиль: чередуй повороты влево и вправо."
   for _,direction in ipairs({-1,1}) do
    local turn=new("TextButton",{Size=UDim2.fromScale(0.36,0.5),Position=UDim2.fromScale(direction==-1 and 0.08 or 0.56,0.2),Text=direction==-1 and "↶" or "↷",TextSize=64,TextColor3=Color3.fromRGB(185,215,215),BackgroundColor3=Color3.fromRGB(35,60,70)},body)
    turn.Activated:Connect(function() send("turn",direction) end)
   end
  end
 end
 local timer=new("TextLabel",{Size=UDim2.fromOffset(310,45),Position=UDim2.new(0.5,-155,0,76),BackgroundColor3=Color3.fromRGB(70,28,25),TextColor3=Color3.fromRGB(255,205,170),Font=Enum.Font.GothamBold,TextSize=25,Visible=false},gui)
 chapterRemote.OnClientEvent:Connect(function(action,data)
  if action=="cinemaEye" then chapterSpectatorHead=data; return end
  if action=="chapterCredits" then
   showCredits(data)
   if data and creditsText then creditsText.Text="Уничтожь Тянку 3\n\nГЛАВА II\nНе скрытая база тянок\n\nАртем • инженер\nДемид • штурм\n\nОперация завершена\nАрхив центра сохранен\n\nНо история еще не закончена…\n\nСпасибо за игру" end
   return
  end
  if action=="run" then enLabel.Text="БЕГИ!  SHIFT — СПРИНТ"; return end
  if action=="terminalLocked" then
   enLabel.Text=not data.cleared and "Панель заблокирована до зачистки волн" or "Нужна ключ-карта последнего охранника"
   task.delay(3,function() if not cutsceneActive then enLabel.Text="" end end)
   return
  end
  if action=="engineering" then draw(data); return end
  if action=="engineeringClose" then closeEngineering(false); lastToken=nil; return end
  if action=="loadout" then
   local changed=not chapterLoadout or chapterLoadout.level~=data.level
   chapterLoadout=data
   refreshSlots(); if changed or not table.find(WD.Order,curName) then selectWeapon(data.equipped or WD.Order[data.level]); if changed then pickupT=0.8; playPickupSound(data.level) end end
   return
  end
  if action=="clear" or action=="ending" then
   closeEngineering(false); chapterLoadout=nil; worldState=nil; timer.Visible=false; lastToken=nil; chapterSpectatorHead=nil
   if action=="ending" then enLabel.Text=data.good and "ХОРОШАЯ КОНЦОВКА" or "ПЛОХАЯ КОНЦОВКА" end
   return
  end
  if action~="state" then return end
  worldState=data; timer.Visible=data.escaping and not cutsceneActive
  if not chapterLoadout or chapterLoadout.level~=data.weaponLevel then chapterLoadout={level=data.weaponLevel,hero=data.role}; refreshSlots(); selectWeapon(WD.Order[data.weaponLevel]) end
  lvlLabel.Text=(data.role=="Artem" and "АРТЕМ" or "ДЕМИД").."  ·  "..data.stage.." / 10"
  enLabel.Text=data.escaping and "БЕГИ!  SHIFT — СПРИНТ" or (("ВОЛНА %d / %d  •  ОХРАНА: %d  •  КАРТА: %s"):format(data.wave or 0,data.rounds or 2,data.enemies,data.keycard and "ЕСТЬ" or "НЕТ"))
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if not engineeringActive then return end
  if input.KeyCode==Enum.KeyCode.Escape then closeEngineering(true)
  elseif challenge and challenge.fast and input.UserInputType==Enum.UserInputType.Keyboard then send("type")
  elseif not processed and input.KeyCode==Enum.KeyCode.Space and challenge and challenge.kind=="weld" then send("pulse") end
 end)
 UIS.InputChanged:Connect(function(input,processed)
  if not processed and not engineeringActive and not cutsceneActive and gui.Enabled and input.UserInputType==Enum.UserInputType.MouseWheel then
   local index=table.find(WD.Order,curName) or 1; local max=chapterLoadout and chapterLoadout.level or (plr:GetAttribute("WeaponLevel") or 1)
   index=(index-1+(input.Position.Z>0 and -1 or 1))%max+1; selectWeapon(WD.Order[index])
  end
 end)
 RunService.RenderStepped:Connect(function()
  if challenge then
   local seconds=math.max(0,math.ceil(challenge.expires-workspace:GetServerTimeNow()))
   footer.Text=("%02d сек.  ·  %d %s"):format(seconds,challenge.progress,challenge.fast and "пакетов доступа" or challenge.kind=="hack" and "поворотов" or "точных действий")
   if cursor then cursor.Position=UDim2.new((math.sin((workspace:GetServerTimeNow()-challenge.start)*2.2)+1)/2,-2,0,-5) end
   local h=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
   if not h or h.Health<=0 or cutsceneActive then closeEngineering(true) end
  end
  if worldState and worldState.escaping then
   local seconds=math.max(0,math.ceil(worldState.deadline-workspace:GetServerTimeNow()))
   timer.Text=("БЕГИ!  %02d:%02d"):format(math.floor(seconds/60),seconds%60)
  end
 end)
 local stamina=new("Frame",{Size=UDim2.fromOffset(180,7),Position=UDim2.new(0,30,1,-108),BackgroundColor3=Color3.fromRGB(28,44,49),Visible=false,BorderSizePixel=0},gui)
 local staminaFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(100,195,165),BorderSizePixel=0},stamina)
 local shieldTrack=new("Frame",{Size=UDim2.new(0.42,0,0,10),Position=UDim2.new(0.29,0,0,135),BackgroundColor3=Color3.fromRGB(32,43,58),Visible=false},gui)
 local shieldFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(75,165,220),BorderSizePixel=0},shieldTrack)
 local shieldText=new("TextLabel",{Size=UDim2.new(1,0,0,23),Position=UDim2.fromOffset(0,14),BackgroundTransparency=1,TextColor3=Color3.fromRGB(180,210,225),Font=Enum.Font.GothamBold,TextSize=14},shieldTrack)
 local function sprint(held) chapterRemote:FireServer("sprint",held) end
 UIS.InputBegan:Connect(function(input,processed)
  if not processed and not engineeringActive and not cutsceneActive and plr:GetAttribute("Chapter")==2 and (input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift) then sprint(true) end
 end)
 UIS.InputEnded:Connect(function(input)
  if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then sprint(UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)) end
 end)
 UIS.WindowFocusReleased:Connect(function() sprint(false) end)
 RunService.RenderStepped:Connect(function(dt)
  local playing=plr:GetAttribute("Chapter")==2 and not cutsceneActive and not menu.Enabled
  stamina.Visible=playing
  staminaFill.Size=UDim2.fromScale((plr:GetAttribute("SprintStamina") or 100)/100,1)
  if playing and not engineeringActive then
   local target=plr:GetAttribute("IsSprinting") and 76 or 70
   cam.FieldOfView+=(target-cam.FieldOfView)*(1-math.exp(-dt*5))
  end
  shieldTrack.Visible=playing and worldState and worldState.stage==10 and worldState.bossPhase~="waiting" and worldState.bossPhase~="broken" or false
  if shieldTrack.Visible then
   shieldFill.Size=UDim2.fromScale(math.clamp((worldState.shieldHP or 0)/(worldState.shieldMax or 1),0,1),1)
   shieldFill.BackgroundColor3=worldState.bossPhase=="exposed" and Color3.fromRGB(230,135,70) or Color3.fromRGB(75,165,220)
   shieldText.Text=worldState.bossPhase=="exposed" and "ЩИТ ОСЛАБЛЕН • ОТКРЫВАЙ ОГОНЬ" or "ЩИТ НЕУЯЗВИМ • ОХРАНА АКТИВНА"
  end
 end)

end
