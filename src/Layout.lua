-- One layout shared by the editable place, source-only runtime and gameplay.
local L={}
L.Size=3072
L.Tile=64
L.SurfaceY=0
L.BlockSize=16
L.PatchCells=8
L.Layers=3
L.CampZ=-1240
L.Zones={
 {name='01 / Тихая равнина',x=0,z=-1024},
 {name='02 / Пыльное море',x=448,z=-896},
 {name='03 / Старый разлом',x=-512,z=-832},
 {name='04 / Кратер Эхо',x=960,z=-448},
 {name='05 / Потерянный зонд',x=-1088,z=-320},
 {name='06 / Застывшая волна',x=128,z=-384},
 {name='07 / Дальний сектор',x=448,z=192},
 {name='08 / Глухая впадина',x=-384,z=256},
 {name='09 / Край тишины',x=1088,z=576},
 {name='10 / Тёмное море',x=-1088,z=768},
 {name='11 / Последний сигнал',x=0,z=1024},
 {name='12 / Северная экспедиция',x=768,z=1152},
}
function L.LayerY(layer) return L.SurfaceY-1.25-(layer-1)*2.5 end
function L.InPatch(x,z,margin)
 local half=L.PatchCells*L.BlockSize/2+(margin or 0)
 for _,zone in ipairs(L.Zones) do
  if math.abs(x-zone.x)<half and math.abs(z-zone.z)<half then return true end
 end
 return false
end
return L
