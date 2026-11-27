"""Execute the actual city builder/drive curve in Luau; inspect geometry numerically.
This is a geometry contract, not a Roblox rendering or streaming simulation.
"""
from pathlib import Path
import subprocess
import sys

luau = Path(sys.argv[1] if len(sys.argv) > 1 else '.tools/luau/build/release/luau').resolve()
source = Path('src/Chapter2Campaign.luau').read_text()
functions = source[source.index('function C2.DriveDistance('):source.index('function C2.CarScene(')]
prelude = r'''
local C2={map={}}
local parts={}
local Enum={Material={Concrete=1,Asphalt=2,Metal=3,Neon=4,Glass=5},ModelStreamingMode={Persistent=1}}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Instance={new=function(kind) assert(kind=="Model"); return {} end}
local function C(...) return {...} end
local function light(...) end
local function c2Part(parent,name,size,pos,color,material)
 assert(parent and size.X>0 and size.Y>0 and size.Z>0)
 assert(math.max(size.X,size.Y,size.Z)<=512,"oversized part: "..name)
 local part={Name=name,Size=size,Position=pos,Parent=parent}
 table.insert(parts,part)
 return part
end
math.randomseed(4217)
local Random={new=function() return {NextInteger=function(_,a,b) return math.random(a,b) end} end}
'''
checks = r'''
local city=C2.BuildEscapeCity()
assert(city.Parent==C2.map and city.ModelStreamingMode==Enum.ModelStreamingMode.Persistent)
local count=#parts
assert(C2.BuildEscapeCity()==city and #parts==count,"builder duplicated city")
local counts={}
for _,p in ipairs(parts) do counts[p.Name]=(counts[p.Name] or 0)+1 end
assert(counts.EscapeRoad==21 and counts.CityBuilding==60 and counts.SkylineTower==60)
assert(counts.PickupBayWall==2 and counts.PickupBayBack==1 and counts.CourtyardRearWall==1)
assert(counts.CityWindow>900 and counts.Sidewalk==42 and counts.StreetLampPole==60)
local function covers(x,z)
 for _,p in ipairs(parts) do
  if p.Name=="EscapeRoad" or p.Name=="RendezvousApron" then
   if math.abs(x-p.Position.X)<=p.Size.X/2 and math.abs(z-p.Position.Z)<=p.Size.Z/2 then return true end
  end
 end
 return false
end
assert(C2.DriveDistance(0)==0 and C2.DriveDistance(-1)==0)
local previous=0
for step=0,1200 do
 local t=step/20
 local d=C2.DriveDistance(t)
 assert(d>=previous,"car reversed")
 for _,axle in ipairs({-4.8,4.8}) do for _,side in ipairs({-1,1}) do
  assert(covers(-70-d+axle,100+side*3.5),"wheel above a road gap at "..t)
 end end
 previous=d
end
-- Acceleration joins cruise without a speed jump.
local left=(C2.DriveDistance(4)-C2.DriveDistance(3.999))/0.001
local right=(C2.DriveDistance(4.001)-C2.DriveDistance(4))/0.001
assert(math.abs(left-right)<0.01 and math.abs(right-32)<0.01)
assert(covers(-70,100) and covers(-58,100))
print("PASS: executed city builder: "..count.." bounded parts, 60 foreground buildings, 60 skyline towers, idempotent persistent model")
print("PASS: all four wheels supported for 1201 drive samples (60 seconds), stationary departure coverage and continuous acceleration")
'''
path = Path('.tools/chapter2-city-test.luau')
path.parent.mkdir(exist_ok=True)
path.write_text(prelude + '\n' + functions + '\n' + checks)
subprocess.run([str(luau), str(path)], check=True)
