import struct,lz4.block,zstandard
from pathlib import Path

def chunks(data):
 p=32
 while p<len(data):
  tag,cl,ul,res=struct.unpack_from('<4sIII',data,p); p+=16
  raw=data[p:p+(cl or ul)]; p+=cl or ul
  if cl: raw=zstandard.ZstdDecompressor().decompress(raw) if raw[:4]==b'\x28\xb5\x2f\xfd' else lz4.block.decompress(raw,uncompressed_size=ul)
  yield tag,raw,res

def string(b,p):
 n=struct.unpack_from('<I',b,p)[0]; return b[p+4:p+4+n].decode(),p+4+n

def enc(s):
 b=s.encode(); return struct.pack('<I',len(b))+b

if __name__=='__main__':
 classes={}
 for tag,b,_ in chunks(Path('Place1.rbxl').read_bytes()):
  if tag==b'INST':
   cid=struct.unpack_from('<I',b)[0]; name,p=string(b,4); count=struct.unpack_from('<I',b,p+1)[0]; classes[cid]=(name,count); print(cid,name,count)
  if tag==b'PROP':
   cid=struct.unpack_from('<I',b)[0]; name,p=string(b,4)
   if name in ('Source','SoundId','Name'):
    typ=b[p]; p+=1
    if typ==1:
     vals=[]
     for i in range(classes[cid][1]):
      v,p=string(b,p); vals.append(v)
      if name=='Source': Path(f'src/{classes[cid][0]}_{i}.luau').write_text(v)
     print('PROP',cid,name,repr(vals)[:4000] if name!='Source' else [len(v) for v in vals])
