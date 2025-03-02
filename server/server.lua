local RSGCore = exports['rsg-core']:GetCoreObject()
local banking = nil
lib.locale()

---------------
-- stash
----------------
RegisterNetEvent('rsg-banking:server:opensafedeposit', function(town)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = locale('sv_lang'), maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local citizenId = Player.PlayerData.citizenid
    local stashName = 'safedeposit_' .. citizenId .. town
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------
-- callback for bank balance
---------------------------------
RSGCore.Functions.CreateCallback('rsg-banking:getBankingInformation', function(source, cb, bankid)

    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end

    if bankid == 'bank' then
        banking = tonumber(Player.PlayerData.money['bank'])
    end

    if bankid == 'valbank' then
        banking = tonumber(Player.PlayerData.money['valbank'])
    end

    if bankid == 'rhobank' then
        banking = tonumber(Player.PlayerData.money['rhobank'])
    end

    if bankid == 'blkbank' then
        banking = tonumber(Player.PlayerData.money['blkbank'])
    end

    if bankid == 'armbank' then
        banking = tonumber(Player.PlayerData.money['armbank'])
    end

    cb(banking)
end)

---------------------------------
-- deposit & withdraw
---------------------------------
RegisterNetEvent('rsg-banking:server:transact', function(type, amount, bankid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(source)
    local currentCash = Player.Functions.GetMoney('cash')
    local currentBank = Player.Functions.GetMoney(bankid)

    amount = tonumber(amount)
    if amount <= 0 then
        lib.notify(src, {title = locale('sv_lang_1'), type = 'error'})
        return
    end

    -- bank-withdraw
    if type == 1 then
        if currentBank >= amount then
            Player.Functions.RemoveMoney(bankid, tonumber(amount), 'bank-withdraw')
            Player.Functions.AddMoney('cash', tonumber(amount), 'bank-withdraw')
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('rsg-banking:client:UpdateBanking', src, newBankBalance, bankid)
        else
            lib.notify(src, {title = locale('sv_lang_2'), type = 'error'})
        end
    end

    -- bank-deposit
    if type == 2 then
        if currentCash >= amount then
            Player.Functions.RemoveMoney('cash', tonumber(amount), 'bank-deposit')
            Player.Functions.AddMoney(bankid, tonumber(amount), 'bank-deposit')
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('rsg-banking:client:UpdateBanking', src, newBankBalance, bankid)
        else
            lib.notify(src, {title = locale('sv_lang_2'), type = 'error'})
        end
    end

    -- create money_clip
    if type == 3 then
        if currentBank >= amount then
            local info = { money = amount }
            Player.Functions.RemoveMoney(bankid, tonumber(amount), 'bank-money_clip')
            Player.Functions.AddItem('money_clip', 1, false, info)
            local newBankBalance = Player.Functions.GetMoney(bankid)
            TriggerClientEvent('rsg-banking:client:UpdateBanking', src, newBankBalance, bankid)
            lib.notify({ title = locale('sv_lang_9'), description = locale('sv_lang_10') .. ' ' .. amount .. ' ' .. locale('sv_lang_11'), type = 'success' })
        else
            lib.notify(src, {title = locale('sv_lang_2'), type = 'error'})
        end
    end

end)

---------------------------------
-- money clip made usable
---------------------------------
RSGCore.Functions.CreateUseableItem('money_clip', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemData = Player.Functions.GetItemBySlot(item.slot)
    if not itemData then return end

    local amount = itemData.info.money
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        Player.Functions.AddMoney('cash', amount)
        lib.notify({ title = locale('sv_lang_3'), description = locale('sv_lang_4') ..' ' .. amount .. ' ' .. locale('sv_lang_5'), type = 'success' })
    end
end)

---------------------------------
-- create money clip command
---------------------------------
RSGCore.Commands.Add('moneyclip', locale('sv_lang_6'), {{ name = 'amount', help = locale('sv_lang_7') }}, true, function(source, args)
    local src = source
    local args1 = tonumber(args[1])
    if args1 <= 0 then
        lib.notify({ title = locale('sv_lang_2'), description = locale('sv_lang_8'), type = 'error' })
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local money = Player.Functions.GetMoney('cash')
    if money and money >= args1 then
        if Player.Functions.RemoveMoney('cash', args1, 'give-money') then
            local info =
            {
                money = args1
            }

            Player.Functions.AddItem('money_clip', 1, false, info)
            lib.notify({ title = locale('sv_lang_9'), description = locale('sv_lang_10') .. ' ' .. args1 .. ' ' .. locale('sv_lang_11'), type = 'success' })
        end
    end
end, 'user')

---------------------------------
-- blood money_clip made usable
---------------------------------
RSGCore.Functions.CreateUseableItem('blood_money_clip', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemData = Player.Functions.GetItemBySlot(item.slot)
    if not itemData then return end

    local amount = itemData.info.money
    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        Player.Functions.AddMoney('bloodmoney', amount)
        lib.notify({ title = locale('sv_lang_12'), description = locale('sv_lang_4') ..' ' .. amount ..' ' .. locale('sv_lang_13'), type = 'success' })
    end
end)

---------------------------------
-- create blood money clip command
---------------------------------
RSGCore.Commands.Add('bloodmoneyclip', locale('sv_lang_14'), {{ name = 'amount', help = locale('sv_lang_15') }}, true, function(source, args)
    local src = source
    local args1 = tonumber(args[1])

    if args1 <= 0 then
        lib.notify({ title = locale('sv_lang_2'), description = locale('sv_lang_8'), type = 'error' })
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local money = Player.Functions.GetMoney('bloodmoney')
    if money and money >= args1 then
        if Player.Functions.RemoveMoney('bloodmoney', args1, 'give-blood-money') then
            local info =
            {
                money = args1
            }

            Player.Functions.AddItem('blood_money_clip', 1, false, info)
            lib.notify({ title = locale('sv_lang_16'), description = locale('sv_lang_10') ..' ' .. args1 ..' ' .. locale('sv_lang_17'), type = 'success' })
        end
    end
end, 'user')

---------------------------------
-- target give money transfer
---------------------------------
RegisterNetEvent('rsg-banking:server:givemoney', function(targetPlayerId, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local targetPlayer = RSGCore.Functions.GetPlayer(tonumber(targetPlayerId))
    
    if not Player then
        TriggerClientEvent('lib.notify', src, { title = locale('sv_lang_18'), description = locale('sv_lang_19'), type = 'error' })
        return
    end

    if not targetPlayer then
        TriggerClientEvent('lib.notify', src, { title = locale('sv_lang_18'), description = locale('sv_lang_20'), type = 'error' })
        return
    end

    if Player.Functions.GetMoney('cash') >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        targetPlayer.Functions.AddMoney('cash', amount)
        TriggerClientEvent('lib.notify', Player.PlayerData.source, { title = locale('sv_lang_21'), description = locale('sv_lang_22') .. amount .. locale('sv_lang_23') .. targetPlayer.PlayerData.charinfo.firstname, type = 'success' })
        TriggerClientEvent('lib.notify', targetPlayer.PlayerData.source, { title = locale('sv_lang_21'), description = locale('sv_lang_24') .. amount .. locale('sv_lang_25') .. Player.PlayerData.charinfo.firstname, type = 'success' })
    else
        TriggerClientEvent('lib.notify', Player.PlayerData.source, { title = locale('sv_lang_18'), description = locale('sv_lang_26'), type = 'error' })
    end
end)
