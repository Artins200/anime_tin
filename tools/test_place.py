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
assert 'OperationsBase' in intro and 'BoardingSteps' in intro
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
