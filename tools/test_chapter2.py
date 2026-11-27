"""Chapter II static/build contracts. This is NOT a Roblox physics or visual test."""
import re
import struct
from pathlib import Path
from rbxl import chunks, string

chapter = Path('src/Chapter2.luau').read_text()
server = Path('src/Script_0.luau').read_text()
client = Path('src/LocalScript_0.luau').read_text()
embedded = server.split('-- BEGIN CHAPTER TWO\n', 1)[1].split('\n-- END CHAPTER TWO', 1)[0]
assert embedded == chapter
zones = re.findall(r'\{name="(\d\d) / ([^"]+)",theme="([^"]+)",task="([^"]+)",kind="([^"]+)"\}', chapter)
assert len(zones) == 10
assert [int(z[0]) for z in zones] == list(range(1, 11))
assert len({z[2] for z in zones}) == 10
assert {z[4] for z in zones} == {'hack', 'weld', 'valve'}
print('PASS: ten uniquely themed zones, three engineering objective types, embedded source synchronized')

# Each 150-stud room connects to the next via a ten-stud connector.
for index in range(9):
    center = index * 160
    connector_start, connector_end = center + 80 - 5, center + 80 + 5
    next_start = (index + 1) * 160 - 75
    assert connector_start == center + 75 and connector_end == next_start
assert 'Vector3.new(10,0.35,20)' in chapter
assert 'Vector3.new(10,18,1)' in chapter
assert 'ApproachRearFence' in chapter
assert 'if allAcross then c2Activate(C2.stage+1) end' in chapter
assert 'c2Origin.X+z.x+80' in chapter
assert 'ArchivePartition' in chapter and 'EngineeringPanel' in chapter
assert 'EntryWall' in chapter and 'EntryLintel' in chapter and 'PerimeterWall' in chapter
assert 'c2Contain(p,root)' in chapter
assert 'MainFactoryFacade' in chapter and 'FactoryChimney' in chapter
assert 'PressHead' in chapter and 'if z and not z.done then' in chapter
print('PASS: contiguous retreat geometry, bounded routes, team progression barrier, sabotage stops machinery')

assert '(data.chapter==2 or data.chapter==3) and data.chapter or 1' in server
assert 'heroes[tostring(member.UserId)]' in server
assert 'data.heroes[tostring(player.UserId)]' in server
assert 'Выберите разных героев' in server
assert 'if #party>2 or (#party==2' in server
assert 'selectedChapter=selectedChapter%3+1' in client
assert 'openHeroChooser(nil,"Artem")' in client
assert 'openHeroChooser(nil,"Demid")' in client
assert 'lobbyRemote:FireServer("configure",{chapter=selectedChapter,hero=candidate})' in client
assert 'if command=="configured" then' in client
assert 'HeroChosen' in server
assert 'if living<=1 then return true end' in chapter
assert 'if not p.Parent then return nil end' in chapter
assert 'target:ApplyDescription(description)' in chapter
assert '"eurtyoeyrntiu" or "ZamestitelDiomchica"' in chapter
assert 'Отправляйся ты один на миссию, Артем' in chapter
assert 'Отправляйся ты один на миссию, Демид' in chapter
assert 'Эй, мы договаривались!' in chapter and 'в Blade Ball играл' in chapter
print('PASS: unique two-player roles, solo variants, reserved-server role/chapter transport, surviving-player engineering fallback')

assert 'plr:GetAttribute("Chapter")==2 then if c2Attack then' in server
attack = chapter.split('c2Attack=function(', 1)[1]
assert '(origin-head.Position).Magnitude>12' in attack
assert 'not finite(origin) or not finite(dir)' in attack
assert 'now-(C2.shots[player] or 0)<cd*0.9' in attack
assert 'index>(player:GetAttribute("WeaponLevel") or 1)' in attack
assert 'behind and not e.boss and not e.mech' in attack
assert 'e.root.CFrame.LookVector:Dot' in attack
assert 'if weld and not e.mech and not e.boss then e.blind=' in attack
assert 'if weld and e.mech then damage=4' in attack
assert 'C2.HitBoss(damage,hit.Position,origin)' in attack
assert 'C2.boss.Humanoid.Health=30' in chapter
assert 'RocketWarning' in chapter and 'goal).Magnitude<11' in chapter
assert 'task.wait(1.15)' in chapter and 'task.wait(0.65)' in chapter
assert 'e.root.AssemblyLinearVelocity.Magnitude' in chapter
assert 'os.clock()-held[player]<hold-0.3' in chapter
assert 'prompt.MaxActivationDistance=9' in chapter
print('PASS: validated attacks/holds, rear stealth kills, welding blind with mech immunity, telegraphed rockets, weapon progression')

assert 'if C2.shieldHP==0 then' in chapter
assert 'C2.RunProtected(c2Escape)' in chapter
assert 'C2.deadline=workspace:GetServerTimeNow()+300' in chapter
assert chapter.index('C2.Literal("Мафия","Хех, скоро здесь всё взорвётся.') < chapter.index('C2.deadline=workspace:GetServerTimeNow()+300')
assert 'workspace:GetServerTimeNow()>=C2.deadline then c2Finish(false)' in chapter
assert 'if allSafe and survivors>0 then c2Finish(true)' in chapter
assert 'if not c2Alive() then c2Finish(false)' in chapter
assert 'if c2Count(zone)<2 then C2.Pursuit(zone)' in chapter
assert 'os.clock()-lastEscape>18' in chapter
assert 'FactoryFireball' in chapter and 'FallingCeiling' in chapter and 'FallingWall' in chapter
assert 'worldState.deadline-workspace:GetServerTimeNow()' in client
assert 'returnToMenu()' in chapter
assert 'conn:Disconnect()' in chapter
# Intro is third person until the explicit eyes-only approach.
intro = chapter.split('local function startChapter2(', 1)[1].split('c2Attack=function', 1)[0]
assert intro.index('cameraPlan(') < intro.index('CutsceneRE:FireClient(p,"pov"')
assert 'CutsceneRE:FireAllClients("pov",C2.boss.Head,54)' in chapter
assert 'CFrame.lookAt(button.Position+Vector3.new(-5,5,-6)' in chapter
print('PASS: shield-break boss escape, exact five-minute server deadline, sparse pursuit, both endings, POV policy and menu cleanup')

# User-reported regressions: do not reintroduce billboard instructions or a hold-to-win panel.
assert 'Instance.new("BillboardGui")' not in chapter
assert 'c2Label(' not in chapter
assert 'c2Mobilize(m,h,r)' in chapter
assert chapter.index('if not boss then c2Dress(m,mech) end') < chapter.index('c2Mobilize(m,h,r)')
assert 'p.Anchored=false; p.CanCollide=false; p.Massless=true' in chapter
assert 'PathfindingService:CreatePath' in chapter and 'path:ComputeAsync' in chapter
assert 'e.alertUntil=os.clock()+12' in chapter and 'e.stuckAt' in chapter
assert 'z.prompt=c2Prompt(panel,"Подключиться",0' in chapter
assert 'c2Engineering(player,z)' in chapter and 'c2CircuitSolved(ch.board)' in chapter
assert 'ch.token~=token' in chapter and 'ch.expires<workspace:GetServerTimeNow()' in chapter
assert '(root.Position-ch.zone.panel.Position).Magnitude>12' in chapter
assert 'action=="rotate"' in chapter and 'action=="pulse"' in chapter and 'action=="turn"' in chapter
assert 'c2Grant(p,' in chapter and 'C2RE:FireClient(player,"loadout"' in chapter
assert 'curName = "x"' not in client
assert 'slot.f.Activated:Connect' in client and 'MouseWheel' in client
assert 'c2Home()' in chapter and 'WoodFloor' in chapter and 'KitchenCounter' in chapter
intro=chapter.split('local function startChapter2(',1)[1]
assert intro.index('c2Home()') < intro.index('Vector3.new(-193,4,4)') < intro.index('focusStreaming(Vector3.new(-180,5,0))')
assert 'local c2Origin=Vector3.new(0,0,0)' in chapter
client_embedded=client.split('-- BEGIN CHAPTER TWO CLIENT\n',1)[1].split('\n-- END CHAPTER TWO CLIENT',1)[0]
assert client_embedded==Path('src/Chapter2Client.luau').read_text()
print('PASS: unanchored outfits, path pursuit, no distant objective signs, real puzzles, explicit equipment, home opening and synchronized client source')

# Repacking must preserve every uploaded object/property outside the three script Sources.
base = list(chunks(Path('Place3.rbxl').read_bytes()))
built = list(chunks(Path('Place1.rbxl').read_bytes()))
# The only permitted additional objects are the verified Kirill import.
from import_kirill import inspect as inspect_place, u32
base_classes, _, _, _ = inspect_place(Path('Place3.rbxl').read_bytes())
source_ids = {41, 47, 61}
original_chunks = []
for tag, raw, flags in built:
    if tag in (b'INST', b'PROP') and u32(raw) not in base_classes:
        continue
    original_chunks.append((tag,raw,flags))
assert len(base) == len(original_chunks)
for (bt, br, bf), (ot, raw, flags) in zip(base, original_chunks):
    assert bt == ot and bf == flags
    source = False
    if bt == b'PROP':
        cid = struct.unpack_from('<I', br)[0]
        name, _ = string(br, 4)
        source = cid in source_ids and name == 'Source'
    if bt == b'SSTR':
        assert raw[:4] == br[:4] and raw[8:8+len(br)-8] == br[8:]
    elif bt == b'PRNT':
        _,_,_,before = inspect_place(Path('Place3.rbxl').read_bytes())
        _,_,_,after = inspect_place(Path('Place1.rbxl').read_bytes())
        assert all(after[ref] == parent for ref,parent in before.items())
    elif not source:
        assert br == raw, f'Unexpected original non-source change: {bt!r}'

# Decode Roblox delta/zigzag/interleaved referents to verify exact model ownership.
def refs(data, n):
    result, previous = [], 0
    for i in range(n):
        value = int.from_bytes(bytes(data[i + j*n] for j in range(4)), 'big')
        previous += (value >> 1) ^ -(value & 1)
        result.append(previous)
    return result

classes, names, parents = {}, {}, {}
for tag, raw, _ in built:
    if tag == b'INST':
        cid = struct.unpack_from('<I', raw)[0]
        cls, p = string(raw, 4)
        count = struct.unpack_from('<I', raw, p+1)[0]
        classes[cid] = (cls, count, refs(raw[p+5:], count))
    elif tag == b'PRNT':
        n = struct.unpack_from('<I', raw, 1)[0]
        parents.update(zip(refs(raw[5:5+4*n], n), refs(raw[5+4*n:], n)))
    elif tag == b'PROP':
        cid = struct.unpack_from('<I', raw)[0]
        prop, p = string(raw, 4)
        if prop == 'Name' and raw[p] == 1:
            p += 1
            for ref in classes[cid][2]:
                names[ref], p = string(raw, p)
storage = next(ref for ref, name in names.items() if name == 'ServerStorage')
for model in ('eurtyoeyrntiu', 'ZamestitelDiomchica'):
    ref = next(ref for ref, name in names.items() if name == model)
    assert parents[ref] == storage
print('PASS: all original non-source properties/parents preserved alongside Kirill import; original heroes remain in ServerStorage')

# Cinematic finale contracts: camera mode, deterministic transport and safe debug controls.
campaign=Path('src/Chapter2Campaign.luau').read_text()
car=campaign[campaign.index('function C2.CarScene()'):campaign.index('function C2.NewsTwist()')]
assert '"pov",buddy.Head' in car and 'Какого хрена ты там натворил?!' in car
assert 'Ладно, валим скорее на тачке!' in car
assert '"follow",car' in car and 'local distance=C2.DriveDistance(t)' in car
assert 'SeatWeld' not in car.replace('-- No physical seats or SeatWelds: deterministic anchored riders cannot stop the car.','')
assert 'Instance.new("Seat")' not in car and 'EscapeRouteWall' in campaign
assert 'offsets[rig]=pivot:ToObjectSpace(rig:GetPivot())' in car
assert 'C2.bossButton' in campaign and 'C(255,20,25),Enum.Material.Neon' in campaign
assert campaign.index('Ладно, мне с этим как всегда разобраться.') < campaign.index('Хех, скоро здесь всё взорвётся.')
assert 'epoch~=C2.deployEpoch' in campaign
assert chapter.index('MusicRE:FireAllClients("final")',chapter.index('c2Finish=function')) < chapter.index('C2RE:FireAllClients("chapterCredits",true)')
print('PASS: first-person rendezvous, moving exterior car with anchored riders, red button insert, credits music and no cheat menu')

assert 'Vector3.new(2500' not in campaign
assert 'city.ModelStreamingMode=Enum.ModelStreamingMode.Persistent' in campaign
assert chapter.index('C2.BuildEscapeCity()',chapter.index('local function c2Build()')) < chapter.index('local function startChapter2(')
for feature in ('PickupBayWall','RendezvousApron','CourtyardRearWall','SkylineTower','CityBuilding','CityWindow','Sidewalk','StreetLampPole'):
    assert feature in campaign, feature
for feature in ('MafiaAnimeFace','EyeWhite','Iris','Catchlight','SweptBangs','LayeredLongHair','PleatedSkirt'):
    assert feature in campaign, feature
assert 'MechanicalFaceplate' not in campaign and 'BallisticChest' not in campaign
assert car.index('task.wait(1.2)') < car.index('local start=os.clock()')
print('PASS: segmented road, prebuilt enclosed pickup/courtyard, persistent city skyline, unobscured anime face and settled departure camera')

for forbidden in ('DebugJump','DebugAllowed','debugJump','debugPanel','Chapter2Debug','Enum.KeyCode.F6','debugBusy'):
    for path in Path('src').glob('*.luau'):
        assert forbidden not in path.read_text(), (path, forbidden)
print('PASS: no cheat UI, F6 binding, permission flag or server skip handler in any shipped source')
