"""Chapter III integration contracts and executed server policies (not Roblox)."""
from pathlib import Path
import subprocess

server=Path('src/Script_0.luau').read_text()
client=Path('src/LocalScript_0.luau').read_text()
chapter=Path('src/Chapter3.luau').read_text()
world=Path('src/Chapter3World.luau').read_text()
ui=Path('src/Chapter3Client.luau').read_text()
assert server.split('-- BEGIN CHAPTER THREE\n')[1].split('\n-- END CHAPTER THREE\n')[0]==chapter
assert chapter.split('-- BEGIN CHAPTER THREE WORLD\n')[1].split('\n-- END CHAPTER THREE WORLD')[0]==world
assert client.split('-- BEGIN CHAPTER THREE CLIENT\n')[1].split('\n-- END CHAPTER THREE CLIENT\n')[0]==ui
assert 'selectedChapter=selectedChapter%3+1' in client
assert '(data.chapter==2 or data.chapter==3) and data.chapter or 1' in server
assert 'C3.Protected(function() C3.Start(party) end)' in server
assert 'if plr:GetAttribute("Chapter")==3 then if c3Attack' in server
for feature in ('silv3r_candy','TransformationCapsule','SuspendedFigure','TowerStair','StairwellPartition','KirillRoomDoor','InvulnerableTowerShield','HardwareBreaker','ModuleCase'):
    assert feature in world
assert 'cfg.Gun=false' in chapter and 'e.suppression' in chapter
assert 'C3.confirmPlayer==p' in chapter and 'helperRoot.Position-C3.zones[10].breaker.Position' in chapter
assert 'C3.relayCounted' not in chapter and 'z.relayCounted=true' in chapter
assert 'C3.shield.CanQuery=false' in chapter
assert 'C3.finished=true; C3.Stop(); returnToMenu()' in chapter
assert 'task.wait(35)' in chapter and chapter.index('C3.modules[index]=true')<chapter.index('C3RE:FireAllClients("credits",true)')
for removed in ('debugJump','DebugAllowed','debugPanel','Enum.KeyCode.F6'):
    assert removed not in server+client
print('PASS: chapter III menu, launch/teleport, combat dispatch, all embedded sources, story/geometry contracts and no cheat menu')

# Reuse the exact proven circuit helpers from chapter II, not a duplicate solver.
c2=Path('src/Chapter2.luau').read_text()
circuits=c2[c2.index('local function c2CircuitSolved'):c2.index('local function c2EndEngineering')]
prelude=r'''
local clock=100
local os={clock=function() return clock end}
local workspace={GetServerTimeNow=function() return clock end}
local introActive=false
local canFight=true
local vec={}
vec.__index=function(t,k)
 if k=="Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end
 if k=="Unit" then local m=math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z); return setmetatable({X=t.X/m,Y=t.Y/m,Z=t.Z/m},vec) end
 return vec[k]
end
function vec.__add(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vec) end
function vec.__sub(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vec) end
function vec.__mul(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vec) end
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vec) end}
Vector3.zero=Vector3.new(0,0,0)
local function typeof(v) return getmetatable(v)==vec and "Vector3" or type(v) end
local cf={}; cf.__mul=function(a,b) return a end
local CFrame={new=function(...) return setmetatable({Position=Vector3.new(...)},cf) end,lookAt=function(pos) return setmetatable({Position=pos},cf) end}
local function C(...) return {...} end
local packets={}
local handler
local function newRemote()
 return {OnServerEvent={Connect=function(_,fn) handler=fn end},FireClient=function(_,p,action,data) table.insert(packets,{player=p,action=action,data=data}) end,FireAllClients=function() end}
end
local NotifyRE={FireClient=function() end,FireAllClients=function() end}
local MusicRE,FadeRE,CutsceneRE=newRemote(),newRemote(),newRemote()
local cameraPlan=function() end
local returned=0
local returnToMenu=function() returned+=1 end
local TweenService={Create=function() return {Play=function() end} end}
local TweenInfo={new=function() return {} end}
local c2WorldWeapon=function() end
local c2Root=function(p) return p.Parent and p.h.Health>0 and p.root or nil,p.h end
local Random={new=function() return {NextInteger=function(_,a,b) return math.random(a,b) end} end}
local Instance={new=function() return {Play=function() end} end}
local Enum={Material={},PartType={Cylinder=1,Ball=2}}
local task={wait=function() end,spawn=function() end}
local WD={Order={"Fists","Pistol"},Stats={Fists={Cooldown=0.4,Range=7,Damage=28},Pistol={Cooldown=0.26,Range=300,Damage=24}}}
local fxFolder={}
local RaycastParams={new=function() return {} end}
Enum.RaycastFilterType={Exclude=1}
local HitRE={FireClient=function() end}
local function tracer() end
local c3Attack
'''
checks=r'''
local function player(role)
 local p={Parent=true,role=role,root={Position=Vector3.zero},h={Health=180,MaxHealth=180}}
 function p:GetAttribute(key) if key=="Hero" then return self.role elseif key=="WeaponLevel" then return 2 end end
 function p:SetAttribute() end
 p.Character={FindFirstChild=function(_,name) if name=="Head" then return {Position=Vector3.zero} end end}
 return p
end
local artem=player("Artem"); local demid=player("Demid"); local intruder=player("Artem")
C3.active=true; C3.finished=false; C3.party={artem,demid}; C3.stage=10; C3.serial=5; C3.hackSerial=0; C3.hackPhase=1; C3.relays=4; C3.key=true; C3.towerOff=false
local z={index=10,cleared=true,panel={Position=Vector3.zero},breaker={Position=Vector3.zero}}
C3.zones={[10]=z}
assert(C3.CanHack(artem) and not C3.CanHack(intruder))
z.cleared=false; assert(not C3.CanHack(artem)); z.cleared=true
C3.relays=3; assert(not C3.CanHack(artem)); C3.relays=4
C3.key=false; assert(not C3.CanHack(artem)); C3.key=true
introActive=true; assert(not C3.CanHack(artem)); introActive=false
assert(C3.Engineer(artem) and not C3.Engineer(demid))
artem.h.Health=0; assert(C3.Engineer(demid) and not C3.CanHack(artem)); artem.h.Health=180
artem.Parent=nil; assert(C3.Engineer(demid)); artem.Parent=true
print("PASS: executed hack clearance/key/relay/session/life/cinematic checks, role lock and dead/disconnected engineer fallback")

C3.OpenHack(artem); local ch=C3.challenge
assert(ch and ch.phase==1)
C3.HackInput(intruder,ch.token); assert(ch.steps==0)
C3.HackInput(artem,"forged"); assert(ch.steps==0)
clock=ch.start+1.2; C3.HackInput(artem,ch.token); assert(ch.steps==1)
C3.HackInput(artem,ch.token); assert(ch.steps==1,"rate limiter failed")
clock+=1/0.35; C3.HackInput(artem,ch.token)
clock+=1/0.35; C3.HackInput(artem,ch.token)
assert(C3.hackPhase==2 and C3.challenge.phase==2)
ch=C3.challenge
for cell=1,9 do
 while ch.board.rotations[cell]~=0 and C3.hackPhase==2 do clock+=0.2; C3.HackInput(artem,ch.token,cell) end
 if C3.hackPhase~=2 then break end
end
assert(C3.hackPhase==3 and C3.challenge.phase==3)
local endings=0
C3.Finale=function() endings+=1; C3.towerOff=true end
ch=C3.challenge
clock+=1; C3.HackInput(artem,ch.token); assert(endings==0,"coop bypassed breaker")
C3.confirmUntil=clock+12; C3.confirmPlayer=artem
clock+=0.2; C3.HackInput(artem,ch.token); assert(endings==0,"self-confirmation accepted")
C3.confirmPlayer=demid; demid.root.Position=Vector3.new(30,0,0)
clock+=0.2; C3.HackInput(artem,ch.token); assert(endings==0,"remote breaker accepted")
demid.root.Position=Vector3.zero
clock+=0.2; C3.HackInput(artem,ch.token); assert(endings==1 and C3.challenge==nil)
C3.HackInput(artem,ch.token); assert(endings==1,"completion replayed")
print("PASS: executed timing/rate limit, real circuit solution, cooperative physical confirmation and one-shot completion")

C3.towerOff=false; C3.party={demid}; C3.hacker=nil; C3.hackPhase=3
C3.OpenHack(demid); ch=C3.challenge; clock+=1; C3.HackInput(demid,ch.token)
assert(endings==2,"solo Demid cannot finish")
C3.towerOff=false; C3.party={artem}; C3.hackPhase=1
C3.OpenHack(artem); ch=C3.challenge; artem.root.Position=Vector3.new(20,0,0)
clock+=1; C3.HackInput(artem,ch.token); assert(C3.challenge==nil,"range escape accepted")
artem.root.Position=Vector3.zero
C3.OpenHack(artem); ch=C3.challenge; clock+=121
C3.HackInput(artem,ch.token); assert(C3.challenge==nil,"expired session accepted")
print("PASS: executed solo terminal fallback, distance loss and expiry cancellation")

C3.Send=function() end
C3.party={artem,demid}; C3.coop=true; C3.stage=6; C3.relays=0
local relay={index=6,cleared=true,objective=false,panel={},gate={},gateClosed=CFrame.new()}
C3.CompleteObjective(demid,relay); assert(not relay.objective)
C3.CompleteObjective(artem,relay); assert(not relay.objective,"coop skipped readiness")
relay.assaultReady=true; C3.CompleteObjective(artem,relay); assert(relay.objective and C3.relays==1)
relay.objective=false; C3.CompleteObjective(artem,relay); assert(C3.relays==1,"checkpoint duplicated relay count")
for clear=0,1 do for objective=0,1 do assert(C3.Ready({cleared=clear==1,objective=objective==1})==(clear==1 and objective==1)) end end
print("PASS: executed role-specific relays, checkpoint idempotency and gate conjunction")

C3.stage=1; C3.hacker=nil; C3.shots={}; C3.mobs={}; C3.towerOff=false
local mob={SetAttribute=function() end}; local hum={Health=80}; function hum:TakeDamage(d) self.Health-=d end
C3.mobs[mob]={hum=hum,civilian=true,down=false,stun=0}
local hit={Instance={Name="Head",FindFirstAncestorOfClass=function() return mob end},Position=Vector3.zero}
workspace.Raycast=function() return hit end
C3.shield={}; clock+=1
c3Attack(artem,"Fists",Vector3.zero,Vector3.new(1,0,0)); clock+=1
c3Attack(artem,"Fists",Vector3.zero,Vector3.new(1,0,0))
assert(C3.mobs[mob].down and hum.Health==80,"civilian was killed instead of suppressed")
local kirill={}; hit.Instance.FindFirstAncestorOfClass=function() return kirill end
clock+=1; c3Attack(artem,"Pistol",Vector3.zero,Vector3.new(1,0,0)); assert(hum.Health==80)
assert(C3.mobs[kirill]==nil)
print("PASS: executed nonlethal civilian suppression and exclusion of original Kirill from combat registry")

C3.collecting=true; C3.modules={}; C3.moduleParts={{},{}}; C3.party={artem,demid}; C3.coop=true; C3.case={}
C3.Scene=function() end; C3.Say=function() end
C3.Stop=function() C3.active=false end
C3.TakeModule(artem,2); C3.TakeModule(demid,1); assert(not C3.modules[1] and not C3.modules[2])
C3.TakeModule(artem,1); assert(C3.modules[1] and not C3.modules[2] and returned==0)
C3.TakeModule(demid,2); assert(C3.modules[2] and C3.finished and returned==1)
C3.TakeModule(demid,2); assert(returned==1)
print("PASS: executed role-specific module collection, one-shot ending and return to menu")
'''
# Build the actual world against geometry-only constructors. Engine physics is
# not emulated, but missing/oversized slabs and disconnected stair runs are caught.
geometry=r'''
local generated={}
C3.BuildHome=function() end
C3.Prompt=function() return {} end
C3.Part=function(parent,name,size,pos)
 assert(math.max(size.X,size.Y,size.Z)<=512)
 local p={Name=name,Size=size,Position=pos,CFrame=CFrame.new(pos.X,pos.Y,pos.Z)}
 table.insert(generated,p); return p
end
local Types={Pistol={}}
local buildRig=function() return {} end
local c2Dress=function() end
local anchorAll=function() end
local light=function() end
'''
# These helpers are resolved lexically inside the world functions.
world_checks=r'''
C3.BuildHome=function() end
C3.Build()
assert(#C3.zones==10)
local steps={}; local roads={}; local gates=0
for _,p in ipairs(generated) do
 if p.Name=="TowerStair" then table.insert(steps,p) end
 if p.Name=="CityRoad" then table.insert(roads,p) end
 if p.Name=="DistrictGate" then assert(p.Size.Z==130); gates+=1 end
end
assert(#steps==96 and gates==5)
for level=0,3 do
 local row={}
 for _,p in ipairs(steps) do if p.Position.Y>level*24 and p.Position.Y<(level+1)*24 then table.insert(row,p) end end
 assert(#row==24)
 table.sort(row,function(a,b) return a.Position.Y<b.Position.Y end)
 for i=2,#row do
  assert(math.abs(row[i].Position.Y-row[i-1].Position.Y-1)<0.001)
  assert(math.abs(row[i].Position.X-row[i-1].Position.X)<=row[i].Size.X)
 end
end
for x=-210,1100 do
 local supported=false
 for _,p in ipairs(roads) do if math.abs(x-p.Position.X)<=p.Size.X/2 then supported=true end end
 assert(supported,"street gap at "..x)
end
print("PASS: executed full world builder: ten arenas, 96 contiguous stair steps, five full-width gates and continuous city road")
'''
geometry_path=Path('.tools/chapter3-geometry-test.luau')
geometry_path.parent.mkdir(exist_ok=True)
geometry_path.write_text(prelude+'\n'+chapter+'\n'+geometry+'\n'+world+'\n'+world_checks)
subprocess.run(['.tools/luau/build/release/luau',str(geometry_path)],check=True)

path=Path('.tools/chapter3-policy-test.luau'); path.parent.mkdir(exist_ok=True)
path.write_text(prelude+'\n'+circuits+'\n'+chapter+'\n'+checks)
subprocess.run(['.tools/luau/build/release/luau',str(path)],check=True)
