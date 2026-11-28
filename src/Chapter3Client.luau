-- Chapter III HUD, binocular overlay and authoritative three-phase terminal UI.
do
 local remote=Remotes:WaitForChild("Chapter3")
 local state; local challenge
 local hud=new("ScreenGui",{Name="Chapter3HUD",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=45,Enabled=false},plr.PlayerGui)
 local objective=new("TextLabel",{Size=UDim2.new(0.74,0,0,82),Position=UDim2.new(0.13,0,0,112),BackgroundColor3=Color3.fromRGB(17,26,42),BackgroundTransparency=0.12,TextColor3=Color3.fromRGB(220,230,240),TextSize=16,TextWrapped=true,Font=Enum.Font.GothamBold},hud)
 local stamina=new("Frame",{Size=UDim2.fromOffset(180,9),Position=UDim2.new(0,30,1,-108),BackgroundColor3=Color3.fromRGB(30,40,55)},hud)
 local fill=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(85,185,175),BorderSizePixel=0},stamina)
 local scope=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=0.3,Visible=false},hud)
 new("TextLabel",{Size=UDim2.fromScale(0.6,0.12),Position=UDim2.fromScale(0.2,0.8),Text="ОПТИКА  ×12  •  СИГНАЛ С ВЕРШИНЫ",TextColor3=Color3.fromRGB(175,220,190),TextSize=22,BackgroundTransparency=1},scope)
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
   local progress=("Волна %d/%d  •  угрозы %d  •  реле %d/4"):format(data.wave,data.rounds,data.enemies,data.relays)
   objective.Text=("III • %s\n%s\n%s"):format(data.name,data.task or "Продвигайтесь к цели",progress)
   if data.cleared then
    local status=data.objective and "Шлюз открыт • соберитесь у выхода" or "Зона зачищена"
    objective.Text=("III • %s\n%s\n%s"):format(data.name,data.task or status,status)
   end
   return
  end
  if action=="hack" then hud.Enabled=true; draw(data); return end
  if action=="hackClose" then close(false); return end
  if action=="binocular" then hud.Enabled=true; scope.Visible=data; return end
  if action=="signal" then
   hud.Enabled=true; flash.BackgroundColor3=Color3.fromRGB(210,220,225); flash.BackgroundTransparency=0.65; TweenService:Create(flash,TweenInfo.new(0.8),{BackgroundTransparency=1}):Play()
   local s=new("Sound",{SoundId="rbxasset://sounds/electronicpingshort.wav",Volume=0.18,PlaybackSpeed=1.2},SoundService); s:Play(); Debris:AddItem(s,2); return
  end
  if action=="aim" then
   hud.Enabled=true; flash.BackgroundColor3=Color3.fromRGB(244,157,94); flash.BackgroundTransparency=0.9
   TweenService:Create(flash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
   task.delay(0.55,function() if flash.Parent then flash.BackgroundColor3=Color3.fromRGB(210,220,225) end end)
   return
  end
  if action=="nonlethal" then
   hitmark.TextColor3=Color3.fromRGB(100,220,170); hitmark.TextTransparency=0
   TweenService:Create(hitmark,TweenInfo.new(0.3),{TextTransparency=1}):Play(); return
  end
  if action=="grab" then -- local damage feedback
   flash.BackgroundColor3=Color3.fromRGB(145,65,70); flash.BackgroundTransparency=0.85; TweenService:Create(flash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play(); return
  end
  if action=="collect" then objective.Text="СИГНАЛ ОТКЛЮЧЕН\nЗаберите контроллер и память из кейса"; return end
  if action=="signalOff" then close(false); scope.Visible=false; return end
  if action=="credits" then
   hud.Enabled=not data
   showCredits(data)
   if data and creditsText then creditsText.Text="Уничтожь Тянку 3\n\nГЛАВА III\nБашня Нейро-Сингулярности\n\nСигнал остановлен\nМодули сохранены\n\nНо Кириллу всё ещё нужна помощь\n\nПродолжение следует\n\nСпасибо за игру" end
   return
  end
  if action=="clear" then close(false); hud.Enabled=false; state=nil; scope.Visible=false; return end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if plr:GetAttribute("Chapter")~=3 then return end
  if challenge and input.KeyCode==Enum.KeyCode.Escape then close(true); return end
  if challenge and input.KeyCode==Enum.KeyCode.Space and challenge.phase==1 then submit(); return end
  if not processed and not cutsceneActive and not engineeringActive and (input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift) then remote:FireServer("sprint",true) end
 end)
 UIS.InputEnded:Connect(function(input) if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then remote:FireServer("sprint",false) end end)
 UIS.WindowFocusReleased:Connect(function() remote:FireServer("sprint",false) end)
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
