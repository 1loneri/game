from pathlib import Path
import xml.etree.ElementTree as ET
import json,zipfile
BASE=Path(__file__).resolve().parent
counter=0
root=ET.Element('roblox',{'version':'4','xmlns:xmime':'http://www.w3.org/2005/05/xmlmime','xmlns:xsi':'http://www.w3.org/2001/XMLSchema-instance','xsi:noNamespaceSchemaLocation':'http://www.roblox.com/roblox.xsd'})
ET.SubElement(root,'External').text='null'
ET.SubElement(root,'External').text='nil'
def item(parent,cls,name,source=None):
 global counter
 counter+=1
 el=ET.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{counter}'})
 props=ET.SubElement(el,'Properties')
 ET.SubElement(props,'string',{'name':'Name'}).text=name
 if source is not None: ET.SubElement(props,'ProtectedString',{'name':'Source'}).text=source
 return el
workspace=item(root,'Workspace','Workspace')
rs=item(root,'ReplicatedStorage','ReplicatedStorage')
f=item(rs,'Folder','Underlayer')
item(f,'RemoteEvent','Action')
for name in ['Config','PetVisual']: item(f,'ModuleScript',name,(BASE/'src'/f'{name}.lua').read_text())
sss=item(root,'ServerScriptService','ServerScriptService')
for name in ['Profile','World']: item(sss,'ModuleScript',name,(BASE/'src'/f'{name}.lua').read_text())
item(sss,'Script','UnderlayerServer',(BASE/'src/Server.server.lua').read_text())
sp=item(root,'StarterPlayer','StarterPlayer')
sps=item(sp,'StarterPlayerScripts','StarterPlayerScripts')
item(sps,'LocalScript','UnderlayerClient',(BASE/'src/Client.client.lua').read_text())
item(root,'Lighting','Lighting')
item(root,'StarterGui','StarterGui')
ET.indent(root)
ET.ElementTree(root).write(BASE/'Underlayer.rbxlx',encoding='utf-8',xml_declaration=True)
project={'name':'Underlayer','tree':{'$className':'DataModel','ReplicatedStorage':{'$className':'ReplicatedStorage','Underlayer':{'$className':'Folder','Config':{'$path':'src/Config.lua'},'PetVisual':{'$path':'src/PetVisual.lua'},'Action':{'$className':'RemoteEvent'}}},'ServerScriptService':{'$className':'ServerScriptService','UnderlayerServer':{'$path':'src/Server.server.lua'},'World':{'$path':'src/World.lua'},'Profile':{'$path':'src/Profile.lua'}},'StarterPlayer':{'$className':'StarterPlayer','StarterPlayerScripts':{'$className':'StarterPlayerScripts','UnderlayerClient':{'$path':'src/Client.client.lua'}}}}}
(BASE/'default.project.json').write_text(json.dumps(project,indent=2))
print('Built', BASE/'Underlayer.rbxlx')
