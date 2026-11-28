"""Structural regression tests. Does not simulate the Roblox engine."""
import struct
from pathlib import Path
from rbxl import chunks, string

parts = list(chunks(Path('Place1.rbxl').read_bytes()))
assert parts[-1][0] == b'END\0'
expected = {41: 'LocalScript', 47: 'ModuleScript', 61: 'Script'}
found = set()
for tag, raw, _ in parts:
    if tag != b'PROP':
        continue
    cid = struct.unpack_from('<I', raw)[0]
    name, p = string(raw, 4)
    if name == 'Source' and cid in expected:
        assert raw[p] == 1
        text, end = string(raw, p + 1)
        assert end == len(raw)
        assert text == Path(f'src/{expected[cid]}_0.luau').read_text()
        found.add(cid)
assert found == set(expected)
server = Path('src/Script_0.luau').read_text()
client = Path('src/LocalScript_0.luau').read_text()
assert 'knockPlayer(char, 0, 30)' not in server
assert 'pickup_other  = "Realistic Gun shot"' in client
assert 'track.TimePosition>=30' not in client
assert 'vm = Instance.new' in client and 'local vm\n' in client
assert 'model:PivotTo(origin:Lerp' in server
assert 'if introActive then return end' in server
forest=server.split('local function buildForest(f)',1)[1].split('local RoomCfg',1)[0]
assert 'Vector3.new(0.2,5,7), Vector3.new(-W/2+0.65,6,0)' in forest
assert 'Vector3.new(7,5,0.2), Vector3.new(0,6,-W/2+0.6)' not in forest
assert 'local function makeExitDoor(cf, openingWidth, openingHeight)' in server
assert 'local width = openingWidth or (currentLevel == 1 and 6 or 10)' in server
assert 'local height = openingHeight or (currentLevel == 1 and 8 or 10)' in server
place=server.split('local function placePlayer(plr, idx)',1)[1].split('local function placeAll()',1)[0]
assert 'workspace:Raycast(target.Position+Vector3.new(0,5,0),Vector3.new(0,-32,0),params)' in place
assert 'hit.Position.Y+3' in place
assert 'KickRE.OnServerEvent:Connect' in server and 'AttackRE.OnServerEvent:Connect' in server
assert 'sessionStarted=true; sessionSize=#party' in server
print('PASS: forest exit is clear, exit doors match openings, spawns ground correctly; server interaction/combat/session handlers exist')
print('PASS: valid chunk stream, 3 exact embedded scripts, cinematic regressions')
intro = server.split('local function playIntro()', 1)[1].split('-- МАФИОЗИ', 1)[0]
assert intro.count('spawnWave(1,token,info)') == 1
assert intro.count('currentExitDoor=makeExitDoor') == 1
assert 'BriefingLaboratory' in intro and 'BoardingSteps' in intro
assert 'prepareEntrance()' in intro
assert 'local duration=math.max(distance/(speedOverride or 12),0.12)' in server
assert 'obstacle.Normal.Y<0.5 and not ignoreStepFaces' in server
assert 'floor.Position.Y+clearance' in server
assert 'root.Anchored=wasAnchored' in server
assert 'entranceUsed=true -- consume before yielding' in server
assert 'return -- entrance breach never advances the level' in server
assert 'cabinFloor.CanCollide=true' in server
assert 'boardingRamp.CanCollide=true' in server
assert 'action == "follow"' in client
assert 'shotDuration<=0 and 1' in client
assert 'unobstructedCamera' in client
assert 'CinematicKick' in client and 'CinematicSeated' in client
print('PASS: one intro wave/exit, separate one-use breach, physical walking, cabin collision, camera and poses')

assert 'baseOffset=Vector3.new(2000,0,0)' in intro
assert 'base:PivotTo(CFrame.new(baseOffset)*base:GetPivot())' in intro
assert 'area.Face=Enum.NormalId.Bottom' in server
assert 'area.Shadows=false' in server
assert 'Build=buildLaboratory' in server
assert 'buildForest(nil)' not in server and 'buildRoom(nil' not in server
assert 'local spots=activeLevelInfo.GetSpots(count)' in server
mafia=server.split('local function playMafioziScene()',1)[1].split('local function playPlaneScene()',1)[0]
assert mafia.index('sceneLock(true)') < mafia.index('clearLevel()')
assert 'local factory=buildConversionFactory()' in mafia
assert 'currentSpawn=factory.Spawn' in mafia
plane=server.split('local function playPlaneScene()',1)[1].split('function startBase()',1)[0]
assert plane.index('sceneLock(true)') < plane.index('clearLevel()')
assert 'planeRide:Disconnect()' in plane
assert 'introActive = false' not in plane
assert 'if introActive then\n     hrp.Anchored=true' in server
print('PASS: separate briefing map, lit laboratory, retained wave geometry, supported/anchored cinematic transitions')
# Lighting additions are intentionally scoped to the starting briefing map.
assert server.count('briefingLight(') == 2  # helper definition + base-only loop
briefing_fixture=server.split('local function briefingLight(',1)[1].split('local function anchorAll',1)[0]
assert 'Enum.Material.Neon' not in briefing_fixture
assert 'PointLight' not in briefing_fixture and 'fill=light' not in briefing_fixture
assert 'area.Brightness=0.65' in briefing_fixture
room=server.split('local function buildRoom(',1)[1].split('local function buildLaboratory(',1)[0]
assert 'if (ix + iz) % 2 == 0 then light(lp' in room
assert 'briefingLight' not in room and 'SurfaceLight' not in room
combat_lab=server.split('local function buildLaboratory(',1)[1].split('-- БАЗА',1)[0]
assert 'ceilingLight(' not in combat_lab and 'briefingLight(' not in combat_lab
assert 'Enum.Material.Neon' not in combat_lab
assert 'ExposureCompensation=0' not in server.split('-- BEGIN CHAPTER THREE\n')[0]
assert 'Lighting.ExposureCompensation=0.03' in server
print('PASS: soft non-neon briefing-only lighting; original combat-room lighting restored')
# Black-screen regressions: readiness ordering, bounded preparation and error cleanup.
assert client.rfind('FireServer("ready")') > client.index('Remotes.Fade.OnClientEvent')
assert 'if not member.Parent or not readyClients[member]' in server
assert 'xpcall(function() startChapter2(party) end,debug.traceback)' in server
assert 'else runScene(playIntro) end' in server
assert 'local ok,err=xpcall(callback,debug.traceback)' in server
assert 'CutsceneRE:FireAllClients("recover")' in server
assert 'until os.clock()>=deadline' in server
assert 'plr:RequestStreamAroundAsync(frame,5)' in client
assert 'Remotes.SceneReady:FireServer("prepared",duration)' in client
assert 'if fadeTween then fadeTween:Cancel() end' in client
assert 'task.delay(20,function()' in client
assert 'generation==controlGeneration' in client
assert 'action=="cam"' in client
assert '1-math.exp(-dt*followSmooth)' in client
assert 'moveModel(entrance,closedDoor*CFrame.new(0,9.5,0),1.8)' in intro
print('PASS: client-ready startup, bounded streaming, fade watchdog/cancellation, recovery and camera plans')

finale=server.split('function startBase()',1)[1].split('-- KICK',1)[0]
assert 'local baseInfo=buildBase(levelFolder)' in finale
assert 'Types.Mafiozi' not in finale
assert 'CutsceneRE:FireAllClients("pov",maf.Head)' in mafia
assert 'CutsceneRE:FireAllClients("pov",ally.Head)' in finale
assert 'CutsceneRE:FireAllClients("pov",android.Head,44)' in finale
assert 'mafHum.Health=0' in mafia
assert 'moveModel(ally,CFrame.lookAt(allyCF.Position' in finale
assert 'visorWeld.Part0=android.Head' in finale
assert 'CutsceneRE:FireAllClients("blaster",true)' in mafia
assert 'Копирование боевых данных и опыта' in client
assert 'Remotes.SceneReady:FireServer("scanDone",data.id)' in client
assert 'Remotes.SceneReady:FireServer("black",frame)' in client
assert finale.index('"scan",{') < finale.index('awaitFinalAck(scanAcknowledged')
assert finale.index('awaitFinalAck(scanAcknowledged') < finale.index('"blackout",id')
assert finale.index('"blackout",id') < finale.index('awaitFinalAck(blackAcknowledged') < finale.index('CreditsRE:FireAllClients(true)')
assert server.count('CreditsRE:FireAllClients(true)') == 1
music_handler=client.split('Remotes.Music.OnClientEvent:Connect',1)[1].split('Remotes.Credits.OnClientEvent',1)[0]
assert 'showCredits' not in music_handler and 'task.spawn' not in music_handler
assert 'bg.BackgroundTransparency = 0' in client
assert 'fadeGeneration~=generation or endingBlack' in client
assert 'forceFinalBlack()' in client
assert 'SceneBlaster' in client and 'ImpulseBlaster' in client
assert 'firstPersonForward' in client
assert 'cam.CFrame.Rotation:Lerp(goal.Rotation,1-math.exp(-dt*5))' in client
assert 'if oldFloor then oldFloor:Destroy() end' in server
assert 'p.Reflectance=0' in server
assert 'maf:Destroy()' in mafia
assert 'Vector3.new(70,0.285,65)' in server
assert 'Enum.HumanoidStateType.Freefall,not on' in server
factory=server.split('buildConversionFactory=function()',1)[1].split('local function buildProductionEpilogue()',1)[0]
for fixture in ['FactoryFloor','FrontWall','SideWall','Roof','EntranceWall','CorridorEnd','ServerRack','ConveyorBelt','FactoryLamp','EmergencyLamp','StorageCrate']:
 assert fixture in factory
assert 'Vector3.new(72,1,80)' in factory
assert 'Vector3.new(0,3.2,-18)' in factory
assert 'ANDROID_NAME="Нейро"' in server
assert 'нашу базу на Дальнем Востоке полностью разрушили' in finale
assert 'hum.Health=0' in finale  # the restored attack really kills the player
assert 'mafHum.BreakJointsOnDeath=false; mafHum.Health=0' in mafia
assert 'moveModel(maf,hitCF*CFrame.new' in mafia
print('PASS: active-NPC POV, pulse/deactivation, ally turn, visor, scan/black acknowledgements, credits only at end')

assert 'local LobbyRE=newRemote("Lobby")' in server
assert 'options.ShouldReserveServer=true' in server
assert 'TeleportService:TeleportAsync(game.PlaceId,party,options)' in server
assert 'if lobby and membership[player]==player.UserId then launch' in server
assert '#lobby.members<4' in server
assert 'hum.MaxHealth*=2' in server
assert 'buildEvidenceTerminal(info,n)' in server
assert 'evidenceCollected[player.UserId]=true' in server
assert 'local STORIES={' in server and '[4]={name="ПРОТОКОЛ СВИДЕТЕЛЬ"' in server
assert 'MusicRE:FireAllClients("finalSlow")' in finale
assert finale.index('MusicRE:FireAllClients("stop")') < finale.index('local baseInfo=buildBase')
assert 'TweenInfo.new(8,Enum.EasingStyle.Sine),{Volume=0.5}' in client
assert 'CutsceneRE:FireAllClients("recon",board,recon)' in intro
assert 'local view=new("ViewportFrame"' in client
assert 'cameraPlan(basePoint' not in intro
assert 'MissionMenu' in client and 'lobbyRemote:FireServer("join",lobby.owner)' in client
assert 'conversationalSubtitle(text)' in client
assert server.count(chr(0x2014)) == 2  # exact requested car and Neuro dialogue
assert 'так — всё довольно плачевно' in server
assert client.count(chr(0x2014)) == 2  # compact sprint HUD, not narrative sanitizer output
print('PASS: coop/menu retained, original combat lighting retained, enclosed factory, separated floor elevations and subtitle policy')

assert 'local function sceneLine(text,minimum)' in server
assert '(utf8.len(text) or #text)*0.045+2' in server
assert 'sceneLine(story().office,6)' in mafia
assert 'sceneLine("Стой, не стреляй. Я сдаюсь, я все расскажу.",5)' in mafia
assert 'task.wait(4)' in mafia
assert 'hitCF*CFrame.new(7,-1.8,1)' in mafia
assert 'Vector3.new(0,3,-12)' not in finale  # no close-up approach to the victim
assert 'Vector3.new(0,3,8)' in finale
assert 'TweenInfo.new(0.7,Enum.EasingStyle.Linear),{Position=head.Position}' in finale
assert finale.index('hum.Health=0') < finale.index('local horde=buildHordeStage()')
assert finale.index('local horde=buildHordeStage()') < finale.index('local production,captive,shutter,arm=buildProductionEpilogue()')
assert finale.index('local production,captive,shutter,arm=buildProductionEpilogue()') < finale.index('"blackout",id')
assert 'awaitFinalAck(armyAcknowledged,id,10)' in finale
assert 'Remotes.SceneReady:FireServer("armyDone",token)' in client
assert 'player.ReplicationFocus=focus' in server
assert 'player.ReplicationFocus=nil' in server
assert 'TyanProductionPlant' in server
assert 'ConversionShutter' in server
assert 'if action=="reveal" then' in client
assert 'setSceneFov(typeof(duration)=="number" and duration or 58,0.6)' in client
print('PASS: readable mafia pacing, visible fatal attack at distance, horde then production insert before final blackout, streaming focus/reveal')

# A factory-owned antagonist must never be recreated at the home base.
assert 'maf.Parent=factory.Model' in mafia
assert 'maf:SetAttribute("FactoryAntagonist",true)' in mafia
assert 'maf:Destroy()' in mafia
assert 'buildConversionFactory()' not in finale
assert finale.index('local ally=buildRig') < finale.index('local androidCfg=')
assert finale.index('for _,lamp in ipairs(factory.Lamps)') < finale.index('local androidCfg=')
assert 'playSecretScene()' in finale and 'returnToMenu()' in finale
assert 'startLevel(1)' not in finale
assert finale.index('CreditsRE:FireAllClients(true)') < finale.index('playSecretScene()') < finale.index('returnToMenu()')
secret=server.split('local function playSecretScene()',1)[1].split('function startBase()',1)[0]
for prop in ['PostCreditsRoom','Floor','Wall','Ceiling','SofaBase','Television','TVStatic','Lamp']:
 assert prop in secret
assert 'secretActor(room,"eurtyoeyrntiu","Артем"' in secret
assert 'secretActor(room,"ZamestitelDiomchica","Демид"' in secret
actor_loader=server.split('local function secretActor(',1)[1].split('local function playSecretScene()',1)[0]
assert 'ServerStorage:FindFirstChild(sourceName)' in actor_loader
assert 'return source:Clone()' in actor_loader
assert 'object.Disabled=true' in actor_loader
assert 'rig:SetAttribute("Placeholder",true)' in actor_loader
assert secret.index('FadeRE:FireAllClients(true') < secret.index('room:Destroy()')
reset=server.split('returnToMenu=function()',1)[1]
assert 'sessionRoster=nil; rosterWaitStart=nil; hasFinishedSession=true' in reset
assert 'table.clear(lobbies); table.clear(membership); table.clear(launching)' in reset
assert 'LobbyRE:FireAllClients("menu")' in reset
assert 'currentSpawn=CFrame.new(0,4,0)' in reset
assert 'if command=="menu" then showMainMenu(); return end' in client
assert 'local function showMainMenu()' in client
assert 'Text=GAME_TITLE' in client
assert 'Уничтожь Тянку 3' in client and 'Уничтожь Тянку 3' in server
assert 'SECTOR 7  /  ОПЕРАЦИЯ' not in client and 'КАРТЕЛЬ ТЯНОК: КОНЕЦ?' not in client

import re
expected=[
 ('Артем','Мда, им вроде за это платят, да? Каким образом андроиды, которых мы в свое время легко контрили, так сильно переигрывают компанию, спонсируемую государством, которая как раз и создана для борьбы с ними?'),
 ('Демид','Ага, есть такое. Я думаю, что они не справятся. Нам нужно вернуться в старые добрые и поставить их на место, согласен?'),
 ('Артем','Ага, думаю, хорошая идея, а то они что-то совсем попутали.'),
 ('Демид','Короче, выдвигаемся помогать уже завтра. Так что нам нужно потренироваться и вспомнить скилл, согласен?'),
 ('Артем','Хах, ну хорошо. С чего начнем? С тренировочной площадки или с чего-то еще?'),
 ('Демид','Лучше давай заходим в Blade Ball быстрее, а то у нас всего лишь одна ночь, чтобы вспомнить скилл.'),
]
block=server.split('local SECRET_DIALOGUE={',1)[1].split('local function secretActor',1)[0]
assert re.findall(r'\{name="([^"]+)",text="([^"]+)"\}',block)==expected
literal=client.split('if action=="dialogue" then',1)[1].split('if action=="reveal"',1)[0]
assert 'sub.Text=frame.text' in literal and 'conversationalSubtitle' not in literal
print('PASS: factory-only boss destroyed, clean base return, literal six-line secret scene, optional supplied rigs, reusable main menu reset')

# Campaign fixes: no early factory reveal, isolated archive participants, real role perks and SFX.
for story_id in ('[1]={name="ОДИНОЧНЫЙ СЛЕД"', '[2]={name="ДВОЙНОЙ СИГНАЛ"', '[3]={name="ТРЕТИЙ КАНАЛ"', '[4]={name="ПРОТОКОЛ СВИДЕТЕЛЬ"'):
 assert story_id in server
stories=server.split('local STORIES={',1)[1].split('\n}',1)[0]
assert 'Конечный адрес пока скрыт' in stories
assert 'Конечный адрес пока зашифрован' in stories
assert 'завод' not in stories.split('[1]=',1)[1].split('[2]=',1)[0]
assert 'мафиози работал на завод' not in stories
assert 'local function isSessionMember(player)' in server
archive=server.split('local function unlockDoor()',1)[1].split('------------------------------------------------------------------ ЛЕС',1)[0]
assert 'isSessionMember(player)' in archive
assert 'not isSessionMember(player)' in archive
assert 'PowerOff = "rbxasset://sounds/electronicpingshort.wav"' in server
assert 'Punch = "rbxasset://sounds/swordslash.wav"' in server
assert 'playSound(SOUNDS.Punch, e.Hrp, 0.35)' in server
assert 'local damageScale = role == "Штурм" and 1.15 or 1' in server
assert 'local rangeScale = role == "Разведка" and 1.2 or 1' in server
assert 'local cooldownScale = role == "Связь" and 0.85 or 1' in server
assert 'local knockScale = role == "Свидетель" and 1.25 or 1' in server
print('PASS: chapter I spoiler gating, session-only archive collection, implemented role perks and non-empty combat audio')
