local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Market=game:GetService('MarketplaceService')
local Policy=game:GetService('PolicyService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local F=RS:WaitForChild('Underlayer')
local C=require(F.Config); local Visual=require(F.PetVisual)
local Profile=require(script.Parent.Profile)
local world=require(script.Parent.World).Build()
local event=F.Action
local rng=Random.new()
local sessions={}
local blocks=Instance.new('Folder'); blocks.Name='Deposits'; blocks.Parent=world.Root
local petsFolder=Instance.new('Folder'); petsFolder.Name='Companions'; petsFolder.Parent=world.Root
local function tell(p,message) if p.Parent then event:FireClient(p,'message',message) end end
local function rootOf(p)
 local ch=p.Character; local h=ch and ch:FindFirstChildOfClass('Humanoid')
 return h and h.Health>0 and ch:FindFirstChild('HumanoidRootPart') or nil
end
local function state(p)
 local s=Profile.Live[p]; if s and not s.busy and not s.saveFailed then return s.data end
end
local function sync(p)
 local s=Profile.Live[p]; local u=sessions[p]
 if not s or not u then return end
 local d=Profile.Copy(s.data); d.receipts=nil
 d.level=C.Level(d.xp); d.help=u.help; d.slots=u.slots and 3 or 1
 d.eggAllowed=u.policy==true and not s.offline
 d.offline=s.offline; d.configured=C.EggProduct>0
 event:FireClient(p,'data',d)
end
local function rebuild(p)
 local u=sessions[p]; local d=Profile.Live[p] and Profile.Live[p].data
 if not u or not d then return end
 for _,model in ipairs(u.models) do model:Destroy() end; u.models={}
 local root=rootOf(p)
 for i,id in ipairs(d.equipped) do
  if i>(u.slots and 3 or 1) then break end
  local pet=d.pets[id]
  if pet and C.Pets[id] then
   local def=table.clone(C.Pets[id])
   if pet.fragments>=5 then def.color=def.color:Lerp(Color3.new(1,1,1),.45) end
   local model=Visual.Build(id,def,pet.growth)
   model.Parent=petsFolder
   model:PivotTo(root and root.CFrame*CFrame.new(i*3,0,4) or CFrame.new(0,6,-45))
   table.insert(u.models,model)
  end
 end
end
local function refreshEntitlements(p)
 local u=sessions[p]; if not u then return end
 for _,kind in ipairs({'Help','Slots'}) do
  local id=kind=='Help' and C.HelpPass or C.SlotsPass
  if id>0 then
   local ok,owns=pcall(Market.UserOwnsGamePassAsync,Market,p.UserId,id)
   if ok then u[string.lower(kind)]=owns end
  end
 end
 sync(p); rebuild(p)
end
local hazardSerial=0
local function hazard(position)
 hazardSerial=hazardSerial+1
 local marker=Instance.new('Part'); marker.Name='UnstableDeposit'; marker.Shape=Enum.PartType.Cylinder
 marker.Size=Vector3.new(.12,16,16); marker.CFrame=CFrame.new(position.X,position.Y+2,position.Z)*CFrame.Angles(0,0,math.pi/2)
 marker.Color=Color3.fromRGB(255,118,92); marker.Material=Enum.Material.Neon; marker.Transparency=.35
 marker.Anchored=true; marker.CanCollide=false; marker.CanQuery=false; marker.Parent=world.Root
 for _,p in ipairs(Players:GetPlayers()) do
  local root=rootOf(p); if root and (root.Position-position).Magnitude<32 then tell(p,'ТРЕСК ПОД НОГАМИ — отойди от красного круга!') end
 end
 task.delay(2.5,function()
  for _,p in ipairs(Players:GetPlayers()) do
   local root=rootOf(p)
   if root and (root.Position-position).Magnitude<10 then root.Parent:FindFirstChildOfClass('Humanoid'):TakeDamage(38) end
  end
  local burst=Instance.new('Part'); burst.Shape=Enum.PartType.Ball; burst.Size=Vector3.new(1,1,1); burst.Position=position
  burst.Color=Color3.fromRGB(223,128,112); burst.Material=Enum.Material.Neon; burst.Anchored=true; burst.CanCollide=false; burst.CanQuery=false; burst.Parent=world.Root
  Tween:Create(burst,TweenInfo.new(.5),{Size=Vector3.new(16,16,16),Transparency=1}):Play()
  marker:Destroy(); game:GetService('Debris'):AddItem(burst,.7)
 end)
end
local function makeBlock(x,z,layer)
 local b=Instance.new('Part'); b.Name='Слой '..layer
 b.Size=Vector3.new(6.8,2.5,6.8); b.Position=Vector3.new(x,4.25-(layer-1)*2.5,z)
 b.Color=({Color3.fromRGB(97,101,109),Color3.fromRGB(75,86,100),Color3.fromRGB(86,75,106)})[layer]
 b.Material=layer==1 and Enum.Material.Sand or Enum.Material.Slate
 b.Anchored=true; b:SetAttribute('Layer',layer); b:SetAttribute('HP',layer+1); b:SetAttribute('MaxHP',layer+1)
 b:SetAttribute('Hazard',rng:NextNumber()<.085)
 b:SetAttribute('Find',rng:NextNumber()<.075)
 b.Parent=blocks
end
for ix=-6,6 do for iz=0,17 do for layer=1,3 do makeBlock(ix*7,iz*7,layer) end end end
local depleted={}
local cleared=0
local function totalCapacity(d) return C.Tools[d.tool].capacity end
local function dig(p,b,auto)
 local d=state(p); local root=rootOf(p)
 if not d or not root or typeof(b)~='Instance' or not b:IsA('BasePart') or b.Parent~=blocks then return end
 if (root.Position-b.Position).Magnitude>18 then return end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={p.Character,petsFolder}
 local origin=root.Position+Vector3.new(0,1,0)
 local hit=workspace:Raycast(origin,b.Position-origin,params)
 if not hit or hit.Instance~=b then return end
 local layer=b:GetAttribute('Layer')
 if d.bag>=totalCapacity(d) then if not auto then tell(p,'Рюкзак полон. Вернись к терминалу в лагере.') end; return end
 local hp=b:GetAttribute('HP')-(auto and 1 or C.Tools[d.tool].power)
 if hp>0 then b:SetAttribute('HP',hp); b.Color=b.Color:Lerp(Color3.fromRGB(156,175,173),.15); return end
 local pos=b.Position; local find=b:GetAttribute('Find'); local danger=b:GetAttribute('Hazard')
 table.insert(depleted,{x=pos.X,z=pos.Z,layer=layer})
 b:Destroy(); cleared=cleared+1
 d.bag=math.min(totalCapacity(d),d.bag+3+layer*2)
 local before=C.Level(d.xp); d.xp=d.xp+5+layer*2
 local level=C.Level(d.xp)
 local changed=false
 for _,id in ipairs(d.equipped) do
  local pet=d.pets[id]
  if pet and pet.growth<math.min(level,50) then
   pet.growth=math.min(level,50,pet.growth+.14); changed=true
  end
 end
 if level>before then tell(p,'УРОВЕНЬ '..level..' • малыши могут вырасти ещё!') end
 if find then
  local ids={'Dust','Moss','Crystal'}; local id=ids[rng:NextInteger(1,#ids)]
  if d.pets[id] then
   d.pets[id].fragments=d.pets[id].fragments+1
   tell(p,'Найден фрагмент: '..C.Pets[id].name..'. 5 фрагментов открывают светлый окрас.')
  else d.pets[id]={growth=1,fragments=0}; tell(p,'В коконе спал '..C.Pets[id].name..'! Открой коллекцию.') end
 end
 if danger then hazard(pos) end
 if changed then
  local u=sessions[p]
  if os.clock()-(u.lastRebuild or 0)>5 then u.lastRebuild=os.clock(); rebuild(p) end
 end
 if cleared==90 then
  for _,pl in ipairs(Players:GetPlayers()) do tell(pl,'Под коркой обнаружена древняя капсула. Центральный сектор изменился.') end
  local capsule=Instance.new('Part'); capsule.Name='AncientCapsule'; capsule.Shape=Enum.PartType.Ball
  capsule.Size=Vector3.new(9,13,9); capsule.Position=Vector3.new(0,1,63); capsule.Material=Enum.Material.Neon
  capsule.Color=Color3.fromRGB(126,137,184); capsule.Anchored=true; capsule.Parent=world.Root
  local prompt=Instance.new('ProximityPrompt'); prompt.ActionText='Освободить малыша'; prompt.ObjectText='Древняя капсула'; prompt.HoldDuration=2; prompt.MaxActivationDistance=13; prompt.Parent=capsule
  local claimed={}
  prompt.Triggered:Connect(function(pl)
   local dd=state(pl); local rr=rootOf(pl)
   if not dd or not rr or (rr.Position-capsule.Position).Magnitude>17 or claimed[pl.UserId] then return end
   claimed[pl.UserId]=true
   if not dd.pets.Crystal then dd.pets.Crystal={growth=1,fragments=0} else dd.pets.Crystal.fragments=dd.pets.Crystal.fragments+2 end
   dd.xp=dd.xp+100; tell(pl,'Кристик освобождён. +100 опыта.'); sync(pl)
  end)
 end
 sync(p)
end
world.Sell.Triggered:Connect(function(p)
 local d=state(p); local root=rootOf(p)
 if not d or not root or (root.Position-world.Sell.Parent.Position).Magnitude>16 then return end
 local amount=d.bag; d.coins=d.coins+amount*2; d.bag=0; sync(p); tell(p,'Сдано '..amount..' ресурсов • +'..(amount*2)..' монет')
end)
world.Upgrade.Triggered:Connect(function(p)
 local d=state(p); local root=rootOf(p)
 if not d or not root or (root.Position-world.Upgrade.Parent.Position).Magnitude>16 then return end
 local nextTool=C.Tools[d.tool+1]
 if not nextTool then tell(p,'Бур уже максимального уровня.'); return end
 if d.coins<nextTool.cost then tell(p,nextTool.name..': нужно '..nextTool.cost..' монет.'); return end
 d.coins=d.coins-nextTool.cost; d.tool=d.tool+1; sync(p); tell(p,'Получен '..nextTool.name..'!')
end)
local function givePet(d,id)
 if d.pets[id] then d.pets[id].fragments=d.pets[id].fragments+1 else d.pets[id]={growth=1,fragments=0} end
end
local function eggRoll()
 local n=rng:NextNumber(0,100); local sum=0
 for _,o in ipairs(C.EggOdds) do sum=sum+o.chance; if n<sum then return o.id end end
 return C.EggOdds[#C.EggOdds].id
end
local function productKind(id)
 if id==0 then return nil end
 if id==C.EggProduct then return 'egg' end
 for pet,product in pairs(C.DirectProducts) do if id==product then return pet end end
end
Market.ProcessReceipt=function(receipt)
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 local s=p and Profile.Live[p]; local u=p and sessions[p]
 local kind=productKind(receipt.ProductId)
 if not p or not s or not u or s.offline or not kind then return Enum.ProductPurchaseDecision.NotProcessedYet end
 while s.busy and p.Parent do task.wait(.1) end
 if not p.Parent or s.saveFailed then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local ok=Profile.Commit(p,function(d)
  if d.receipts[receipt.PurchaseId] then return end
  if kind=='egg' then d.eggs=d.eggs+1 else givePet(d,kind) end
  d.receipts[receipt.PurchaseId]=true
 end)
 if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
 sync(p); tell(p,kind=='egg' and 'Яйцо добавлено в коллекцию. Открой его в магазине.' or 'Малыш добавлен в коллекцию!')
 return Enum.ProductPurchaseDecision.PurchaseGranted
end
Market.PromptGamePassPurchaseFinished:Connect(function(p,id,purchased)
 if purchased and (id==C.HelpPass or id==C.SlotsPass) then task.defer(refreshEntitlements,p) end
end)
local function onPlayer(p)
 sessions[p]={models={},help=false,slots=false,policy=false,lastAction=0,lastDig=0}
 local s,err=Profile.Load(p)
 if not s then sessions[p]=nil; p:Kick(err); return end
 if not p.Parent then Profile.WaitSave(p,true); Profile.Live[p]=nil; sessions[p]=nil; return end
 local u=sessions[p]
 local ok,policy=pcall(Policy.GetPolicyInfoForPlayerAsync,Policy,p)
 if ok then u.policy=policy.ArePaidRandomItemsRestricted==false end
 local function character(ch)
  local hum=ch:WaitForChild('Humanoid'); hum.WalkSpeed=18
  hum.Died:Connect(function()
   local live=Profile.Live[p]
   if not live then return end
   -- Wait out an in-flight durable purchase before changing the same profile.
   while live.busy do task.wait(.05) end
   local d=live.data; local lost=math.ceil(d.bag*.25); d.bag=d.bag-lost
   tell(p,'Экстренная эвакуация. Потеряно '..lost..' несданных ресурсов.'); sync(p)
  end)
  task.delay(.8,function() if sessions[p] then rebuild(p); sync(p) end end)
 end
 p.CharacterAdded:Connect(character)
 if p.Character then task.spawn(character,p.Character) end
 refreshEntitlements(p); sync(p)
 if s.offline then tell(p,'РЕЖИМ STUDIO: сохранение недоступно. Прогресс временный, покупки отключены.') end
end
Players.PlayerAdded:Connect(onPlayer)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer,p) end
Players.PlayerRemoving:Connect(function(p)
 Profile.WaitSave(p,true)
 local u=sessions[p]; if u then for _,m in ipairs(u.models) do m:Destroy() end end
 sessions[p]=nil; Profile.Live[p]=nil
end)
event.OnServerEvent:Connect(function(p,action,arg)
 local u=sessions[p]; local d=state(p)
 if not u or not d then return end
 if action=='sync' then if os.clock()-(u.lastSync or 0)<1 then return end; u.lastSync=os.clock(); sync(p); return end
 if action=='dig' then
  if os.clock()-u.lastDig<.32 then return end; u.lastDig=os.clock(); dig(p,arg,false); return
 end
 if os.clock()-u.lastAction<.4 then return end; u.lastAction=os.clock()
 if action=='equip' then
  if typeof(arg)~='string' or not d.pets[arg] then return end
  local found=table.find(d.equipped,arg)
  if found then table.remove(d.equipped,found)
  elseif #d.equipped<(u.slots and 3 or 1) then table.insert(d.equipped,arg)
  else tell(p,'Все места заняты. Сначала убери выбранного спутника.'); return end
  rebuild(p); sync(p)
 elseif action=='buy' then
  if Profile.Live[p].offline then tell(p,'Покупки отключены в режиме без сохранения.'); return end
  if arg=='help' or arg=='slots' then
   local id=arg=='help' and C.HelpPass or C.SlotsPass
   if id<=0 then tell(p,'Покупка ещё не настроена создателем.'); return end
   if (arg=='help' and u.help) or (arg=='slots' and u.slots) then tell(p,'Уже приобретено.'); return end
   Market:PromptGamePassPurchase(p,id)
  else
   local id=0
   if arg=='egg' then
    if not u.policy then tell(p,'Платные случайные яйца недоступны для этого аккаунта. Выбери конкретного малыша.'); return end
    id=C.EggProduct
   elseif typeof(arg)=='string' then id=C.DirectProducts[arg] or 0 end
   if id<=0 then tell(p,'Покупка ещё не настроена создателем.'); return end
   Market:PromptProductPurchase(p,id)
  end
 elseif action=='hatch' then
  if not u.policy or Profile.Live[p].offline or d.eggs<1 then tell(p,'Нет доступного яйца или открытие недоступно.'); return end
  local id=eggRoll()
  local ok=Profile.Commit(p,function(dd) dd.eggs=dd.eggs-1; givePet(dd,id) end)
  if ok then tell(p,'Из яйца появился '..C.Pets[id].name..'! Повтор даёт фрагмент окраса.'); sync(p) end
 end
end)
local tickTime=0
Run.Heartbeat:Connect(function(dt)
 tickTime=tickTime+dt; if tickTime<.05 then return end
 local step=tickTime; tickTime=0
 for p,u in pairs(sessions) do
  local r=rootOf(p)
  if r then
   for i,m in ipairs(u.models) do
    if m.PrimaryPart then
     local x=(i-(#u.models+1)/2)*3
     local target=r.CFrame*CFrame.new(x,.2+math.sin(os.clock()*3+i)*.25,4)
     m:PivotTo(m:GetPivot():Lerp(target,1-math.exp(-7*step)))
    end
   end
  end
 end
end)
task.spawn(function()
 while task.wait(3) do
  for p,u in pairs(sessions) do
   local r=rootOf(p)
   if u.help and #u.models>0 and r then
    local nearest=nil; local distance=15
    for _,b in ipairs(blocks:GetChildren()) do
     local n=(b.Position-r.Position).Magnitude
     if n<distance then distance=n; nearest=b end
    end
    if nearest then for _=1,#u.models do if nearest.Parent then dig(p,nearest,true) end end end
   end
  end
 end
end)
task.spawn(function()
 while task.wait(45) do for p in pairs(Profile.Live) do task.spawn(Profile.WaitSave,p,false) end end
end)
task.spawn(function()
 while task.wait(600) do
  -- Rare server-wide respawn: only three fully emptied columns, never inside a player.
  local count=0
  for index=#depleted,1,-1 do
   local spot=depleted[index]; local free=true
   for _,b in ipairs(blocks:GetChildren()) do if b.Position.X==spot.x and b.Position.Z==spot.z then free=false; break end end
   for _,p in ipairs(Players:GetPlayers()) do local r=rootOf(p); if r and (r.Position-Vector3.new(spot.x,r.Position.Y,spot.z)).Magnitude<12 then free=false end end
   if free then
    for layer=1,3 do makeBlock(spot.x,spot.z,layer) end
    table.remove(depleted,index); count=count+1
    if count>=3 then break end
   end
  end
  if count>0 then for _,p in ipairs(Players:GetPlayers()) do tell(p,'Сканер: обнаружено '..count..' новых залежей.') end end
 end
end)
game:BindToClose(function()
 local pending=0
 for p in pairs(Profile.Live) do pending=pending+1; task.spawn(function() Profile.WaitSave(p,true); pending=pending-1 end) end
 local deadline=os.clock()+25; while pending>0 and os.clock()<deadline do task.wait(.1) end
end)
