-- Native Terrain outside the dig grid; no floating rectangular platform edge.
local T={}
function T.Build(world)
 if world:GetAttribute('OuterTerrainReady') then return end
 local terrain=workspace.Terrain
 local core=1536; local extent=4096
 local material=Enum.Material.Sand
 terrain:SetMaterialColor(material,Color3.fromRGB(126,129,136))
 terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(98,104,113))
 local tz=require(script.Parent.Layout).TrainingZ
 local written=0
 local function fill(x0,x1,z0,z1)
  -- Bounded batches avoid oversized native Terrain operations.
  for x=x0,x1-1,512 do for z=z0,z1-1,512 do
   local right=math.min(x+512,x1); local far=math.min(z+512,z1)
   terrain:FillBlock(CFrame.new((x+right)/2,-16,(z+far)/2),Vector3.new(right-x,32,far-z),material)
   written=written+1; if written%8==0 then task.wait() end
  end end
 end
 -- Do not temporarily fill the room while generating the northern landscape.
 terrain:FillBlock(CFrame.new(0,20,tz+25),Vector3.new(200,80,220),Enum.Material.Air)
 fill(-extent,-100,-extent,-core); fill(100,extent,-extent,-core)
 fill(-100,100,-extent,tz-85); fill(-100,100,tz+135,-core)
 fill(-extent,extent,core,extent)
 fill(-extent,-core,-core,core)
 fill(core,extent,-core,core)
 for i=1,180 do
  local x=math.sin(i*127.1)*3650; local z=math.sin(i*311.7)*3650
  local radius=70+(i%7)*14
  if math.max(math.abs(x),math.abs(z))>core+radius+100 and (Vector3.new(x,0,z)-Vector3.new(0,0,tz)).Magnitude>radius+220 then
   terrain:FillBall(Vector3.new(x,-radius*.76,z),radius,i%4==0 and Enum.Material.Rock or material)
   if i%6==0 then terrain:FillBall(Vector3.new(x+radius*.5,22,z),32,Enum.Material.Air) end
  end
  if i%6==0 then task.wait() end
 end
 for _,p in ipairs(world:GetChildren()) do if p.Name=='OuterGroundPreview' then p:Destroy() end end
 world:SetAttribute('OuterTerrainReady',true)
end
return T
