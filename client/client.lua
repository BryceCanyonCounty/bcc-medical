local OfficeGroup = GetRandomIntInRange(0, 0xffffff)
local CabinetPrompt
local HasJob = false
local IsCalled = false
local NpcDoctor = 0
DamageBone = _U('None')
DamageBoneSelf = _U('None')
DamageHash = nil

local function CheckPlayerJob()
    local result = VORPcore.Callback.TriggerAwait('bcc-medical:CheckJob')
    HasJob = false
    if result then
        HasJob = true
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if Citizen.InvokeNative(0xDCF06D0CDFF68424, PlayerPedId(), Guns[DamageHash], 0) then -- HasEntityBeenDamagedByWeapon
            TriggerEvent('bcc-medical:ApplyBleed')
        end
        local size = GetNumberOfEvents(0) -- get number of events for EVENT GROUP 0 (SCRIPT_EVENT_QUEUE_AI). Check table below.
        if size > 0 then
            for i = 0, size - 1 do
                local eventAtIndex = GetEventAtIndex(0, i)

                if eventAtIndex == `EVENT_ENTITY_DAMAGED` then
                    local eventDataSize = 9
                    local eventDataStruct = DataView.ArrayBuffer(128) -- buffer must be 8*eventDataSize or bigger
                    eventDataStruct:SetInt32(0, 0)                    -- Damaged Entity Id
                    eventDataStruct:SetInt32(8, 0)                    -- Object/Ped Id that Damaged Entity
                    eventDataStruct:SetInt32(16, 0)                   -- Weapon Hash that Damaged Entity
                    eventDataStruct:SetInt32(24, 0)                   -- Ammo Hash that Damaged Entity
                    eventDataStruct:SetInt32(32, 0)                   -- (float) Damage Amount
                    eventDataStruct:SetInt32(40, 0)                   -- Unknown
                    eventDataStruct:SetInt32(48, 0)                   -- (float) Entity Coord x
                    eventDataStruct:SetInt32(56, 0)                   -- (float) Entity Coord y
                    eventDataStruct:SetInt32(64, 0)                   -- (float) Entity Coord z

                    local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    local playerPed = eventDataStruct:GetInt32(0)
                    if is_data_exists and playerPed == PlayerPedId() then
                        DamageHash = eventDataStruct:GetInt32(16)
                        DamageAmount = eventDataStruct:GetFloat32(32)
                        Entity(playerPed).state:set('damageHash', DamageHash, true)

                        if ((Guns[DamageHash]) and (DamageAmount > 2.0)) or ((Knives[DamageHash]) and (DamageAmount > 2.0)) then
                            TriggerEvent('bcc-medical:ApplyBleed')
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('bcc-medical:ApplyBleed', function()
    math.randomseed(GetGameTimer())
    local chancetobleed = math.random(100)
    if Config.devMode then
        print('Bleed Chance', chancetobleed)
    end
    if chancetobleed >= Config.bleedChance then
        TriggerServerEvent('bcc-medical:SetBleed', 1)
    end
end)

local function StartPrompts()
    CabinetPrompt = PromptRegisterBegin()
    PromptSetControlAction(CabinetPrompt, Config.keys.usePrompt)
    PromptSetText(CabinetPrompt, CreateVarString(10, 'LITERAL_STRING', _U('Open_Cabinet')))
    PromptSetEnabled(CabinetPrompt, true)
    PromptSetVisible(CabinetPrompt, true)
    PromptSetStandardMode(CabinetPrompt, true)
    PromptSetGroup(CabinetPrompt, OfficeGroup)
    PromptRegisterEnd(CabinetPrompt)
end

local function ManageOfficeBlip(site, closed)
    local siteCfg = Offices[site]

    if closed and not siteCfg.blip.showClosed then
        if Offices[site].Blip then
            RemoveBlip(Offices[site].Blip)
            Offices[site].Blip = nil
        end
        return
    end

    if not Offices[site].Blip then
        siteCfg.Blip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, siteCfg.office.location.x, siteCfg.office.location.y, siteCfg.office.location.z) -- BlipAddForCoords
        SetBlipSprite(siteCfg.Blip, siteCfg.blip.sprite, true)
        Citizen.InvokeNative(0x9CB1A1623062F402, siteCfg.Blip, siteCfg.blip.name) -- SetBlipName
    end

    local color = siteCfg.blip.color.open
    if closed then color = siteCfg.blip.color.closed end
    Citizen.InvokeNative(0x662D364ABF16DE2F, Offices[site].Blip, joaat(Config.BlipColors[color])) -- BlipAddModifier
end

CreateThread(function()
    StartPrompts()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000
        local hour = GetClockHours()

        if IsEntityDead(playerPed) then goto END end

        for site, siteCfg in pairs(Offices) do
            local distance = #(playerCoords - siteCfg.office.location)
            -- Office Closed
            if (siteCfg.office.hours.active and hour >= siteCfg.office.hours.close) or (siteCfg.office.hours.active and hour < siteCfg.office.hours.open) then
                if siteCfg.blip.show then
                    ManageOfficeBlip(site, true)
                end
                if distance <= siteCfg.office.distance then
                    sleep = 0
                    PromptSetActiveGroupThisFrame(OfficeGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.office.prompt .. _U('hours') ..
                        siteCfg.office.hours.open .. _U('to') .. siteCfg.office.hours.close .. _U('hundred')))
                    PromptSetEnabled(CabinetPrompt, false)
                end
                -- Office Open
            else
                if siteCfg.blip.show then
                    ManageOfficeBlip(site, false)
                end
                if distance <= siteCfg.office.distance then
                    sleep = 0
                    PromptSetActiveGroupThisFrame(OfficeGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.office.prompt))
                    PromptSetEnabled(CabinetPrompt, true)
                    if Citizen.InvokeNative(0xC92AC953F0A982AE, CabinetPrompt) then -- PromptHasStandardModeCompleted
                        CheckPlayerJob()
                        if HasJob then
                            OpenCabinetMenu(siteCfg.menu)
                        else
                            VORPcore.NotifyRightTip(_U('you_do_not_have_job'), 4000)
                        end
                    end
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

local function LoadAnim(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function LoadModel(model, modelName)
    if not IsModelValid(model) then
        return print('Invalid model:', modelName)
    end
    RequestModel(model, false)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

RegisterNetEvent('bcc-medical:CallNpcDoctor', function()
    local playerPed = PlayerPedId()
    if not IsEntityDead(playerPed) then
        return VORPcore.NotifyRightTip(_U('notdead'), 4000)
    end

    VORPcore.NotifyRightTip(_U('calldoctor'), 4000)

    if NpcDoctor ~= 0 then
        DeleteEntity(NpcDoctor)
        NpcDoctor = 0
    end

    local hasPayment = VORPcore.Callback.TriggerAwait('bcc-medical:CurrencyCheck')
    if not hasPayment then return end

    local modelName = Config.doctors.ped
    local model = joaat(modelName)
    LoadModel(model, modelName)

    local coords = GetEntityCoords(playerPed)
    local x, y, z
    local foundground = false
    local groundZ = 0.0
    while not foundground do
        local randomAngle = math.rad(math.random(0, 360))
        x = coords.x + math.sin(randomAngle) * math.random(1, 100) * 0.3
        y = coords.y + math.cos(randomAngle) * math.random(1, 100) * 0.3
        z = coords.z

        local valid, outPosition = GetSafeCoordForPed(x, y, z, false, 16)
        if valid then
            x, y, z = outPosition.x, outPosition.y, outPosition.z
        else
            Wait(100)
            goto END
        end

        foundground, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z)
        if foundground then
            z = groundZ
        end

        ::END::
    end

    NpcDoctor = CreatePed(model, x + 2.0, y, z, true, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, NpcDoctor, false) -- SetRandomOutfitVariation

    while not IsPedReadyToRender(NpcDoctor) do
        Wait(10)
    end
    SetModelAsNoLongerNeeded(model)

    Citizen.InvokeNative(0x923583741DC87BCE, NpcDoctor, 'default') -- SetPedDesiredLocoForModel

    TaskLookAtEntity(NpcDoctor, playerPed, -1, 2048, 3)
    Wait(500)
    ClearPedTasks(NpcDoctor)

    -- Makes the NPC move to a position closer to the player
    local moveToX = coords.x + 1.0
    local moveToY = coords.y + 1.0
    local moveToZ = coords.z
    ClearPedTasksImmediately(NpcDoctor)
    TaskGoToCoordAnyMeans(NpcDoctor, moveToX, moveToY, moveToZ, 2.0, 0, false, 786603, 0xbf800000) -- Increase speed
    if Config.devMode then
        print('NPC is moving towards the player...')
    end

    local lastDistance = -1
    while true do
        Wait(100)
        local npcCoords = GetEntityCoords(NpcDoctor)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(npcCoords - playerCoords)

        -- Rounds the distance to the nearest integer
        local roundedDistance = math.floor(distance + 0.5)
        -- Updates notification only if distance changes
        if roundedDistance ~= lastDistance then
            lastDistance = roundedDistance
            VORPcore.NotifyRightTip(_U('distance') .. tostring(roundedDistance) .. _U('meters'), 1)
        end

        if distance < 2.0 then
            if Config.devMode then
                print('NPC has reached the player.')
            end

            ClearPedTasks(NpcDoctor)
            TaskPickupCarriableEntity(NpcDoctor, playerPed)
            Wait(2000)

            local isCarrying = IsPedCarryingSomething(NpcDoctor)
            if isCarrying then
                if Config.devMode then
                    print('NPC successfully picked up the player.')
                end
                -- Wait for the task of carrying the player to complete
                Wait(7000)
                break
            else
                if Config.devMode then
                    print('NPC failed to pick up the player. Trying again...')
                end
                -- If it fails, you can try a new approach
                TaskGoToCoordAnyMeans(NpcDoctor, moveToX, moveToY, moveToZ, 2.0, 0, false, 786603, 0xbf800000)
            end
        end

        -- Recalculate distance and position if necessary
        if distance > 10.0 then
            -- If the NPC is too far away, try a new approach
            TaskGoToCoordAnyMeans(NpcDoctor, coords.x + 1.0, coords.y + 1.0, coords.z, 2.0, 0, false, 786603, 0xbf800000)
            Wait(500)
        end
    end

    local newX = coords.x + math.random(-2, 2)
    local newY = coords.y + math.random(-2, 2)
    local newZ = coords.z

    DoScreenFadeOut(800)
    TaskPlaceCarriedEntityAtCoord(NpcDoctor, playerPed, newX, newY, newZ, 5.0, 0)
    Wait(5000)

    DeleteEntity(NpcDoctor)
    NpcDoctor = 0

    -- Revive the player
    if Config.doctors.toHospital then
        TriggerServerEvent('bcc-medical:PlayerRespawn')
        while IsScreenFadedOut() do
            Wait(50)
        end
    else
        TriggerServerEvent('bcc-medical:PlayerRevive')
        Wait(800)
        DoScreenFadeIn(800)
    end

    local currency = Config.doctors.currency
    if currency == 0 then
        VORPcore.NotifyRightTip(_U('revived') .. '$' .. tostring(Config.doctors.amount), 4000)
    elseif currency == 1 then
        VORPcore.NotifyRightTip(_U('revived') .. Config.doctors.amount .. _U('gold'), 4000)
    end
end)

function GetClosestPlayer()
    local players = GetActivePlayers()
    local player = PlayerId()
    local coords = GetEntityCoords(PlayerPedId())
    local closestDistance = -1
    local closestPlayer = -1
    for i = 1, #players, 1 do
        local target = GetPlayerPed(players[i])
        if players[i] ~= player then
            local distance = #(coords - GetEntityCoords(target))
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = players[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

RegisterNetEvent('bcc-medical:ReviveClosestPlayer', function(reviveItem)
    local closestPlayer, closestDistance = GetClosestPlayer()

    if closestPlayer == -1 or closestDistance > 2.0 then
        return VORPcore.NotifyRightTip(_U('not_near_player'), 4000)
    end

    local playerPed = PlayerPedId()
    local closestPlayerPed = GetPlayerPed(closestPlayer)
    local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(closestPlayerPed))
    if dist > 1.5 then
        return VORPcore.NotifyRightTip(_U('tooFarFromPlayer'), 4000)
    end

    if not IsPedDeadOrDying(closestPlayerPed, true) then
        return VORPcore.NotifyRightTip(_U('player_not_unconscious'), 4000)
    end

    local dict = 'mech_revive@unapproved'
    LoadAnim(dict)
    TaskPlayAnim(playerPed, dict, 'revive', 1.0, 1.0, 4500, 0, 0, false, false, false)
    Wait(4500)
    DoScreenFadeOut(800)
    Wait(800)
    TriggerServerEvent('bcc-medical:ReviveClosestPlayer', reviveItem, GetPlayerServerId(closestPlayer))
    Wait(800)
    DoScreenFadeIn(800)
end)

RegisterNetEvent('bcc-medical:GetClosestPlayerHeal', function(item, itemLabel, perm)
    local closestPlayer, closestDistance = GetClosestPlayer()

    if closestPlayer ~= -1 and closestDistance <= 1.5 then
        local closestPlayerSrc = GetPlayerServerId(closestPlayer)
        local isBleeding = PatientBleedCheck(closestPlayerSrc)

        if isBleeding then
            TriggerServerEvent('bcc-medical:StopBleed', false, closestPlayerSrc, item, perm)
            VORPcore.NotifyRightTip(_U('You_Used') .. itemLabel .. _U('onPatient'), 4000)
        else
            VORPcore.NotifyRightTip(_U('patientNotBleeding'), 4000)
        end
    else
        local isBleeding = PlayerBleedCheck()

        if isBleeding then
            TriggerServerEvent('bcc-medical:StopBleed', true, nil, item, perm)
            VORPcore.NotifyRightTip(_U('You_Used') .. itemLabel .. _U('onYourself'), 4000)
        else
            VORPcore.NotifyRightTip(_U('notBleeding'), 4000)
        end
    end
end)

RegisterCommand(Config.Command, function(source, args, rawCommand)
    local closestPlayer, closestDistance = GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 2.0 then
        OpenDoctorMenu()
        return
    end
    OpenPlayerMenu()
end, false)

function CallMedicalService()
    if not IsCalled then
        IsCalled = true
        TriggerServerEvent('bcc-medical:AlertJobs')
        Wait(Config.doctors.timer * 60000)
        IsCalled = false
    else
        VORPcore.NotifyRightTip(_U('cooldown'), 4000)
    end
end

-- Export the function
exports('CallMedicalService', CallMedicalService)

RegisterCommand(Config.doctors.command, function(source, args, rawCommand)
    CallMedicalService()
end, false)

local function MonitorBleed()
    TriggerServerEvent('bcc-medical:SendPlayers')

    CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            Wait(20000) -- Check every 20 seconds
            local isBleeding = PlayerBleedCheck()
            if isBleeding then
                Citizen.InvokeNative(0x835F131E7DC8F97A, playerPed, -25.00, 0, 0) -- ChangeEntityHealth
                if Config.AnimOnBleed then
                    local dict = 'amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a'
                    if not IsEntityPlayingAnim(playerPed, dict, 'idle_b', 3) then
                        RequestAnimDict(dict)
                        while not HasAnimDictLoaded(dict) do
                            Wait(10)
                        end
                        TaskPlayAnim(playerPed, dict, 'idle_b', 5.0, 1.0, 4000, 31, 0, false, false, false)
                    end
                end
            end
        end
    end)
end

if not Config.devMode then
    RegisterNetEvent('vorp:SelectedCharacter', function(charid)
        MonitorBleed()
    end)
else
    RegisterCommand('dmgtest', function(source, args, rawCommand)
        Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -10.00, 0, `weapon_pistol_mauser`)
    end, false)

    MonitorBleed()
end

function DamageHashCheck(damageHash)
    local hash = damageHash
    if not damageHash then
        hash = DamageHash
    end
    local damageType

    if (hash == -842959696) then
        damageType = _U('hurt')
    elseif (hash == 1885857703) or (hash == -544306709) then
        damageType = _U('burn')
    elseif Knives[hash] then
        damageType = _U('cut')
    elseif Blunt[hash] then
        damageType = _U('bruised')
    elseif Guns[hash] then
        damageType = _U('shot')
    else
        damageType = _U('None')
    end

    return damageType
end

-- Function to check part and set damageboneself based on the bone parameter
function CheckPart(bone)
    local damageBone = nil

    if (bone == 6884) or (bone == 43312) then
        damageBone = _U('RightLeg')
    elseif (bone == 65478) or (bone == 55120) or (bone == 45454) then
        damageBone = _U('LeftLeg')
    elseif (bone == 14411) or (bone == 14410) then
        damageBone = _U('Stomach')
    elseif (bone == 14412) then
        damageBone = _U('Stomach_Chest')
    elseif (bone == 14414) then
        damageBone = _U('Chest')
    elseif (bone == 54187) or (bone == 46065) then
        damageBone = _U('RightArm')
    elseif (bone == 37873) or (bone == 53675) then
        damageBone = _U('LeftArm')
    elseif (bone == 0) then
        damageBone = _U('None')
    end

    return damageBone
end

function GetPlayers()
    local players = {}
    for i = 0, 256 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, GetPlayerServerId(i))
        end
    end
    return players
end

function PlayerBleedCheck()
    local isBleeding = VORPcore.Callback.TriggerAwait('bcc-medical:CheckBleed')
    if isBleeding and isBleeding == 1 then
        return true
    end
    return false
end

function PatientBleedCheck(closestPlayerSrc)
    local isBleeding = VORPcore.Callback.TriggerAwait('bcc-medical:CheckPatientBleed', closestPlayerSrc)
    if isBleeding and isBleeding == 1 then
        return true
    end
    return false
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    ClearPedTasksImmediately(PlayerPedId())
    for _, officeCfg in pairs(Offices) do
        if officeCfg.Blip then
            RemoveBlip(officeCfg.Blip)
            officeCfg.Blip = nil
        end
    end
    if NpcDoctor ~= 0 then
        DeleteEntity(NpcDoctor)
        NpcDoctor = 0
    end
end)
