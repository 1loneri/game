-- Original geometric monster models: distinct anatomy, layered eyes and growth details.
local V={}
function V.Build(id,def,growth)
 local m=Instance.new('Model'); m.Name=id
 local g=math.clamp(growth,1,50); local scale=.52+g*.018
 local stage=g>=50 and 5 or g>=30 and 4 or g>=15 and 3 or g>=6 and 2 or 1
 local dark=Color3.fromRGB(27,34,46); local cream=Color3.fromRGB(232,222,198)
 local col=def.color
 local function shape(name,size,pos,color,kind,rot,material)
  local p=Instance.new(kind=='wedge' and 'WedgePart' or 'Part'); p.Name=name
  if kind=='ball' then p.Shape=Enum.PartType.Ball elseif kind=='cylinder' then p.Shape=Enum.PartType.Cylinder end
  p.Size=size*scale; p.CFrame=CFrame.new(pos*scale)*(rot or CFrame.new()); p.Color=color
  p.Material=material or Enum.Material.SmoothPlastic
  p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=true; p.Parent=m
  return p
 end
 local function ball(n,s,p,c) return shape(n,s,p,c,'ball') end
 local bodySize=(id=='Crystal' or id=='Sol') and Vector3.new(2,1.65,2.8) or Vector3.new(2.1,1.9,2.3)
 local body=ball('Torso',bodySize,Vector3.new(0,0,.35),col); m.PrimaryPart=body
 -- A separate head, jaw, muzzle, belly, four feet, toes and layered eyes.
 ball('Head',Vector3.new(2,1.65,1.65),Vector3.new(0,.62,-.95),col)
 ball('Muzzle',Vector3.new(1.3,.7,.75),Vector3.new(0,.16,-1.62),cream)
 ball('Belly',Vector3.new(1.45,1.25,.8),Vector3.new(0,-.12,-.55),col:Lerp(cream,.6))
 ball('Nose',Vector3.new(.25,.18,.18),Vector3.new(0,.35,-2),dark)
 shape('Mouth',Vector3.new(.34,.045,.055),Vector3.new(0,.02,-2.01),dark)
 for _,side in ipairs({-1,1}) do
  local x=side*.56
  ball('EyeSocket',Vector3.new(.62,.71,.35),Vector3.new(x,.83,-1.62),col:Lerp(dark,.24))
  ball('EyeWhite',Vector3.new(.47,.57,.23),Vector3.new(x,.85,-1.78),cream)
  ball('Iris',Vector3.new(.26,.4,.15),Vector3.new(x,.84,-1.89),dark)
  ball('EyeGlint',Vector3.new(.1,.13,.07),Vector3.new(x-.055,.95,-1.97),Color3.new(1,1,1))
  ball('Cheek',Vector3.new(.35,.16,.12),Vector3.new(side*.82,.3,-1.58),col:Lerp(Color3.fromRGB(228,146,155),.5))
  for _,z in ipairs({-.7,1.03}) do
   ball('Leg',Vector3.new(.58,.85,.65),Vector3.new(side*.86,-.68,z),col:Lerp(dark,.1))
   ball('Paw',Vector3.new(.7,.4,.94),Vector3.new(side*.87,-1.04,z-.16),col)
   for toe=-1,1 do ball('Claw',Vector3.new(.12,.12,.23),Vector3.new(side*.87+toe*.18,-1.04,z-.58),cream) end
  end
 end
 if id=='Dust' then
  for _,side in ipairs({-1,1}) do
   shape('TallEar',Vector3.new(.62,1.25+stage*.12,.52),Vector3.new(side*.77,1.73,-.62),col,'wedge',CFrame.Angles(0,side*.3,side*-.3))
   shape('EarInner',Vector3.new(.27,.8,.12),Vector3.new(side*.77,1.7,-.94),cream,'wedge')
   for i=1,3 do shape('CheekTuft',Vector3.new(.4,.45,.6),Vector3.new(side*(.96+i*.08),.35+i*.18,-.7),col,'wedge',CFrame.Angles(0,0,side*.7)) end
  end
  ball('TailBase',Vector3.new(.65,.65,1.4),Vector3.new(0,.1,1.85),col)
  shape('TailTip',Vector3.new(1.1,.85,1.3),Vector3.new(0,.45,2.45),cream,'wedge',CFrame.Angles(.4,0,0))
 elseif id=='Moss' then
  for i=1,3+stage do
   local a=i*math.pi*2/(3+stage)
   shape('LeafCrown',Vector3.new(.5,.25,1.25),Vector3.new(math.cos(a)*.55,1.35,math.sin(a)*.55-.2),Color3.fromRGB(74,137,94),'wedge',CFrame.Angles(-.4,a,0))
  end
  shape('Stem',Vector3.new(.25,.7,.25),Vector3.new(0,1.55,-.35),Color3.fromRGB(113,151,89))
  ball('Bud',Vector3.new(.65,.6,.65),Vector3.new(0,2,-.35),Color3.fromRGB(205,172,126))
  for _,side in ipairs({-1,1}) do shape('LeafEar',Vector3.new(.8,.25,1.3),Vector3.new(side*1.05,1,-.5),col,'wedge',CFrame.Angles(.4,side*.7,side*.6)) end
  for i=1,3 do ball('TailSegment',Vector3.new(.6-i*.1,.55-i*.08,.75),Vector3.new(0,.1+i*.2,1.4+i*.45),col) end
 elseif id=='Crystal' then
  shape('BackShell',Vector3.new(2.15,.75,2.25),Vector3.new(0,.65,.55),col:Lerp(dark,.2),'wedge')
  for i=1,2+stage do
   local x=(i%2==0 and -1 or 1)*.45; local z=.1+math.floor((i-1)/2)*.5
   shape('QuartzPlate',Vector3.new(.42,.75+stage*.15,.5),Vector3.new(x,1.2,z),col:Lerp(cream,.3),'wedge',CFrame.Angles(0,0,x*.35),Enum.Material.Neon)
  end
  for _,side in ipairs({-1,1}) do shape('HeadHorn',Vector3.new(.4,.9,.45),Vector3.new(side*.77,1.55,-.5),cream,'wedge',CFrame.Angles(-.4,0,side*.2)) end
  for i=1,3 do shape('ArmoredTail',Vector3.new(.8-i*.15,.55,1),Vector3.new(0,.1,1.3+i*.55),col,'wedge') end
 elseif id=='Nova' then
  for _,side in ipairs({-1,1}) do
   for i=1,3 do shape('WingFeather',Vector3.new(.5,.2,1.7),Vector3.new(side*(1+i*.28),.6+i*.16,.15),col:Lerp(cream,i*.15),'wedge',CFrame.Angles(.2,side*.5,side*-.5)) end
   shape('CrescentEar',Vector3.new(.5,1.6,.6),Vector3.new(side*.8,1.65,-.6),col,'wedge',CFrame.Angles(.2,0,side*.4))
  end
  ball('ForeheadGem',Vector3.new(.32,.46,.2),Vector3.new(0,1.19,-1.77),Color3.fromRGB(240,212,143))
  for i=1,4 do ball('StarTail',Vector3.new(.5,.45,.6),Vector3.new(0,.2+i*.2,1.2+i*.4),col:Lerp(cream,i*.15)) end
 elseif id=='Umbra' then
  for _,side in ipairs({-1,1}) do
   shape('CurvedHornBase',Vector3.new(.5,1.1,.6),Vector3.new(side*.8,1.5,-.5),dark,'wedge',CFrame.Angles(-.4,0,side*.3))
   shape('HornTip',Vector3.new(.3,.85,.35),Vector3.new(side*1.02,2.15,-.3),cream,'wedge',CFrame.Angles(.5,0,side*.4))
   for i=1,stage do shape('BackSpine',Vector3.new(.35,.5,.5),Vector3.new(side*.55,.95,.1+i*.35),dark,'wedge') end
  end
  shape('LongTail',Vector3.new(.35,.4,2),Vector3.new(0,.1,2),col,'wedge',CFrame.Angles(.25,0,0))
  shape('SpadeTail',Vector3.new(.9,.25,.9),Vector3.new(0,.35,3),dark,'wedge')
 else
  for i=1,8+stage do
   local a=i*math.pi*2/(8+stage)
   shape('SunMane',Vector3.new(.42,.65,.5),Vector3.new(math.cos(a)*1.08,.65+math.sin(a)*1.02,-.78),col:Lerp(cream,.2),'wedge',CFrame.Angles(0,0,a-math.pi/2))
  end
  for i=1,3 do ball('Tail',Vector3.new(.5,.5,.8),Vector3.new(0,.2+i*.14,1.3+i*.5),col) end
  shape('FlameTip',Vector3.new(.8,1,.65),Vector3.new(0,.9,2.9),Color3.fromRGB(241,143,83),'wedge')
 end
 if stage>=3 then for _,side in ipairs({-1,1}) do shape('ShoulderMark',Vector3.new(.15,.45,.6),Vector3.new(side*1.05,.1,-.1),cream,'wedge') end end
 if stage>=4 then for i=1,3 do shape('Crest',Vector3.new(.3,.45,.5),Vector3.new(0,1.1,.1+i*.45),col:Lerp(cream,.4),'wedge') end end
 local gui=Instance.new('BillboardGui'); gui.Size=UDim2.fromOffset(160,30); gui.StudsOffset=Vector3.new(0,3.1*scale,0); gui.MaxDistance=35; gui.Parent=body
 local label=Instance.new('TextLabel'); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=def.name; label.Font=Enum.Font.GothamMedium; label.TextSize=12; label.TextColor3=cream; label.TextStrokeTransparency=.5; label.Parent=gui
 return m
end
return V
