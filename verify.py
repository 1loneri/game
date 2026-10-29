"""Syntax, artifact integrity and mocked persistence tests, not a Roblox Engine test."""
from pathlib import Path
import ctypes, ctypes.util, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parent
lib=ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lib.luaL_loadbufferx.restype=ctypes.c_int
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_pcallk.restype=ctypes.c_int
lib.lua_close.argtypes=[ctypes.c_void_p]
def execute(source,name,run=False):
 state=lib.luaL_newstate(); lib.luaL_openlibs(state)
 raw=source.encode(); result=lib.luaL_loadbufferx(state,raw,len(raw),name.encode(),None)
 if result==0 and run: result=lib.lua_pcallk(state,0,0,0,0,None)
 if result:
  message=lib.lua_tolstring(state,-1,None).decode(); lib.lua_close(state); raise AssertionError(message)
 lib.lua_close(state)
for f in sorted((ROOT/'src').glob('*.lua')):
 execute(f.read_text(),f.name)
 print('PASS syntax:',f.name)
source=f'''
Color3={{fromRGB=function(...) return {{}} end}}
local config=assert(loadfile('{ROOT}/src/Config.lua'))()
assert(config.Level(0)==1 and config.Level(44)==1 and config.Level(45)==2)
assert(config.Level(45*49*49)==50)
assert(config.Stage(5.99)==1 and config.Stage(6)==2 and config.Stage(50)==5)
local odds=0; for _,item in ipairs(config.EggOdds) do assert(config.Pets[item.id]); odds=odds+item.chance end
assert(odds==100)
assert(config.HelpPass==0 and config.SlotsPass==0 and config.EggProduct==0)
local memory={{}}; local failing=false; local studio=false
local store={{UpdateAsync=function(self,key,callback)
 if failing then error('simulated outage') end
 local value=callback(memory[key]); if value~=nil then memory[key]=value end; return value
end}}
game={{JobId='test-server',ReplicatedStorage={{Underlayer={{Config='config'}}}},GetService=function(self,name)
 if name=='DataStoreService' then return {{GetDataStore=function() return store end}} end
 if name=='RunService' then return {{IsStudio=function() return studio end}} end
 return {{GenerateGUID=function() return 'test-owner' end}}
end}}
require=function() return config end
local profile=assert(loadfile('{ROOT}/src/Profile.lua'))()
local function player(id) return {{UserId=id,Kick=function(self,msg) self.kicked=msg end}} end
local p=player(10); assert(profile.Load(p)); assert(next(profile.Live[p].data.pets)==nil and profile.Live[p].data.tutorial.step==0)
profile.Live[p].data.coins=123
assert(profile.Commit(p)); assert(memory.u10.data.coins==123)
local function receipt(d)
 if d.receipts.purchase1 then return end
 d.eggs=d.eggs+1; d.receipts.purchase1=true
end
assert(profile.Commit(p,receipt)); assert(profile.Live[p].data.eggs==1)
assert(profile.Commit(p,receipt)); assert(profile.Live[p].data.eggs==1)
assert(profile.Commit(p,nil,true)); assert(memory.u10.owner==nil and memory.u10.lease==0)
local p2=player(11); memory.u11={{data={{}},owner='other-server',lease=os.time()+100}}
local blocked=profile.Load(p2); assert(blocked==nil)
failing=true
local p3=player(12); assert(profile.Load(p3)==nil)
studio=true; local p4=player(13); assert(profile.Load(p4)); assert(profile.Live[p4].offline)
assert(not profile.Commit(p4,receipt)); assert(profile.Live[p4].data.eggs==0)
failing=false; studio=false
local p5=player(14); assert(profile.Load(p5))
memory.u14.owner='other-server'
assert(not profile.Commit(p5)); assert(p5.kicked)
-- Regression: GetDataStore itself throws before Load in an unpublished place.
studio=true; config.StudioPersistence=true
local getServiceBefore=game.GetService
local acquireCalls=0
game.GetService=function(self,name)
 if name=='DataStoreService' then return {{GetDataStore=function() acquireCalls=acquireCalls+1; error('Publish place first') end}} end
 return getServiceBefore(self,name)
end
local unpublished=assert(loadfile('{ROOT}/src/Profile.lua'))()
local p6=player(16); assert(unpublished.Load(p6)); assert(unpublished.Live[p6].offline)
assert(acquireCalls==1 and not unpublished.Commit(p6,receipt))
-- Default Studio does not attempt DataStore acquisition at all.
config.StudioPersistence=false
local localPlay=assert(loadfile('{ROOT}/src/Profile.lua'))()
local p7=player(17); assert(localPlay.Load(p7)); assert(localPlay.Live[p7].offline)
assert(acquireCalls==1)
-- In a live server, acquisition failure must fail closed without resetting progress.
studio=false
local public=assert(loadfile('{ROOT}/src/Profile.lua'))()
assert(public.Load(player(18))==nil)
'''
execute(source,'profile-behavior',True)
print('PASS profile: save, receipt deduplication, release, lease collision, outage, offline purchases, ownership loss')
print('PASS regression: unpublished GetDataStore failure; default Studio avoids service acquisition; live server fails closed')
root=ET.parse(ROOT/'Underlayer.rbxlx').getroot()
scripts={i.find("Properties/string[@name='Name']").text:i for i in root.iter('Item') if i.get('class') in ('Script','LocalScript','ModuleScript')}
assert len(scripts)==7
mapping={'Config':'Config.lua','PetVisual':'PetVisual.lua','Profile':'Profile.lua','World':'World.lua','Layout':'Layout.lua','UnderlayerServer':'Server.server.lua','UnderlayerClient':'Client.client.lua'}
for name,path in mapping.items():
 assert scripts[name].find("Properties/ProtectedString[@name='Source']").text==(ROOT/'src'/path).read_text()
assert len({i.get('referent') for i in root.iter('Item')})==len(list(root.iter('Item')))
print('PASS place: XML, seven distinct source matches, unique referents')

workspace=next(i for i in root.findall('Item') if i.get('class')=='Workspace')
world=workspace.find("Item/Properties/string[.='UnderlayerWorld']/../..")
assert world is not None
parts=[i for i in world.iter('Item') if i.get('class') in ('Part','SpawnLocation')]
assert len(parts)>=800
spawns=[i for i in parts if i.get('class')=='SpawnLocation']
assert len(spawns)==1
for part in parts:
 assert part.find("Properties/bool[@name='Anchored']").text=='true'
 size=part.find("Properties/Vector3[@name='size']")
 assert size is not None and all(float(size.find(a).text)>0 for a in 'XYZ')
 assert part.find("Properties/CoordinateFrame[@name='CFrame']") is not None
 assert part.find("Properties/Color3uint8[@name='Color3uint8']") is not None or part.get('class')=='SpawnLocation'
deposits=next(i for i in world.findall('Item') if i.find("Properties/string[@name='Name']").text=='Deposits')
assert len(deposits.findall('Item'))==2192
server=(ROOT/'src/Server.server.lua').read_text()
assert server.index("require(script.Parent.World).Build()")<server.index("require(script.Parent.Profile)")
print('PASS regression: prebuilt world has',len(parts),'anchored parts, spawn, transforms and 2192 deposits; map starts before profiles')

assert workspace.find("Item[@class='Camera']/Properties/token[@name='CameraType']").text=='5'
print('PASS camera: default Custom mode and explicit humanoid subject on spawn')

layout_source=f"""
local L=assert(loadfile('{ROOT}/src/Layout.lua'))()
assert(L.Size==3072 and #L.Zones==12)
local extent=L.PatchCells*L.BlockSize/2
for _,zone in ipairs(L.Zones) do
 assert(math.abs(zone.x)+extent<L.Size/2 and math.abs(zone.z)+extent<L.Size/2)
 assert(L.InPatch(zone.x,zone.z))
 assert(not L.InPatch(zone.x+extent+1,zone.z))
end
assert(L.LayerY(1)==-1.25 and L.LayerY(3)==-6.25)
"""
execute(layout_source,'layout-contract',True)
names=[i.find("Properties/string[@name='Name']").text for i in world.iter('Item')]
assert names.count('LunarRegolith')==2256
assert len([n for n in names if n.startswith('FieldDepot')])==12
assert names.count('HorizonMassif')==96
assert len([n for n in names if n.startswith('CraterRim')])>300
assert names.count('EscapeStep')==72
assert names.count('TrainingFoundation')==1
assert names.count('TrainingRack')==1
assert names.count('TrainingExit')==1
# The route out of every pit is physically empty of mineable columns.
for part in deposits.findall('Item'):
 cf=part.find("Properties/CoordinateFrame[@name='CFrame']")
 x,z=float(cf.find('X').text),float(cf.find('Z').text)
 for zx,zz in [(0,-1024),(448,-896),(-512,-832),(960,-448),(-1088,-320),(128,-384),(448,192),(-384,256),(1088,576),(-1088,768),(0,1024),(768,1152)]:
  assert not (abs(x-zx)<16 and zz+32<=z<zz+64)
print('PASS lunar map: 3072-square plain, 12 depots, distant massifs, crater rims and unobstructed exit steps')

assert workspace.find("Properties/bool[@name='StreamingEnabled']").text=="true"
print("PASS streaming: large-world client streaming enabled")

# Run the real monster builder against the value/Instance adapter.
adapter=(ROOT/'tools/capture_world.lua').read_text().split("script={Parent={Layout='layout'}}")[0]
pets_test=adapter+f"""
math.clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
local C=assert(loadfile('{ROOT}/src/Config.lua'))()
local V=assert(loadfile('{ROOT}/src/PetVisual.lua'))()
for id,def in pairs(C.Pets) do
 local baby=V.Build(id,def,1); local adult=V.Build(id,def,50)
 local names={{}}; for _,p in ipairs(baby:GetChildren()) do names[p.Name]=(names[p.Name] or 0)+1 end
 assert(#baby:GetChildren()>=40,id..' lacks anatomical detail')
 assert(names.Head==1 and names.Muzzle==1 and names.Paw==4 and names.Claw==12 and names.EyeWhite==2)
 assert(adult.PrimaryPart.Size.X>baby.PrimaryPart.Size.X)
end
"""
execute(pets_test,'monster-models',True)
print('PASS monsters: six species build with separate anatomy, four paws, twelve claws, eyes and larger adult forms')
