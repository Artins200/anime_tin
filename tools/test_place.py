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
