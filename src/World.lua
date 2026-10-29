local W={}
function W.Build()
 local old=workspace:FindFirstChild('UnderlayerWorld')
 if old then
  local terminal=old:FindFirstChild('Terminal')
  local bench=old:FindFirstChild('Workbench')
  if terminal and bench then
   local sell=terminal:FindFirstChildOfClass('ProximityPrompt')
   local upgrade=bench:FindFirstChildOfClass('ProximityPrompt')
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
 local lighting=game:GetService('Lighting')
 lighting.ClockTime=5.4; lighting.Brightness=2.5; lighting.Ambient=Color3.fromRGB(100,115,130); lighting.OutdoorAmbient=Color3.fromRGB(100,114,130)
 lighting.FogColor=Color3.fromRGB(30,41,52); lighting.FogStart=80; lighting.FogEnd=310
 local atmosphere=Instance.new('Atmosphere'); atmosphere.Density=.2; atmosphere.Color=Color3.fromRGB(152,175,186); atmosphere.Decay=Color3.fromRGB(46,52,71); atmosphere.Parent=lighting
 block('Bedrock',Vector3.new(210,8,260),Vector3.new(0,-11,50),Color3.fromRGB(28,34,43))
 block('Camp',Vector3.new(92,6,52),Vector3.new(0,0,-44),Color3.fromRGB(48,60,69),Enum.Material.Concrete)
 -- Stairs remain after excavation, so players can leave the lowest layer.
 for i=0,7 do
  local top=-6+(i+1)*1.2
  block('ExitStep',Vector3.new(100,1.3,2.1),Vector3.new(0,top-.65,-5-i*2),Color3.fromRGB(58,68,78),Enum.Material.Concrete)
 end
 local spawn=Instance.new('SpawnLocation'); spawn.Name='CampSpawn'; spawn.Size=Vector3.new(7,1,7); spawn.Position=Vector3.new(0,4,-45); spawn.Anchored=true; spawn.Neutral=true; spawn.Transparency=1; spawn.Parent=root
 for _,x in ipairs({-36,36}) do
  block('Tower',Vector3.new(2,22,2),Vector3.new(x,13,-39),Color3.fromRGB(51,65,74),Enum.Material.Metal)
  local lamp=block('Lamp',Vector3.new(3,1,3),Vector3.new(x,24,-39),Color3.fromRGB(171,224,213),Enum.Material.Neon)
  local light=Instance.new('PointLight'); light.Brightness=3; light.Range=55; light.Color=lamp.Color; light.Parent=lamp
 end
 local terminal=block('Terminal',Vector3.new(9,6,5),Vector3.new(-16,6,-42),Color3.fromRGB(74,104,111),Enum.Material.Metal)
 local screen=block('TerminalScreen',Vector3.new(7,3,.2),Vector3.new(-16,7,-44.6),Color3.fromRGB(127,207,188),Enum.Material.Neon)
 local prompt=Instance.new('ProximityPrompt'); prompt.ActionText='Сдать ресурсы'; prompt.ObjectText='Терминал экспедиции'; prompt.HoldDuration=.25; prompt.MaxActivationDistance=12; prompt.Parent=terminal
 local bench=block('Workbench',Vector3.new(9,4,5),Vector3.new(16,5,-42),Color3.fromRGB(105,87,71),Enum.Material.Metal)
 local up=Instance.new('ProximityPrompt'); up.ActionText='Улучшить инструмент'; up.ObjectText='Мастерская'; up.HoldDuration=.25; up.MaxActivationDistance=12; up.Parent=bench
 for _,x in ipairs({-82,82}) do
  for z=-35,150,24 do
   local rock=block('Cliff',Vector3.new(27,45+(z%19),30),Vector3.new(x,10,z),Color3.fromRGB(37,45,57))
   rock.CFrame=rock.CFrame*CFrame.Angles(.1,z*.03,.08)
  end
 end
 for i=1,14 do
  local x=(i%2==0 and -1 or 1)*(22+i*2.5); local z= i*11-10
  local shard=block('DistantCrystal',Vector3.new(1.5,4+i%4,1.5),Vector3.new(x,1,z),Color3.fromRGB(92,139,163),Enum.Material.Neon)
  shard.CFrame=shard.CFrame*CFrame.Angles(.15,0,.25)
 end
 local board=block('Sign',Vector3.new(26,8,1),Vector3.new(0,12,-66),Color3.fromRGB(24,35,43),Enum.Material.Metal)
 local sg=Instance.new('SurfaceGui'); sg.Face=Enum.NormalId.Front; sg.Parent=board
 local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text='UNDERLAYER\nЭКСПЕДИЦИЯ 07 / НЕ БУДИТЬ'; t.TextColor3=Color3.fromRGB(192,224,215); t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Parent=sg
 -- Camp details keep the first view readable, with a path facing the dig site.
 for z=-58,-24,7 do
  block('Walkway',Vector3.new(10,.15,5),Vector3.new(0,3.1,z),Color3.fromRGB(87,98,104),Enum.Material.Metal)
 end
 for _,x in ipairs({-25,25}) do
  for _,z in ipairs({-50,-34}) do
   block('CanopyPost',Vector3.new(.5,9,.5),Vector3.new(x,7.5,z),Color3.fromRGB(74,83,94),Enum.Material.Metal)
  end
 end
 block('Canopy',Vector3.new(54,.35,20),Vector3.new(0,12,-42),Color3.fromRGB(64,85,88),Enum.Material.Fabric)
 for i=1,6 do
  local x=-34+(i%3)*5; local z=-57+math.floor((i-1)/3)*4
  block('Cargo',Vector3.new(3.6,3.5,3.4),Vector3.new(x,4.8,z),Color3.fromRGB(105,100,85),Enum.Material.Metal)
  block('CargoBand',Vector3.new(3.7,.35,3.5),Vector3.new(x,5.1,z),Color3.fromRGB(174,149,99),Enum.Material.Metal)
 end
 for i=1,16 do
  local x=i%2==0 and -51 or 51; local z=-10+math.floor((i-1)/2)*17
  local base=block('Beacon',Vector3.new(.6,3,.6),Vector3.new(x,0,z),Color3.fromRGB(80,95,101),Enum.Material.Metal)
  local glow=block('BeaconGlow',Vector3.new(.8,.7,.8),Vector3.new(x,1.8,z),Color3.fromRGB(151,213,195),Enum.Material.Neon)
  local lamp=Instance.new('PointLight'); lamp.Color=glow.Color; lamp.Brightness=.7; lamp.Range=15; lamp.Parent=glow
 end
 for i=1,20 do
  local side=i%2==0 and -1 or 1
  local rock=block('WeatheredRock',Vector3.new(10+i%4*3,9+i%5*2,13+i%3*4),Vector3.new(side*(60+i%3*3),-2,i*8-12),Color3.fromRGB(45+i%3*4,53+i%4*3,64+i%3*3))
  rock.Shape=Enum.PartType.Ball
  rock.CFrame=rock.CFrame*CFrame.Angles(i*.2,i*.4,.25)
 end
 return {Root=root, Sell=prompt, Upgrade=up}
end
return W
