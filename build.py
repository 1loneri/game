"""Build a Studio place with a visible world, before any server code executes."""
from pathlib import Path
import xml.etree.ElementTree as ET
import json, math, ctypes, ctypes.util, tempfile
BASE=Path(__file__).resolve().parent

def capture_scene():
    library=ctypes.util.find_library('lua5.4')
    if not library: raise RuntimeError('Install Lua 5.4 shared library to rebuild the prebuilt scene')
    lib=ctypes.CDLL(library)
    lib.luaL_newstate.restype=ctypes.c_void_p
    lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
    lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
    lib.luaL_loadbufferx.restype=ctypes.c_int
    lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
    lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]; lib.lua_tolstring.restype=ctypes.c_char_p
    lib.lua_close.argtypes=[ctypes.c_void_p]
    with tempfile.TemporaryDirectory() as temp:
        dest=Path(temp)/'scene.json'
        code=(f'WORLD_LAYOUT={json.dumps(str(BASE/"src/Layout.lua"))}\nWORLD_SOURCE={json.dumps(str(BASE/"src/World.lua"))}\nWORLD_OUTPUT={json.dumps(str(dest))}\n'+(BASE/'tools/capture_world.lua').read_text()).encode()
        state=lib.luaL_newstate(); lib.luaL_openlibs(state)
        status=lib.luaL_loadbufferx(state,code,len(code),b'world-capture',None)
        if status==0: status=lib.lua_pcallk(state,0,0,0,0,None)
        if status:
            error=lib.lua_tolstring(state,-1,None).decode(); lib.lua_close(state); raise RuntimeError(error)
        lib.lua_close(state)
        return json.loads(dest.read_text())

counter=0
root=ET.Element('roblox',{'version':'4','xmlns:xmime':'http://www.w3.org/2005/05/xmlmime','xmlns:xsi':'http://www.w3.org/2001/XMLSchema-instance','xsi:noNamespaceSchemaLocation':'http://www.roblox.com/roblox.xsd'})
ET.SubElement(root,'External').text='null'; ET.SubElement(root,'External').text='nil'

def item(parent,cls,name,source=None):
    global counter
    counter+=1
    el=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{counter}'})
    props=ET.SubElement(el,'Properties'); ET.SubElement(props,'string',{'name':'Name'}).text=name
    if source is not None: ET.SubElement(props,'ProtectedString',{'name':'Source'}).text=source
    return el

TOKENS={'Enum.Material.Slate':800,'Enum.Material.Sand':1296,'Enum.Material.Metal':1088,'Enum.Material.Concrete':816,'Enum.Material.Neon':288,'Enum.Material.Fabric':1312,'Enum.Material.SmoothPlastic':272,'Enum.Material.Glass':1568,'Enum.NormalId.Bottom':4,'Enum.SurfaceType.Smooth':0,'Enum.PartType.Ball':0,'Enum.PartType.Block':1,'Enum.NormalId.Front':5,'Enum.Font.GothamBold':20}

def prop(el,name,value):
    ps=el.find('Properties')
    if isinstance(value,bool): ET.SubElement(ps,'bool',{'name':name}).text=str(value).lower()
    elif isinstance(value,(int,float)): ET.SubElement(ps,'int' if name=='StarCount' else 'float',{'name':name}).text=str(value)
    elif isinstance(value,str):
        if value.startswith('Enum.'):
            assert value in TOKENS, value
            ET.SubElement(ps,'token',{'name':name}).text=str(TOKENS[value])
        else: ET.SubElement(ps,'string',{'name':name}).text=value
    elif isinstance(value,dict):
        kind=value['_type']
        if kind=='Vector3':
            p=ET.SubElement(ps,'Vector3',{'name':name})
            for key in 'XYZ': ET.SubElement(p,key).text=str(value[key])
        elif kind=='Color3':
            p=ET.SubElement(ps,'Color3',{'name':name})
            for key in 'RGB': ET.SubElement(p,key).text=str(value[key])
        elif kind=='CFrame':
            p=ET.SubElement(ps,'CoordinateFrame',{'name':name})
            for key in 'XYZ': ET.SubElement(p,key).text=str(value[key])
            for r in range(3):
                for c in range(3): ET.SubElement(p,f'R{r}{c}').text=str(value['R'][r*3+c])
        elif kind=='UDim2':
            p=ET.SubElement(ps,'UDim2',{'name':name})
            for key in ('XS','XO','YS','YO'): ET.SubElement(p,key).text=str(value[key.lower()])
        else: raise ValueError(kind)

# Position is a runtime convenience; XML stores CFrame. Material/shape property names
# follow Roblox's serialization names, with all default physical parts anchored.
def node(parent,desc):
    values=desc['properties']; el=item(parent,desc['class'],values.get('Name',desc['class']))
    for key,value in values.items():
        if desc['class']=='Sky' and key.startswith('Skybox'):
            content=ET.SubElement(el.find('Properties'),'Content',{'name':key}); ET.SubElement(content,'null'); continue
        if key in ('Name','Position') or (key=='CFrame' and value is None): continue
        if key=='ClockTime' and desc['class']=='Lighting':
            prop(el,'TimeOfDay',f'{int(value):02d}:{round((value%1)*60):02d}:00'); continue
        serialized={'Size':'size','Shape':'shape'}.get(key,key) if desc['class'] in ('Part','SpawnLocation') else key
        if key=='Color' and desc['class'] in ('Part','SpawnLocation'):
            rgb=[round(value[k]*255) for k in 'RGB']
            ET.SubElement(el.find('Properties'),'Color3uint8',{'name':'Color3uint8'}).text=str(0xff000000 | rgb[0]<<16 | rgb[1]<<8 | rgb[2])
        else: prop(el,serialized,value)
    if desc['class'] in ('Part','SpawnLocation'):
        if 'CFrame' not in values:
            pos=values.get('Position',{'X':0,'Y':0,'Z':0})
            prop(el,'CFrame',{'_type':'CFrame','X':pos['X'],'Y':pos['Y'],'Z':pos['Z'],'R':[1,0,0,0,1,0,0,0,1]})
    for child in desc['children']:
        node(el,child)
    return el

workspace=item(root,'Workspace','Workspace')
prop(workspace,'StreamingEnabled',True)
for name,value in [('StreamingMinRadius',128),('StreamingTargetRadius',512)]:
    ET.SubElement(workspace.find('Properties'),'int',{'name':name}).text=str(value)
item(workspace,'Terrain','Terrain')
scene=capture_scene()
world=node(workspace,scene['world'])
# Static visuals extracted from the free, endorsed Roblox pack; scripts are absent.
asset_file=BASE/'assets/Roblox_Station_Props.rbxmx'
if asset_file.exists():
    for instance in ET.parse(asset_file).getroot().findall('Item'): world.append(instance)
rs=item(root,'ReplicatedStorage','ReplicatedStorage'); f=item(rs,'Folder','Underlayer'); item(f,'RemoteEvent','Action')
for name in ['Config','PetVisual','Layout']: item(f,'ModuleScript',name,(BASE/'src'/f'{name}.lua').read_text())
sss=item(root,'ServerScriptService','ServerScriptService')
for name in ['Profile','World','Layout','TerrainWorld']: item(sss,'ModuleScript',name,(BASE/'src'/f'{name}.lua').read_text())
item(sss,'Script','UnderlayerServer',(BASE/'src/Server.server.lua').read_text())
sp=item(root,'StarterPlayer','StarterPlayer'); prop(sp,'EnableMouseLockOption',False); sps=item(sp,'StarterPlayerScripts','StarterPlayerScripts')
item(sps,'LocalScript','UnderlayerClient',(BASE/'src/Client.client.lua').read_text())
node(root,scene['lighting']); item(root,'StarterGui','StarterGui')
# Initial editor camera looks from behind camp towards the excavation.
cam=item(workspace,'Camera','Camera')
# Build an orthonormal look-at matrix; -Z points toward target.
eye=(155,72,-1725); target=(0,20,-1920)
def norm(v):
    length=math.sqrt(sum(x*x for x in v)); return tuple(x/length for x in v)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
back=norm(tuple(a-b for a,b in zip(eye,target))); right=norm(cross((0,1,0),back)); up=cross(back,right)
rot=[right[i] if j==0 else up[i] if j==1 else back[i] for i in range(3) for j in range(3)]
prop(cam,'CFrame',{'_type':'CFrame','X':eye[0],'Y':eye[1],'Z':eye[2],'R':rot})
ET.SubElement(cam.find('Properties'),'token',{'name':'CameraType'}).text='5'
ET.SubElement(workspace.find('Properties'),'Ref',{'name':'CurrentCamera'}).text=cam.get('referent')
# Compact XML keeps a larger prebuilt lunar map practical to download.
ET.ElementTree(root).write(BASE/'Underlayer.rbxlx',encoding='utf-8',xml_declaration=False)
# Rojo keeps World.Build as a fallback for source-only syncs.
project={'name':'Underlayer','tree':{'$className':'DataModel','ReplicatedStorage':{'$className':'ReplicatedStorage','Underlayer':{'$className':'Folder','Config':{'$path':'src/Config.lua'},'PetVisual':{'$path':'src/PetVisual.lua'},'Layout':{'$path':'src/Layout.lua'},'Action':{'$className':'RemoteEvent'}}},'ServerScriptService':{'$className':'ServerScriptService','UnderlayerServer':{'$path':'src/Server.server.lua'},'World':{'$path':'src/World.lua'},'TerrainWorld':{'$path':'src/TerrainWorld.lua'},'Layout':{'$path':'src/Layout.lua'},'Profile':{'$path':'src/Profile.lua'}},'StarterPlayer':{'$className':'StarterPlayer','StarterPlayerScripts':{'$className':'StarterPlayerScripts','UnderlayerClient':{'$path':'src/Client.client.lua'}}}}}
(BASE/'default.project.json').write_text(json.dumps(project,indent=2))
print('Built visible world:',sum(1 for i in world.iter('Item') if i.get('class') in ('Part','SpawnLocation')),'physical parts')
print(BASE/'Underlayer.rbxlx')
