local VORPcore = exports.vorp_core:GetCore()

local StaffTable = {}
local TempHealed = {}

local function CheckPlayerJob(src)
    local character = VORPcore.getUser(src).getUsedCharacter
    local playerJob = character.job
    for _, job in ipairs(MedicJobs) do
        if (playerJob == job) then
            return true
        end
    end
    return false
end

VORPcore.Callback.Register('bcc-medical:CheckJob', function(source, cb)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return cb(false) end

    local hasJob = CheckPlayerJob(src)
    if hasJob then
        cb(true)
    else
        cb(false)
    end
end)

---@param table table
---@param job string
---@return boolean
local CheckPlayer = function(table, job)
    for _, jobholder in pairs(table) do
        local onduty = exports['syn_society']:IsPlayerOnDuty(jobholder, job)
        print(onduty)
        return onduty
    end

    return false
end

local function CheckTable(table, element)
    for k, v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
end

RegisterNetEvent('bcc-medical:AlertJobs', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local docs = 0
    if Config.synsociety then
        if CheckPlayer(StaffTable, MedicJobs[1]) or CheckPlayer(StaffTable, MedicJobs[2]) then
            VORPcore.NotifyRightTip(src, _U('doctoractive'), 4000)
        else
            TriggerClientEvent('bcc-medical:CallNpcDoctor', src)
            return
        end
    else
        for _, player in ipairs(GetPlayers()) do
            local playerUser = VORPcore.getUser(player)
            local playerChar = playerUser.getUsedCharacter
            if CheckTable(MedicJobs, playerChar.job) then
                docs = docs + 1
            end
        end
    end
    if docs < 1 then
        TriggerClientEvent('bcc-medical:CallNpcDoctor', src)
    else
        VORPcore.NotifyRightTip(src, _U('doctoractive2'), 4000)
        --VORPcore.NotifyRightTip(src, _U('doctoractive'), 4000) -- Send /alert... needs to be added
    end
end)

---@param bleed integer
RegisterServerEvent('bcc-medical:SetBleed', function(bleed)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local Character = user.getUsedCharacter
    local identifier = Character.identifier
    local Charid = Character.charIdentifier

    MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { bleed, Charid, identifier })
end)


RegisterServerEvent('bcc-medical:SendPlayers', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local Character = user.getUsedCharacter
    local job = Character.job -- player job

    if CheckTable(MedicJobs, job) then
        StaffTable[#StaffTable + 1] = src -- id
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for index, value in pairs(StaffTable) do
        if value == src then
            StaffTable[index] = nil
        end
    end
end)

RegisterServerEvent('bcc-medical:TakeItem', function(label, item, quantity)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local Character = user.getUsedCharacter
    local playername = Character.firstname .. ' ' .. Character.lastname

    local canCarry = exports.vorp_inventory:canCarryItem(src, item, quantity)
    if not canCarry then
        VORPcore.NotifyRightTip(src, _U('not_enough_space'), 4000)
        return
    end
    exports.vorp_inventory:addItem(src, item, quantity)
    VORPcore.NotifyRightTip(src, _U('Received') .. tostring(quantity) .. ' ' .. label, 4000)
    VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, playername .. ' took ' .. quantity .. ' ' .. label)
end)

VORPcore.Callback.Register('bcc-medical:CurrencyCheck', function(source, cb)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return cb(false) end
    local Character = user.getUsedCharacter
    local currency = Config.doctors.currency
    local cost = Config.doctors.amount
    local money = nil
    if currency == 0 then
        money = Character.money
    elseif currency == 1 then
        money = Character.gold
    end

    if not Config.gonegative and money < cost then
        VORPcore.NotifyRightTip(src, _U('notenough'), 4000)
        return cb(false)
    end

    Character.removeCurrency(currency, cost)
    cb(true)
end)

RegisterNetEvent('bcc-medical:ReviveClosestPlayer', function(reviveItem, closestPlayer)
    -- Player
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local Character = user.getUsedCharacter
    local playerName = Character.firstname .. ' ' .. Character.lastname
    -- Target
    local targetUser = VORPcore.getUser(closestPlayer)
    if not targetUser then return end
    local target = targetUser.getUsedCharacter
    local targetName = target.firstname .. ' ' .. target.lastname
    local count = exports.vorp_inventory:getItemCount(src, nil, reviveItem)

    if count > 0 then
        exports.vorp_inventory:subItem(src, reviveItem, 1)
        VORPcore.Player.Revive(closestPlayer)
        if Config.usewebhook then
            VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, _U('Player_Syringe') .. playerName .. _U('Used_Syringe') .. targetName)
        end
    else
        VORPcore.NotifyRightTip(src, _U('Missing') .. reviveItem, 4000)
    end
end)

RegisterServerEvent('bcc-medical:ManageBleedStatus', function(mySelf, closestPlayer, item, perm)
    -- mySelf Character
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter

    -- Remove Bandage/Stitches Item from My Inventory
    local count = exports.vorp_inventory:getItemCount(src, nil, item)
    if count > 0 then
        exports.vorp_inventory:subItem(src, item, 1)
    end

    -- closestPlayer Character
    if not mySelf then
        local targetUser = VORPcore.getUser(closestPlayer)
        if not targetUser then return end
        character = targetUser.getUsedCharacter
    end

    -- Database Character Data to Update
    local identifier = character.identifier
    local charId = character.charIdentifier

    if not perm then
        MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 2, charId, identifier })
        TempHealed[tostring(charId)] = os.time()
    else
        MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 0, charId, identifier })
    end
end)

VORPcore.Callback.Register('bcc-medical:CheckBleed', function(source, cb)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return cb(false) end
    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local result = MySQL.query.await('SELECT `bleed` FROM `characters` WHERE `charidentifier` = ? AND `identifier` = ?', { charid, identifier })
    if not result or not result[1] then return cb(false) end
    local bleed = result[1].bleed

    -- If Temp Healed with Bandage Item
    if bleed == 2 then
        local onList = false
        for id, time in pairs(TempHealed) do
            if tostring(charid) == id then
                onList = true
                if os.difftime(os.time(), time) >= Config.restartBleedTime * 60 then
                    MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 1, charid, identifier })
                    TempHealed[id] = nil
                    bleed = 1
                    break
                end
            end
        end
        if not onList then
            TempHealed[tostring(charid)] = os.time()
        end
    end

    cb(bleed)
end)

VORPcore.Callback.Register('bcc-medical:CheckPatientBleed', function(source, cb, patientSrc)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return cb(false) end
    -- Patient Data
    local patientUser = VORPcore.getUser(patientSrc)
    if not patientUser then return cb(false) end
    local character = patientUser.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local result = MySQL.query.await('SELECT `bleed` FROM `characters` WHERE `charidentifier` = ? AND `identifier` = ?', { charid, identifier })

    if not result or not result[1] then return cb(false) end

    cb(result[1].bleed)
end)

CreateThread(function ()
    for _, itemCfg in pairs(Config.BandageItems) do
        exports.vorp_inventory:registerUsableItem(itemCfg.item, function(data)
            local src = data.source
            exports.vorp_inventory:closeInventory(src)
            TriggerClientEvent('bcc-medical:CheckPlayerBleeding', src, itemCfg.item, itemCfg.label, false)
        end)
    end
end)

CreateThread(function ()
    for _, itemCfg in pairs(Config.Stitches) do
        exports.vorp_inventory:registerUsableItem(itemCfg.item, function(data)
            local src = data.source
            local doctor = CheckPlayerJob(src)
            exports.vorp_inventory:closeInventory(src)
            if not doctor then
                VORPcore.NotifyRightTip(src, _U('you_do_not_have_job'), 4000)
                return
            end
            TriggerClientEvent('bcc-medical:CheckPlayerBleeding', src, itemCfg.item, itemCfg.label, true)
        end)
    end
end)

CreateThread(function ()
    for _, itemCfg in pairs(Config.ReviveItems) do
        exports.vorp_inventory:registerUsableItem(itemCfg.item, function(data)
            local src = data.source
            local doctor = CheckPlayerJob(src)
            exports.vorp_inventory:closeInventory(src)
            if not doctor then
                VORPcore.NotifyRightTip(src, _U('you_do_not_have_job'), 4000)
                return
            end
            TriggerClientEvent('bcc-medical:ReviveClosestPlayer', src, itemCfg.item)
            VORPcore.NotifyRightTip(src, _U('You_Used') .. itemCfg.label, 4000)
        end)
    end
end)

RegisterServerEvent('bcc-medical:PlayerRevive', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end

    VORPcore.Player.Revive(src)
end)

RegisterServerEvent('bcc-medical:PlayerRespawn', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end

    VORPcore.Player.Respawn(src)
end)

local function UpdateBleed(playerSource)
    local src = playerSource
    local user = VORPcore.getUser(src)
    if not user then return end
    local Char = user.getUsedCharacter
    local identifier = Char.identifier
    local Charid = Char.charIdentifier

    MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 0, Charid, identifier })
    if Config.devMode then
        print('Stopped Bleding for', GetPlayerName(src))
    end
end

RegisterNetEvent('bcc_medical:checkout')
AddEventHandler('bcc_medical:checkout', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    
    if not user then return end
    
    -- Get character data
    local Char = user.getUsedCharacter
    local identifier = Char.identifier
    local Charid = Char.charIdentifier
    local money = Char.money

    -- Check if the player has enough money
    if money < Config.AssistantHealMoney then
        -- Send notification for insufficient money
        VORPcore.NotifyAvanced(_source, _U('notEnoughMoney') .. (Config.AssistantHealMoney - money), "inventory_items", "money_billstack", "COLOR_RED", 4000)
        return
    end

    -- Deduct the money from the character
    Char.removeCurrency(0, Config.AssistantHealMoney)  -- 0 for dollars, 1 for gold if needed

    -- Heal the player
    VORPcore.Player.Heal(_source)

    -- Update the database to stop the bleeding
    UpdateBleed(_source)

    -- Send a notification for successful healing
    VORPcore.NotifyAvanced(_source, _U('medicalAssistantTreated') .. Config.AssistantHealMoney, "inventory_items", "money_billstack", "COLOR_GREEN", 4000)

end)

RegisterNetEvent('bcc_medical:checkoutRevive')
AddEventHandler('bcc_medical:checkoutRevive', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    
    if not user then return end
    
    -- Get character data
    local Char = user.getUsedCharacter
    local identifier = Char.identifier
    local Charid = Char.charIdentifier
    local money = Char.money

    if not Config.gonegative and money < Config.AssistantReviveMoney then
        -- Send notification for insufficient money
        VORPcore.NotifyAvanced(_source, _U('notEnoughMoney') .. (Config.AssistantReviveMoney - money), "inventory_items", "money_billstack", "COLOR_RED", 4000)
        return
    end

    Char.removeCurrency(0, Config.AssistantReviveMoney)  -- 0 for dollars, 1 for gold if needed

    VORPcore.Player.Revive(_source)

    UpdateBleed(_source)

    VORPcore.NotifyAvanced(_source, _U('medicalAssistantRevive') .. Config.AssistantReviveMoney, "inventory_items", "money_billstack", "COLOR_GREEN", 4000)
end)

-- Per vorp docs these only require AddEventHandler
-- RegisterNetEvent has been added as player received error 'not safe for net'
RegisterNetEvent('vorp_core:Server:OnPlayerRevive')
AddEventHandler('vorp_core:Server:OnPlayerRevive', function(playerSource)
    if Config.StopBleedOnRevive then
        UpdateBleed(playerSource)
    end
end)

RegisterNetEvent('vorp_core:Server:OnPlayerRespawn')
AddEventHandler('vorp_core:Server:OnPlayerRespawn', function(playerSource)
    if Config.StopBleedOnRespawn then
        UpdateBleed(playerSource)
    end
end)

function printTable(t)
    local printTable_cache = {}
    local function sub_printTable(t, indent)

        if (printTable_cache[tostring(t)]) then
            print(indent .. "*" .. tostring(t))
        else
            printTable_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos,val in pairs(t) do
                    if (type(val) == "table") then
                        print(indent .. "[" .. pos .. "] => " .. tostring(t).. " {")
                        sub_printTable(val, indent .. string.rep(" ", string.len(pos)+8))
                        print(indent .. string.rep(" ", string.len(pos)+6 ) .. "}")
                    elseif (type(val) == "string") then
                        print(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end

    if (type(t) == "table") then
        print(tostring(t) .. " {")
        sub_printTable(t, "  ")
        print("}")
    else
        sub_printTable(t, "  ")
    end
end
