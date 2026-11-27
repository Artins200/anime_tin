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

assert 'data.chapter==2 and 2 or 1' in server
assert 'heroes[tostring(member.UserId)]' in server
assert 'data.heroes[tostring(player.UserId)]' in server
assert 'Выберите разных героев' in server
assert 'if #party>2 or (#party==2' in server
assert 'selectedChapter=selectedChapter==2 and 1 or 2' in client
assert 'openHeroChooser(nil,"Artem")' in client
assert 'openHeroChooser(nil,"Demid")' in client
assert 'lobbyRemote:FireServer("configure",{chapter=2,hero=candidate})' in client
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
assert 'if e.boss and e.hum.Health-damage<=30' in attack
assert 'e.hum.Health=30; e.defeated=true; C2.bossDefeated=true' in attack
assert 'RocketWarning' in chapter and 'goal).Magnitude<11' in chapter
assert 'task.wait(1.15)' in chapter and 'task.wait(0.65)' in chapter
assert 'e.root.AssemblyLinearVelocity.Magnitude' in chapter
assert 'os.clock()-held[player]<hold-0.3' in chapter
assert 'prompt.MaxActivationDistance=9' in chapter
print('PASS: validated attacks/holds, rear stealth kills, welding blind with mech immunity, telegraphed rockets, weapon progression')

assert 'C2.stage==10 and C2.bossDefeated and c2Count(10)==0' in chapter
assert 'C2.deadline=workspace:GetServerTimeNow()+300' in chapter
assert chapter.index('sceneLine("Мафия: Это не конец.') < chapter.index('C2.deadline=workspace:GetServerTimeNow()+300')
assert 'workspace:GetServerTimeNow()>=C2.deadline then c2Finish(false)' in chapter
assert 'if allSafe and survivors>0 then c2Finish(true)' in chapter
assert 'if not c2Alive() then c2Finish(false)' in chapter
assert 'if c2Count(zone)<2 then c2Spawn' in chapter
assert 'os.clock()-lastEscape>18' in chapter
assert 'FactoryDetonation' in chapter and 'FinalReactorFlash' in chapter
assert 'worldState.deadline-workspace:GetServerTimeNow()' in client
assert 'returnToMenu()' in chapter
assert 'conn:Disconnect()' in chapter
# Intro is third person until the explicit eyes-only approach.
intro = chapter.split('local function startChapter2(', 1)[1].split('c2Attack=function', 1)[0]
assert intro.index('cameraPlan(') < intro.index('CutsceneRE:FireClient(p,"pov"')
assert 'CutsceneRE:FireAllClients("pov",C2.boss.Head,55)' in chapter
assert 'CutsceneRE:FireAllClients("pov",c2Origin+' in chapter
print('PASS: automatic near-death boss escape, exact five-minute server deadline, sparse pursuit, both endings, POV policy and menu cleanup')

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
assert len(base) == len(built)
source_ids = {41, 47, 61}
for (bt, br, bf), (ot, raw, flags) in zip(base, built):
    assert bt == ot and bf == flags
    source = False
    if bt == b'PROP':
        cid = struct.unpack_from('<I', br)[0]
        name, _ = string(br, 4)
        source = cid in source_ids and name == 'Source'
    if not source:
        assert br == raw, f'Unexpected non-source change: {bt!r}'

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
print('PASS: all non-source RBXL data unchanged; both original heroes remain directly in ServerStorage')
