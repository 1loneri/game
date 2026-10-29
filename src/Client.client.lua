local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Market=game:GetService('MarketplaceService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local F=RS:WaitForChild('Underlayer'); local C=require(F.Config); local Visual=require(F.PetVisual)
local event=F:WaitForChild('Action'); local data=nil
local gui=Instance.new('ScreenGui'); gui.Name='UnderlayerUI'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild('PlayerGui')
local palette={bg=Color3.fromRGB(20,23,28),panel=Color3.fromRGB(32,37,43),line=Color3.fromRGB(62,70,78),text=Color3.fromRGB(232,233,229),muted=Color3.fromRGB(158,166,172),accent=Color3.fromRGB(172,198,181),gold=Color3.fromRGB(226,191,126)}
local function corner(obj,n) local c=Instance.new('UICorner'); c.CornerRadius=UDim.new(0,n or 4); c.Parent=obj end
local function frame(parent,size,pos,color)
 local f=Instance.new('Frame'); f.Size=size; f.Position=pos; f.BackgroundColor3=color or palette.panel; f.BorderSizePixel=0; f.Parent=parent; corner(f); return f
end
local function label(parent,size,pos,txt,n,color)
 local l=Instance.new('TextLabel'); l.BackgroundTransparency=1; l.Size=size; l.Position=pos; l.Text=txt; l.TextColor3=color or palette.text
 l.Font=Enum.Font.GothamMedium; l.TextSize=n or 16; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; l.Parent=parent; return l
end
local function button(parent,size,pos,txt,callback,color)
 local b=Instance.new('TextButton'); b.Size=size; b.Position=pos; b.Text=txt; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=palette.bg
 b.BackgroundColor3=color or palette.accent; b.AutoButtonColor=true; b.BorderSizePixel=0; b.Parent=parent; corner(b,4)
 b.Activated:Connect(callback); return b
end
-- Compact HUD: information stays in the corners; the world remains unobstructed.
local top=frame(gui,UDim2.fromOffset(274,102),UDim2.fromOffset(18,14),palette.bg)
top.BackgroundTransparency=.16
label(top,UDim2.new(1,-28,0,20),UDim2.fromOffset(14,9),'UNDERLAYER  /  07',12,palette.muted)
local stats=label(top,UDim2.new(1,-28,0,38),UDim2.fromOffset(14,31),'Подключение к экспедиции…',14)
local levelText=label(top,UDim2.new(1,-28,0,16),UDim2.fromOffset(14,76),'',10,palette.muted)
local xpBack=frame(top,UDim2.new(1,-28,0,2),UDim2.fromOffset(14,96),palette.line)
local xpBar=frame(xpBack,UDim2.fromScale(0,1),UDim2.fromScale(0,0),palette.accent)
local toast=frame(gui,UDim2.new(.8,0,0,48),UDim2.new(.1,0,1,-155),palette.bg)
local toastText=label(toast,UDim2.new(1,-24,1,0),UDim2.fromOffset(12,0),'',13)
toast.Visible=false
local help=label(gui,UDim2.fromOffset(310,30),UDim2.new(0,18,1,-98),'ЛКМ — копать    E — взаимодействовать',11,palette.muted)
local cross=label(gui,UDim2.fromOffset(18,18),UDim2.new(.5,-9,.5,-9),'·',24,palette.text); cross.TextXAlignment=Enum.TextXAlignment.Center
local targetText=label(gui,UDim2.fromOffset(300,32),UDim2.new(.5,-150,.5,20),'',12); targetText.TextXAlignment=Enum.TextXAlignment.Center
local nav=frame(gui,UDim2.fromOffset(330,40),UDim2.new(0,18,1,-60),palette.bg)
nav.BackgroundTransparency=.12
local modal=frame(gui,UDim2.new(.94,0,.71,0),UDim2.fromScale(.03,.19),palette.bg); modal.Visible=false
local title=label(modal,UDim2.new(1,-80,0,48),UDim2.fromOffset(18,0),'',22,palette.accent)
button(modal,UDim2.fromOffset(40,34),UDim2.new(1,-52,0,8),'×',function() modal.Visible=false end)
local content=Instance.new('ScrollingFrame'); content.Size=UDim2.new(1,-28,1,-64); content.Position=UDim2.fromOffset(14,54); content.BackgroundTransparency=1; content.BorderSizePixel=0
content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.CanvasSize=UDim2.new(); content.ScrollBarThickness=5; content.ScrollBarImageColor3=palette.accent; content.Parent=modal
local list=Instance.new('UIListLayout'); list.Padding=UDim.new(0,10); list.SortOrder=Enum.SortOrder.LayoutOrder; list.Parent=content
local padding=Instance.new('UIPadding'); padding.PaddingBottom=UDim.new(0,14); padding.PaddingRight=UDim.new(0,6); padding.Parent=content
local currentPage=''; local previewStage=1
local selectedPreview='Dust'; local previewModel=nil; local spin=0
local products={}; local fetchPending={}
local function price(id,isPass)
 if not id or id<=0 then return 'Не настроено' end
 local key=tostring(id)..tostring(isPass)
 if products[key] then return products[key] end
 if not fetchPending[key] then
  fetchPending[key]=true
  task.spawn(function()
   local ok,info=pcall(Market.GetProductInfoAsync,Market,id,isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
   products[key]=ok and info and info.PriceInRobux and (tostring(info.PriceInRobux)..' R$') or 'Цена в окне Roblox'
   fetchPending[key]=nil
  end)
 end
 return 'Цена в окне Roblox'
end
local function clear()
 previewModel=nil
 for _,child in ipairs(content:GetChildren()) do if child:IsA('Frame') or child:IsA('TextLabel') then child:Destroy() end end
 content.CanvasPosition=Vector2.zero
end
local function row(height)
 local r=frame(content,UDim2.new(1,0,0,height),UDim2.new(),palette.panel); return r
end
local function viewport(parent,id,growth,size,pos)
 local v=Instance.new('ViewportFrame'); v.Size=size; v.Position=pos; v.BackgroundTransparency=1
 v.Ambient=Color3.fromRGB(182,194,211); v.LightColor=Color3.fromRGB(245,231,215); v.LightDirection=Vector3.new(-1,-1,-1); v.Parent=parent
 local world=Instance.new('WorldModel'); world.Parent=v
 local m=Visual.Build(id,C.Pets[id],growth)
 -- Remove overhead nameplates from the 3D preview.
 for _,desc in ipairs(m:GetDescendants()) do if desc:IsA('BillboardGui') then desc:Destroy() end end
 m.Parent=world
 local camera=Instance.new('Camera'); camera.CFrame=CFrame.lookAt(Vector3.new(4,2.5,-7),Vector3.new(0,.4,0)); camera.FieldOfView=36; camera.Parent=v; v.CurrentCamera=camera
 return m
end
local function buy(key) event:FireServer('buy',key) end
local render
render=function(page)
 currentPage=page; clear(); modal.Visible=true
 if page=='collection' then
  title.Text='Коллекция / рост малышей'
  if not data then label(row(60),UDim2.fromScale(1,1),UDim2.new(),'Загрузка...',16); return end
  local info=row(60)
  label(info,UDim2.new(1,-24,1,0),UDim2.fromOffset(12,0),'Активных: '..#data.equipped..'/'..data.slots..' • бесплатный спутник следует за тобой. Помощь в добыче — отдельный пропуск.',13,palette.muted)
  local preview=row(240)
  local grow=({1,6,15,30,50})[previewStage]
  previewModel=viewport(preview,selectedPreview,grow,UDim2.new(.45,0,1,-20),UDim2.fromOffset(0,10))
  label(preview,UDim2.new(.53,-12,0,55),UDim2.new(.46,0,0,12),C.Pets[selectedPreview].name..' / просмотр роста',18)
  label(preview,UDim2.new(.53,-12,0,60),UDim2.new(.46,0,0,68),'Уровни: 1 → 6 → 15 → 30 → 50\nСтадия '..previewStage..' из 5',13,palette.muted)
  button(preview,UDim2.new(.49,0,0,40),UDim2.new(.46,0,0,145),'Следующая стадия',function() previewStage=previewStage%5+1; render('collection') end)
  label(preview,UDim2.new(.53,-12,0,40),UDim2.new(.46,0,0,190),'Это предпросмотр, он не меняет питомца.',11,palette.muted)
  for _,id in ipairs({'Dust','Moss','Crystal','Nova','Umbra','Sol'}) do
   local def=C.Pets[id]; local owned=data.pets[id]; local r=row(126)
   viewport(r,id,owned and owned.growth or 1,UDim2.new(.22,0,1,0),UDim2.new())
   label(r,UDim2.new(.76,-10,0,30),UDim2.new(.23,0,0,8),def.name..(def.premium and ' • особый' or ''),16,def.color)
   label(r,UDim2.new(.76,-10,0,35),UDim2.new(.23,0,0,38),owned and ('Рост '..string.format('%.1f',owned.growth)..' / '..data.level..' • фрагменты '..owned.fragments) or (def.premium and 'Покупка в магазине' or 'Спит в одном из коконов'),12,palette.muted)
   button(r,UDim2.new(.34,0,0,34),UDim2.new(.23,0,0,82),'Посмотреть рост',function() selectedPreview=id; previewStage=1; render('collection') end)
   if owned then
    button(r,UDim2.new(.34,0,0,34),UDim2.new(.61,0,0,82),table.find(data.equipped,id) and 'Убрать' or 'Взять с собой',function() event:FireServer('equip',id) end)
   end
  end
 elseif page=='shop' then
  title.Text='Магазин экспедиции'
  local intro=row(94)
  label(intro,UDim2.new(1,-24,1,0),UDim2.fromOffset(12,0),'Бесплатно: раскопки, все три инструмента, уровень и три вида малышей. За Robux: помощь, особые малыши и 3 активных спутника. Предметы не обмениваются.',14,palette.muted)
  for _,entry in ipairs({{key='help',name='Помощь малышей',desc='Каждый активный малыш наносит 1 урон залежи рядом раз в 3 секунды.',id=C.HelpPass},{key='slots',name='Три спутника',desc='Три активных малыша вместо одного. Коллекция всегда без ограничения.',id=C.SlotsPass}}) do
   local r=row(128)
   label(r,UDim2.new(1,-24,0,30),UDim2.fromOffset(12,8),entry.name,18)
   label(r,UDim2.new(1,-24,0,40),UDim2.fromOffset(12,40),entry.desc,13,palette.muted)
   button(r,UDim2.new(1,-24,0,32),UDim2.fromOffset(12,87),price(entry.id,true),function() buy(entry.key) end)
  end
  for _,id in ipairs({'Nova','Umbra','Sol'}) do
   local r=row(145); viewport(r,id,10,UDim2.new(.25,0,1,0),UDim2.new())
   label(r,UDim2.new(.71,0,0,30),UDim2.new(.27,0,0,10),C.Pets[id].name..' • конкретный малыш',17,C.Pets[id].color)
   label(r,UDim2.new(.71,0,0,38),UDim2.new(.27,0,0,43),'Гарантированный вид. Повтор: +1 фрагмент светлого окраса.',12,palette.muted)
   button(r,UDim2.new(.34,0,0,38),UDim2.new(.27,0,0,94),price(C.DirectProducts[id],false),function() buy(id) end)
   button(r,UDim2.new(.32,0,0,38),UDim2.new(.64,0,0,94),'Стадии роста',function() selectedPreview=id; previewStage=1; render('collection') end)
  end
  local egg=row(208)
  label(egg,UDim2.new(1,-24,0,36),UDim2.fromOffset(12,8),'Кристальное яйцо',20,palette.gold)
  local odds={}; for _,o in ipairs(C.EggOdds) do table.insert(odds,C.Pets[o.id].name..' — '..o.chance..'%') end
  label(egg,UDim2.new(1,-24,0,56),UDim2.fromOffset(12,44),table.concat(odds,'   /   ')..'\nПовтор даёт 1 фрагмент окраса. 5 фрагментов → светлый окрас.',13)
  local allowed=data and data.eggAllowed
  button(egg,UDim2.new(1,-24,0,36),UDim2.fromOffset(12,108),allowed and ('Купить яйцо • '..price(C.EggProduct,false)) or 'Случайные покупки недоступны',function() if allowed then buy('egg') end end,allowed and palette.gold or palette.muted)
  button(egg,UDim2.new(1,-24,0,36),UDim2.fromOffset(12,156),'Открыть яйцо • в наличии '..(data and data.eggs or 0),function() event:FireServer('hatch') end,palette.accent)
 elseif page=='journal' then
  title.Text='Журнал экспедиции'
  for _,entry in ipairs({
   {'01 / ПЕРВАЯ СМЕНА','Спустись с лагеря к серой корке. Наведи курсор на блок и удерживай ЛКМ. На телефоне используй кнопку «Копать».'},
   {'02 / РЕСУРСЫ','Рюкзак ограничен. Сдавай добычу у левого терминала в лагере. На выручку улучшай инструмент у правого верстака.'},
   {'03 / НЕ БУДИТЬ','Если под землёй раздаётся треск и появляется красный круг, отойди. Через 2,5 секунды случится выброс. При гибели теряется 25% несданного.'},
   {'04 / СПЯЩИЕ','Иногда под коркой прячутся малыши. Возьми найденного спутника с собой: он постепенно растёт до твоего уровня, пока ты раскапываешь залежи.'},
   {'05 / ГЛУБИНА','Слои: пыль → камень → кристальная корка. После 90 общих очищенных блоков откроется древняя капсула. Каждый может получить её награду.'},
   {'06 / ПЛАНЕТА ПОМНИТ','Внутри одного сервера раскопки общие. Раз в 10 минут возвращаются до трёх залежей. На новом сервере поверхность создаётся заново.'},
  }) do local r=row(136); label(r,UDim2.new(1,-24,0,32),UDim2.fromOffset(12,8),entry[1],16,palette.accent); label(r,UDim2.new(1,-24,0,86),UDim2.fromOffset(12,43),entry[2],14,palette.muted) end
 end
end
for i,item in ipairs({{'Малыши','collection'},{'Магазин','shop'},{'Журнал','journal'}}) do
 button(nav,UDim2.new(1/3,-10,0,28),UDim2.new((i-1)/3,5,0,6),item[1],function() if modal.Visible and currentPage==item[2] then modal.Visible=false else render(item[2]) end end)
end
for _,b in ipairs(nav:GetChildren()) do
 if b:IsA('TextButton') then b.BackgroundColor3=palette.panel; b.TextColor3=palette.text; b.TextSize=12 end
end
local function character(ch)
 local h=ch:WaitForChild('Humanoid')
 h.CameraOffset=Vector3.new(2,1,0)
 player.CameraMinZoomDistance=6; player.CameraMaxZoomDistance=22
 player.CameraMode=Enum.CameraMode.Classic
 task.wait(.3)
 local cam=workspace.CurrentCamera
 cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=h
 local r=ch:FindFirstChild('HumanoidRootPart')
 if r then cam.CFrame=CFrame.lookAt(r.Position+Vector3.new(12,9,-17),r.Position+Vector3.new(0,2,0)) end
end
player.CharacterAdded:Connect(character); if player.Character then task.spawn(character,player.Character) end
local holding=false; local target=nil; local lastDig=0; local mouse=player:GetMouse()
local function rayTarget()
 local cam=workspace.CurrentCamera; if not cam then return nil end
 local ray
 if UIS.TouchEnabled and not UIS.MouseEnabled then ray=cam:ViewportPointToRay(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
 else
  local pos=UIS:GetMouseLocation(); ray=cam:ScreenPointToRay(pos.X,pos.Y)
 end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 local omit={}; if player.Character then table.insert(omit,player.Character) end
 local world=workspace:FindFirstChild('UnderlayerWorld'); if world and world:FindFirstChild('Companions') then table.insert(omit,world.Companions) end
 params.FilterDescendantsInstances=omit
 local result=workspace:Raycast(ray.Origin,ray.Direction*150,params)
 if result and result.Instance.Parent and result.Instance.Parent.Name=='Deposits' then return result.Instance end
 return nil
end
local selection=Instance.new('Highlight'); selection.FillColor=palette.accent; selection.FillTransparency=.84; selection.OutlineColor=palette.accent; selection.DepthMode=Enum.HighlightDepthMode.Occluded; selection.Parent=workspace.CurrentCamera
UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then holding=true end
 if not processed and input.KeyCode==Enum.KeyCode.B then render('collection') end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then holding=false end end)
UIS.WindowFocusReleased:Connect(function() holding=false end)
local digButton=button(gui,UDim2.fromOffset(112,56),UDim2.new(1,-130,1,-132),'Копать',function() if not modal.Visible then local b=rayTarget(); if b then event:FireServer('dig',b) end end end)
digButton.Visible=UIS.TouchEnabled
local toastToken=0
local function message(txt)
 toastToken=toastToken+1; local token=toastToken
 toastText.Text=txt; toast.Visible=true
 task.delay(8,function() if token==toastToken then toast.Visible=false end end)
end
event.OnClientEvent:Connect(function(action,payload)
 if action=='message' then message(payload)
 elseif action=='data' then
  data=payload
  local tool=C.Tools[data.tool]
  stats.Text='Уровень '..data.level..'    •    '..data.coins..' монет\n'..tool.name..'    /    '..data.bag..' из '..tool.capacity
  local floor=45*(data.level-1)^2; local ceiling=45*data.level^2
  xpBar.Size=UDim2.fromScale(math.clamp((data.xp-floor)/(ceiling-floor),0,1),1)
  levelText.Text=data.offline and 'Тестовый запуск • без сохранения' or ('Опыт '..data.xp)
  if modal.Visible and currentPage=='collection' then render('collection') elseif modal.Visible and currentPage=='shop' then render('shop') end
 end
end)
local accum=0
Run.RenderStepped:Connect(function(dt)
 if previewModel and previewModel.Parent then spin=spin+dt*.4; previewModel:PivotTo(CFrame.Angles(0,spin,0)) end
 accum=accum+dt; if accum<.05 then return end; accum=0
 target=not modal.Visible and rayTarget() or nil; selection.Adornee=target
 targetText.Text=target and (target.Name..'  '..tostring(target:GetAttribute('HP'))..' / '..tostring(target:GetAttribute('MaxHP'))) or ''
 if holding and not modal.Visible and target and os.clock()-lastDig>.36 then lastDig=os.clock(); event:FireServer('dig',target) end
end)
task.spawn(function()
 for _=1,15 do if data then return end; event:FireServer('sync'); task.wait(1) end
 stats.Text='Мир загружен, сервер не отвечает'
 message('Скрипт игры не запустился. Открой View → Output и посмотри первую красную ошибку.')
end)
