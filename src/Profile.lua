-- Session lease + serialized writes. Studio can run offline; purchases cannot.
local DSS=game:GetService('DataStoreService')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local C=require(game.ReplicatedStorage.Underlayer.Config)
-- DataStore acquisition itself can throw in an unpublished place.
local store
local acquired, result=pcall(function()
 if Run:IsStudio() and not C.StudioPersistence then return nil end
 return DSS:GetDataStore(C.SaveName)
end)
if acquired then store=result end
local owner=game.JobId~='' and game.JobId or Http:GenerateGUID(false)
local P={}; P.Live={}
local function copy(x)
 if type(x)~='table' then return x end
 local y={}; for k,v in pairs(x) do y[k]=copy(v) end; return y
end
local function fresh()
 return {coins=0,xp=0,bag=0,tool=1,pets={Dust={growth=1,fragments=0}},equipped={'Dust'},eggs=0,receipts={}}
end
function P.Load(player)
 local success, record=false,nil
 if store then success, record=pcall(function()
  return store:UpdateAsync('u'..player.UserId,function(old)
   old=old or {data=fresh()}
   if old.owner and old.owner~=owner and (old.lease or 0)>os.time() then return nil end
   old.owner=owner; old.lease=os.time()+180; return old
  end)
 end) end
 if success and not record then return nil,'Твой профиль ещё открыт на другом сервере. Попробуй через минуту.' end
 if not success and not Run:IsStudio() then return nil,'Не удалось загрузить сохранение. Попробуй снова позже.' end
 local state={data=success and record.data or fresh(),busy=false,offline=not success,owner=owner}
 local d=state.data; d.receipts=d.receipts or {}; d.eggs=d.eggs or 0
 P.Live[player]=state
 return state
end
function P.Commit(player, transform, release)
 local s=P.Live[player]; if not s or s.busy then return false end
 if s.offline then return false end
 s.busy=true
 local snapshot=copy(s.data)
 local ok,result=pcall(function()
  return store:UpdateAsync('u'..player.UserId,function(old)
   if not old or old.owner~=owner then return nil end
   local nextData=copy(snapshot)
   -- Purchase receipts are saved atomically with their grant.
   nextData.receipts=copy(old.data.receipts or {})
   if transform then transform(nextData) end
   local result={data=nextData,lease=release and 0 or os.time()+180}
   if not release then result.owner=owner end
   return result
  end)
 end)
 if ok and result then s.data=result.data end
 s.busy=false
 if not ok or not result then
  s.saveFailed=true
  if not release then player:Kick('Сохранение недоступно. Войди снова, чтобы защитить прогресс.') end
  return false
 end
 return true
end
function P.WaitSave(player,release)
 local s=P.Live[player]; if not s or s.offline then return end
 local deadline=os.clock()+20
 while s.busy and os.clock()<deadline do task.wait(.1) end
 if not s.busy then P.Commit(player,nil,release) end
end
function P.Copy(x) return copy(x) end
return P
