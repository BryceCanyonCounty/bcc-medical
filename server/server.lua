local VORPcore = exports.vorp_core:GetCore()

local StaffTable = {}

local function CheckPlayerJob(playerJob)
    for _, job in ipairs(MedicJobs) do
        if (playerJob == job) then
            return true
        end
    end
end

VORPcore.Callback.Register('bcc-medical:CheckJob', function(source, cb)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return cb(false) end
    local Character = user.getUsedCharacter
    local playerJob = Character.job

    if not playerJob then return cb(false) end

    local hasJob = false
    hasJob = CheckPlayerJob(playerJob)
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
        local onduty = exports["syn_society"]:IsPlayerOnDuty(jobholder, job)
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

RegisterNetEvent("bcc-medical:AlertJobs", function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local docs = 0
    if Config.synsociety then
        if CheckPlayer(StaffTable, MedicJobs[1]) or CheckPlayer(StaffTable, MedicJobs[2]) then
            VORPcore.NotifyRightTip(_source, _U('doctoractive'), 4000)
        else
            TriggerClientEvent('bcc-medical:FindDoc', _source)
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
        TriggerClientEvent('bcc-medical:FindDoc', _source)
    else
        VORPcore.NotifyRightTip(_source, _U('doctoractive2'), 4000)
        --VORPcore.NotifyRightTip(_source, _U('doctoractive'), 4000) -- Send /alert... needs to be added
    end
end)

---@param bleed integer
RegisterServerEvent('bcc-medical:SetBleed', function(bleed)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    local identifier = Character.identifier
    local Charid = Character.charIdentifier

    MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { bleed, Charid, identifier })
end)


RegisterServerEvent("bcc-medical:SendPlayers", function(source)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    local job = Character.job -- player job

    if CheckTable(MedicJobs, job) then
        StaffTable[#StaffTable + 1] = _source -- id
    end
end)

AddEventHandler('playerDropped', function()
    local _source = source
    for index, value in pairs(StaffTable) do
        if value == _source then
            StaffTable[index] = nil
        end
    end
end)

RegisterServerEvent('bcc-medical:TakeItem', function(item, number)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    local playername = Character.firstname .. ' ' .. Character.lastname

    exports.vorp_inventory:addItem(_source, item, number)
    VORPcore.NotifyRightTip(_source, _U('Received') .. number .. _U('Of') .. item, 4000)
    VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, playername .. " took " .. number .. ' ' .. item)
end)

VORPcore.Callback.Register('bcc-medical:RevivePlayer', function(source, cb)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return cb(false) end
    local Character = user.getUsedCharacter
    local money = Character.money
    local cost = Config.doctors.amount

    if not Config.gonegative and money < cost then
        VORPcore.NotifyRightTip(_source, _U('notenough') .. cost, 4000)
        return cb(false)
    end

    Character.removeCurrency(0, cost) -- Remove money 1000 | 0 = money, 1 = gold, 2 = rol
    VORPcore.NotifyRightTip(_source, _U('revived') .. cost, 4000)
    cb(true)
end)

RegisterNetEvent('bcc-medical:ReviveClosestPlayer', function(reviveItem, closestPlayer)
    -- Player
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Character = user.getUsedCharacter
    local playerName = Character.firstname .. ' ' .. Character.lastname
    -- Target
    local targetUser = VORPcore.getUser(closestPlayer)
    if not targetUser then return end
    local target = targetUser.getUsedCharacter
    local targetName = target.firstname .. ' ' .. target.lastname
    local count = exports.vorp_inventory:getItemCount(_source, nil, reviveItem)

    if count > 0 then
        exports.vorp_inventory:subItem(_source, reviveItem, 1)
        --TriggerClientEvent('bcc-medical:Revive', closestPlayer)
        TriggerEvent('bcc-medical:RevivePlayer', closestPlayer)
        if Config.usewebhook then
            VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, _U('Player_Syringe') .. playerName .. _U('Used_Syringe') .. targetName)
        end
    else
        VORPcore.NotifyRightTip(_source, _U('Missing') .. reviveItem, 4000)
    end
end)

RegisterServerEvent('bcc-medical:StopBleed', function(mySelf, closestPlayer, perm)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Char = user.getUsedCharacter
    local charIdentifier = Char.identifier
    local Charid = Char.charIdentifier

    local targetIdentifier
    local targetid
    if closestPlayer then
        local targetUser = VORPcore.getUser(closestPlayer)
        if not targetUser then return end
        local target = targetUser.getUsedCharacter
        targetIdentifier = target.identifier
        targetid = target.charIdentifier
    end

    local id
    local identifier
    if mySelf then
        id = Charid
        identifier = charIdentifier
    else
        id = targetid
        identifier = targetIdentifier
    end

    if not perm then
        local result = MySQL.query.await('SELECT `bleed` FROM `characters` WHERE `charidentifier` = ? AND `identifier` = ?', { id, identifier })
        if result and result[1].bleed == 1 then
            MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 0, id, identifier })
            Wait(60000 * 60 * 6) -- 6 hours / Find a better way to do this
            MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 1, id, identifier })
        end
    else
        MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 0, id, identifier })
    end
end)

VORPcore.Callback.Register('bcc-medical:CheckBleed', function(source, cb)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return cb(false) end
    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local result = MySQL.query.await('SELECT `bleed` FROM `characters` WHERE `charidentifier` = ? AND `identifier` = ?', { charid, identifier })

    if not result or not result[1] then return cb(false) end

    cb(result[1].bleed)
end)

CreateThread(function ()
    for _, item in ipairs(Config.ReviveItems) do
        exports.vorp_inventory:registerUsableItem(item, function(data)
            local _source = data.source
            exports.vorp_inventory:closeInventory(_source)
            TriggerClientEvent('bcc-medical:GetClosestPlayerRevive', _source, item)
            exports.vorp_inventory:subItem(_source, item, 1)
            VORPcore.NotifyRightTip(_source, _U('You_Used') .. item, 4000)
        end)
    end
end)

CreateThread(function ()
    for _, item in ipairs(Config.BandageItems) do
        exports.vorp_inventory:registerUsableItem(item, function(data)
            local _source = data.source
            exports.vorp_inventory:closeInventory(_source)
            TriggerClientEvent('bcc-medical:GetClosestPlayerHeal', _source, false)
            exports.vorp_inventory:subItem(_source, item, 1)
            VORPcore.NotifyRightTip(_source, _U('You_Used') .. item, 4000)
        end)
    end
end)

exports.vorp_inventory:registerUsableItem(Config.Stitches, function(data)
    local _source = data.source
    local stitches = Config.Stitches
    exports.vorp_inventory:closeInventory(_source)
    TriggerClientEvent('bcc-medical:GetClosestPlayerHeal', _source, true)
    exports.vorp_inventory:subItem(_source, stitches, 1)
    VORPcore.NotifyRightTip(_source, _U('You_Used') .. stitches, 4000)
end)

RegisterServerEvent('bcc-medical:RevivePlayer', function(source)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end

    VORPcore.Player.Revive(_source)
end)

RegisterServerEvent('bcc-medical:RespawnPlayer', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end

    VORPcore.Player.Respawn(_source)
end)

local function UpdateBleed(source)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local Char = user.getUsedCharacter
    local identifier = Char.identifier
    local Charid = Char.charIdentifier

    MySQL.query.await('UPDATE `characters` SET `bleed` = ? WHERE `charidentifier` = ? AND `identifier` = ?', { 0, Charid, identifier })
    if Config.devMode then
        print('Stopped Bleding for', GetPlayerName(_source))
    end
end

AddEventHandler('vorp_core:Server:OnPlayerRevive', function(source)
    if Config.StopBleedOnRevive then
        UpdateBleed(source)
    end
end)

AddEventHandler('vorp_core:Server:OnPlayerRespawn', function(source)
    if Config.StopBleedOnRespawn then
        UpdateBleed(source)
    end
end)
