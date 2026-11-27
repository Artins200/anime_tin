"""Execute actual Chapter II helper functions in Luau with tiny policy-only mocks.
Not an engine/physics/network simulation. Requires the Luau CLI (optional path argument).
"""
from pathlib import Path
import subprocess
import sys

luau = Path(sys.argv[1] if len(sys.argv) > 1 else '.tools/luau/build/release/luau').resolve()
if not luau.is_file():
    raise SystemExit('Luau CLI not found; pass its path as the first argument.')
prelude = r'''
local clock=100
local os={clock=function() return clock end}
local sent={}
local function newRemote()
 return {FireClient=function(_,player,action,data) table.insert(sent,{player=player,action=action,data=data}) end}
end
local vec={}; vec.__index=vec
function vec.__sub(a,b)
 local x,y,z=a.X-b.X,a.Y-b.Y,a.Z-b.Z
 return {Magnitude=math.sqrt(x*x+y*y+z*z)}
end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vec) end}
local function signal()
 local event={callbacks={}}
 function event:Connect(fn)
  local conn={Connected=true}; function conn:Disconnect() self.Connected=false end
  table.insert(self.callbacks,{fn,conn}); return conn
 end
 function event:Fire(...)
  for _,entry in ipairs(self.callbacks) do if entry[2].Connected then entry[1](...) end end
 end
 return event
end
local Instance={new=function(kind)
 assert(kind=="ProximityPrompt")
 return {Triggered=signal(),PromptButtonHoldBegan=signal(),PromptButtonHoldEnded=signal()}
end}
local task={defer=function(fn) fn() end}
'''
checks = r'''
local function player(hero,health)
 local p={Parent=true,attrs={Hero=hero}}
 local hum={Health=health,MaxHealth=180}
 local root={Position=Vector3.new(0,0,0)}
 local char={}
 function char:FindFirstChildOfClass(kind) assert(kind=="Humanoid"); return hum end
 function char:FindFirstChild(name) assert(name=="HumanoidRootPart"); return root end
 function p:GetAttribute(key) return self.attrs[key] end
 p.Character=char
 return p,hum,root
end
local artem,ah=player("Artem",180)
local demid,dh,dr=player("Demid",180)
C2.party={artem,demid}
assert(c2Alive())
assert(c2Allowed(artem,"engineering"))
assert(not c2Allowed(demid,"engineering"))
ah.Health=0
assert(c2Allowed(demid,"engineering"),"surviving Demid must not be softlocked")
ah.Health=180; artem.Parent=nil
assert(c2Allowed(demid,"engineering"),"disconnected engineer must not block panels")
artem.Parent=true
C2.party={demid}
assert(c2Allowed(demid,"engineering"),"solo Demid needs remote panels")
C2.party={artem,demid}; ah.Health=0; dh.Health=0
assert(not c2Alive())
dh.Health=180; ah.Health=180
print("PASS: executed role, solo, death and disconnect policies")

C2.mobs={
 live={Parent=true}, dead={Parent=true}, downed={Parent=true}, gone={}, other={Parent=true}
}
local models=C2.mobs
C2.mobs={
 [models.live]={hum={Health=50},zone=10},
 [models.dead]={hum={Health=0},zone=10},
 [models.downed]={hum={Health=30},zone=10,defeated=true},
 [models.gone]={hum={Health=50},zone=10},
 [models.other]={hum={Health=50},zone=9},
}
assert(c2Count(10)==1,"downed boss, corpses and removed models cannot block escape")
assert(c2Count(9)==1 and c2Count(8)==0)
C2.stage=10; C2.zones={[10]={done=false}}; C2.escaping=false
c2Send()
assert(#sent==2 and sent[1].data.role=="Artem" and sent[2].data.role=="Demid")
assert(sent[1].data.enemies==1)
C2.escaping=true; C2.deadline=777
c2Send()
assert(sent[3].data.escaping and sent[3].data.deadline==777)
print("PASS: executed defeated-boss counting and per-player objective/clock payloads")

C2.active=true; C2.finished=false; C2.escaping=false
local calls=0
local panel={Position=Vector3.new(0,0,0)}
local prompt=c2Prompt(panel,"Hack",5,function(p) assert(p==demid); calls+=1 end)
assert(prompt.MaxActivationDistance==9 and prompt.HoldDuration==5)
prompt.Triggered:Fire(demid); assert(calls==0,"must hold before trigger")
prompt.PromptButtonHoldBegan:Fire(demid)
clock+=1; prompt.Triggered:Fire(demid); assert(calls==0,"short hold rejected")
clock+=5; dr.Position=Vector3.new(30,0,0)
prompt.Triggered:Fire(demid); assert(calls==0,"remote trigger rejected")
dr.Position=Vector3.new(0,0,0)
prompt.Triggered:Fire(demid); assert(calls==1)
prompt.PromptButtonHoldEnded:Fire(demid)
prompt.Triggered:Fire(demid); assert(calls==1,"released hold rejected")
C2.finished=true
prompt.PromptButtonHoldBegan:Fire(demid); clock+=6
prompt.Triggered:Fire(demid); assert(calls==1,"finished session cannot interact")
for _,connection in ipairs(C2.connections) do connection:Disconnect() end
C2.finished=false; prompt.Triggered:Fire(demid); assert(calls==1,"cleanup disconnects prompts")
print("PASS: executed hold-duration, proximity, session and connection-cleanup checks")
'''
path = Path('.tools/chapter2-policy-test.luau')
path.parent.mkdir(exist_ok=True)
path.write_text(prelude + '\n' + Path('src/Chapter2.luau').read_text() + '\n' + checks)
subprocess.run([str(luau), str(path)], check=True)
