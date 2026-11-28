"""Losslessly transplant only ServerStorage.silv3r_candy from l12.rbxl.
Original chunks are unchanged except the instance counts, shared-string table and
parent table. Selected property bytes are preserved; only IDs are remapped.
Unknown encodings fail closed rather than silently losing avatar data.
"""
import struct
from pathlib import Path
from rbxl import chunks, enc, string


def u32(b, p=0): return struct.unpack_from('<I', b, p)[0]
def pack(n): return struct.pack('<I', n)
def blob(b, p):
    end = p + 4 + u32(b, p)
    assert end <= len(b)
    return b[p:end], end

def lanes(b, n, width):
    assert len(b) == n * width
    return [bytes(b[i+j*n] for j in range(width)) for i in range(n)]

def weave(values):
    return bytes(v[j] for j in range(len(values[0])) for v in values) if values else b''

def ints(b, n, delta=False):
    result, prev = [], 0
    for raw in lanes(b, n, 4):
        v = int.from_bytes(raw, 'big'); v = (v >> 1) ^ -(v & 1)
        if delta: v += prev; prev = v
        result.append(v)
    return result

def intbytes(values, delta=False):
    result, prev = [], 0
    for v in values:
        x = v-prev if delta else v
        prev = v
        result.append(((x << 1) ^ (x >> 31)).to_bytes(4, 'big'))
    return weave(result)

def cframes(b, n, p=0):
    rotations = []
    for _ in range(n):
        end = p + (37 if b[p] == 0 else 1)
        rotations.append(b[p:end]); p = end
    positions = lanes(b[p:p+12*n], n, 12); p += 12*n
    return list(zip(rotations, positions)), p


def decode(typ, b, n):
    widths = {2:1, 3:4, 4:4, 12:12, 13:8, 14:12, 18:4,
              26:3, 27:8, 28:4, 31:16, 33:8}
    if typ in widths: return lanes(b, n, widths[typ])
    if typ == 19: return ints(b, n, True)
    p = 0; values = []
    if typ == 1:
        for _ in range(n):
            value, p = blob(b, p); values.append(value)
    elif typ in (16, 30):
        if typ == 30: assert b[0] == 16; p = 1
        values, p = cframes(b, n, p)
        if typ == 30:
            assert b[p] == 2; p += 1
            values = [(rot, pos, flag) for (rot, pos), flag in zip(values, b[p:p+n])]; p += n
    elif typ == 25:
        for _ in range(n):
            flag = b[p]; assert flag in (0,1,2,3)
            end = p + 1 + (24 if flag == 3 else 20 if flag == 1 else 0)
            values.append(b[p:end]); p = end
    elif typ == 34:
        kinds = ints(b[:n*4], n); p = n*4
        count = u32(b, p); p += 4; uris = []
        for _ in range(count):
            uri, p = blob(b, p); uris.append(uri)
        count = u32(b, p); p += 4
        objects = list(reversed(ints(b[p:p+count*4], count, True))); p += count*4
        assert u32(b, p) == 0, 'External Content refs require explicit support'; p += 4
        uri_iter, obj_iter = iter(uris), iter(objects)
        for kind in kinds:
            assert kind in (0,1,2)
            values.append((kind, next(uri_iter) if kind == 1 else next(obj_iter) if kind == 2 else None))
    else: raise ValueError(f'Unsupported selected property type {typ}')
    assert p == len(b), (typ, p, len(b))
    assert len(values) == n
    return values


def encode(typ, values):
    if typ == 19: return intbytes(values, True)
    if typ in (1,25): return b''.join(values)
    if typ in (16,30):
        out = b''.join(v[0] for v in values) + weave([v[1] for v in values])
        return b'\x10' + out + b'\x02' + bytes(v[2] for v in values) if typ == 30 else out
    if typ == 34:
        uris = [v for k,v in values if k == 1]
        objects = [v for k,v in values if k == 2]
        return (intbytes([k for k,_ in values]) + pack(len(uris)) + b''.join(uris)
                + pack(len(objects)) + intbytes(list(reversed(objects)), True) + pack(0))
    return weave(values)


def inspect(data):
    classes, props, names, parents = {}, {}, {}, {}
    for tag,b,_ in chunks(data):
        if tag == b'INST':
            cid = u32(b); kind,p = string(b,4); service=b[p]; n=u32(b,p+1)
            classes[cid] = (kind, ints(b[p+5:p+5+4*n], n, True), service)
        elif tag == b'PROP':
            cid=u32(b); name,p=string(b,4); typ=b[p]
            props[cid,name]=(typ,b[p+1:])
            if name == 'Name':
                for r,raw in zip(classes[cid][1], decode(typ,b[p+1:],len(classes[cid][1]))):
                    names[r]=raw[4:].decode()
        elif tag == b'PRNT':
            n=u32(b,1); parents.update(zip(ints(b[5:5+4*n],n,True),ints(b[5+4*n:],n,True)))
    return classes, props, names, parents


def transplant(target, donor):
    dc,dp,dn,parents=inspect(donor); bc,bp,bn,baseparents=inspect(target)
    root=next(r for r,n in dn.items() if n=='silv3r_candy')
    storage=next(r for r,n in bn.items() if n=='ServerStorage')
    assert dn[parents[root]]=='ServerStorage'
    if any(n=='silv3r_candy' for n in bn.values()):
        raise ValueError('silv3r_candy already exists; refusing to duplicate/overwrite')
    selected={root}
    while True:
        expanded=selected|{r for r,p in parents.items() if p in selected}
        if expanded==selected: break
        selected=expanded
    refs={r: max(bn)+1+i for i,r in enumerate(sorted(selected))}
    old=list(chunks(target)); source=list(chunks(donor))
    bs=next((b for t,b,_ in old if t==b'SSTR'),pack(0)+pack(0))
    ds=next((b for t,b,_ in source if t==b'SSTR'),pack(0)+pack(0))
    assert u32(bs)==0 and u32(ds)==0
    shared_offset=u32(bs,4)
    shared=pack(0)+pack(shared_offset+u32(ds,4))+bs[8:]+ds[8:]
    appended=[]; cidnext=max(bc)+1
    for cid,(kind,rr,service) in dc.items():
        indices=[i for i,r in enumerate(rr) if r in selected]
        if not indices: continue
        assert not service
        newid=cidnext; cidnext+=1
        appended.append((b'INST',pack(newid)+enc(kind)+b'\0'+pack(len(indices))+intbytes([refs[rr[i]] for i in indices],True),0))
        for (pcid,name),(typ,raw) in dp.items():
            if pcid!=cid: continue
            allvalues=decode(typ,raw,len(rr))
            assert encode(typ,allvalues)==raw, (kind,name,'codec roundtrip')
            values=[allvalues[i] for i in indices]
            if typ == 19:
                assert all(v==-1 or v in refs for v in values), (kind,name,'external instance reference')
                values=[refs.get(v,-1) for v in values]
            elif typ == 28:
                values=[(int.from_bytes(v,'big')+shared_offset).to_bytes(4,'big') for v in values]
            elif typ == 34:
                assert all(k!=2 or v in refs or v==-1 for k,v in values)
                values=[(k,refs.get(v,-1) if k==2 else v) for k,v in values]
            appended.append((b'PROP',pack(newid)+enc(name)+bytes([typ])+encode(typ,values),0))
    newparents=dict(baseparents)
    newparents.update({refs[r]:storage if r==root else refs[parents[r]] for r in selected})
    prnt=b'\0'+pack(len(newparents))+intbytes(list(newparents),True)+intbytes(list(newparents.values()),True)
    header=bytearray(target[:32]); struct.pack_into('<II',header,16,len(bc)+cidnext-max(bc)-1,len(baseparents)+len(selected))
    out=bytearray(header); inserted=False; has_shared=False
    for tag,b,res in old:
        if tag==b'SSTR': b=shared; has_shared=True
        if tag==b'PRNT':
            if not has_shared: out+=struct.pack('<4sIII',b'SSTR',0,len(shared),0)+shared
            for at,ab,ar in appended: out+=struct.pack('<4sIII',at,0,len(ab),ar)+ab
            b=prnt; inserted=True
        out+=struct.pack('<4sIII',tag,0,len(b),res)+b
    assert inserted
    result=bytes(out)
    rc,rp,rn,rparents=inspect(result)
    assert len(rn)==len(bn)+len(selected)
    assert all(rn[r]==n and rparents[r]==baseparents[r] for r,n in bn.items())
    assert rparents[refs[root]]==storage
    for key,value in bp.items(): assert rp[key]==value
    return result, len(selected)


if __name__=='__main__':
    path=Path('Place1.rbxl')
    result,count=transplant(path.read_bytes(),Path('l12.rbxl').read_bytes())
    path.write_bytes(result)
    print(f'Imported silv3r_candy: {count} instances; original properties and parents preserved; {len(result)} bytes')
