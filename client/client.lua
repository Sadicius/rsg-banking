local RSGCore = exports['rsg-core']:GetCoreObject()
local BankOpen = false
local SpawnedBankBilps = {}

---------------------------------
-- prompts and blips if needed
---------------------------------
CreateThread(function()
    for _,v in pairs(Config.BankLocations) do
        if Config.UseTarget then
            exports['rsg-target']:AddCircleZone(v.bankid, v.coords, 1, {
                name = v.bankid,
                useZ = true
            }, {
                options = {
                    {
                        type = "client",
                        icon = "fas fa-bank",
                        label = "Open bank",
                        action = function()
                            TriggerEvent('rsg-banking:client:OpenBanking', v.bankid)
                        end
                    },
                },
                distance = 1.5
            })
        else
            exports['rsg-core']:createPrompt(v.bankid, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], Lang:t('client.lang_1')..v.name, {
                type = 'client',
                event = 'rsg-banking:client:OpenBanking',
                args = {v.bankid},
            })
        end
        if v.showblip == true then    
            local BankBlip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(BankBlip, joaat(v.blipsprite), true)
            SetBlipScale(BankBlip, v.blipscale)
            SetBlipName(BankBlip, v.name)
            table.insert(SpawnedBankBilps, BankBlip)
        end
    end
end)

---------------------------------
-- set bank door default state
---------------------------------
CreateThread(function()
    for _,v in pairs(Config.BankDoors) do
        AddDoorToSystemNew(v.door, 1, 1, 0, 0, 0, 0)
        DoorSystemSetDoorState(v.door, v.state)
    end
end)

---------------------------------
-- open bank with opening hours
---------------------------------
local OpenBank = function(bankid)
    local hour = GetClockHours()
    if (hour < Config.OpenTime) or (hour >= Config.CloseTime) then
        lib.notify({
            title = Lang:t('client.lang_2'),
            description = Lang:t('client.lang_3')..Config.OpenTime..Lang:t('client.lang_4'),
            type = 'error',
            icon = 'fa-solid fa-building-columns',
            iconAnimation = 'shake',
            duration = 7000
        })
        return
    end
    RSGCore.Functions.TriggerCallback('rsg-banking:getBankingInformation', function(banking)
        if banking ~= nil then
            SendNUIMessage({action = "OPEN_BANK", balance = banking, id = bankid})
            SetNuiFocus(true, true)
            BankOpen = true
            SetTimecycleModifier('RespawnLight')
            for i=0, 10 do SetTimecycleModifierStrength(0.1 + (i / 10)); Wait(10) end
        end
    end, bankid)
end

---------------------------------
-- get bank hours function
---------------------------------
local GetBankHours = function()
    local hour = GetClockHours()
    if (hour < Config.OpenTime) or (hour >= Config.CloseTime) then
        for k, v in pairs(SpawnedBankBilps) do
            BlipAddModifier(v, joaat('BLIP_MODIFIER_MP_COLOR_2'))
        end
    else
        for k, v in pairs(SpawnedBankBilps) do
            BlipAddModifier(v, joaat('BLIP_MODIFIER_MP_COLOR_8'))
        end
    end           
    Wait(60000) -- every min
end

---------------------------------
-- get bank hours on player loading
---------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    GetBankHours()
end)

---------------------------------
-- update bank hours every min
---------------------------------
CreateThread(function()
    while true do
        GetBankHours()
        Wait(60000) -- every min
    end       
end)

---------------------------------
-- close bank
---------------------------------
local CloseBank = function()
    SendNUIMessage({action = "CLOSE_BANK"})
    SetNuiFocus(false, false)
    BankOpen = false
    for i=1, 10 do SetTimecycleModifierStrength(1.0 - (i / 10)); Wait(15) end
    ClearTimecycleModifier()
end

---------------------------------
-- NUI stuff
---------------------------------
RegisterNUICallback('CloseNUI', function()
    CloseBank()
end)

RegisterNUICallback('SafeDeposit', function()
    CloseBank()
    TriggerEvent('rsg-banking:client:safedeposit')
end)

AddEventHandler('rsg-banking:client:OpenBanking', function(bankid)
    OpenBank(bankid)
end)

RegisterNUICallback('Transact', function(data)
    TriggerServerEvent('rsg-banking:server:transact', data.type, data.amount, data.id)
end)

---------------------------------
-- update bank balance
---------------------------------
RegisterNetEvent('rsg-banking:client:UpdateBanking', function(newbalance, bankid)
    if not BankOpen then return end
    SendNUIMessage({action = "UPDATE_BALANCE", balance = newbalance, id = bankid})
end)

---------------------------------
-- bank safe deposit box
---------------------------------
RegisterNetEvent('rsg-banking:client:safedeposit', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        local cid = PlayerData.citizenid
        local ZoneTypeId = 1
        local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
        local town = GetMapZoneAtCoords(x,y,z, ZoneTypeId)

        if town == -744494798 then
            town = 'Armadillo'
        end
        if town == 1053078005 then
            town = 'Blackwater'
        end
        if town == 2046780049 then
            town = 'Rhodes'
        end
        if town == -765540529 then
            town = 'SaintDenis'
        end
        if town == 459833523 then
            town = 'Valentine'
        end

        TriggerServerEvent("inventory:server:OpenInventory", "stash", cid..town, { maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots } )
        TriggerEvent("inventory:client:SetCurrentStash", cid..town)
    end)
end)
