"""Verify the complete imported avatar against the untouched donor place."""
from collections import Counter
from pathlib import Path
import struct
from rbxl import chunks, string
from import_kirill import inspect, decode, u32

source = Path('l12.rbxl').read_bytes()
built = Path('Place1.rbxl').read_bytes()
base = Path('Place3.rbxl').read_bytes()
dc, dp, dn, dparents = inspect(source)
bc, bp, bn, bparents = inspect(built)
_, _, original_names, _ = inspect(base)
root = next(r for r,n in dn.items() if n == 'silv3r_candy')
selected = {root}
while True:
    new = selected | {r for r,p in dparents.items() if p in selected}
    if new == selected: break
    selected = new
added = set(bn) - set(original_names)
assert len(added) == len(selected) == 70
mapping = dict(zip(sorted(selected), sorted(added)))
storage = next(r for r,n in bn.items() if n == 'ServerStorage')
assert bparents[mapping[root]] == storage
assert sum(n == 'silv3r_candy' for n in bn.values()) == 1
for r in selected:
    assert bn[mapping[r]] == dn[r]
    assert bparents[mapping[r]] == (storage if r == root else mapping[dparents[r]])

# Match every property, including mesh/texture content, clothes, CFrames,
# Motor6D/Weld links, and HumanoidDescription instance references.
base_cids = set(inspect(base)[0])
added_cids = set(bc) - base_cids
actual_types = Counter()

def shared_strings(data):
    raw = next(b for t,b,_ in chunks(data) if t == b'SSTR')
    result = []; p = 8
    for _ in range(u32(raw,4)):
        fingerprint = raw[p:p+16]; p += 16
        n = u32(raw,p); p += 4
        result.append((fingerprint,raw[p:p+n])); p += n
    assert p == len(raw)
    return result

ds, bs = shared_strings(source), shared_strings(built)
verified = 0
for cid,(kind,rr,_) in dc.items():
    indices = [i for i,r in enumerate(rr) if r in selected]
    if not indices: continue
    newrefs = [mapping[rr[i]] for i in indices]
    newcid = next(c for c in added_cids if bc[c][0] == kind and bc[c][1] == newrefs)
    actual_types[kind] += len(indices)
    for (pcid,name),(typ,raw) in dp.items():
        if pcid != cid: continue
        values = [decode(typ,raw,len(rr))[i] for i in indices]
        actual_type, actual_raw = bp[newcid,name]
        assert actual_type == typ
        actual = decode(typ,actual_raw,len(indices))
        if typ == 19:
            values = [mapping.get(v,-1) for v in values]
        elif typ == 28:
            values = [ds[int.from_bytes(v,'big')] for v in values]
            actual = [bs[int.from_bytes(v,'big')] for v in actual]
        elif typ == 34:
            values = [(k,mapping.get(v,-1) if k == 2 else v) for k,v in values]
        assert actual == values, (kind,name)
        verified += 1
assert actual_types['Humanoid'] == 1 and actual_types['Animator'] == 1
assert actual_types['Motor6D'] == 6 and actual_types['Weld'] == 2
assert actual_types['Accessory'] == 2 and actual_types['Shirt'] == 1 and actual_types['Pants'] == 1
assert not any(actual_types[k] for k in ('Script','LocalScript','ModuleScript'))
class_count, instance_count = struct.unpack_from('<II',built,16)
assert class_count == len(bc) and instance_count == len(bn)
print(f'PASS: exact Kirill subtree: 70 instances, {verified} property arrays, correct parents and remapped joint references')
print('PASS: original clothes/accessories/meshes/textures preserved; one ServerStorage.silv3r_candy; no donor scripts/world imported')
