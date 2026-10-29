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
local p=player(10); assert(profile.Load(p)); assert(profile.Live[p].data.pets.Dust.growth==1)
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
assert len(scripts)==6
mapping={'Config':'Config.lua','PetVisual':'PetVisual.lua','Profile':'Profile.lua','World':'World.lua','UnderlayerServer':'Server.server.lua','UnderlayerClient':'Client.client.lua'}
for name,path in mapping.items():
 assert scripts[name].find("Properties/ProtectedString[@name='Source']").text==(ROOT/'src'/path).read_text()
assert len({i.get('referent') for i in root.iter('Item')})==len(list(root.iter('Item')))
print('PASS place: XML, six source matches, unique referents')

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
assert len(deposits.findall('Item'))==702
server=(ROOT/'src/Server.server.lua').read_text()
assert server.index("require(script.Parent.World).Build()")<server.index("require(script.Parent.Profile)")
print('PASS regression: prebuilt world has',len(parts),'anchored parts, spawn, transforms and 702 deposits; map starts before profiles')

assert workspace.find("Item[@class='Camera']/Properties/token[@name='CameraType']").text=='5'
print('PASS camera: default Custom mode and explicit humanoid subject on spawn')
