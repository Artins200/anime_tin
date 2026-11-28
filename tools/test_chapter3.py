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
assert 'Lighting.ClockTime=22.15' in chapter and 'Lighting.Brightness=1.65' in chapter and 'bloom.Intensity=0.16' in chapter
assert 'LEDStreetLampHead' in world and 'WarmStreetLamp' in world and 'NTyanArmoredTransport' in chapter
assert 'function buildSedan' in world and 'SedanTire' in world and 'WreckedCar' not in world
assert 'FarNeighborhoodBuilding' in world and 'BoulevardTreeCanopy' in world and 'StreetEdgeKerb' in world
assert 'HorizonHighrise' in world and 'HorizonEndcap' in world and 'CitySafetyPerimeter' in world
assert 'outerGround.CanCollide=true' in world and 'Vector3.new(1.5,16,174)' in world
assert 'StairwellPartition' in world and 'slab(82,31,0,-25.5); slab(82,31,0,25.5)' in world
assert 'Vector3.new(2.65,0.65,18.5)' in world and 'DistrictTitle' not in world and 'DistrictGateHeader' not in world
assert 'PrepareCapturedCivilian' in chapter and 'hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true)' in chapter
assert 'e.hum:TakeDamage(damage)' in chapter and 'ragdoll(m,not civilian)' in chapter
assert 'SubduedAlive' not in chapter and 'NonlethalProtection' not in chapter and 'nonlethal' not in ui
assert 'C3.ProtectCivilian' not in chapter and 'C3.Suppress' not in chapter
assert 'NeuroFactoryCityBackdrop' in world and 'DistantLitWindow' in world
assert 'local factory,neuro,assistant,screen=C3.BuildVillain()' in chapter and 'cameraPlan(C3.Pos(-340,166,1880)' not in chapter
assert 'Begin at eye level with Neuro already speaking' in chapter
assert 'C3.sceneCollision[piece]=piece.CanCollide' in chapter and 'part.Name=="SofaSeat"' in world
assert 'CinematicIgnoreObstacles' in chapter and 'followAuthoredRoute' in server
assert 'local windowGuide=C3.coop and "Демид"' in chapter and 'recoverChapter(introError)' in chapter
assert 'function C3.TowerReinforcement()' in chapter and 'Поднимайте захваченный отряд НТЯН' in chapter
assert 'Дуговой карабин' in Path('src/ModuleScript_0.luau').read_text() and 'Enum.KeyCode.Six' in client
assert 'ShieldResonanceShell' in world and 'ShieldEnergyArc' in world and 'C3.shieldParts' in chapter
assert 'KeyboardKeyCode=Enum.KeyCode.E' in chapter and 'GamepadKeyCode=Enum.KeyCode.ButtonX' in chapter
assert 'CFrame.lookAt(slotPosition,flatLook,Vector3.yAxis)' in chapter
assert 'CFrame.lookAt(neuroPivot.Position,assistantFocus,Vector3.yAxis)' in chapter
for feature in ('TaperedTowerLeg','TowerXBrace','TowerAnchorShoe','TopWhipAntenna','TowerSignalMarker'):
    assert feature in world
assert 'TowerSignalFin' not in world and 'TowerBeacon",Vector3.new(3,2,3)' in world
assert 'CutsceneRE:FireAllClients("pov",C3.Pos(960,150,0),54)' in chapter
assert 'cameraPlan(C3.Pos(-178,9,0),C3.Pos(-175,8,0),C3.Pos(-50,3,0)' in chapter
assert 'CutsceneRE:FireAllClients("followRig",C3.party[1].Character' in chapter
assert 'buddyRoute=' in chapter and 'C3.buddy:SetAttribute("StayingWithKirill",true)' in chapter
assert 'C3.Pos(-160,18,-10)' in chapter and 'C3.Pos(-193,18,-12)' in chapter
assert 'C3.Pos(-178,18,-13)' in chapter and 'TweenService:Create(C3.kirillDoor' in chapter
assert 'window.CanCollide=false; window.CanTouch=false; window.CanQuery=false' in world
assert 'for stair=1,15 do' in chapter and 'local z=-20+stair*2.5; local y=stair+3' in chapter
# All camera shots cross the window aperture (x=-148, y=3..10, z=-18..18).
def window_crossing(camera_x,camera_y,camera_z,target_x,target_y,target_z):
    t=(-148-camera_x)/(target_x-camera_x)
    return (camera_y+(target_y-camera_y)*t,camera_z+(target_z-camera_z)*t)
for camera,target in (((-204,10,-18),(-60,0,0)),((-175,8,0),(-50,3,0)),((-153,5,-5),(960,150,0))):
    y,z=window_crossing(*camera,*target)
    assert 3<y<10, f'window camera ray is blocked by sill/lintel at y={y}'
    assert -18<z<18, f'window camera hits side wall at z={z}'
assert 'C3.Pos(-184,15.2,-15),C3.Pos(-184,18,-8)' in world
assert 'C3.Pos(-205,18,0)' in chapter and 'C3.Pos(-160,18,-10)' in chapter
assert 'walkRoutes(mainRoute,buddyRoute)' in chapter and 'synchronizePartners~=false' in server
assert 'if action=="pov" then' in client and 'BackgroundTransparency=1,Visible=false' in ui
assert 'ОПТИКА' not in ui and '×3' not in ui and 'BackgroundTransparency=0.3,Visible=false' not in ui
assert 'chosenHero=="Artem" and "Demid" or "Artem"' in chapter
assert 'KirillNeonBlue' in world and 'KirillNeonViolet' in world
for detail in ('CommandDais','CommandStationMonitor','FactoryWallProcessMonitor','GantryBridge','ClonePodStatus','ArtemElectronicsBench','DemidFieldKitRack','KirillBookshelf','KirillDeskMonitor','cloneStyles','SilkHeadband','SoftFringeLeft','EyeGlintLeft','TailoredCollar','UniformBrooch'):
    assert detail in world
assert 'if stage==10 and p:GetAttribute("Hero")=="Artem" then' in world
assert 'C3.CanHack(p)' in world and 'stage==10 and 1.2 or nil' in world
assert 'C3.Pos(pos.X,pos.Y,pos.Z),28,0.8,"HomeFillLamp"' in world
assert 'light(tube,spec.color,18,0.45)' in world
assert 'C3.Lamp(m,o+Vector3.new(x,47,z),72,1.45' in world
assert 'tweenCharTo(character,windowTarget,1.5,false,12,false,false)' in chapter
assert 'local entry=C3.Pos(-174,4,zOffset)' in chapter
assert 'if lockFacing then' in server and 'root.CFrame=CFrame.lookAt(root.Position,root.Position+faceDirection,Vector3.yAxis)' in server
assert 'SingularityLandmark' in world and 'Chapter3CityBackdrop' in world
assert 'C3_CollisionAndGameplay' in world and 'TowerStairGate' in world
assert 'local z={index=i,center=C3.Pos(x,4,0),start=C3.Pos(x-62,4,0)' in world
assert 'C3.zones[i]=z' in world and 'C3.zones[stage]=z' in world
assert 'Landmark geometry is a non-colliding visual shell' in world
assert 'MainStreetAsphalt' in world and 'DistrictTitle' not in world and 'NTyanOffice' in world
assert 'C3.Send(force)' in chapter and 'now-(C3.lastStateSent or 0)<1' in chapter
assert 'local signature=("%d:%d:%d:%d:%d:%d:%d:%d")' in chapter
assert 'C3.map:Destroy()' in chapter and 'C3.lastStateSignature=nil' in chapter
assert 'task.delay(0.4,function() if held[p]==started then held[p]=nil end end)' in chapter
assert 'held[p]=nil -- every activation consumes its own hold; no replay window' in chapter
assert 'prepareView(C3.Pos(960,150,0))' in chapter
assert 'cfg.Gun=not civilian' in chapter and 'C3.PrepareCapturedCivilian(m,h)' in chapter and 'C3.Suppress' not in chapter
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
local CFrame={new=function(...) return setmetatable({Position=Vector3.new(...)},cf) end,lookAt=function(pos) return setmetatable({Position=pos},cf) end,Angles=function() return setmetatable({Position=Vector3.zero},cf) end}
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
local mob={SetAttribute=function() end,GetDescendants=function() return {} end}; local hum={Health=92,MaxHealth=92,MoveTo=function() end}; function hum:TakeDamage(d) self.Health=math.max(0,self.Health-d) end
C3.mobs[mob]={hum=hum,root={Position=Vector3.zero},civilian=true,down=false,stun=0}
local hit={Instance={Name="Head",FindFirstAncestorOfClass=function() return mob end},Position=Vector3.zero}
workspace.Raycast=function() return hit end
C3.shield={}; clock+=1
for _=1,4 do c3Attack(artem,"Fists",Vector3.zero,Vector3.new(1,0,0)); clock+=1 end
assert(hum.Health==0,"captured civilian damage did not reach lethal health")
local kirill={}; hit.Instance.FindFirstAncestorOfClass=function() return kirill end
clock+=1; c3Attack(artem,"Pistol",Vector3.zero,Vector3.new(1,0,0)); assert(hum.Health==0)
assert(C3.mobs[kirill]==nil)
print("PASS: executed lethal captured-civilian damage and exclusion of original Kirill from combat registry")

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
local stairs,roads,approach,gates,airlocks={}, {},nil,0,0
for _,p in ipairs(generated) do
 if p.Name=="TowerStair" then table.insert(stairs,p) end
 if p.Name=="MainStreetAsphalt" then table.insert(roads,p) end
 if p.Name=="TowerApproach" then approach=p end
 if p.Name=="DistrictGate" then assert(p.Size.Z==174); gates+=1 end
 if p.Name=="TowerStairGate" then assert(p.Size.Z>=20.2); airlocks+=1 end
 if p.Name=="DeploymentDoor" then assert(p.Size.Y>=10) end
end
assert(#stairs==80 and gates==5 and airlocks==4)
for _,p in ipairs(stairs) do assert(p.Size.Z==18.5,"stair tread must fully support the protected stair lane") end
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
assert(#roads==5,"continuous five-segment street expected")
table.sort(roads,function(a,b) return a.Position.X<b.Position.X end)
for i=2,#roads do
 assert(roads[i].Position.X-roads[i-1].Position.X<= (roads[i].Size.X+roads[i-1].Size.X)/2,"street segment gap")
end
assert(approach and approach.Position.X-approach.Size.X/2<=roads[#roads].Position.X+roads[#roads].Size.X/2,"road-to-tower approach gap")
for stage=6,9 do
 local z=C3.zones[stage]
 assert(math.abs(z.exit.Y-z.start.Y-24)<0.001,"tower gate exit must meet next floor")
 assert(math.abs(z.exit.X-984)<0.01 and math.abs(z.exit.Z-C3.origin.Z)<0.01)
end
assert(math.abs(C3.zones[6].start.X-930)<0.01,"tower entry must meet the plaza")
assert(math.abs(C3.zones[7].start.Y-C3.zones[6].exit.Y)<0.01,"floor 7 start must meet floor 6 exit")
local towerInteriorFloors,towerLandings=0,0
for _,p in ipairs(generated) do
 if p.Name=="TowerFloor" then towerInteriorFloors+=1 end
 if p.Name=="TowerStairLanding" then towerLandings+=1 end
end
assert(towerInteriorFloors==9 and towerLandings==8,"four protected stair corridors need solid side floors and both end landings")
local facades,groundTiles,perimeterWalls,stairWalls={},0,0,0
for _,p in ipairs(generated) do
 if p.Name=="BlockFacade" then table.insert(facades,p) end
 if p.Name=="OuterCityGround" then groundTiles+=1 end
 if p.Name=="CitySafetyPerimeter" then perimeterWalls+=1 end
 if p.Name=="StairwellPartition" then stairWalls+=1 end
end
assert(#facades==38 and groundTiles==12 and perimeterWalls==14 and stairWalls==24,"sealed city perimeter and protected stairwell parts missing")
table.sort(facades,function(a,b) return a.Position.X<b.Position.X end)
assert(facades[1].Position.X-facades[1].Size.X/2<=-409 and facades[#facades].Position.X+facades[#facades].Size.X/2>=1289,"street wall does not reach the city safety perimeter")
for i=2,19 do assert(facades[i].Position.X-facades[i].Size.X/2<=facades[i-1].Position.X+facades[i-1].Size.X/2,"walk-around gap between street facades") end
for stage=1,5 do
 local gate=C3.zones[stage].gate; local joinedSides={}
 for _,facade in ipairs(facades) do
  local offsetZ=facade.Position.Z-C3.origin.Z; local sideZ=math.abs(offsetZ)
  if math.abs(facade.Position.X-gate.Position.X)<=facade.Size.X/2 and sideZ==98 and gate.Size.Z/2>sideZ-facade.Size.Z/2 then joinedSides[offsetZ>0 and 1 or -1]=true end
 end
 assert(joinedSides[1] and joinedSides[-1],"street gate must overlap both side buildings; side bypass remains")
end
print("PASS: street, approach and full-width gates are continuous; city has collision-safe ground and wrapped skyline; tower stair corridors are enclosed over solid floor wings; every gate joins building walls")
'''
geometry_path=Path('.tools/chapter3-geometry-test.luau')
geometry_path.parent.mkdir(exist_ok=True)
geometry_path.write_text(prelude+'\n'+circuits+'\n'+chapter+'\n'+geometry+'\n'+world+'\nC3.BuildHome=function() end\n'+world_checks)
luau=Path('.tools/luau/build/release/luau')
if not luau.is_file():
    print('SKIP: executable geometry/policy checks need .tools/luau/build/release/luau; static integration checks passed')
else:
    subprocess.run([str(luau),str(geometry_path)],check=True)
    path=Path('.tools/chapter3-policy-test.luau'); path.parent.mkdir(exist_ok=True)
    path.write_text(prelude+'\n'+circuits+'\n'+chapter+'\n'+checks)
    subprocess.run([str(luau),str(path)],check=True)
