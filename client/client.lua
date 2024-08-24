local VORPcore = exports.vorp_core:GetCore()
local Menu = exports.vorp_menu:GetMenuData()

local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local UsePrompt
local HealthCheck = false
local CreatedPed = 0
local DamageBone = _U('None')
local DamageBoneSelf = _U('None')
local HasJob = false
local InMenu = false
local IsCalled = false
local DamageHash = nil

local function SetupUsePrompt()
	UsePrompt = PromptRegisterBegin()
	PromptSetControlAction(UsePrompt, Config.keys.usePrompt)
	PromptSetText(UsePrompt, CreateVarString(10, 'LITERAL_STRING', _U('use')))
	PromptSetEnabled(UsePrompt, true)
	PromptSetVisible(UsePrompt, true)
	PromptSetStandardMode(UsePrompt, true)
	PromptSetGroup(UsePrompt, PromptGroup)
	PromptRegisterEnd(UsePrompt)
end

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
		if Citizen.InvokeNative(0xDCF06D0CDFF68424, PlayerPedId(), Guns[tostring(DamageHash)], 0) then -- HasEntityBeenDamagedByWeapon
			TriggerEvent('bcc-medical:ApplyBleed')
		end
		local size = GetNumberOfEvents(0) -- get number of events for EVENT GROUP 0 (SCRIPT_EVENT_QUEUE_AI). Check table below.
		if size > 0 then
			for i = 0, size - 1 do
				local eventAtIndex = GetEventAtIndex(0, i)

				if eventAtIndex == `EVENT_ENTITY_DAMAGED` then
					local eventDataSize = 9
					local eventDataStruct = DataView.ArrayBuffer(128) -- buffer must be 8*eventDataSize or bigger
					eventDataStruct:SetInt32(0, 0)  -- Damaged Entity Id
                    eventDataStruct:SetInt32(8, 0)  -- Object/Ped Id that Damaged Entity
                    eventDataStruct:SetInt32(16, 0) -- Weapon Hash that Damaged Entity
                    eventDataStruct:SetInt32(24, 0) -- Ammo Hash that Damaged Entity
                    eventDataStruct:SetInt32(32, 0) -- (float) Damage Amount
                    eventDataStruct:SetInt32(40, 0) -- Unknown
                    eventDataStruct:SetInt32(48, 0) -- (float) Entity Coord x
                    eventDataStruct:SetInt32(56, 0) -- (float) Entity Coord y
                    eventDataStruct:SetInt32(64, 0) -- (float) Entity Coord z

					local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize)          -- GET_EVENT_DATA
					local Player = eventDataStruct:GetInt32(0)
					if is_data_exists and Player == PlayerPedId() then
						DamageHash = eventDataStruct:GetInt32(16)
						DamageAmount = eventDataStruct:GetFloat32(32)

						if ((Guns[tostring(DamageHash)]) and (DamageAmount > 2.0)) or ((Knives[tostring(DamageHash)]) and (DamageAmount > 2.0)) then
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

CreateThread(function()
	SetupUsePrompt()
	while true do
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(PlayerPedId(), true)
        local sleep = 1000

        if InMenu or IsEntityDead(playerPed) then goto END end

		for _, officeCfg in pairs(Offices) do
            local distance = #(playerCoords - officeCfg.coords)
			if distance <= 1.5 then
                sleep = 0
				PromptSetActiveGroupThisFrame(PromptGroup, CreateVarString(10, 'LITERAL_STRING', _U('Open_Cabinet')))
				if Citizen.InvokeNative(0xC92AC953F0A982AE, UsePrompt) then -- PromptHasStandardModeCompleted
					CheckPlayerJob()
                    if HasJob then
                        CabinetMenu()
                        InMenu = true
                    else
                        VORPcore.NotifyRightTip(_U('you_do_not_have_job'), 4000)
                    end
				end
			end
		end
        ::END::
        Wait(sleep)
	end
end)

CreateThread(function()
	for office, officeCfg in pairs(Offices) do
		officeCfg.Blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, officeCfg.coords.x, officeCfg.coords.y, officeCfg.coords.z) -- BlipAddForCoords
		SetBlipSprite(officeCfg.Blip, officeCfg.blip.sprite, true)
		Citizen.InvokeNative(0x9CB1A1623062F402, officeCfg.Blip, officeCfg.blip.name) -- SetBlipName
        Citizen.InvokeNative(0x662D364ABF16DE2F, Offices[office].Blip, joaat(Config.BlipColors[officeCfg.blip.color])) -- BlipAddModifier
	end
end)

local function LoadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(500)
	end
end

local function RevivePlayer(reviveitem, playerPed)
	local closestPlayerPed = GetPlayerPed(playerPed)
	if IsPedDeadOrDying(closestPlayerPed, true) then
		local dict = 'mech_revive@unapproved'
		LoadAnimDict(dict)
		TaskPlayAnim(PlayerPedId(), dict, 'revive', 1.0, 8.0, 2000, 31, 0, false, false, false)
		Wait(2000)
		ClearPedTasks(PlayerPedId())
		TriggerServerEvent('bcc-medical:ReviveClosestPlayer', reviveitem, GetPlayerServerId(playerPed))
	else
		VORPcore.NotifyRightTip(_U('player_not_unconscious'), 4000)
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

function SpawnNPC()
    local modelName = Config.doctors.ped
	local model = joaat(modelName)
    LoadModel(model, modelName)

	local coords = GetEntityCoords(PlayerPedId())
	local randomAngle = math.rad(math.random(0, 360))
	local x = coords.x + math.sin(randomAngle) * math.random(1, 100) * 0.3
	local y = coords.y + math.cos(randomAngle) * math.random(1, 100) * 0.3 -- End Number multiplied by is radius to player
	local z = coords.z
	local b, rdcoords, rdcoords2 = GetClosestVehicleNode(coords.x, coords.y, coords.z, 1, 10.0, 10.0)
	if (rdcoords.x == 0.0 and rdcoords.y == 0.0 and rdcoords.z == 0.0) then
		local valid, outPosition = GetSafeCoordForPed(x, y, z, false, 8)
		if valid then
			x = outPosition.x
			y = outPosition.y
			z = outPosition.z
		end
	else
		local valid, outPosition = GetSafeCoordForPed(x, y, z, false, 16)
		if valid then
			x = outPosition.x
			y = outPosition.y
			z = outPosition.z
		end

		local foundground, groundZ, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)
		if foundground then
			z = groundZ
		else
			VORPcore.NotifyRightTip(_U('missground'), 4000)
			DeleteEntity(CreatedPed)
			CreatedPed = 0
		end
	end

	if CreatedPed == 0 then
		CreatedPed = CreatePed(model, x + 2.0, y, z, true, false, false, false)
		Wait(500)
	end

	Citizen.InvokeNative(0x283978A15512B2FE, CreatedPed, true) -- SetRandomOutfitVariation

	FreezeEntityPosition(CreatedPed, false)
	Citizen.InvokeNative(0x923583741DC87BCE, CreatedPed, "default") -- SetPedDesiredLocoForModel
	TaskGoToEntity(CreatedPed, PlayerPedId(), -1, 2.0, 5.0, 1073741824, 1)
	Wait(7000)
	DeleteEntity(CreatedPed)
	CreatedPed = 0
    local canRevive = VORPcore.Callback.TriggerAwait('bcc-medical:RevivePlayer')
    if canRevive then
        if Config.doctors.toHospital then
            DoScreenFadeOut(800)
            Wait(800)
            TriggerEvent('vorp_core:respawnPlayer')
            while IsScreenFadedOut do
                Wait(50)
            end
        else
            DoScreenFadeOut(800)
            Wait(800)
            TriggerEvent('vorp:resurrectPlayer')
            Wait(800)
            DoScreenFadeIn(800)
        end
    end
end

RegisterNetEvent('bcc-medical:FindDoc', function()
	if IsEntityDead(PlayerPedId()) then
		VORPcore.NotifyRightTip(_U('calldoctor'), 4000)
		SpawnNPC()
	else
		VORPcore.NotifyRightTip(_U('notdead'), 4000)
	end
end)

local function GetClosestPlayer()
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

RegisterNetEvent('bcc-medical:GetClosestPlayerRevive', function(reviveItem)
	local closestPlayer, closestDistance = GetClosestPlayer()
	if closestPlayer ~= -1 and closestDistance <= 1.5 then
		RevivePlayer(reviveItem, closestPlayer)
	else
		VORPcore.NotifyRightTip(_U('not_near_player'), 4000)
	end
end)

RegisterNetEvent('bcc-medical:GetClosestPlayerHeal', function(perm)
	local closestPlayer, closestDistance = GetClosestPlayer()

	if closestPlayer ~= -1 and closestDistance <= 1.5 then
		TriggerServerEvent('bcc-medical:StopBleed', false, GetPlayerServerId(closestPlayer), perm)
	else
		TriggerServerEvent('bcc-medical:StopBleed', true, nil, perm)
	end
end)

RegisterNetEvent("bcc-medical:Revive", function()
    TriggerEvent('vorp:resurrectPlayer')
end)

RegisterCommand(Config.Command, function(source, args, rawCommand)
	CheckPlayerJob()
	if HasJob then
		DoctorMenu()
	else
		MedicMenu()
	end
end, false)


RegisterCommand(Config.doctors.command, function(source, args, rawCommand)
	if not IsCalled then
		IsCalled = true
		TriggerServerEvent('bcc-medical:AlertJobs')
		Wait(Config.doctors.timer * 60000)
		IsCalled = false
	else
		VORPcore.NotifyRightTip(_U('cooldown'), 4000)
	end
end, false)

local function MonitorBleed()
    local player = GetPlayerServerId(PlayerId())
	Wait(100)
	TriggerServerEvent("bcc-medical:SendPlayers", player)

	CreateThread(function()
		while true do
			Wait(1000 * 20)
            local IsBleeding = VORPcore.Callback.TriggerAwait('bcc-medical:CheckBleed')
			if IsBleeding and IsBleeding == 1 then
				Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -25.00, 0, 0) -- ChangeEntityHealth
                if Config.AnimOnBleed then
                    local dict = "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a"
				    if not IsEntityPlayingAnim(PlayerPedId(), dict, "idle_b", 3) then
					    RequestAnimDict(dict)
					    while not HasAnimDictLoaded(dict) do
						    Citizen.Wait(100)
					    end
					    TaskPlayAnim(PlayerPedId(), dict, "idle_b", 5.0, 1.0 , 4000, 31, 0, false, false, false)
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
    RegisterCommand("dmgtest", function(source, args, rawCommand)
		Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -10.00, 0, `weapon_pistol_mauser`)
	end, false)

    MonitorBleed()
end

local function DamageHashCheck()
	if DamageHash == -842959696 then
		DamageHash = 'appear to be hurt'
	elseif DamageHash == 1885857703 or DamageHash == -544306709 then
		DamageHash = 'appears to be burnt'
	elseif Knives[tostring(DamageHash)] then
		DamageHash = 'appears to be cut'
	elseif Blunt[tostring(DamageHash)] then
		DamageHash = 'appears to be bruised'
	elseif Guns[tostring(DamageHash)] then
		DamageHash = 'appears to be shot'
	else
		DamageHash = 'None'
	end
	return DamageHash
end

function MedicMenu()
    Menu.CloseAll()
	local Elements = {}
	local playerPed = PlayerPedId()
	local closestPlayer, closestDistance = GetClosestPlayer()
	local closestPlayerPed = GetPlayerPed(closestPlayer)
	local closesthit, closestbone = GetPedLastDamageBone(closestPlayerPed)
	local hit, bone = GetPedLastDamageBone(playerPed)
	if DamageHash == nil then DamageHash = 'None' end

	TriggerEvent("bcc-medical:CheckPart", bone)
	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		TriggerEvent("bcc-medical:CheckPartOther", closestbone)
		Wait(1000)
		table.insert(Elements, {
			label = _U('ClosestInjury') .. DamageBone,
			value = 'lastwound',
			desc = _U('ClosestInjuryDesc') .. DamageBone
		})
	end

	Elements = {
		{
			label = _U('InjuredPart') .. DamageBoneSelf,
			value = 'lastwoundself',
			desc = _U('InjuredPartDesc') .. DamageBoneSelf
		},
		{
			label = _U('Wound') .. DamageHashCheck(),
			value = 'wound',
			desc = _U('WoundDesc')
		},
	}

	Menu.Open('default', GetCurrentResourceName(), 'vorp_menu_medic',
    {
        title    = _U('PlayerMenu'),
        align    = 'top-left',
        elements = Elements,
    },
    function(data, menu)
        if (data.current.value == 'lastwound') then
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                if HealthCheck == false then
                    HealthCheck = true
                    hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
                    TriggerEvent("bcc-medical:CheckPartOther", closestbone)
                else
                    HealthCheck = false
                end
            end
            MedicMenu()
        end
        if (data.current.value == 'lastwoundself') then
            if HealthCheck == false then
                HealthCheck = true
                hit, bone = GetPedLastDamageBone(PlayerPedId())
                TriggerEvent("bcc-medical:CheckPart", bone)
            else
                HealthCheck = false
            end
            MedicMenu()
        end
    end,
    function(data, menu)
        DamageBone = _U('None')
        DamageBoneSelf = _U('None')
        menu.close()
    end)
end

function DoctorMenu()
    Menu.CloseAll()
	local DocElements = {}
	local playerPed = PlayerPedId()
	local health = GetEntityHealth(playerPed)
	local pulse = health / 4 + math.random(20, 30)
	local closestPlayer, closestDistance = GetClosestPlayer()
	local closestPlayerPed = GetPlayerPed(closestPlayer)
	local patienthealth = GetEntityHealth(closestPlayerPed)
	local patientpulse = patienthealth / 4 + math.random(20, 30)

	local closesthit, closestbone = GetPedLastDamageBone(closestPlayerPed)
	local hit, bone = GetPedLastDamageBone(PlayerPedId())
	if DamageHash == nil then DamageHash = 'None' end

	TriggerEvent("bcc-medical:CheckPart", bone)
	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		TriggerEvent("bcc-medical:CheckPartOther", closestbone)
		Wait(1000)
		table.insert(DocElements, {
			label = _U('ClosestInjury') .. DamageBone,
			value = 'lastwound',
			desc = _U('ClosestInjuryDesc') .. DamageBone
		})
		table.insert(DocElements, {
			label = _U('ClosestWound') .. DamageHashCheck(),
			value = 'wound',
			desc = _U('WoundDesc')
		})
		table.insert(DocElements,
			{
				label = _U('PatientPulse') .. patientpulse,
				value = 'patientpulse',
				desc = _U('PatientPulse') .. patientpulse
			}
		)
	end
	DocElements = {
		{ label = _U('Pulse') .. pulse, value = 'pulse', desc = _U('Pulse') },
		{
			label = _U('InjuredPart') .. DamageBoneSelf,
			value = 'lastwoundself',
			desc = _U('InjuredPartDesc') .. DamageBoneSelf
		},
		{
			label = _U('Wound') .. DamageHashCheck(),
			value = 'wound',
			desc = _U('WoundDesc')
		},
	}

	Menu.Open('default', GetCurrentResourceName(), 'vorp_menu_doctor',
    {
        title    = _U('DoctorMenu'),
        align    = 'top-left',
        elements = DocElements,
    },
    function(data, menu)
        if (data.current.value == 'lastwound') then
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                if HealthCheck == false then
                    HealthCheck = true
                    hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
                    TriggerEvent("bcc-medical:CheckPartOther", closestbone)
                else
                    HealthCheck = false
                end
            end
            DoctorMenu()
        end
        if (data.current.value == 'lastwoundself') then
            if HealthCheck == false then
                HealthCheck = true
                hit, bone = GetPedLastDamageBone(playerPed)
                TriggerEvent("bcc-medical:CheckPart", bone)
            else
                HealthCheck = false
            end
            DoctorMenu()
        end
    end,
    function(data, menu)
        DamageBone = _U('None')
        DamageBoneSelf = _U('None')
        menu.close()
    end)
end

function CabinetMenu()
	Menu.CloseAll()

    local elements
    if Config.PropCrafting then
        elements = {
            { label = _U('Stitch'), value = 'takestim' },
            { label = "Doctor Bag", value = 'takebag', desc = "Doctor Bag" },
        }
    else
        elements = {
            { label = _U('Stitch'), value = 'takestim' },
        }
    end

	local myInput = {
		type = "enableinput",                                      -- don't touch
		inputType = "input",                                       -- input type
		button = _U('Button'),                                     -- button name
		placeholder = _U('Placeholder'),                           -- placeholder name
		style = "block",                                           -- don't touch
		attributes = {
			inputHeader = _U('Amount'),                            -- header
			type = "text",                                         -- inputype text, number,date,textarea ETC
			pattern = "[0-9]",                                     --  only numbers "[0-9]" | for letters only "[A-Za-z]+"
			title = _U('NumOnly'),                                 -- if input doesnt match show this message
			style = "border-radius: 10px; background-color: ; border:none;" -- style
		}
	}

	Menu.Open('default', GetCurrentResourceName(), 'vorp_menu_cabinet',
    {
        title    = _U('CabinetMenu'),
        subtext  = _U('CabinetDesc'),
        align    = 'top-left',
        elements = elements,
    },
    function(data, menu)
        if (data.current.value == 'takestim') then
            TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(result)
                if result ~= "" or result then -- making sure its not empty or nil
                    TriggerServerEvent('bcc-medical:TakeItem', "NeedleandThread", tonumber(result))
                else
                    print("its empty?") -- notify
                end
            end)
        end

        if (data.current.value == 'takebag') then
            TriggerServerEvent('bcc-medical:TakeItem', "Doctor_Bag", 1)
        end
    end,
    function(data, menu)
        InMenu = false
        menu.close()
    end)
end

AddEventHandler('bcc-medical:CheckPart', function(bone)
	if bone == 6884 or bone == 43312 then
		DamageBoneSelf = _U('RightLeg')
	elseif bone == 65478 or bone == 55120 or bone == 45454 then
		DamageBoneSelf = _U('LeftLeg')
	elseif bone == 14411 or bone == 14410 then
		DamageBoneSelf = _U('Stomach')
	elseif bone == 14412 then
		DamageBoneSelf = _U('Stomach_Chest')
	elseif bone == 14414 then
		DamageBoneSelf = _U('Chest')
	elseif bone == 54187 or bone == 46065 then
		DamageBoneSelf = _U('RightArm')
	elseif bone == 37873 or bone == 53675 then
		DamageBoneSelf = _U('LeftArm')
	elseif bone == 0 then
		DamageBoneSelf = "None"
	end
end)

AddEventHandler('bcc-medical:CheckPartOther', function(bone)
	if bone == 6884 or bone == 43312 then
		DamageBone = _U('RightLeg')
	elseif bone == 65478 or bone == 55120 or bone == 45454 then
		DamageBone = _U('LeftLeg')
	elseif bone == 14411 or bone == 14410 then
		DamageBone = _U('Stomach')
	elseif bone == 14412 then
		DamageBone = _U('Stomach_Chest')
	elseif bone == 14414 then
		DamageBone = _U('Chest')
	elseif bone == 54187 or bone == 46065 then
		DamageBone = _U('RightArm')
	elseif bone == 37873 or bone == 53675 then
		DamageBone = _U('LeftArm')
	elseif bone == 0 then
		DamageBone = "None"
	end
end)

function GetPlayers()
	local players = {}
	for i = 0, 256 do
		if NetworkIsPlayerActive(i) then
			table.insert(players, GetPlayerServerId(i))
		end
	end
	return players
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
end)