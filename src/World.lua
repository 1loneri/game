local Layout=require(script.Parent.Layout)
local W={}
function W.Build()
 local old=workspace:FindFirstChild('UnderlayerWorld')
 if old then
  local terminal=old:FindFirstChild('Terminal'); local bench=old:FindFirstChild('Workbench')
  if terminal and bench then
   local sell=terminal:FindFirstChildOfClass('ProximityPrompt'); local upgrade=bench:FindFirstChildOfClass('ProximityPrompt')
   if sell and upgrade then return {Root=old,Sell=sell,Upgrade=upgrade} end
  end
  old:Destroy()
 end
 local root=Instance.new('Folder'); root.Name='UnderlayerWorld'; root.Parent=workspace
 local function block(name,size,pos,color,material)
  local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=pos; p.Anchored=true
  p.Color=color; p.Material=material or Enum.Material.Slate; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=root; return p
 end
 local dust=Color3.fromRGB(135,137,140)
 local rock=Color3.fromRGB(98,102,109)
 local metal=Color3.fromRGB(69,78,86)
 local warm=Color3.fromRGB(227,186,110)
 -- Waypoint anchors remain for the HUD, without floating world billboards.
 local function sign(parent,txt)
  parent.Transparency=1; parent.CanCollide=false; parent.CanQuery=false
 end
 local function lamp(x,y,z)
  block('MarkerPost',Vector3.new(.6,3,.6),Vector3.new(x,y+1.5,z),metal,Enum.Material.Metal)
  local glow=block('MarkerLamp',Vector3.new(.9,.6,.9),Vector3.new(x,y+3.1,z),warm,Enum.Material.Neon)
  local light=Instance.new('PointLight'); light.Color=warm; light.Range=18; light.Brightness=.6; light.Parent=glow
 end
 local function sellTerminal(name,x,z)
  local p=block(name,Vector3.new(6,4,4),Vector3.new(x,2,z),metal,Enum.Material.Metal)
  local screen=block('DepotScreen',Vector3.new(4,1.5,.2),Vector3.new(x,3,z-2.1),Color3.fromRGB(171,202,194),Enum.Material.Neon)
  local prompt=Instance.new('ProximityPrompt'); prompt.Name='SellPrompt'; prompt.ActionText='Сдать ресурсы'; prompt.ObjectText='Пункт экспедиции'
  prompt.HoldDuration=.25; prompt.MaxActivationDistance=12; prompt.Parent=p
  return prompt
 end
 local lighting=game:GetService('Lighting')
 lighting.ClockTime=0; lighting.Brightness=0; lighting.ExposureCompensation=0; lighting.Ambient=Color3.fromRGB(0,0,0); lighting.OutdoorAmbient=Color3.fromRGB(0,0,0)
 lighting.FogColor=Color3.fromRGB(12,16,25); lighting.FogStart=1150; lighting.FogEnd=2800
 lighting.EnvironmentDiffuseScale=0; lighting.EnvironmentSpecularScale=0
 -- No atmospheric haze: this is an airless moon with a visible distant horizon.
 lighting.GlobalShadows=true
 local sky=Instance.new('Sky'); sky.Name='LunarSky'; sky.StarCount=2600; sky.CelestialBodiesShown=false
 sky.SkyboxBk=''; sky.SkyboxDn=''; sky.SkyboxFt=''; sky.SkyboxLf=''; sky.SkyboxRt=''; sky.SkyboxUp=''; sky.Parent=lighting
 -- Editor-visible ground around the central map. Runtime Terrain replaces these
 -- preview slabs. A station-sized cutout prevents floor z-fighting in either mode.
 local extent=4096; local core=1536; local stationZ=Layout.TrainingZ
 local function preview(x0,x1,z0,z1)
  block('OuterGroundPreview',Vector3.new(x1-x0,9,z1-z0),Vector3.new((x0+x1)/2,-4.6,(z0+z1)/2),dust,Enum.Material.Sand)
 end
 preview(-extent,-100,-extent,-core); preview(100,extent,-extent,-core)
 preview(-100,100,-extent,stationZ-85); preview(-100,100,stationZ+135,-core)
 preview(-extent,extent,core,extent); preview(-extent,-core,-core,core); preview(core,extent,-core,core)
 block('DeepBedrock',Vector3.new(Layout.Size+64,8,Layout.Size+64),Vector3.new(0,-13,0),rock)
 local half=Layout.Size/2
 for ix=0,Layout.Size/Layout.Tile-1 do
  for iz=0,Layout.Size/Layout.Tile-1 do
   local x=-half+Layout.Tile/2+ix*Layout.Tile; local z=-half+Layout.Tile/2+iz*Layout.Tile
   if not Layout.InPatch(x,z) then
    local shade=131+(ix*7+iz*11)%12
    block('LunarRegolith',Vector3.new(Layout.Tile,9,Layout.Tile),Vector3.new(x,-4.5,z),Color3.fromRGB(shade,shade+1,shade+4),Enum.Material.Sand)
   end
  end
 end
 local deposits=Instance.new('Folder'); deposits.Name='Deposits'; deposits.Parent=root
 for zi,zone in ipairs(Layout.Zones) do
  for ix=0,Layout.PatchCells-1 do for iz=0,Layout.PatchCells-1 do for layer=1,Layout.Layers do
   local x=zone.x-64+8+ix*Layout.BlockSize; local z=zone.z-64+8+iz*Layout.BlockSize
   local color=layer==1 and dust or (layer==2 and rock or Color3.fromRGB(101,98,116))
   if not (math.abs(x-zone.x)<16 and z>=zone.z+32) then
   local b=block('Layer'..layer,Vector3.new(Layout.BlockSize,2.5,Layout.BlockSize),Vector3.new(x,Layout.LayerY(layer),z),color,layer==1 and Enum.Material.Sand or Enum.Material.Slate)
   b.Parent=deposits
   end
  end end end
  local plate=block('SectorSign',Vector3.new(19,4,.4),Vector3.new(zone.x,3,zone.z-75),metal,Enum.Material.Metal)
  sign(plate,zone.name)
  sellTerminal('FieldDepot'..zi,zone.x+82,zone.z-66)
  for _,side in ipairs({-1,1}) do lamp(zone.x+side*71,0,zone.z-65); lamp(zone.x+side*71,0,zone.z+65) end
  -- Permanent escape steps, cut into a strip at the south edge of each dig site.
  for i=0,5 do
   local top=-7.5+i*1.5
   local step=block('EscapeStep',Vector3.new(12,1.5,3),Vector3.new(zone.x,top-.75,zone.z+47+i*3),metal,Enum.Material.Concrete)
   step.Parent=root
  end
 end
 -- Broad impact craters: a low polygonal inner wall and an outer sloping rim.
 local craters={{x=-190,z=-370,r=95,h=12},{x=335,z=8,r=120,h=16},{x=-390,z=48,r=100,h=11},{x=280,z=550,r=110,h=13},{x=-500,z=530,r=95,h=10},{x=150,z=-610,r=68,h=8},{x=-310,z=-1120,r=145,h=16},{x=1050,z=-1050,r=175,h=22},{x=-1100,z=150,r=160,h=20},{x=1100,z=960,r=180,h=24},{x=-580,z=1100,r=195,h=21},{x=420,z=720,r=130,h=17}}
 for ci,c in ipairs(craters) do
  local n=48
  for i=0,n-1 do
   local a=i*math.pi*2/n
   for _,outer in ipairs({false,true}) do
    local span=outer and 40 or 28
    local r=c.r+(outer and span/2 or -span/2)
    local y=c.h/2
    local slope=math.atan(c.h/span)*(outer and 1 or -1)
    local px,pz=c.x+math.cos(a)*r,c.z+math.sin(a)*r
    if not Layout.InPatch(px,pz,32) then
    local segment=block('CraterRim'..ci,Vector3.new((2*math.pi*r/n)+2,1.4,math.sqrt(span*span+c.h*c.h)),Vector3.new(c.x+math.cos(a)*r,y,c.z+math.sin(a)*r),Color3.fromRGB(117+ci%3*4,120+ci%3*4,126+ci%3*4))
    segment.CFrame=segment.CFrame*CFrame.Angles(0,math.pi/2-a,0)*CFrame.Angles(slope,0,0)
    end
   end
  end
 end
 -- Long-distance silhouettes, outside the playable plain; no narrow rock corridor.
 for i=1,96 do
  local a=i*math.pi*2/96; local radius=2000+math.sin(i*4.1)*190
  local m=block('HorizonMassif',Vector3.new(150+i%4*30,90+i%5*22,170+i%3*35),Vector3.new(math.cos(a)*radius,15,math.sin(a)*radius),Color3.fromRGB(73+i%3*5,78+i%3*5,88+i%3*5))
  m.Shape=Enum.PartType.Ball; m.CFrame=m.CFrame*CFrame.Angles(.18,i*.7,.12)
 end
 -- Scattered boulders, with the main route and excavation sites kept clear.
 for i=1,330 do
  local x=math.sin(i*127.1)*1450; local z=math.sin(i*311.7)*1450
  if not Layout.InPatch(x,z) and math.abs(x)>95 and math.abs(z-Layout.CampZ)>55 then
   local s=2+i%8
   local stone=block('LunarBoulder',Vector3.new(s*1.4,s,s*1.2),Vector3.new(x,s*.2,z),Color3.fromRGB(99+i%5*4,102+i%5*4,109+i%5*4))
   stone.Shape=Enum.PartType.Ball; stone.CFrame=stone.CFrame*CFrame.Angles(i*.8,i*.3,i*.12)
  end
 end
 -- Small expedition camp, dwarfed by the surrounding landscape.
 local cz=Layout.CampZ
 block('Camp',Vector3.new(92,1,56),Vector3.new(0,.5,cz),metal,Enum.Material.Metal)
 local spawn=Instance.new('SpawnLocation'); spawn.Name='CampSpawn'; spawn.Size=Vector3.new(7,1,7); spawn.Position=Vector3.new(0,1.5,cz); spawn.Anchored=true; spawn.Neutral=true; spawn.Transparency=1; spawn.Parent=root
 local prompt=sellTerminal('Terminal',-18,cz)
 local bench=block('Workbench',Vector3.new(8,3,4),Vector3.new(18,2.5,cz),Color3.fromRGB(104,98,87),Enum.Material.Metal)
 local up=Instance.new('ProximityPrompt'); up.ActionText='Улучшить инструмент'; up.ObjectText='Мастерская'; up.HoldDuration=.25; up.MaxActivationDistance=12; up.Parent=bench
 for _,x in ipairs({-34,34}) do lamp(x,1,cz-12); lamp(x,1,cz+18) end
 local shelter=block('Habitat',Vector3.new(24,13,18),Vector3.new(-25,7,cz-25),Color3.fromRGB(194,196,193),Enum.Material.Metal)
 block('HabitatDoor',Vector3.new(5,8,.5),Vector3.new(-25,4.5,cz-15.7),metal,Enum.Material.Metal)
 for _,x in ipairs({-31,-19}) do block('HabitatWindow',Vector3.new(3,2,.3),Vector3.new(x,8,cz-15.7),warm,Enum.Material.Neon) end
 local dish=block('Dish',Vector3.new(13,2,13),Vector3.new(28,20,cz-18),Color3.fromRGB(168,174,179),Enum.Material.Metal)
 dish.Shape=Enum.PartType.Ball; dish.CFrame=dish.CFrame*CFrame.Angles(.65,0,.2)
 block('DishMast',Vector3.new(1,18,1),Vector3.new(28,10,cz-18),metal,Enum.Material.Metal)
 for i=1,5 do block('Cargo',Vector3.new(4,3,4),Vector3.new(35+(i%2)*5,2,cz-12+math.floor(i/2)*5),Color3.fromRGB(151,140,111),Enum.Material.Metal) end
 local board=block('MissionSign',Vector3.new(22,5,.4),Vector3.new(0,5,cz+22),metal,Enum.Material.Metal)
 sign(board,'UNDERLAYER / 07\nРАСКОПКИ ВПЕРЕДИ')
 -- Route lamps lead to the first site, not a wall around the map.
 for z=cz+50,Layout.Zones[1].z-85,40 do lamp(-10,0,z) end
 -- A distant probe rewards navigation with a recognizable landmark.
 block('LostProbe',Vector3.new(9,6,9),Vector3.new(Layout.Zones[5].x,4,Layout.Zones[5].z-85),Color3.fromRGB(181,179,169),Enum.Material.Metal)
 for _,x in ipairs({-1,1}) do block('SolarPanel',Vector3.new(16,.3,9),Vector3.new(Layout.Zones[5].x+x*16,6,Layout.Zones[5].z-85),Color3.fromRGB(43,57,79),Enum.Material.Metal) end
 -- Enclosed training room, with a shallow practice pit and a solid bottom.
 local tz=Layout.TrainingZ
 block('TrainingFoundation',Vector3.new(144,8,128),Vector3.new(0,-9,tz),Color3.fromRGB(76,83,91),Enum.Material.Concrete)
 for ix=0,15 do for iz=0,13 do
  local x=-64+4+ix*8; local z=tz-56+4+iz*8
  if not (x>=8 and x<40 and z>=tz-16 and z<tz+16) then
   block('TrainingFloor',Vector3.new(8,5,8),Vector3.new(x,-2.5,z),Color3.fromRGB(118,127,133),Enum.Material.Concrete)
  end
 end end
 -- Chamfered white station shell, orange banding, recessed glazing and vents.
 local white=Color3.fromRGB(205,208,212)
 local orange=Color3.fromRGB(224,148,55)
 local trim=Color3.fromRGB(44,49,56)
 local outline={{-52,-64},{52,-64},{72,-44},{72,44},{52,64},{-52,64},{-72,44},{-72,-44}}
 local function detail(name,size,x,y,z,color,material,yaw)
  local p=block(name,size,Vector3.new(x,y,tz+z),color,material or Enum.Material.SmoothPlastic)
  if yaw then p.CFrame=p.CFrame*CFrame.Angles(0,yaw,0) end
  return p
 end
 for i,a in ipairs(outline) do
  local b=outline[i%#outline+1]
  local dx,dz=b[1]-a[1],b[2]-a[2]; local len=math.sqrt(dx*dx+dz*dz)
  local tx,tt=dx/len,dz/len; local nx,nz=tt,-tx; local yaw=-math.atan2(dz,dx)
  local cx,cz=(a[1]+b[1])/2,(a[2]+b[2])/2
  local function face(name,w,h,depth,u,y,out,color,mat)
   return detail(name,Vector3.new(w,h,depth),cx+tx*u+nx*out,y,cz+tt*u+nz*out,color,mat,yaw)
  end
  local front=i==5
  local bays=math.max(1,math.floor(len/20)); local width=len/bays
  face('StationLowerBand',len-.12,.65,.22,0,7.7,1.16,orange)
  face('StationUpperBand',len-.12,.65,.22,0,35.1,1.16,orange)
  face('StationCrown',len+.25,2,3.4,0,44.6,.15,white)
  face('StationDarkRoofLip',len-.12,.25,2.8,0,45.75,.15,trim)
  for j=0,bays-1 do
   local u=-len/2+width*(j+.5)
   if not (front and math.abs(u)<width*.45) then
    face('StationPanelBase',width-.1,11,2,u,5.5,0,white)
    face('StationPanelHeader',width-.1,11,2,u,38.5,0,white)
    local window=3.5
    for _,side in ipairs({-1,1}) do
     face('StationPanelPier',(width-window)/2-.04,22,2,u+side*(width+window)/4,22,0,white)
    end
    face('StationWindow',window,21.7,.3,u,22,-.05,Color3.fromRGB(82,125,153),Enum.Material.Glass)
    for _,side in ipairs({-1,1}) do
     face('StationWindowFrame',.34,22.3,.42,u+side*(window/2+.15),22,.87,trim)
    end
    for _,yy in ipairs({10.95,33.05}) do face('StationWindowFrame',window+.6,.34,.42,u,yy,.87,trim) end
    -- Vent housing is physically in front of the wall, not coplanar with it.
    face('StationVent',width-4,3.3,.32,u,39.8,1.25,trim)
    for slat=0,5 do face('StationVentSlat',width-4.5,.14,.18,u,38.55+slat*.48,1.51,Color3.fromRGB(96,100,105)) end
    if j%2==0 then
     face('StationLowerVent',width-5,2,.32,u,3.8,1.25,trim)
     for slat=0,3 do face('StationVentSlat',width-5.5,.12,.18,u,3.1+slat*.45,1.51,Color3.fromRGB(96,100,105)) end
    end
   else
    face('StationDoorHeader',width-.1,25,2,u,31.5,0,white)
    face('StationDoorFrame',14,1.2,2.9,u,15.7,.35,trim)
    for _,side in ipairs({-1,1}) do
     face('StationDoorFrame',1.2,15.3,2.9,u+side*6.4,7.65,.35,trim)
     face('StationDoor',5.65,14.8,.7,u+side*2.91,7.4,.45,white)
     face('StationDoorGlass',.8,6,.18,u+side*2.4,10.3,.92,Color3.fromRGB(83,128,155))
     face('StationDoorAccent',5.65,.38,.18,u+side*2.91,3.2,.92,orange)
    end
   end
  end
  -- Every external light has visible housing and a downward-facing lens.
  local fixture=face('StationExteriorLamp',2,.7,2,0,41,6,trim)
  local lens=face('StationExteriorLampLens',1.4,.12,1.4,0,40.57,6,Color3.fromRGB(247,222,179),Enum.Material.Neon)
  local spot=Instance.new('SpotLight'); spot.Name='StationLamp'; spot.Face=Enum.NormalId.Bottom
  spot.Color=Color3.fromRGB(248,226,191); spot.Angle=105; spot.Range=65; spot.Brightness=2; spot.Shadows=true; spot.Parent=lens
 end
 detail('StationRoof',Vector3.new(104,1.6,128),0,44,0,white)
 detail('StationRoofWing',Vector3.new(20,1.6,88),62,44,0,white)
 detail('StationRoofWing',Vector3.new(20,1.6,88),-62,44,0,white)
 for _,c in ipairs({{62,54,math.pi},{-62,54,math.pi/2},{62,-54,-math.pi/2},{-62,-54,0}}) do
  local wedge=Instance.new('WedgePart'); wedge.Name='StationRoofCorner'; wedge.Size=Vector3.new(1.6,20,20)
  wedge.CFrame=CFrame.new(c[1],44,tz+c[2])*CFrame.Angles(0,c[3],0)*CFrame.Angles(0,0,math.pi/2)
  wedge.Anchored=true; wedge.Color=white; wedge.Material=Enum.Material.SmoothPlastic; wedge.Parent=root
 end
 for _,x in ipairs({-38,38}) do for _,z in ipairs({-29,29}) do
  local housing=detail('StationCeilingFixture',Vector3.new(12,.5,3),x,41,z,trim)
  local lens=detail('StationCeilingLens',Vector3.new(11,.15,2),x,40.63,z,Color3.fromRGB(231,239,229),Enum.Material.Neon)
  local light=Instance.new('SpotLight'); light.Face=Enum.NormalId.Bottom; light.Angle=110; light.Range=68; light.Brightness=2.7
  light.Color=Color3.fromRGB(229,236,225); light.Shadows=true; light.Parent=lens
 end end
 -- Exterior steps and apron do not extend underneath the excavation pit.
 for i=0,4 do
  local y=-i
  detail('StationEntryStep',Vector3.new(30,1,3),0,y-.5,66+i*3,Color3.fromRGB(122,128,134),Enum.Material.Concrete)
 end
 for i=1,5 do
  detail('StationOuterStep',Vector3.new(30,1,3),0,-5+i-.5,118+i*3,Color3.fromRGB(122,128,134),Enum.Material.Concrete)
 end
 detail('StationApron',Vector3.new(180,3,42),0,-6.5,100,Color3.fromRGB(103,109,118),Enum.Material.Concrete)
 block('StationLunarPad',Vector3.new(320,8,300),Vector3.new(0,-13,tz),rock)
 local function interact(name,pos,txt)
  local p=block(name,Vector3.new(7,4,4),pos,metal,Enum.Material.Metal)
  local pp=Instance.new('ProximityPrompt'); pp.Name='TeachPrompt'; pp.ActionText=txt; pp.ObjectText='Учебный отдел'; pp.MaxActivationDistance=12; pp.HoldDuration=.25; pp.Parent=p
  local panel=block(name..'Label',Vector3.new(10,2,.3),pos+Vector3.new(0,4,0),metal,Enum.Material.Metal); sign(panel,txt)
  return p
 end
 interact('TrainingRack',Vector3.new(-45,2,tz-30),'Получить инструмент')
 interact('TrainingNest',Vector3.new(48,2,tz+4),'Осмотреть кокон')
 interact('TrainingSell',Vector3.new(-45,2,tz+27),'Сдать учебную добычу')
 local gate=interact('TrainingExit',Vector3.new(0,3,tz+56),'Завершить обучение')
 gate.Transparency=1; gate.CanCollide=false; gate.CanQuery=false
 local pit=block('TrainingPitMarker',Vector3.new(22,3,.4),Vector3.new(24,4,tz+20),metal,Enum.Material.Metal); sign(pit,'УЧЕБНЫЙ УЧАСТОК / ЛКМ')
 for ix=0,3 do for iz=0,3 do for layer=1,2 do
  local part=block('Layer'..layer,Vector3.new(8,2.5,8),Vector3.new(12+ix*8,Layout.LayerY(layer),tz-12+iz*8),layer==1 and dust or rock,Enum.Material.Sand)
  part.Parent=deposits
 end end end
 local intro=block('TrainingInstructions',Vector3.new(34,8,.4),Vector3.new(-15,9,tz-55),metal,Enum.Material.Metal)
 sign(intro,'УЧЕБНЫЙ ОТДЕЛ / 07\nПОЛУЧИ ЩЁТКУ → ОЧИСТИ УЧАСТОК → НАЙДИ КОКОН')
 local generator=block('BaseGenerator',Vector3.new(10,6,7),Vector3.new(-52,3,cz+28),Color3.fromRGB(97,101,91),Enum.Material.Metal)
 local repair=Instance.new('ProximityPrompt'); repair.Name='TeachPrompt'; repair.ActionText='Восстановить генератор'; repair.ObjectText='База / 80 монет'; repair.HoldDuration=1; repair.MaxActivationDistance=14; repair.Parent=generator
 spawn.Position=Vector3.new(-25,2,tz)
 return {Root=root,Sell=prompt,Upgrade=up}
end
return W
