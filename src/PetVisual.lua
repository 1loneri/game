local V = {}
function V.Build(id, def, growth)
 local model=Instance.new('Model'); model.Name=id
 local scale=0.48+math.min(growth,50)/50*0.85
 local function ball(name,size,pos,color,material)
  local p=Instance.new('Part'); p.Name=name; p.Shape=Enum.PartType.Ball
  p.Size=size*scale; p.CFrame=CFrame.new(pos*scale); p.Color=color
  p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false
  p.Parent=model; return p
 end
 local body=ball('Body',Vector3.new(2.5,2.1,2.4),Vector3.zero,def.color)
 model.PrimaryPart=body
 local dark=Color3.fromRGB(18,26,33)
 for _,x in ipairs({-0.56,0.56}) do
  ball('Eye',Vector3.new(.32,.46,.24),Vector3.new(x,.15,-1.08),dark)
  ball('Glint',Vector3.new(.1,.12,.08),Vector3.new(x-.04,.25,-1.2),Color3.new(1,1,1),Enum.Material.Neon)
  ball('Foot',Vector3.new(.7,.45,.8),Vector3.new(x,-.9,-.25),def.color:Lerp(dark,.15))
 end
 ball('Mouth',Vector3.new(.22,.11,.12),Vector3.new(0,-.3,-1.18),dark)
 local count=math.min(5,1+math.floor(growth/10))
 if def.kind=='sprout' then
  for i=1,count do ball('Leaf',Vector3.new(.65,1.1,.35),Vector3.new((i-(count+1)/2)*.35,1.25,0),Color3.fromRGB(88,164,118)) end
 elseif def.kind=='crystal' or def.kind=='star' or def.kind=='sun' then
  for i=1,count do
   local p=ball('Crystal',Vector3.new(.4,.6+i*.15,.4),Vector3.new((i-(count+1)/2)*.4,1.1,0),def.color:Lerp(Color3.new(1,1,1),.4),Enum.Material.Neon)
   p.Shape=Enum.PartType.Block; p.CFrame=p.CFrame*CFrame.Angles(0,0,.35)
  end
 else
  for _,x in ipairs({-1,1}) do ball('Ear',Vector3.new(.65,.8+growth*.025,.7),Vector3.new(x,.95,.2),def.color) end
 end
 if growth>=15 then ball('Tail',Vector3.new(.8,1,1.4),Vector3.new(0,-.1,1.4),def.color) end
 if growth>=30 then
  for _,x in ipairs({-1.25,1.25}) do ball('Fin',Vector3.new(.6,1.1,1.3),Vector3.new(x,.1,.5),def.color:Lerp(Color3.new(1,1,1),.2)) end
 end
 local gui=Instance.new('BillboardGui'); gui.Size=UDim2.fromOffset(160,32); gui.StudsOffset=Vector3.new(0,2.2*scale,0); gui.MaxDistance=45; gui.Parent=body
 local label=Instance.new('TextLabel'); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=def.name
 label.Font=Enum.Font.GothamMedium; label.TextSize=13; label.TextColor3=Color3.fromRGB(226,237,231); label.TextStrokeTransparency=.4; label.Parent=gui
 return model
end
return V
