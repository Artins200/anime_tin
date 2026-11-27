"""Structural regression tests. Does not simulate the Roblox engine."""
import struct
from pathlib import Path
from rbxl import chunks, string

parts = list(chunks(Path('Place1.rbxl').read_bytes()))
assert parts[-1][0] == b'END\0'
expected = {31: 'LocalScript', 36: 'ModuleScript', 47: 'Script'}
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
print('PASS: valid chunk stream, 3 exact embedded scripts, cinematic regressions')
intro = server.split('local function playIntro()', 1)[1].split('-- МАФИОЗИ', 1)[0]
assert intro.count('spawnWave(1,token,info)') == 1
assert intro.count('currentExitDoor=makeExitDoor') == 1
assert 'BriefingLaboratory' in intro and 'BoardingSteps' in intro
assert 'prepareEntrance()' in intro
assert 'local duration=math.max(distance/12,0.12)' in server
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
assert 'Vector3.new(44,2,60)' in mafia  # support includes the Z=20 entrance spawn
assert 'currentSpawn=CFrame.lookAt(Vector3.new(0,3.2,20)' in mafia
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
assert 'ExposureCompensation=0' not in server
print('PASS: soft non-neon briefing-only lighting; original combat-room lighting restored')
# Black-screen regressions: readiness ordering, bounded preparation and error cleanup.
assert client.rfind('FireServer("ready")') > client.index('Remotes.Fade.OnClientEvent')
assert 'if not member.Parent or not readyClients[member]' in server
assert 'runScene(playIntro)' in server
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
assert 'buildConversionFactory()' in finale
assert 'CutsceneRE:FireAllClients("pov",boss.Head)' in finale
assert 'CutsceneRE:FireAllClients("pov",ally.Head)' in finale
assert 'CutsceneRE:FireAllClients("pov",android.Head,44)' in finale
assert 'bossHum.Health=0' in finale
assert 'moveModel(ally,CFrame.lookAt(allyCF.Position' in finale
assert 'visorWeld.Part0=android.Head' in finale
assert 'CutsceneRE:FireAllClients("blaster",true)' in finale
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
assert 'Vector3.new(0, -0.38, 0)' in server
assert 'Vector3.new(70,0.285,65)' in server
assert 'Enum.HumanoidStateType.Freefall,not on' in server
factory=server.split('local function buildConversionFactory()',1)[1].split('-- Rename this constant',1)[0]
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
assert finale.index('MusicRE:FireAllClients("stop")') < finale.index('local factory=buildConversionFactory')
assert 'TweenInfo.new(8,Enum.EasingStyle.Sine),{Volume=0.5}' in client
assert 'CutsceneRE:FireAllClients("recon",board,recon)' in intro
assert 'local view=new("ViewportFrame"' in client
assert 'cameraPlan(basePoint' not in intro
assert 'MissionMenu' in client and 'lobbyRemote:FireServer("join",lobby.owner)' in client
assert 'conversationalSubtitle(text)' in client
assert chr(0x2014) not in server and chr(0x2014) not in client
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
