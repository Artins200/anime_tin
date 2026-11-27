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
assert 'track.TimePosition>=30' in client
assert 'vm = Instance.new' in client and 'local vm\n' in client
assert 'model:PivotTo(origin:Lerp' in server
assert 'if introActive then return end' in server
print('PASS: valid chunk stream, 3 exact embedded scripts, cinematic regressions')
intro = server.split('local function playIntro()', 1)[1].split('-- МАФИОЗИ', 1)[0]
assert intro.count('spawnWave(1,token,info)') == 1
assert intro.count('currentExitDoor=makeExitDoor') == 1
assert 'BriefingLaboratory' in intro and 'BoardingSteps' in intro
assert 'prepareEntrance()' in intro
assert 'hum:MoveTo(target.Position)' in server
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
assert 'if readyClients[player] then selected=player; break end' in server
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
