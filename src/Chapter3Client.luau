-- Chapter III HUD, binocular overlay and authoritative three-phase terminal UI.
do
 local remote=Remotes:WaitForChild("Chapter3")
 local debugRemote=Remotes:WaitForChild("DebugTools")
 local debugAccess=Remotes:WaitForChild("DebugAccess")
 local state; local challenge
 local hud=new("ScreenGui",{Name="Chapter3HUD",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=45,Enabled=false},plr.PlayerGui)
 local objective=new("TextLabel",{Size=UDim2.new(0.7,0,0,55),Position=UDim2.new(0.15,0,0,125),BackgroundColor3=Color3.fromRGB(17,26,42),BackgroundTransparency=0.15,TextColor3=Color3.fromRGB(220,230,240),TextSize=17,TextWrapped=true,Font=Enum.Font.GothamBold},hud)
 local stamina=new("Frame",{Size=UDim2.fromOffset(180,9),Position=UDim2.new(0,30,1,-108),BackgroundColor3=Color3.fromRGB(30,40,55)},hud)
 local fill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(85,185,175),BorderSizePixel=0},stamina)
 local towerPanel=new("Frame",{Size=UDim2.new(0,420,0,64),Position=UDim2.new(0.5,-210,1,-92),BackgroundColor3=Color3.fromRGB(17,24,34),BackgroundTransparency=0.12,Visible=false},hud)
 local towerTitle=new("TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="РАДИОБАШНЯ НЕЙРО",TextColor3=Color3.fromRGB(235,225,215),TextSize=16,Font=Enum.Font.GothamBold},towerPanel)
 local towerBack=new("Frame",{Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,34),BackgroundColor3=Color3.fromRGB(56,35,42),BorderSizePixel=0},towerPanel)
 local towerFill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(205,63,65),BorderSizePixel=0},towerBack)
 local escapeClock=new("TextLabel",{Size=UDim2.fromOffset(310,58),Position=UDim2.new(0.5,-155,0,110),BackgroundColor3=Color3.fromRGB(70,21,27),BackgroundTransparency=0.12,TextColor3=Color3.fromRGB(255,231,217),TextSize=34,Font=Enum.Font.GothamBlack,Text="03:00",Visible=false},hud)
 local debugGui=new("ScreenGui",{Name="Chapter3DebugMenu",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100,Enabled=false},plr.PlayerGui)
 local debugPanel=new("Frame",{Size=UDim2.fromOffset(420,540),Position=UDim2.new(0.5,-210,0.5,-270),BackgroundColor3=Color3.fromRGB(14,20,30),BackgroundTransparency=0.04},debugGui)
 new("TextLabel",{Size=UDim2.new(1,-20,0,42),Position=UDim2.fromOffset(10,8),BackgroundTransparency=1,Text="F6 • DEBUG / CHAPTER III",TextColor3=Color3.fromRGB(180,220,210),TextSize=20,Font=Enum.Font.GothamBold},debugPanel)
 local debugStatus=new("TextLabel",{Size=UDim2.new(1,-20,0,34),Position=UDim2.fromOffset(10,48),BackgroundTransparency=1,Text="Только Studio или владелец игры",TextColor3=Color3.fromRGB(223,190,150),TextSize=14,TextWrapped=true},debugPanel)
 local debugList=new("ScrollingFrame",{Size=UDim2.new(1,-20,1,-94),Position=UDim2.fromOffset(10,86),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},debugPanel)
 new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},debugList)
 local function debugButton(label,action,value)
  local b=new("TextButton",{Size=UDim2.new(1,-8,0,38),BackgroundColor3=Color3.fromRGB(34,54,67),TextColor3=Color3.fromRGB(230,238,235),TextSize=15,Font=Enum.Font.Gotham,Text=label,AutoButtonColor=true},debugList)
  b.Activated:Connect(function() debugRemote:FireServer(action,value) end)
  return b
 end
 debugButton("Запустить главу III сейчас","start")
 for _,stage in ipairs({1,5,6,10}) do debugButton("Перейти на этап "..stage,"stage",stage) end
 debugButton("Отключить защиту (финальный терминал)","shieldOff")
 debugButton("Сразу к башне снаружи","tower")
 debugButton("Уничтожить башню → сцена Нейро","destroyTower")
 debugButton("Запустить трёхминутный побег","escape")
 debugButton("Тестировать вылет, взрыв и титры","flight")
 local scope=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},hud)
 -- A quiet, transparent reticle keeps the street bright; no opaque mask or zoom label.
 local scopeColor=Color3.fromRGB(190,222,205)
 for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do
  local x=sx<0 and 0.045 or 0.955; local y=sy<0 and 0.06 or 0.94
  local ox=sx<0 and 0 or -26; local oy=sy<0 and 0 or -2
  new("Frame",{Size=UDim2.fromOffset(26,2),Position=UDim2.new(x,ox,y,oy),BackgroundColor3=scopeColor,BackgroundTransparency=0.22,BorderSizePixel=0},scope)
  new("Frame",{Size=UDim2.fromOffset(2,26),Position=UDim2.new(x,sx<0 and 0 or -2,y,sy<0 and 0 or -26),BackgroundColor3=scopeColor,BackgroundTransparency=0.22,BorderSizePixel=0},scope)
 end end
 new("Frame",{Size=UDim2.fromOffset(14,2),Position=UDim2.new(0.5,-7,0.5,-1),BackgroundColor3=scopeColor,BackgroundTransparency=0.35,BorderSizePixel=0},scope)
 new("Frame",{Size=UDim2.fromOffset(2,14),Position=UDim2.new(0.5,-1,0.5,-7),BackgroundColor3=scopeColor,BackgroundTransparency=0.35,BorderSizePixel=0},scope)
 new("Frame",{Size=UDim2.fromOffset(3,3),Position=UDim2.new(0.5,-1.5,0.5,-1.5),BackgroundColor3=scopeColor,BackgroundTransparency=0.05,BorderSizePixel=0},scope)
 local flash=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(210,220,225),BackgroundTransparency=1,ZIndex=40},hud)
 local terminal=new("Frame",{Size=UDim2.fromScale(0.76,0.77),Position=UDim2.fromScale(0.12,0.12),BackgroundColor3=Color3.fromRGB(14,24,38),Visible=false,ZIndex=60},hud)
 local title=new("TextLabel",{Size=UDim2.fromScale(0.86,0.15),Position=UDim2.fromScale(0.04,0.02),TextColor3=Color3.fromRGB(145,215,200),TextSize=23,TextWrapped=true,BackgroundTransparency=1,ZIndex=61},terminal)
 local body=new("Frame",{Size=UDim2.fromScale(0.9,0.62),Position=UDim2.fromScale(0.05,0.2),BackgroundTransparency=1,ZIndex=61},terminal)
 local help=new("TextLabel",{Size=UDim2.fromScale(0.9,0.14),Position=UDim2.fromScale(0.05,0.84),TextColor3=Color3.fromRGB(180,200,215),TextSize=17,TextWrapped=true,BackgroundTransparency=1,ZIndex=61},terminal)
 local function close(send)
  if send and challenge then remote:FireServer("cancel") end
  challenge=nil; terminal.Visible=false; engineeringActive=false
  if not cutsceneActive and not menu.Enabled then setSceneControls(true); UIS.MouseBehavior=Enum.MouseBehavior.LockCenter; UIS.MouseIconEnabled=false end
 end
 local exit=new("TextButton",{Size=UDim2.fromScale(0.08,0.12),Position=UDim2.fromScale(0.9,0.02),Text="×",TextSize=28,BackgroundTransparency=1,TextColor3=Color3.fromRGB(225,205,200),ZIndex=62},terminal)
 exit.Activated:Connect(function() close(true) end)
 local function submit(value) if challenge then remote:FireServer("hack",challenge.token,value) end end
 local function draw(data)
  challenge=data; terminal.Visible=true; engineeringActive=true; setSceneControls(false); UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
  for _,c in ipairs(body:GetChildren()) do c:Destroy() end
  if data.phase==1 then
   title.Text="I / ПЕРЕХВАТ ЧАСТОТЫ  •  "..data.steps.." / 3"
   help.Text="Нажимай ПРОБЕЛ или кнопку, когда указатель внутри зелёного сектора."
   local track=new("Frame",{Size=UDim2.fromScale(0.9,0.16),Position=UDim2.fromScale(0.05,0.25),BackgroundColor3=Color3.fromRGB(37,51,70),Name="Frequency"},body)
   new("Frame",{Size=UDim2.fromScale(0.32,1),Position=UDim2.fromScale(0.3,0),BackgroundColor3=Color3.fromRGB(45,125,95)},track)
   new("Frame",{Name="Cursor",Size=UDim2.new(0,5,1,0),BackgroundColor3=Color3.fromRGB(245,225,170)},track)
   local b=new("TextButton",{Text="ЗАФИКСИРОВАТЬ",Size=UDim2.fromScale(0.7,0.2),Position=UDim2.fromScale(0.15,0.6),TextSize=22,TextColor3=Color3.fromRGB(220,235,235),BackgroundColor3=Color3.fromRGB(44,90,104)},body)
   b.Activated:Connect(function() submit() end)
  elseif data.phase==2 then
   title.Text="II / ПЕРЕНАПРАВЛЕНИЕ СЕТИ"
   help.Text="Вращай контакты. Соедини вход слева в среднем ряду с выходом справа."
   for i=1,9 do
    local x=(i-1)%3; local y=math.floor((i-1)/3)
    local b=new("TextButton",{Text="",Size=UDim2.fromScale(0.24,0.28),Position=UDim2.fromScale(0.1+x*0.28,y*0.32),BackgroundColor3=Color3.fromRGB(32,53,70)},body)
    local ports=data.board.base[i]; local rotation=data.board.rotations[i]
    for _,edge in ipairs(ports) do do
     local actual=(edge+rotation)%4
     local lines={{0.46,0,0.08,0.55},{0.46,0.46,0.54,0.08},{0.46,0.46,0.08,0.54},{0,0.46,0.55,0.08}}
     local l=lines[actual+1]
     new("Frame",{Position=UDim2.fromScale(l[1],l[2]),Size=UDim2.fromScale(l[3],l[4]),BackgroundColor3=Color3.fromRGB(115,215,180),BorderSizePixel=0},b)
    end end
    b.Activated:Connect(function() submit(i) end)
   end
  else
   title.Text="III / ОТКЛЮЧЕНИЕ ВЕЩАНИЯ"
   help.Text=state and state.coop and "Демид подтверждает размыкатель напротив. Затем Артём отключает передачу. Если напарник выбыл, доступен аварийный одиночный режим." or "Отключи передачу. Реле уже изолированы на нижних ярусах."
   local b=new("TextButton",{Text="ОТКЛЮЧИТЬ БАШНЮ",Size=UDim2.fromScale(0.9,0.3),Position=UDim2.fromScale(0.05,0.3),TextSize=24,TextColor3=Color3.fromRGB(240,225,210),BackgroundColor3=Color3.fromRGB(125,52,67)},body)
   b.Activated:Connect(function() submit() end)
  end
  for _,d in ipairs(body:GetDescendants()) do if d:IsA("GuiObject") then d.ZIndex=62 end end
 end
 remote.OnClientEvent:Connect(function(action,data)
  if action=="state" then
   state=data; hud.Enabled=true
   objective.Text=("III • %s\nВолна %d/%d  |  Угрозы: %d  |  Реле: %d/4"):format(data.name,data.wave,data.rounds,data.enemies,data.relays)
   if data.cleared then objective.Text="III • "..data.name..(data.stage==10 and "\nВзломайте главный терминал" or data.objective and "\nСоберитесь у следующего шлюза" or "\nОтключите панель у шлюза") end
   return
  end
  if action=="hack" then hud.Enabled=true; draw(data); return end
  if action=="hackClose" then close(false); return end
  if action=="binocular" then hud.Enabled=true; scope.Visible=data; return end
  if action=="signal" then
   hud.Enabled=true; flash.BackgroundTransparency=0.65; TweenService:Create(flash,TweenInfo.new(0.8),{BackgroundTransparency=1}):Play()
   local s=new("Sound",{SoundId="rbxasset://sounds/electronicpingshort.wav",Volume=0.18,PlaybackSpeed=1.2},SoundService); s:Play(); Debris:AddItem(s,2); return
  end
  if action=="grab" then -- local damage feedback
   flash.BackgroundColor3=Color3.fromRGB(145,65,70); flash.BackgroundTransparency=0.85; TweenService:Create(flash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play(); return
  end
  if action=="collect" then objective.Text="СИГНАЛ ОТКЛЮЧЕН\nЗаберите контроллер и память из кейса"; return end
  if action=="signalOff" then close(false); scope.Visible=false; return end
  if action=="towerBattle" then towerPanel.Visible=true; towerFill.Size=UDim2.fromScale(1,1); return end
  if action=="towerHealth" then
   local ratio=math.clamp((data.health or 0)/math.max(data.maxHealth or 1,1),0,1)
   towerPanel.Visible=true; towerFill.Size=UDim2.fromScale(ratio,1); towerTitle.Text=("РАДИОБАШНЯ НЕЙРО • %d%%"):format(math.floor(ratio*100+0.5)); return
  end
  if action=="towerDestroyed" then towerPanel.Visible=false; towerTitle.Text="РАДИОБАШНЯ УНИЧТОЖЕНА"; return end
  if action=="escapeStart" then escapeClock.Visible=true; escapeClock.Text="03:00"; return end
  if action=="escapeTick" then
   local seconds=math.max(0,tonumber(data) or 0)
   escapeClock.Visible=true; escapeClock.Text=string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
   escapeClock.TextColor3=seconds<=30 and Color3.fromRGB(255,90,70) or Color3.fromRGB(255,231,217); return
  end
  if action=="escapeClear" then escapeClock.Visible=false; towerPanel.Visible=false; return end
  if action=="credits" then
   hud.Enabled=not data
   showCredits(data)
   if data and creditsText then creditsText.Text="Уничтожь Тянку 3\n\nГЛАВА III\nБашня Нейро-Сингулярности\n\nСигнал остановлен\nМодули сохранены\n\nНо Кириллу всё ещё нужна помощь\n\nПродолжение следует\n\nСпасибо за игру" end
   return
  end
  if action=="clear" then close(false); hud.Enabled=false; state=nil; scope.Visible=false; towerPanel.Visible=false; escapeClock.Visible=false; return end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if plr:GetAttribute("Chapter")~=3 then return end
  if challenge and input.KeyCode==Enum.KeyCode.Escape then close(true); return end
  if challenge and input.KeyCode==Enum.KeyCode.Space and challenge.phase==1 then submit(); return end
  if not processed and not cutsceneActive and not engineeringActive and (input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift) then remote:FireServer("sprint",true) end
 end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then remote:FireServer("sprint",false) end end)
 UIS.WindowFocusReleased:Connect(function() remote:FireServer("sprint",false) end)
 debugRemote.OnClientEvent:Connect(function(action,message)
  if action=="error" then debugStatus.Text=tostring(message); debugStatus.TextColor3=Color3.fromRGB(255,130,120) end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if input.KeyCode~=Enum.KeyCode.F6 then return end
  debugGui.Enabled=not debugGui.Enabled
  if debugGui.Enabled then
   local ok,allowed=pcall(function() return debugAccess:InvokeServer() end)
   if ok and allowed then
    debugStatus.Text="Доступ разрешён • кнопки управляются сервером"
    debugStatus.TextColor3=Color3.fromRGB(150,225,175)
   else
    debugStatus.Text="Нет доступа. Меню работает только в Studio или у владельца игры."
    debugStatus.TextColor3=Color3.fromRGB(255,130,120)
   end
  end
 end)
 RunService.RenderStepped:Connect(function(dt)
  if plr:GetAttribute("Chapter")~=3 then return end
  local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
  if hum and hum.Health<=0 and not cutsceneActive then
   for _,other in ipairs(Players:GetPlayers()) do
    local oh=other.Character and other.Character:FindFirstChildOfClass("Humanoid"); local head=other.Character and other.Character:FindFirstChild("Head")
    if other~=plr and oh and oh.Health>0 and head then cam.CameraType=Enum.CameraType.Scriptable; cam.CFrame=head.CFrame; break end
   end
  elseif hum and hum.Health>0 and not cutsceneActive and not engineeringActive then cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=hum end
  objective.Visible=state~=nil and not cutsceneActive
  stamina.Visible=not cutsceneActive
  fill.Size=UDim2.fromScale((plr:GetAttribute("SprintStamina") or 100)/100,1)
  if not cutsceneActive and not engineeringActive then local target=plr:GetAttribute("IsSprinting") and 76 or 70; cam.FieldOfView+=(target-cam.FieldOfView)*(1-math.exp(-dt*5)) end
  if challenge and challenge.phase==1 then
   local track=body:FindFirstChild("Frequency"); if track then track.Cursor.Position=UDim2.fromScale((workspace:GetServerTimeNow()-challenge.start)*0.35%1,0) end
  end
 end)
end
