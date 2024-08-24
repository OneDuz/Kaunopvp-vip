RegisterCommand("VIP", function()
    lib.callback('vip:getDaysLeft', source, function(data)
        if data.isVip then
            lib.registerContext({
                id = 'VIP_MENIU',
                title = 'VIP',
                options = {
                    {
                        title = 'VIP',
                        description = 'VIP YPATYBĖS',
                        icon = 'star',
                        onSelect = function()
                            lib.showContext('VIP_MENIU2')
                        end,
                    },
                    {
                        title = 'PANAUDOTI KODĄ',
                        description = 'PATEIKITE KODĄ NORĖDAMI GAUTI VIP',
                        icon = 'barcode',
                        onSelect = function()
                            local input = lib.inputDialog('VIP KODO ĮVEDIMAS', {
                                { type = 'number', label = 'Įveskite čia', description = 'Kai kuris skaičiaus aprašymas'},
                            })

                            if not input[1] then return end
                            lib.callback('vip:redeemcode', source, function(data)
                                lib.notify({
                                    title = 'VIP',
                                    description = data.response,
                                    type = data.status
                                })
                            end, json.encode(input[1]))
                        end,
                    },
                    {
                        title = 'VIP',
                        description = 'GAUKITE KASDIEN GINKLUS',
                        icon = 'clock',
                        onSelect = function()
                            lib.callback('vip:getguns', source, function(data)
                                lib.notify({
                                    title = 'VIP',
                                    description = data,
                                    type = "inform"
                                })
                            end)
                        end,
                    },
                    {
                        title = 'VIP',
                        description = 'GAUKITE KASDIEN PINIGUS',
                        icon = 'clock',
                        onSelect = function()
                            lib.callback('vip:getmoney', source, function(data)
                                lib.notify({
                                    title = 'VIP',
                                    description = data,
                                    type = "inform"
                                })
                            end)
                        end,
                    },
                    {
                        title = 'VIP',
                        description = 'VIP PASIBAIGIMAS',
                        icon = 'clock',
                        metadata = {
                            { label = 'VIP Statusas', value = data.isVip },
                            { label = 'Likę VIP Dienos',   value = data.daysLeft }
                        },
                    },
                }
            })
        else
            lib.registerContext({
                id = 'VIP_MENIU',
                title = 'VIP',
                options = {
                    {
                        title = 'VIP',
                        description = 'VIP YPATYBĖS',
                        icon = 'star',
                        disabled = true
                    },
                    {
                        title = 'PANAUDOTI KODĄ',
                        description = 'PATEIKITE KODĄ NORĖDAMI GAUTI VIP',
                        icon = 'barcode',
                        onSelect = function()
                            local input = lib.inputDialog('VIP KODO ĮVEDIMAS', {
                                { type = 'number', label = 'Įveskite čia', description = 'Kai kuris skaičiaus aprašymas', icon = 'hashtag' },
                            })

                            if not input[1] then return end
                            lib.callback('vip:redeemcode', source, function(data)
                                lib.notify({
                                    title = 'VIP',
                                    description = data.response,
                                    type = data.status
                                })
                            end, json.encode(input[1]))
                        end,
                    },
                    {
                        title = 'VIP',
                        description = 'VIP PASIBAIGIMAS',
                        icon = 'clock',
                        metadata = {
                            { label = 'VIP Statusas', value = data.isVip },
                            { label = 'Likę VIP Dienos',   value = data.daysLeft }
                        },
                    },
                }
            })
        end
        lib.showContext('VIP_MENIU')
    end)
end)


lib.registerContext({
    id = 'VIP_MENIU2',
    title = 'VIP',
    options = {
        {
            title = 'Daugiau vietos',
            description = 'Daugiau vietos inventorius',
            icon = 'box-open',
        },
        {
            title = 'Greitesnis atgaivinimas',
            description = 'Jūsų atgaivinimo laikas sumažinamas, kad atgaivintumėte greičiau',
            icon = 'face-kiss-wink-heart',
        },
        {
            title = 'Gaukite šarvus',
            description = 'Po prisikėlimo gausite nemokamai šarvus',
            icon = 'shield',
        },
        {
            title = 'Speciali transporto priemonė',
            description = 'Gausite specialią transporto priemonę, kurią galėsite vairuoti tik jūs',
            icon = 'car',
        },
        {
            title = 'Kasdieniai pinigai',
            description = 'Kasdien gausite apie 1M pinigų',
            icon = 'money-bill',
        },
        {
            title = 'Kasdieniai ginklai',
            description = 'Kasdien gausite 18 ginklų, dauguma jų bus atsitiktiniai',
            icon = 'person-rifle',
        },
        {
            title = '/v',
            description = '/v chatas su kitais vip zaidejais per visa serveri',
            icon = 'crown',
        },
        {
            title = '/tune',
            description = '/tune komanda kuris leis jums belekur savo tr.p tuninti',
            icon = 'car',
        },
        {
            title = '/VTP',
            description = 'Galesite lengviau ir greiciau i zonas nukeliauti',
            icon = 'person-walking-with-cane',
        },
        -- {
        --     title = '2X XP',
        --     description = 'Daugiau XP gausite',
        --     icon = 'soap',
        -- },
    }
})


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    lib.callback('vip:getDaysLeft', source, function(data)
        if data.isVip then
            print("you have vip yay loaded")
        end
    end)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        lib.callback('vip:getDaysLeft', source, function(data)
            if data.isVip then
                print("you have vip yay started")
            end
        end)
    end
end)


Citizen.CreateThread(function()
    while true do
        print("[VIP] 5 mins has passed checking vip status...")
        lib.callback('vip:getDaysLeft', source, function(data)
            print("[VIP] data sent")
            print("[VIP] data recieved", data)
            if data.isVip then
                print("[VIP] vip data = "..json.encode(data).."")
            end
        end)
        Citizen.Wait(300000)
    end
end)


RegisterCommand("VIPPED", function()
    lib.callback('vip:getDaysLeft', source, function(data)
        if data.isVip then
            lib.registerContext({
                id = 'VIP_PED',
                title = 'VIP PEDAI',
                options = {
                    {
                        title = 'Pasikeisti Ped',
                        icon = 'person',
                        onSelect = function()
                            lib.registerContext({
                                id = 'VIP_PEDAI',
                                title = 'VIP PEDAI',
                                options = {
                                    {
                                        title = 'PED #1',
                                        icon = 'person',
                                        image = 'https://docs.fivem.net/peds/a_f_m_beach_01.webp',
                                        onSelect = function()
                                            setpednx("a_f_m_beach_01")
                                        end
                                    },
                                    {
                                        title = 'PED #2',
                                        icon = 'person',
                                        image = 'https://docs.fivem.net/peds/a_m_m_fatlatin_01.webp',
                                        onSelect = function()
                                            setpednx("a_m_m_fatlatin_01")
                                        end
                                    },
                                    {
                                        title = 'DEFAULT #1',
                                        icon = 'person',
                                        image = 'https://docs.fivem.net/peds/mp_m_freemode_01.webp',
                                        onSelect = function()
                                            setpednx("mp_m_freemode_01")
                                        end
                                    },
                                    {
                                        title = 'DEFAULT #2',
                                        icon = 'person',
                                        image = 'https://docs.fivem.net/peds/mp_f_freemode_01.webp',
                                        onSelect = function()
                                            setpednx("mp_f_freemode_01")
                                        end
                                    },
                                }
                            })
                            lib.showContext('VIP_PEDAI')

                        end
                    },
                }
            })
        lib.showContext('VIP_PED')
        end
    end)
end)

function setpednx(modelname)
        local model = GetHashKey(modelname)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(500)
        end
        local playerPed = PlayerPedId()
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        local newPlayerPed = PlayerPedId()
        if newPlayerPed ~= playerPed then
            SetPedDefaultComponentVariation(newPlayerPed)
        end
end

--[[


    lib.callback('vip:getDaysLeft', source, function(data)
        print(data.isVip)
        print(data.daysLeft)
    end)

]]
