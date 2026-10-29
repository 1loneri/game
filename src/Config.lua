local C = {}
C.Version = 3
C.StudioPersistence = false -- Play работает без публикации и API-доступа; true только для теста DataStore
C.SaveName = 'Underlayer_v1'
C.HelpPass = 0 -- game pass: автоматическая помощь выбранных малышей
C.SlotsPass = 0 -- game pass: всего три активных спутника вместо одного
C.EggProduct = 0 -- developer product: одно яйцо
C.DirectProducts = {Nova=0, Umbra=0, Sol=0} -- developer products: конкретный малыш
C.EggOdds = {{id='Nova',chance=60},{id='Umbra',chance=30},{id='Sol',chance=10}}
C.Pets = {
 Dust={name='Пылик',color=Color3.fromRGB(172,183,189),kind='fluff',premium=false},
 Moss={name='Мохлик',color=Color3.fromRGB(124,175,145),kind='sprout',premium=false},
 Crystal={name='Кристик',color=Color3.fromRGB(133,191,208),kind='crystal',premium=false},
 Nova={name='Нова',color=Color3.fromRGB(184,148,240),kind='star',premium=true},
 Umbra={name='Умбра',color=Color3.fromRGB(106,134,198),kind='horns',premium=true},
 Sol={name='Сол',color=Color3.fromRGB(246,189,113),kind='sun',premium=true},
}
C.Tools = {
 {name='Щётка',cost=0,power=1,capacity=50},
 {name='Скребок',cost=140,power=2,capacity=100},
 {name='Бур',cost=650,power=4,capacity=200},
}
function C.Level(xp) return math.floor(math.sqrt(math.max(0,xp)/45))+1 end
function C.Stage(growth)
 if growth>=50 then return 5 elseif growth>=30 then return 4 elseif growth>=15 then return 3 elseif growth>=6 then return 2 end
 return 1
end
return C
