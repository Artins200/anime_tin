"""Chapter III integration contracts and executed server policies (not Roblox)."""
from pathlib import Path
import math
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
for feature in ('silv3r_candy','TransformationCapsule','SuspendedClone','FactoryLeftWall','FactoryRightWall','FactoryRearWall','TowerStair','StairwellPartition','KirillRoomDoor','InvulnerableTowerShield','HardwareBreaker','ModuleCase'):
    assert feature in world
assert 'Эммм, что это было?' in chapter and 'Чекни в окно.' in chapter
assert 'Lighting.Brightness=1.65' in chapter and 'bloom.Intensity=0' in chapter
assert 'CFrame.lookAt(slotPosition,flatLook,Vector3.yAxis)' in chapter
assert 'CFrame.lookAt(neuroPivot.Position,assistantFocus,Vector3.yAxis)' in chapter
for feature in ('TaperedTowerLeg','TowerXBrace','TowerAnchorShoe','TopWhipAntenna','TowerSignalMarker'):
    assert feature in world
assert 'TowerSignalFin' not in world and 'TowerBeacon",Vector3.new(3,2,3)' in world
assert 'CutsceneRE:FireAllClients("pov"' not in chapter
assert 'cameraPlan(C3.Pos(-204,9,-17)' in chapter and 'inside the living room' in chapter
assert 'cameraPlan(C3.Pos(-196,9,-15)' in chapter and 'cameraPlan(C3.Pos(-204,10,-18)' in chapter
assert 'CutsceneRE:FireAllClients("followRig",C3.party[1].Character' in chapter
assert 'buddyRoute=' in chapter and 'C3.buddy:SetAttribute("StayingWithKirill",true)' in chapter
assert 'C3.Pos(-160,18,-10)' in chapter and 'C3.Pos(-193,18,-12)' in chapter
assert 'C3.Pos(-178,18,-13)' in chapter and 'TweenService:Create(C3.kirillDoor' in chapter
assert 'window.CanCollide=false; window.CanTouch=false; window.CanQuery=false' in world
# Sightlines from both establishing shots must pass through the real opening
# (z -18..18 at x -148), not graze either solid window jamb.
def window_crossing(camera_x,camera_y,camera_z,target_x,target_y,target_z):
    t=(-148-camera_x)/(target_x-camera_x)
    return (camera_y+(target_y-camera_y)*t,camera_z+(target_z-camera_z)*t)
for camera,target in (((-204,10,-18),(-60,0,0)),((-201,9,-14),(-50,2,0)),((-201,9,-15),(-60,0,0))):
    y,z=window_crossing(*camera,*target)
    assert 3<y<10, f'window camera ray is blocked by sill/lintel at y={y}'
    assert -18<z<18, f'window camera hits side wall at z={z}'
assert 'C3.Pos(-184,15.2,-15),C3.Pos(-184,18,-8)' in world
assert 'C3.Pos(-205,18,0)' in chapter and 'C3.Pos(-160,18,-10)' in chapter
assert 'walkRoutes(mainRoute,buddyRoute)' in chapter and 'synchronizePartners~=false' in server
assert 'chosenHero=="Artem" and "Demid" or "Artem"' in chapter
assert 'KirillNeonBlue' in world and 'KirillNeonViolet' in world
for detail in ('CommandDais','CommandStationMonitor','FactoryWallProcessMonitor','GantryBridge','ClonePodStatus','ArtemElectronicsBench','DemidFieldKitRack','KirillBookshelf','KirillDeskMonitor'):
    assert detail in world
assert 'if stage==10 and p:GetAttribute("Hero")=="Artem" then' in world
assert 'C3.CanHack(p)' in world and 'stage==10 and 1.2 or nil' in world
assert 'C3.Pos(pos.X,pos.Y,pos.Z),28,0.8,"HomeFillLamp"' in world
assert 'light(tube,spec.color,18,0.45)' in world
assert 'C3.Lamp(m,o+Vector3.new(x,47,z),72,1.45' in world
assert 'tweenCharTo(p.Character,windowView,1.5,true,12,false,false)' in chapter
assert 'if lockFacing then' in server and 'root.CFrame=CFrame.lookAt(root.Position,root.Position+faceDirection,Vector3.yAxis)' in server
assert 'SingularityLandmark' in world and 'Chapter3CityBackdrop' in world
assert 'C3_CollisionAndGameplay' in world and 'TowerStairGate' in world
assert 'Landmark geometry is a non-colliding visual shell' in world
assert 'MainStreetAsphalt' in world and 'DistrictTitle' in world and 'NTyanOffice' in world
assert 'C3.Send(force)' in chapter and 'now-(C3.lastStateSent or 0)<1' in chapter
assert 'local signature=("%d:%d:%d:%d:%d:%d:%d:%d")' in chapter
assert 'C3.map:Destroy()' in chapter and 'C3.lastStateSignature=nil' in chapter
assert 'task.delay(0.4,function() if held[p]==started then held[p]=nil end end)' in chapter
assert 'held[p]=nil -- every activation consumes its own hold; no replay window' in chapter
assert 'prepareView(C3.Pos(960,103,0))' in chapter
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
local Instance={new=function() local o={Play=function() end}; function o:GetDescendants() return {} end; return o end}
UDim2={fromScale=function(x,y) return {X=x,Y=y} end}
local Enum={Material={},PartType={Cylinder=1,Ball=2},ModelStreamingMode={Persistent=1},SurfaceGuiSizingMode={PixelsPerStud=1},NormalId={Front=1,Right=2},Font={GothamBold=1}}
local task={wait=function() end,spawn=function() end}
local WD={Order={"Fists","Pistol"},Stats={Fists={Cooldown=0.4,Range=7,Damage=28},Pistol={Cooldown=0.26,Range=300,Damage=24}}}
local fxFolder={}
local RaycastParams={new=function() return {} end}
Enum.RaycastFilterType={Exclude=1}
local HitRE={FireClient=function() end}
local function tracer() end
local C2={SitRig=function() end}
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
local relay={index=6,cleared=true,objective=false,panel={},breaker={Position=Vector3.zero},gate={},gateClosed=CFrame.new()}
C3.confirmPlayer=nil; C3.confirmUntil=nil
C3.CompleteObjective(demid,relay); assert(not relay.objective)
C3.CompleteObjective(artem,relay); assert(not relay.objective,"coop skipped readiness")
relay.assaultReady=true; C3.confirmPlayer=demid; C3.confirmUntil=clock-1
C3.CompleteObjective(artem,relay); assert(not relay.objective,"expired teammate confirmation accepted")
C3.confirmUntil=clock+12; C3.CompleteObjective(artem,relay); assert(relay.objective and C3.relays==1)
relay.objective=false; C3.CompleteObjective(artem,relay); assert(C3.relays==1,"checkpoint duplicated relay count")
for clear=0,1 do for objective=0,1 do assert(C3.Ready({cleared=clear==1,objective=objective==1})==(clear==1 and objective==1)) end end
print("PASS: executed role-specific relays, checkpoint idempotency and gate conjunction")

C3.stage=1; C3.hacker=nil; C3.shots={}; C3.mobs={}; C3.towerOff=false
local mob={SetAttribute=function() end,GetDescendants=function() return {} end}; local hum={Health=80,MaxHealth=80,MoveTo=function() end}; function hum:TakeDamage(d) self.Health-=d end
C3.mobs[mob]={hum=hum,root={Position=Vector3.zero},civilian=true,down=false,stun=0}
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
# Execute the actual rebuilt world with light geometry-only mocks. This checks
# route continuity, stair reachability, floor holes, spawn doors and collision layers.
geometry=r'''
local generated={}
levelFolder={}
Types={Pistol={}}
buildRig=function() return {Name="MockGuard"} end
c2Dress=function() end
anchorAll=function() end
light=function() return {} end
local UDim2={fromScale=function(x,y) return {X=x,Y=y} end}
C3.BuildHome=function() end
C3.Lamp=function(parent,pos,range,brightness,name) return C3.Part(parent,name or "AreaLamp",Vector3.new(2,0.2,2),pos,C(1,1,1),Enum.Material.Concrete) end
C3.Beam=function(parent,name,a,b,width,color) return C3.Part(parent,name,Vector3.new(width,width,(b-a).Magnitude),(a+b)*0.5,color,Enum.Material.Metal) end
C3.CommunicationEquipment=function() end
C3.BuildRadioMast=function() end
C3.Prompt=function() return {} end
C3.Part=function(parent,name,size,pos)
 assert(math.max(size.X,size.Y,size.Z)<=512,"oversized Roblox part: "..name)
 local p={Name=name,Size=size,Position=pos,CFrame=CFrame.new(pos.X,pos.Y,pos.Z),Parent=parent,CanCollide=true,CanQuery=true,CanTouch=true}
 table.insert(generated,p); return p
end
'''
world_checks=r'''
C3.Build()
assert(#C3.zones==10)
local stairs,road,approach,gates,airlocks={},nil,nil,0,0
for _,p in ipairs(generated) do
 if p.Name=="TowerStair" then table.insert(stairs,p) end
 if p.Name=="MainStreetAsphalt" then road=p end
 if p.Name=="TowerApproach" then approach=p end
 if p.Name=="DistrictGate" then assert(p.Size.Z==82); gates+=1 end
 if p.Name=="TowerStairGate" then airlocks+=1 end
 if p.Name=="DeploymentDoor" then assert(p.Size.Y>=10) end
end
assert(#stairs==80 and gates==5 and airlocks==4)
for level=0,3 do
 local row={}
 for _,p in ipairs(stairs) do if p.Position.Y>level*24 and p.Position.Y<(level+1)*24 then table.insert(row,p) end end
 assert(#row==20,"each of four stair flights must have 20 treads")
 table.sort(row,function(a,b) return a.Position.Y<b.Position.Y end)
 for i=2,#row do
  assert(math.abs(row[i].Position.Y-row[i-1].Position.Y-1.2)<0.001,"stair rise discontinuity")
  assert(math.abs(row[i].Position.X-row[i-1].Position.X-2.4)<0.001,"stair tread gap")
 end
end
assert(road and math.abs(road.Position.X-390)<0.001 and road.Size.X==1010)
assert(approach and approach.Position.X-approach.Size.X/2<=road.Position.X+road.Size.X/2,"road-to-tower approach gap")
for stage=6,9 do
 local z=C3.zones[stage]
 assert(math.abs(z.exit.Y-z.start.Y-24)<0.001,"tower gate exit must meet next floor")
 assert(math.abs(z.exit.X-984)<0.01 and math.abs(z.exit.Z-C3.origin.Z)<0.01)
end
assert(math.abs(C3.zones[6].start.X-930)<0.01,"tower entry must meet the plaza")
assert(math.abs(C3.zones[7].start.Y-C3.zones[6].exit.Y)<0.01,"floor 7 start must meet floor 6 exit")
local towerInteriorFloors=0
for _,p in ipairs(generated) do if p.Name=="TowerFloor" then towerInteriorFloors+=1 end end
assert(towerInteriorFloors==17,"four open stair decks and a solid crown must total 17 safe floor pieces")
print("PASS: rebuilt city route and plaza meet; tower has 80 continuous treads, open stairwell slots, four progression gates and separate visual shell")
'''
geometry_path=Path('.tools/chapter3-geometry-test.luau')
geometry_path.parent.mkdir(exist_ok=True)
geometry_path.write_text(prelude+'\n'+circuits+'\n'+chapter+'\n'+geometry+'\n'+world+'\n'+world_checks)
luau=Path('.tools/luau/build/release/luau')
if not luau.is_file():
    print('SKIP: executable geometry/policy checks need .tools/luau/build/release/luau; static integration checks passed')
else:
    subprocess.run([str(luau),str(geometry_path)],check=True)
    path=Path('.tools/chapter3-policy-test.luau'); path.parent.mkdir(exist_ok=True)
    path.write_text(prelude+'\n'+circuits+'\n'+chapter+'\n'+checks)
    subprocess.run([str(luau),str(path)],check=True)
