-- Minimal build-time Roblox value/Instance adapter. Not an engine simulator.
local vecmt={}
local function vector(x,y,z) return setmetatable({_type='Vector3',X=x,Y=y,Z=z},vecmt) end
vecmt.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vecmt.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vecmt.__index=function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
vecmt.__mul=function(a,b) if type(a)=='number' then return vector(a*b.X,a*b.Y,a*b.Z) end; return vector(a.X*b,a.Y*b,a.Z*b) end
Vector3={new=vector}; Vector3.zero=vector(0,0,0)
local colmt={}
local function color(r,g,b) return setmetatable({_type='Color3',R=r,G=g,B=b},colmt) end
colmt.__index={Lerp=function(a,b,t) return color(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end}
Color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end}
UDim2={fromOffset=function(x,y) return {_type='UDim2',xs=0,xo=x,ys=0,yo=y} end,fromScale=function(x,y) return {_type='UDim2',xs=x,xo=0,ys=y,yo=0} end}
Enum=setmetatable({},{__index=function(_,group) return setmetatable({},{__index=function(_,value) return 'Enum.'..group..'.'..value end}) end})
local cfmt={}
local function cf(x,y,z,r)
 return setmetatable({_type='CFrame',X=x or 0,Y=y or 0,Z=z or 0,R=r or {1,0,0,0,1,0,0,0,1}},cfmt)
end
cfmt.__mul=function(a,b)
 local ar,br=a.R,b.R; local rr={}
 for row=0,2 do for col=0,2 do
  local v=0; for k=0,2 do v=v+ar[row*3+k+1]*br[k*3+col+1] end; rr[row*3+col+1]=v
 end end
 return cf(a.X+ar[1]*b.X+ar[2]*b.Y+ar[3]*b.Z,a.Y+ar[4]*b.X+ar[5]*b.Y+ar[6]*b.Z,a.Z+ar[7]*b.X+ar[8]*b.Y+ar[9]*b.Z,rr)
end
CFrame={new=function(x,y,z) if type(x)=='table' then return cf(x.X,x.Y,x.Z) end; return cf(x,y,z) end,Angles=function(x,y,z)
 local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
 return cf(0,0,0,{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
end}
local methods={}
local mt={__index=function(t,k)
 if methods[k] then return methods[k] end
 if k=='Position' then local p=t._props.CFrame; if p then return vector(p.X,p.Y,p.Z) end end
 if k=='CFrame' then local p=t._props.Position; if p then return cf(p.X,p.Y,p.Z) end; return cf() end
 return t._props[k]
end,__newindex=function(t,k,v)
 if k=='Parent' then
  local old=rawget(t,'_parent')
  if old then for i,child in ipairs(old._children) do if child==t then table.remove(old._children,i); break end end end
  if v then table.insert(v._children,t) end; rawset(t,'_parent',v) else t._props[k]=v end
end}
function methods:FindFirstChild(name)
 for _,v in ipairs(self._children) do if v.Name==name then return v end end
end
function methods:FindFirstChildOfClass(cls)
 for _,v in ipairs(self._children) do if v._class==cls then return v end end
end
function methods:GetChildren() return self._children end
function methods:Destroy() end
Instance={new=function(cls) return setmetatable({_class=cls,_props={},_children={}},mt) end}
workspace=Instance.new('Workspace')
local lighting=Instance.new('Lighting')
game={GetService=function(_,name) assert(name=='Lighting'); return lighting end}
local function escape(s) return '"'..s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
local function json(x)
 local kind=type(x)
 if kind=='string' then return escape(x) end
 if kind=='number' or kind=='boolean' then return tostring(x) end
 if kind~='table' then return 'null' end
 local parts={}
 if #x>0 then for _,v in ipairs(x) do table.insert(parts,json(v)) end; return '['..table.concat(parts,',')..']' end
 for k,v in pairs(x) do table.insert(parts,escape(tostring(k))..':'..json(v)) end
 return '{'..table.concat(parts,',')..'}'
end
script={Parent={Layout='layout'}}
require=function(ref) assert(ref=='layout'); return assert(loadfile(WORLD_LAYOUT))() end
local W=assert(loadfile(WORLD_SOURCE))(); local result=W.Build()
local reused=W.Build(); assert(reused.Root==result.Root and reused.Sell==result.Sell and reused.Upgrade==result.Upgrade,'Prebuilt world was replaced')
local function export(node)
 local children={}; for _,child in ipairs(node._children) do table.insert(children,export(child)) end
 return {class=node._class,properties=node._props,children=children}
end
local file=assert(io.open(WORLD_OUTPUT,'w')); file:write(json({world=export(result.Root),lighting=export(lighting)})); file:close()
