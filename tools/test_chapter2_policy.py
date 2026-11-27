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
local RunService={IsStudio=function() return false end}
local C=function(...) return {...} end
local clock=100
local game={PrivateServerOwnerId=0,GetService=function() return {} end}
local Enum={HumanoidStateType={Running="Running"}}
local WD={Order={"Fists","Pistol","SMG","Shotgun","Rifle"}}
local os={clock=function() return clock end}
local sent={}
local chapterHandler
local workspace={GetServerTimeNow=function() return clock end}
local function newRemote()
 return {OnServerEvent={Connect=function(_,fn) chapterHandler=fn; return {Disconnect=function() end} end},FireClient=function(_,player,action,data) table.insert(sent,{player=player,action=action,data=data}) end}
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
local queued,timers={},{}
local task={defer=function(fn) fn() end,spawn=function(fn) table.insert(queued,fn) end,delay=function(_,fn) table.insert(timers,fn) end}
'''
checks = r'''
-- The same post-outfit finalizer used by spawned enemies must unanchor ALL parts.
local bodies={{Name="Torso",Anchored=true},{Name="HairRibbon",Anchored=true},{Name="HumanoidRootPart",Anchored=true}}
for _,body in ipairs(bodies) do function body:IsA(kind) return kind=="BasePart" end end
local model={GetDescendants=function() return bodies end}
local mobileHum={PlatformStand=true,AutoRotate=false,ChangeState=function(self,state) self.state=state end}
local root={SetNetworkOwner=function(self,owner) self.ownedByServer=owner==nil end}
c2Mobilize(model,mobileHum,root)
for _,body in ipairs(bodies) do assert(not body.Anchored,"outfit welded the NPC to the world") end
assert(mobileHum.state=="Running" and mobileHum.AutoRotate and not mobileHum.PlatformStand and root.ownedByServer)
assert(bodies[1].CanCollide and not bodies[2].CanCollide)
print("PASS: executed NPC mobility repair including anchored clothing regression")

math.randomseed(73)
local rng={NextInteger=function(_,a,b) return math.random(a,b) end}
for _=1,100 do
 local board=c2CircuitBoard(rng)
 assert(not c2CircuitSolved(board),"random puzzle starts completed")
 for i=1,9 do board.rotations[i]=0 end
 assert(c2CircuitSolved(board),"puzzle has no known solution")
 board.rotations[4]=1
 assert(not c2CircuitSolved(board),"disconnected input falsely accepted")
end
print("PASS: executed 100 generated circuit puzzles: unsolved start, valid path, severed path rejected")

local function player(hero,health)
 local p={Parent=true,attrs={Hero=hero}}
 local hum={Health=health,MaxHealth=180}
 local root={Position=Vector3.new(0,0,0)}
 local char={}
 function char:FindFirstChildOfClass(kind) assert(kind=="Humanoid"); return hum end
 function char:FindFirstChild(name) assert(name=="HumanoidRootPart"); return root end
 function p:GetAttribute(key) return self.attrs[key] end
 function p:SetAttribute(key,value) self.attrs[key]=value end
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

local savedEquip=c2WorldWeapon
c2WorldWeapon=function(p,name) p:SetAttribute("EquippedWeapon",name) end
sent={}
demid:SetAttribute("WeaponLevel",1)
for level=2,5 do
 c2Grant(demid,level)
 assert(demid:GetAttribute("WeaponLevel")==level)
 assert(demid:GetAttribute("EquippedWeapon")==WD.Order[level])
 assert(sent[#sent].action=="loadout" and sent[#sent].data.equipped==WD.Order[level])
end
c2WorldWeapon=savedEquip
print("PASS: executed authoritative pistol/SMG/shotgun/rifle grants and explicit client loadout packets")


-- Run the real remote interaction handler, including rejects and completion.
C2.active=true; C2.finished=false; C2.escaping=false; C2.stage=3; C2.challenges={}; C2.challengeSerial=0
C2.party={artem,demid}; ah.Health=180; dh.Health=180; artem.Parent=true
local completed=0
local zone={cleared=true,keyCollected=true,index=3,kind="hack",panel={Position=Vector3.new(0,0,0)},complete=function() completed+=1 end}
local function session(p)
 local board=c2CircuitBoard(rng); for i=1,9 do board.rotations[i]=0 end; board.rotations[4]=3
 local ch={token="real-token",zone=zone,board=board,progress=0,expires=clock+90,last=0,start=clock,target=0.5}
 C2.challenges[p]=ch; zone.owner=p; return ch
end
session(artem)
chapterHandler(artem,"rotate","fake-token",4); assert(completed==0)
clock+=1; chapterHandler(artem,"success","real-token",true); assert(completed==0,"client success flag must not open gate")
clock+=1; chapterHandler(artem,"rotate","real-token",4)
assert(completed==1 and not C2.challenges[artem],"actual solution must complete exactly once")
clock+=1; chapterHandler(artem,"rotate","real-token",4); assert(completed==1,"replayed completion accepted")
local ch=session(artem); ch.expires=clock-1
clock+=1; chapterHandler(artem,"rotate","real-token",4); assert(completed==1 and not C2.challenges[artem])
session(demid); clock+=1; chapterHandler(demid,"rotate","real-token",4)
assert(completed==1 and not C2.challenges[demid],"wrong role accepted")
session(artem)
local ar=artem.Character:FindFirstChild("HumanoidRootPart"); ar.Position=Vector3.new(40,0,0)
clock+=1; chapterHandler(artem,"rotate","real-token",4)
assert(completed==1 and not C2.challenges[artem],"distant terminal accepted")
ar.Position=Vector3.new(0,0,0)
-- Opening a valve interface via E alone does not complete it. Eight real turns do.
zone.kind="valve"; zone.owner=nil
c2Engineering(artem,zone)
assert(completed==1 and C2.challenges[artem],"opening terminal completed objective")
local token=C2.challenges[artem].token
for i=1,8 do clock+=0.2; chapterHandler(artem,"turn",token,i%2==1 and -1 or 1) end
assert(completed==2 and not C2.challenges[artem])
print("PASS: executed engineering protocol: actual solution, replay/token/role/range/timeout rejects, E alone cannot win")

-- Removed preview commands must not change authoritative game state.
assert(C2.DebugJump==nil and C2.DebugAllowed==nil)
local previousStage=C2.stage
local queueBefore=#queued
chapterHandler(artem,"debugJump","finale")
assert(C2.stage==previousStage and #queued==queueBefore)
print("PASS: removed debug functions absent; legacy skip packet has no effect")

-- Door gates are a conjunction, not merely a completed terminal timer.
for clear=0,1 do for card=0,1 do for hack=0,1 do
 local z={cleared=clear==1,keyCollected=card==1,hacked=hack==1}
 assert(C2.GateReady(z)==(clear==1 and card==1 and hack==1))
 assert(C2.CanUseTerminal(z)==(clear==1 and card==1))
 z.deploying=true; assert(not C2.CanUseTerminal(z))
end end end
print("PASS: executed all clearance/keycard/hack gate combinations and deployment lock")

zone.kind="hack"; zone.keyCollected=false; zone.cleared=true; zone.owner=nil
C2.challenges={}; C2.party={artem,demid}
c2Engineering(artem,zone); assert(not C2.challenges[artem],"engineer bypassed keycard")
zone.keyCollected=true; zone.cleared=false
c2Engineering(artem,zone); assert(not C2.challenges[artem],"engineer bypassed guard waves")
zone.cleared=true
c2Engineering(artem,zone)
local fast=C2.challenges[artem]; assert(fast.fast and not fast.board and fast.required==18)
local previous=completed
for _=1,100 do chapterHandler(artem,"type",fast.token) end
assert(C2.challenges[artem] and C2.challenges[artem].progress<=1,"typing rate limiter bypassed")
for _=1,18 do clock+=0.06; chapterHandler(artem,"type",fast.token) end
assert(completed==previous+1 and not C2.challenges[artem],"engineer keyboard hack did not complete")
c2Engineering(artem,zone); local lost=C2.challenges[artem]; zone.keyCollected=false
clock+=1; chapterHandler(artem,"type",lost.token)
assert(not C2.challenges[artem] and completed==previous+1,"card removal during typing ignored")
zone.keyCollected=true; C2.party={demid}
-- Test the actual non-engineer handler with a genuine non-fast session.
local normal=session(demid); normal.fast=false
clock+=1; chapterHandler(demid,"type",normal.token)
assert(normal.progress==0 and C2.challenges[demid],"Demid obtained fast keyboard hacking")
c2EndEngineering(demid)
print("PASS: executed fast engineer typing, keycard/clearance/rate-limit checks, card loss and non-engineer denial")

C2.party={artem}; C2.active=true; C2.finished=false; C2.challenges={}
ah.MoveDirection={Magnitude=1}
C2.sprint={[artem]={held=true,stamina=100,publish=0,rest=0}}
C2.SprintTick(1); assert(ah.WalkSpeed==28 and C2.sprint[artem].stamina==78)
C2.SprintTick(4); assert(ah.WalkSpeed==16 and C2.sprint[artem].stamina==0)
C2.SprintTick(0.1); assert(ah.WalkSpeed==16,"exhausted sprint oscillates")
C2.sprint[artem].held=false; C2.SprintTick(2); assert(C2.sprint[artem].stamina>0)
C2.challenges[artem]={}; ah.WalkSpeed=0; C2.SprintTick(1); assert(ah.WalkSpeed==0,"sprint unlocked terminal movement")
C2.challenges={}
print("PASS: executed server sprint speed, stamina drain, exhaustion hysteresis, regeneration and terminal lock")

-- Actual wave transition callback: only the last guard schedules the next round.
local savedDrop,savedDoor=C2.DropCard,C2.Door
local cards=0
C2.DropCard=function() cards+=1 end; C2.Door=function() end
C2.stage=3; C2.escaping=false; C2.zones[3]={index=3,x=320,wave=1,rounds=2,waveActive=true,deploying=false}
local zw=C2.zones[3]; C2.mobs={}; queued={}; timers={}
local down={wave=1,root={Position=Vector3.new(350,3,0)}}
C2.OnEnemyDown(3,down,nil)
assert(cards==1 and not zw.waveActive and not zw.cleared and #timers==1)
C2.OnEnemyDown(3,down,nil); assert(cards==1 and #timers==1,"duplicate final death scheduled two waves")
timers[1](); assert(zw.wave==2 and zw.waveActive and zw.deploying and #queued==1)
zw.deploying=false
C2.OnEnemyDown(3,{wave=2,root=down.root},nil)
assert(cards==2 and zw.cleared and not C2.GateReady(zw))
zw.keyCollected=true; assert(C2.CanUseTerminal(zw) and not C2.GateReady(zw))
zw.hacked=true; assert(C2.GateReady(zw))
C2.DropCard=savedDrop; C2.Door=savedDoor
print("PASS: executed last-enemy keycards, duplicate-death protection, next wave and final clear/hack progression")

local savedSpark=C2.Spark; C2.Spark=function() end
C2.stage=10; C2.zones[10]={cleared=false}; C2.bossPhase="guarded"; C2.shieldHP=900; C2.shieldMax=900
C2.shield={}; C2.cracks={{},{},{}}; C2.boss={Parent=true,Humanoid={Health=750}}
C2.mobs={[C2.boss]={boss=true,defeated=false,zone=10,hum=C2.boss.Humanoid}}
C2.HitBoss(99999,Vector3.new(0,0,0),nil); assert(C2.shieldHP==900,"guarded boss took damage")
C2.bossPhase="exposed"; C2.HitBoss(100,Vector3.new(0,0,0),nil); assert(C2.shieldHP==900,"phase string bypassed live guards")
C2.zones[10].cleared=true; C2.HitBoss(600,Vector3.new(0,0,0),nil)
assert(C2.shieldHP==300 and C2.cracks[1].Transparency==0.1 and C2.cracks[2].Transparency==0.1)
queued={}
C2.HitBoss(300,Vector3.new(0,0,0),nil)
assert(C2.bossPhase=="broken" and C2.shieldHP==0 and C2.boss.Humanoid.Health==30 and #queued==1)
C2.HitBoss(300,Vector3.new(0,0,0),nil); assert(#queued==1,"shield break scheduled two endings")
C2.Spark=savedSpark
print("PASS: executed boss invulnerability, exposed shield damage/cracks and one-shot defeat transition")

'''
path = Path('.tools/chapter2-policy-test.luau')
path.parent.mkdir(exist_ok=True)
path.write_text(prelude + '\n' + Path('src/Chapter2.luau').read_text() + '\n' + checks)
subprocess.run([str(luau), str(path)], check=True)
