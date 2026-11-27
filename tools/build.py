"""Patch only the three source properties; preserve every other RBXL chunk."""
from pathlib import Path
import struct
from rbxl import chunks, string, enc
# Keep the standalone chapter source and embedded server in sync.
chapter_path=Path('src/Chapter2.luau')
chapter=chapter_path.read_text()
start=chapter.index('-- BEGIN CAMPAIGN DIRECTOR')
end=chapter.index('-- END CAMPAIGN DIRECTOR',start)
chapter_path.write_text(chapter[:start]+'-- BEGIN CAMPAIGN DIRECTOR\n'+Path('src/Chapter2Campaign.luau').read_text()+'\n'+chapter[end:])
server_path=Path('src/Script_0.luau')
server=server_path.read_text()
start=server.index('-- BEGIN CHAPTER TWO')
end=server.index('-- END CHAPTER TWO',start)
server_path.write_text(server[:start]+'-- BEGIN CHAPTER TWO\n'+Path('src/Chapter2.luau').read_text()+'\n'+server[end:])
client_path=Path('src/LocalScript_0.luau')
client=client_path.read_text()
start=client.index('-- BEGIN CHAPTER TWO CLIENT')
end=client.index('-- END CHAPTER TWO CLIENT',start)
client_path.write_text(client[:start]+'-- BEGIN CHAPTER TWO CLIENT\n'+Path('src/Chapter2Client.luau').read_text()+'\n'+client[end:])
# Embed chapter III geometry, server and client without changing RBXL objects.
c3path=Path('src/Chapter3.luau')
c3=c3path.read_text()
a=c3.index('-- BEGIN CHAPTER THREE WORLD'); b=c3.index('-- END CHAPTER THREE WORLD',a)
c3path.write_text(c3[:a]+'-- BEGIN CHAPTER THREE WORLD\n'+Path('src/Chapter3World.luau').read_text()+'\n'+c3[b:])
for destination,source,begin,end in [
 ('src/Script_0.luau','src/Chapter3.luau','-- BEGIN CHAPTER THREE','-- END CHAPTER THREE'),
 ('src/LocalScript_0.luau','src/Chapter3Client.luau','-- BEGIN CHAPTER THREE CLIENT','-- END CHAPTER THREE CLIENT')]:
 text=Path(destination).read_text(); a=text.index(begin+'\n'); b=text.index('\n'+end+'\n',a)
 Path(destination).write_text(text[:a]+begin+'\n'+Path(source).read_text()+text[b:])
path=Path('Place1.rbxl')
data=path.read_bytes(); out=bytearray(data[:32]); count=0
sources={41:'src/LocalScript_0.luau',47:'src/ModuleScript_0.luau',61:'src/Script_0.luau'}
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
