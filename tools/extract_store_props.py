"""Extract static visuals from Roblox's free endorsed architecture pack.
Input: locally converted rbxmx for Creator Store asset 10980780693.
No scripts, physics blobs, emitters, sounds or lights are retained.
"""
from pathlib import Path
import xml.etree.ElementTree as E
import numpy as np,copy,json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT.parent/'roblox_architecture.rbxmx'
source=E.parse(SOURCE).getroot()
root=E.Element('roblox',version='4');E.SubElement(root,'External').text='null';E.SubElement(root,'External').text='nil'
container=E.SubElement(root,'Item',{'class':'Folder','referent':'StorePropsRoot'})
p=E.SubElement(container,'Properties');E.SubElement(p,'string',name='Name').text='RobloxStationProps'
keep={'Name','CFrame','size','InitialSize','MeshId','TextureID','Color3uint8','Material','DoubleSided','Reflectance','Transparency','RenderFidelity'}
maps={'Name','AlphaMode','ColorMap','MetalnessMap','NormalMap','RoughnessMap','TexturePack'}
placements=[('Lobby_Vent',(-48,24,-1981),7),('Lobby_Vent',(38,24,-1981),7),('Energey_Cond',(59,4,-1948),5),('EmergencyKit',(-58,6,-1940),3),('Canister_Recharge',(-56,5,-1900),6),('Lobby_AC',(58,8,-1903),8),('EmergencySuitLocker01',(-56,5,-1882),8)]
index=0;report=[]
for source_name,target,height in placements:
 model=next(i for i in source.iter('Item') if i.get('class')=='Model' and i.findtext("Properties/string[@name='Name']")==source_name)
 parts=[]
 for part in model.iter('Item'):
  if part.get('class')!='MeshPart':continue
  pp=part.find('Properties'); name=pp.findtext("string[@name='Name']",'')
  if any(word in name.lower() for word in ['sign','display','decal','glow','light']):continue
  cf=pp.find("CoordinateFrame[@name='CFrame']"); sz=pp.find("Vector3[@name='size']")
  if cf is None or sz is None:continue
  pos=np.array([float(cf.findtext(k)) for k in 'XYZ']); rot=np.array([float(cf.findtext(f'R{r}{c}')) for r in range(3) for c in range(3)]).reshape(3,3)
  size=np.array([float(sz.findtext(k)) for k in 'XYZ']); extent=np.abs(rot)@size/2
  parts.append((part,pos,rot,size,extent))
 if not parts:continue
 lower=np.min([pos-ext for _,pos,_,_,ext in parts],axis=0);upper=np.max([pos+ext for _,pos,_,_,ext in parts],axis=0)
 center=(lower+upper)/2;scale=height/(upper-lower)[1]
 index+=1;group=E.SubElement(container,'Item',{'class':'Model','referent':f'StoreModel{index}'})
 props=E.SubElement(group,'Properties');E.SubElement(props,'string',name='Name').text=source_name
 for part,pos,rot,size,_ in parts:
  index+=1;new=E.SubElement(group,'Item',{'class':'MeshPart','referent':f'StoreMesh{index}'})
  pp=E.SubElement(new,'Properties')
  for property in part.find('Properties'):
   if property.get('name') in keep and property.get('name') not in ('CFrame','size','InitialSize'): pp.append(copy.deepcopy(property))
  E.SubElement(pp,'bool',name='Anchored').text='true'
  for field in ['CanCollide','CanQuery','CanTouch']: E.SubElement(pp,'bool',name=field).text='false'
  E.SubElement(pp,'bool',name='CastShadow').text='true'
  cf=E.SubElement(pp,'CoordinateFrame',name='CFrame')
  position=(pos-center)*scale+np.array(target)
  for k,v in zip('XYZ',position):E.SubElement(cf,k).text=str(v)
  for r in range(3):
   for c in range(3):E.SubElement(cf,f'R{r}{c}').text=str(rot[r,c])
  # InitialSize remains at the source mesh's native scale. Size applies the instance scale.
  for field,values in [('size',size*scale),('InitialSize',size)]:
   node=E.SubElement(pp,'Vector3',name=field)
   for k,v in zip('XYZ',values):E.SubElement(node,k).text=str(v)
  for child in part.findall('Item'):
   if child.get('class')=='SurfaceAppearance':
    index+=1;sa=E.SubElement(new,'Item',{'class':'SurfaceAppearance','referent':f'StoreSurface{index}'})
    sp=E.SubElement(sa,'Properties')
    for prop in child.find('Properties'):
     if prop.get('name') in maps:sp.append(copy.deepcopy(prop))
 report.append({'name':source_name,'mesh_parts':len(parts),'height':height})
E.ElementTree(root).write(ROOT/'assets/Roblox_Station_Props.rbxmx',encoding='utf-8',xml_declaration=True)
print(json.dumps(report,ensure_ascii=False))
