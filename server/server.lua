local VORPcore = exports.vorp_core:GetCore() -- NEW includes new callback system

local function devPrint(msg)
    if Config.devMode then
        print("DEV: " .. msg)
    end
end

local stafftable = {}

RegisterServerEvent('legacy_medic:checkjob', function()
    devPrint("Checking player job.")
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local job = Character.job
    TriggerClientEvent('legacy_medic:sendjob', _source, job)
end)

local CheckPlayer = function(table, job)
    devPrint("Checking if any player is on duty for job: " .. job)
    for _, jobholder in pairs(table) do
        local onduty = exports["syn_society"]:IsPlayerOnDuty(jobholder, job)
        devPrint("On duty status for " .. jobholder .. ": " .. tostring(onduty))
        return onduty
    end
    devPrint("No player on duty found for job: " .. job)
    return false
end

local lastDocCheckTime = 0
local sendNpcOverride = false
local preventNpc = false
local callDoctorPlayer = nil

-- Register the /sendNpc command
RegisterCommand('sendNpc', function(source, args, rawCommand)
    if CheckTable(Config.MedicJobs, VORPcore.getUser(source).getUsedCharacter.job) then
        sendNpcOverride = true
        if callDoctorPlayer then
            TriggerClientEvent('legacy_medic:finddoc', callDoctorPlayer)  -- Send NPC to the player who called the doctor
            lastDocCheckTime = os.time() -- Reset the timer to prevent duplicate NPCs
        else
            VORPcore.NotifyRightTip(source, _U('no_player_called'), 4000)  -- Notify if no player called the doctor
        end
    end
end, false)

-- Register the /cp command
RegisterCommand('cp', function(source, args, rawCommand)
    if CheckTable(Config.MedicJobs, VORPcore.getUser(source).getUsedCharacter.job) then
        preventNpc = true
        VORPcore.NotifyRightTip(source, _U('cp_activated'), 4000)
    end
end, false)

RegisterServerEvent("legacy_medicalertjobs")
AddEventHandler("legacy_medicalertjobs", function()
    local src = source
    callDoctorPlayer = src  -- Track the player who called the doctor
    local docs = 0
    local currentTime = os.time()
    local pos = GetEntityCoords(GetPlayerPed(src))

    devPrint("Alerting for medical jobs status.")
    devPrint("Config.synsociety: " .. tostring(Config.synsociety))
    if Config.synsociety then
        local isDoctorOnDuty = CheckPlayer(stafftable, Config.MedicJobs[1]) or CheckPlayer(stafftable, Config.MedicJobs[2])
        devPrint("Doctor on duty status: " .. tostring(isDoctorOnDuty))
        if isDoctorOnDuty then
            VORPcore.NotifyRightTip(src, _U('doctoractive'), 4000)
            devPrint("Doctor is active on duty.")
            lastDocCheckTime = currentTime -- Reset the timer since a doctor is found
        else
            TriggerClientEvent('legacy_medic:finddoc', src, pos)
        end
    else
        for z, m in ipairs(GetPlayers()) do
            local User = VORPcore.getUser(m)
            local used = User.getUsedCharacter
            if CheckTable(Config.MedicJobs, used.job) then
                docs = docs + 1
                devPrint("Doctor found: " .. User.getIdentifier())
            end
            AlertJob("medicalEmergency", "A fost raportata o urgenta medicala! Va rugam sa interveniti.", { x = pos.x, y = pos.y, z = pos.z })
        end
        devPrint("Total doctors checked: " .. tostring(docs))

        if sendNpcOverride or (currentTime - lastDocCheckTime > 60 and docs == 0 and not preventNpc) then
            if not sendNpcOverride then
                CreateThread(function()
                    Wait(60000) -- Wait for 60 seconds
                    if docs == 0 and not preventNpc then
                        TriggerClientEvent('legacy_medic:finddoc', src, pos)
                        devPrint("Sending NPC Doctor after 1 minute.")
                        lastDocCheckTime = os.time() -- Reset the timer after triggering the event
                    else
                        devPrint("No NPC Doctor needed. preventNpc is true.")
                    end
                end)
            else
                TriggerClientEvent('legacy_medic:finddoc', src, pos)
                devPrint("Sending NPC Doctor immediately due to sendNpcOverride.")
                lastDocCheckTime = os.time() -- Reset the timer after triggering the event
                sendNpcOverride = false
                preventNpc = false
            end
        else
            devPrint("NPC Doctor not sent due to cooldown. Time left: " .. tostring(60 - (currentTime - lastDocCheckTime)) .. " seconds.")
        end
    end
end)

RegisterServerEvent('legacy_medic:SetBleed', function(bleed)
    devPrint("Setting bleed status for a character.")
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Character.charIdentifier
    local param = {
        ['Charid'] = Charid,
        ['bleed'] = bleed
    }
    exports.oxmysql:execute("UPDATE characters SET bleed=@bleed WHERE charidentifier=@Charid", param)
    devPrint("Bleed status set to " .. tostring(bleed) .. " for character ID: " .. Charid)
end)


RegisterServerEvent("legacy_medic:sendPlayers", function(source)
    devPrint("Adding player to staff table.")
    local _source = source
    local user = VORPcore.getUser(_source).getUsedCharacter
    local job = user.job
    if CheckTable(Config.MedicJobs, job) then
        stafftable[#stafftable + 1] = _source
        devPrint("Player " .. _source .. " added to staff table. Job: " .. job)
    end
end)

AddEventHandler('playerDropped', function()
    devPrint("Player disconnected. Cleaning up staff table.")
    local _source = source
    for index, value in pairs(stafftable) do
        if value == _source then
            stafftable[index] = nil
            devPrint("Player " .. _source .. " removed from staff table.")
        end
    end
end)

RegisterServerEvent('legacy_medic:takeitem', function(item, number)
    devPrint("Player taking item: " .. item .. " Amount: " .. tostring(number))
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playername = Character.firstname .. ' ' .. Character.lastname
    exports.vorp_inventory:addItem(_source, item, number)
    VORPcore.NotifyRightTip(_source, _U('Received') .. number .. _U('Of') .. item, 4000)
    VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook, playername .. " took " .. number .. ' ' .. item)
    devPrint("Item added and notification sent.")
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
AddEventHandler('legacy_medic:reviveclosestplayer', function(closestPlayer)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local target = VORPcore.getUser(closestPlayer).getUsedCharacter
    local playname2 = target.firstname .. ' ' .. target.lastname
    local playername = Character.firstname .. ' ' .. Character.lastname
    local itemsUsed = false

    local function attemptReviveWithItem(item)
        exports.vorp_inventory:getItemCount(_source, function(count)
            if count > 0 then
                exports.vorp_inventory:subItem(_source, item, 1, nil, function(success)
                    if success then
                        TriggerClientEvent('legacy_medic:revive', closestPlayer)
                        devPrint(playername .. " used a " .. item .. " on " .. playname2)
                        if Config.usewebhook then
                            VORPcore.AddWebhook(Config.WebhookTitle, Config.Webhook,
                                _U('Player_Syringe') .. playername .. _U('Used_Syringe') .. playname2)
                        end
                        itemsUsed = true
                    else
                        VORPcore.NotifyRightTip(_source, _U('FailedToUse') .. item, 4000)
                        devPrint("Failed to use revive item: " .. item)
                    end
                end)
            end
        end, item, nil)
    end

    for _, item in ipairs(Config.ReviveItems) do
        attemptReviveWithItem(item)
    end

    Wait(1000)  -- Short delay to ensure all items are checked

    if not itemsUsed then
        VORPcore.NotifyRightTip(_source, _U('Missing') .. table.concat(Config.ReviveItems, ' or '), 4000)
        devPrint("Failed to revive: Missing all revive items")
    end
end)

RegisterServerEvent('legacy_medic:healplayer')
AddEventHandler('legacy_medic:healplayer', function(closestPlayer)
    devPrint("Healing closest player.")
    TriggerClientEvent('vorp:heal', closestPlayer)
end)

RegisterServerEvent('legacy_medic:StopBleedTemp')
AddEventHandler('legacy_medic:StopBleedTemp', function(self, closestPlayer)
    devPrint("Attempting to temporarily stop bleeding.")
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
    devPrint("Stopping bleeding permanently.")
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
        devPrint("Bleeding permanently stopped for self.")
    else
        exports.oxmysql:execute("UPDATE characters SET bleed=0 WHERE charidentifier=@targetid", param)
        devPrint("Bleeding permanently stopped for character ID: " .. targetid)
    end
end)

RegisterServerEvent('legacy_medic:CheckBleed')
AddEventHandler('legacy_medic:CheckBleed', function()
    devPrint("Checking bleeding status.")
    local _source = source
    local Char = VORPcore.getUser(_source).getUsedCharacter
    local Charid = Char.charIdentifier
    local param = {
        ['Charid'] = Charid
    }
    local result = MySQL.query.await("SELECT bleed FROM characters WHERE charidentifier=@Charid", param)
    TriggerClientEvent('legacy_medic:SendBleed', _source, result[1].bleed)
    devPrint("Bleed status for " .. Charid .. ": " .. tostring(result[1].bleed))
end)

-- Register Usable Items for Bandages
for _, v in ipairs(Config.BandageItems) do
    exports.vorp_inventory:registerUsableItem(v, function(data)
        local source = data.source
        
        -- Close the inventory when the item is used
        exports.vorp_inventory:closeInventory(source)
        
        -- Use the item
        TriggerClientEvent('legacy_medic:getclosestplayerbandage', source)
        VORPcore.NotifyRightTip(source, "You used " .. v, 4000)
        devPrint(source .. " used bandage item " .. v)
    end)
end

-- Register Usable Item for Stitches
exports.vorp_inventory:registerUsableItem(Config.Stitches, function(data)
    local source = data.source
    
    -- Close the inventory when the item is used
    exports.vorp_inventory:closeInventory(source)
    
    -- Use the item
    TriggerClientEvent('legacy_medic:getclosestplayerstitch', source)
    VORPcore.NotifyRightTip(source, "You used " .. Config.Stitches, 4000)
    devPrint(source .. " used stitches item " .. Config.Stitches)
end)

-- Register Usable Items for Revive Items
for _, v in ipairs(Config.ReviveItems) do
    exports.vorp_inventory:registerUsableItem(v, function(data)
        local source = data.source
        
        -- Close the inventory when the item is used
        exports.vorp_inventory:closeInventory(source)
        
        -- Use the item
        TriggerClientEvent('legacy_medic:getclosestplayerrevive', source)
        VORPcore.NotifyRightTip(source, "You used " .. v, 4000)
        devPrint(source .. " used revive item " .. v)
    end)
end


function CheckTable(table, element)
    if not table then
        devPrint("Warning: Table passed to CheckTable is nil.")
        return false
    end
    if element == nil then
        devPrint("Warning: Element passed to CheckTable is nil.")
        return false
    end
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

function CheckJob(src, alertType)
    local user = VORPcore.getUser(src)
    if not user then
        devPrint("No user found for source " .. tostring(src))
        return false
    end

    local character = user.getUsedCharacter
    if not character then
        devPrint("No character data available for source " .. tostring(src))
        return false
    end

    local alertConfig = Config.alertPermissions[alertType]
    if not alertConfig then
        devPrint("No alert configuration found for alert type: " .. tostring(alertType))
        return false
    end

    if not character.job or not character.jobGrade then
        devPrint("Job or job grade data missing for source: " .. tostring(src))
        return false
    end

    -- Check job eligibility and grade within the allowed range
    local jobConfig = alertConfig.allowedJobs[character.job]
    if jobConfig then
        local jobGrade = tonumber(character.jobGrade)
        if jobGrade >= jobConfig.minGrade and jobGrade <= jobConfig.maxGrade then
            return true
        else
            devPrint("User does not meet job grade requirements for alert type: " ..
            tostring(alertType) .. " with job: " .. character.job .. " at grade: " .. character.jobGrade)
            return false
        end
    else
        devPrint("Job " .. tostring(character.job) .. " not permitted for alert type: " .. tostring(alertType))
        return false
    end
end

-- Helper function to check if a value is in a table (for job checking)
function table.includes(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Server-side function to alert users about specific events and include location data
function AlertJob(alertType, message, coords)
    local alertConfig = Config.alertPermissions[alertType]
    if not alertConfig then
        devPrint("Alert configuration missing for type: " .. alertType)
        return
    end

    local users = VORPcore.getUsers()
    for _, user in pairs(users) do
        if user and CheckJob(user.source, alertType) then
            TriggerClientEvent('bcc-medical:notify', user.source, {
                message = message,
                notificationType = "alert",
                x = coords.x,
                y = coords.y,
                z = coords.z,
                blipSprite = alertConfig.blipSettings.blipSprite,
                blipScale = alertConfig.blipSettings.blipScale,
                blipColor = alertConfig.blipSettings.blipColor,
                blipLabel = alertConfig.blipSettings.blipLabel,
                blipDuration = alertConfig.blipSettings.blipDuration,
                gpsRouteDuration = alertConfig.blipSettings.gpsRouteDuration, --- Newly added
                useGpsRoute = true
            })
        else
            devPrint("User does not match job requirements for " .. alertType .. ": " .. user.source)
        end
    end
end
