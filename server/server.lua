
local VORPcore = exports.vorp_core:GetCore() -- NEW includes  new callback system

local stafftable = {}

RegisterServerEvent('legacy_medic:checkjob', function()
    print('working')
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local job = Character.job
    TriggerClientEvent('legacy_medic:sendjob', _source, job)
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

RegisterServerEvent("legacy_medicalertjobs", function()
    local _source = source
    local docs = 0
    if Config.synsociety then
        if CheckPlayer(stafftable, MedicJobs[1]) or CheckPlayer(stafftable, MedicJobs[2]) then
            VORPcore.NotifyRightTip(_source, _U('doctoractive'), 4000)
        else
            TriggerClientEvent('legacy_medic:finddoc', _source)
        end
    else
        for z, m in ipairs(GetPlayers()) do
            local User = VORPcore.getUser(m)
            local used = User.getUsedCharacter
            if CheckTable(MedicJobs, used.job) then
                docs = docs + 1
            end
            if docs < 1 then
                TriggerClientEvent('legacy_medic:finddoc', _source)
            end
        end
    end
end)

RegisterServerEvent('legacy_medic:SetBleed', function(bleed)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Character.charIdentifier
    local param = {
        ['Charid'] = Charid,
        ['bleed'] = bleed
    }
    exports.oxmysql:execute("UPDATE characters SET bleed=@bleed WHERE charidentifier=@Charid", param)
end)


RegisterServerEvent("legacy_medic:sendPlayers", function(source)
    local _source = source
    local user = VORPcore.getUser(_source).getUsedCharacter
    local job = user.job -- player job

    if CheckTable(MedicJobs, job) then
        stafftable[#stafftable + 1] = _source -- id
    end
end)

AddEventHandler('playerDropped', function()
    local _source = source
    for index, value in pairs(stafftable) do
        if value == _source then
            stafftable[index] = nil
        end
    end
end)

RegisterServerEvent('legacy_medic:takeitem', function(item, number)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playername = Character.firstname .. ' ' .. Character.lastname
    exports.vorp_inventory:addItem(_source, item, number)
    VORPcore.NotifyRightTip(_source, _U('Received') .. number .. _U('Of') .. item, 4000)
    VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, playername .. " took " .. number .. ' ' .. item)
end)

RegisterServerEvent("legacy_medic:reviveplayer")
AddEventHandler("legacy_medic:reviveplayer", function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local money = Character.money
    if not Config.gonegative then
        if money >= Config.doctors.amount then
            Character.removeCurrency(0, Config.doctors.amount) -- Remove money 1000 | 0 = money, 1 = gold, 2 = rol
            VORPcore.NotifyRightTip(_source, _U('revived') .. Config.doctors.amount, 4000)
            TriggerClientEvent('legacy_medic:npcrevive', _source)
        else
            VORPcore.NotifyRightTip(_source, _U('notenough') .. Config.doctors.amount, 4000)
        end
    elseif Config.gonegative then
        Character.removeCurrency(0, Config.doctors.amount) -- Remove money 1000 | 0 = money, 1 = gold, 2 = rol
        VORPcore.NotifyRightTip(_source, _U('revived') .. Config.doctors.amount, 4000)
        TriggerClientEvent('legacy_medic:npcrevive', _source)
    else
        VORPcore.NotifyRightTip(_source, _U('notenough') .. Config.doctors.amount, 4000)
    end
end)

RegisterServerEvent('legacy_medic:reviveclosestplayer')
AddEventHandler('legacy_medic:reviveclosestplayer', function(reviveitem,closestPlayer)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local target = VORPcore.getUser(closestPlayer).getUsedCharacter
    local playname2 = target.firstname .. ' ' .. target.lastname
    local count = exports.vorp_inventory:getItemCount(source, nil, reviveitem)
    local playername = Character.firstname .. ' ' .. Character.lastname

    if count > 0 then
        exports.vorp_inventory:subItem(_source, reviveitem, 1)
        TriggerClientEvent('legacy_medic:revive', closestPlayer)
        if Config.usewebhook then
            VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, _U('Player_Syringe') .. playername .. _U('Used_Syringe') .. playname2)
        end
    else
        VORPcore.NotifyRightTip(_source, _U('Missing') .. Config.Revive, 4000)
    end
end)

RegisterServerEvent('legacy_medic:healplayer')
AddEventHandler('legacy_medic:healplayer', function(closestPlayer)
    TriggerClientEvent('vorp:heal', closestPlayer)
end)

RegisterServerEvent('legacy_medic:StopBleedTemp')
AddEventHandler('legacy_medic:StopBleedTemp', function(self, closestPlayer)
    local _source = source
    local Char = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Char.charIdentifier
    local target, targetid
    if closestPlayer then
        target = VORPcore.getUser(closestPlayer).getUsedCharacter
        targetid = target.charIdentifier
    end
    local param = {
        ['Charid'] = Charid,
        ['targetid'] = targetid
    }
    if self then
        local result = MySQL.query.await("SELECT bleed FROM characters WHERE charidentifier=@Charid", param)
        if result[1].bleed == 1 then
            exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@Charid", param)
            Wait(60000 * 60 * 6)
            exports.oxmysql:execute("UPDATE characters SET bleed=1 WHERE charidentifier=@Charid", param)
        end
    else
        local result = MySQL.query.await("SELECT bleed FROM characters WHERE charidentifier=@targetid", param)
        if result[1].bleed == 1 then
            exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@targetid", param)
            Wait(60000 * 60 * 6)
            exports.oxmysql:execute("UPDATE characters SET bleed=1 WHERE charidentifier=@targetid", param)
        end
    end
end)

RegisterServerEvent('legacy_medic:StopBleedPerm')
AddEventHandler('legacy_medic:StopBleedPerm', function(self, closestPlayer)
    local _source = source
    local Char = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Char.charIdentifier
    local target, targetid
    if closestPlayer then
        target = VORPcore.getUser(closestPlayer).getUsedCharacter
        targetid = target.charIdentifier
    end
    local param = {
        ['Charid'] = Charid,
        ['targetid'] = targetid

    }
    if self then
        exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@Charid", param)
    else
        exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@targetid", param)
    end
end)

RegisterServerEvent('legacy_medic:CheckBleed')
AddEventHandler('legacy_medic:CheckBleed', function()
    local _source = source
    local Char = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Char.charIdentifier
    local param = {
        ['Charid'] = Charid
    }
    local result = MySQL.query.await("SELECT bleed FROM characters WHERE charidentifier=@Charid", param)
    TriggerClientEvent('legacy_medic:SendBleed', _source, result[1].bleed)
end)

CreateThread(function ()
    for k, v in ipairs(Config.ReviveItems) do
        exports.vorp_inventory:registerUsableItem(v, function (data)
            TriggerClientEvent('legacy_medic:getclosestplayerrevive', data.source)
            exports.vorp_inventory:subItem(data.source, v, 1)
            VORPcore.NotifyRightTip(data.source, "You used " .. v, 4000)
        end)
    end
end)

CreateThread(function ()
    for k, v in ipairs(Config.BandageItems) do
        exports.vorp_inventory:registerUsableItem(v, function (data)
            TriggerClientEvent('legacy_medic:getclosestplayerbandage', data.source)
            exports.vorp_inventory:subItem(data.source, v, 1)
            VORPcore.NotifyRightTip(data.source, "You used " .. v, 4000)
        end)
    end
end)

exports.vorp_inventory:registerUsableItem(Config.Stitches, function (data)
    TriggerClientEvent('legacy_medic:getclosestplayerstitch', data.source)
    exports.vorp_inventory:subItem(data.source, Config.Stitches, 1)
    VORPcore.NotifyRightTip(data.source, "You used " .. Config.Stitches, 4000)
end)


function CheckTable(table, element)
    for k, v in pairs(table) do
        if v == element then
            return true
        end
    end
    return false
end

RegisterNetEvent("vorp_core:Server:OnPlayerRevive",function()
    if Config.StopBleedOnRevive then
        local _source = source
        local Char = VORPcore.getUser(_source).getUsedCharacter
        local Charid = Char.charIdentifier
        local param = {
            ['Charid'] = Charid
        }

        exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@Charid", param)
        if Config.devMode then 
            print('Stopped Bleding for',GetPlayerName(_source)) 
        end
    end
end)

