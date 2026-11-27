"""Patch only the three source properties; preserve every other RBXL chunk."""
from pathlib import Path
import struct
from rbxl import chunks, string, enc
path=Path('Place1.rbxl')
data=path.read_bytes(); out=bytearray(data[:32]); count=0
sources={31:'src/LocalScript_0.luau',36:'src/ModuleScript_0.luau',47:'src/Script_0.luau'}
for tag,raw,res in chunks(data):
 if tag==b'PROP':
  cid=struct.unpack_from('<I',raw)[0]; name,p=string(raw,4)
  if name=='Source' and cid in sources:
   assert raw[p]==1
   raw=raw[:p+1]+enc(Path(sources[cid]).read_text()); count+=1
 out+=struct.pack('<4sIII',tag,0,len(raw),res)+raw
assert count==3
# Validate complete roundtrip before replacing the place.
assert list(chunks(bytes(out)))[-1][0]==b'END\x00'
path.write_bytes(out)
print(f'Built {path}: {len(out)} bytes; {count} scripts embedded')
