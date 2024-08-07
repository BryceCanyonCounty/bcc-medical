local healthcheck = false
local createdped = 0
local damagebone = _U('None')
local damageboneself = _U('None')
local Playerjob
local inmenu = false
local iscalled = false
local DamageHash = nil

local VORPcore = exports.vorp_core:GetCore()


local PromptGorup = GetRandomIntInRange(0, 0xffffff)

function SetupUsePrompt()
	local str = 'Use'
	UsePrompt = PromptRegisterBegin()
	PromptSetControlAction(UsePrompt, 0xC7B5340A)
	str = CreateVarString(10, 'LITERAL_STRING', str)
	PromptSetText(UsePrompt, str)
	PromptSetEnabled(UsePrompt, true)
	PromptSetVisible(UsePrompt, true)
	PromptSetStandardMode(UsePrompt, 1)
	PromptSetGroup(UsePrompt, PromptGorup)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C, UsePrompt, true)
	PromptRegisterEnd(UsePrompt)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if Citizen.InvokeNative(0xDCF06D0CDFF68424, PlayerPedId(), Guns[tostring(DamageHash)], 0) then
			TriggerEvent('legacy_medic:ApplyBleed')
		end
		local size = GetNumberOfEvents(0) -- get number of events for EVENT GROUP 0 (SCRIPT_EVENT_QUEUE_AI). Check table below.
		if size > 0 then
			for i = 0, size - 1 do
				local eventAtIndex = GetEventAtIndex(0, i)

				if eventAtIndex == `EVENT_ENTITY_DAMAGED` then      
					local eventDataSize = 9  

					local eventDataStruct = DataView.ArrayBuffer(128) -- buffer must be 8*eventDataSize or bigger
					eventDataStruct:SetInt32(0, 0)     -- 8*0 offset for 0 element of eventData
					eventDataStruct:SetInt32(8, 0)     -- 8*1 offset for 1 element of eventData
					eventDataStruct:SetInt32(16, 0)    -- 8*2 offset for 2 element of eventData
					eventDataStruct:SetInt32(24, 0)    -- 8*3 offset for 3 element of eventData
					eventDataStruct:SetInt32(32, 0)    -- 8*4 offset for 4 element of eventData
					eventDataStruct:SetInt32(40, 0)    -- 8*4 offset for 5 element of eventData
					eventDataStruct:SetInt32(48, 0)    -- 8*4 offset for 6 element of eventData
					eventDataStruct:SetInt32(56, 0)    -- 8*4 offset for 7 element of eventData
					eventDataStruct:SetInt32(64, 0)    -- 8*4 offset for 8 element of eventData

					-- etc +8 offset for each next element (if data size is bigger then 5)

					local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize)          -- GET_EVENT_DATA
					local Player = eventDataStruct:GetInt32(0) -- 8*1 offset for 1 element of eventData
					if is_data_exists and Player == PlayerPedId() then
						DamageHash = eventDataStruct:GetInt32(16)

						DamageAmount = eventDataStruct:GetFloat32(32)

						if Guns[tostring(DamageHash)] and DamageAmount > 2.0 then
							TriggerEvent('legacy_medic:ApplyBleed')
						elseif Knives[tostring(DamageHash)] and DamageAmount > 2.0 then
							TriggerEvent('legacy_medic:ApplyBleed')
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent('legacy_medic:ApplyBleed', function()
	math.randomseed(GetGameTimer())
	local chancetobleed = math.random(100)
	if Config.devMode then 
		print('Bleed Chance',chancetobleed) 
	end
	if chancetobleed >= Config.bleedChance then
		TriggerServerEvent('legacy_medic:SetBleed', 1)
	end
end)

RegisterNetEvent('legacy_medic:SendBleed', function(isbleeding)
	IsBleeding = isbleeding
end)


Citizen.CreateThread(function()
	SetupUsePrompt()
	while true do
		Wait(1)
		local ped = PlayerPedId()
		local pedpos = GetEntityCoords(PlayerPedId(), true)
		local isDead = IsEntityDead(ped)
		for k, v in pairs(Doctoroffices) do
			local distance = GetDistanceBetweenCoords(v.Pos.x, v.Pos.y, v.Pos.z, pedpos.x, pedpos.y, pedpos.z, false)
			if distance < 1.5 and not isDead and not inmenu then
				local item_name = CreateVarString(10, 'LITERAL_STRING', _U('Open_Cabinet'))
				PromptSetActiveGroupThisFrame(PromptGorup, item_name)
				if Citizen.InvokeNative(0xC92AC953F0A982AE, UsePrompt) then
					TriggerServerEvent('legacy_medic:checkjob')
					Wait(2000)
					if CheckTable(MedicJobs, Playerjob) then
						CabinetMenu()
						inmenu = true
					else
						VORPcore.NotifyRightTip(_U('you_do_not_have_job'), 4000)
					end
				end
			end
		end
	end
end)

Citizen.CreateThread(function()
	for k, v in pairs(Doctoroffices) do
		local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.Pos.x, v.Pos.y, v.Pos.z)
		SetBlipSprite(blip, -695368421, 1)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, _U('Map_Blip'))
	end
end)

function RevivePlayer(reviveitem,playerPed)
	local closestPlayerPed = GetPlayerPed(playerPed)
	if IsPedDeadOrDying(closestPlayerPed, 1) then
		local dic = "mech_revive@unapproved"
		local anim = "revive"
		loadAnimDict(dic)
		TaskPlayAnim(PlayerPedId(), dic, anim, 1.0, 8.0, 2000, 31, 0, true, true, false, false, true)
		Wait(2000)
		ClearPedTasksImmediately(PlayerPedId())
		TriggerServerEvent('legacy_medic:reviveclosestplayer', reviveitem,GetPlayerServerId(playerPed))
	else
		VORPcore.NotifyRightTip(_U('player_not_unconscious'), 4000)
	end
end

function SpawnNPC()
	local model = GetHashKey(Config.doctors.ped)
	RequestModel(model)
	if not HasModelLoaded(model) then
		RequestModel(model)
	end
	while not HasModelLoaded(model) or HasModelLoaded(model) == 0 or model == 1 do
		Citizen.Wait(1)
	end

	local coords = GetEntityCoords(PlayerPedId())
	local randomAngle = math.rad(math.random(0, 360))
	x = coords.x + math.sin(randomAngle) * math.random(1, 100) * 0.3
	y = coords.y + math.cos(randomAngle) * math.random(1, 100) * 0.3 -- End Number multiplied by is radius to player
	z = coords.z
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
			DeleteEntity(createdped)
			createdped = 0
		end
	end

	if createdped == 0 then
		createdped = CreatePed(model, x + 2.0, y, z, true, false, false, false)
		Wait(500)
	end

	Citizen.InvokeNative(0x283978A15512B2FE, createdped, true)

	local ped = PlayerPedId()
	FreezeEntityPosition(createdped, false)
	Citizen.InvokeNative(0x923583741DC87BCE, createdped, "default")
	TaskGoToEntity(createdped, ped, -1, 2.0, 5.0, 1073741824, 1)
	Wait(7000)
	DeleteEntity(createdped)
	createdped = 0
	TriggerServerEvent('legacy_medic:reviveplayer')
end

RegisterNetEvent('legacy_medic:finddoc')
AddEventHandler('legacy_medic:finddoc', function()
	if IsEntityDead(PlayerPedId()) then
		VORPcore.NotifyRightTip(_U('calldoctor'), 4000)
		SpawnNPC()
	else
		VORPcore.NotifyRightTip(_U('notdead'), 4000)
	end
end)

RegisterNetEvent('legacy_medic:getclosestplayerrevive', function(reviveitem)
	local closestPlayer, closestDistance = GetClosestPlayer()
	if closestPlayer ~= -1 and closestDistance <= 1.5 then
		RevivePlayer(reviveitem,closestPlayer)
	else
		VORPcore.NotifyRightTip(_U('not_near_player'), 4000)
	end
end)

RegisterNetEvent('legacy_medic:reviveclosest')
AddEventHandler('legacy_medic:reviveclosest', function(closestPlayer)
	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Citizen.Wait(50)
	end

	Citizen.Wait(1200)
	TriggerEvent('vorp:resurrectPlayer', closestPlayer)
	DoScreenFadeIn(800)
end)

RegisterNetEvent('legacy_medic:getclosestplayerbandage', function()
	local ped = PlayerPedId()
	local closestPlayer, closestDistance = GetClosestPlayer()

	if closestPlayer ~= -1 and closestDistance <= 1.0 then
		TriggerServerEvent('legacy_medic:healplayer', GetPlayerServerId(closestPlayer))
		TriggerServerEvent('legacy_medic:StopBleedTemp', false, GetPlayerServerId(closestPlayer))
	else
		TriggerServerEvent('legacy_medic:StopBleedTemp', true)
	end
end)

RegisterNetEvent('legacy_medic:getclosestplayerstitch', function()
	local ped = PlayerPedId()
	local closestPlayer, closestDistance = GetClosestPlayer()

	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		TriggerServerEvent('legacy_medic:StopBleedPerm', false, GetPlayerServerId(closestPlayer))
	else
		TriggerServerEvent('legacy_medic:StopBleedPerm', true, nil)
	end
end)

RegisterNetEvent('legacy_medic:sendjob', function(job)
	Playerjob = job
end)

RegisterCommand(Config.Command, function(source, args)
	TriggerServerEvent('legacy_medic:checkjob')
	Wait(250)
	if CheckTable(MedicJobs, Playerjob) then
		DoctorMenu()
	else
		MedicMenu()
	end
end)


RegisterCommand(Config.doctors.command, function(source)
	if not iscalled then
		iscalled = true
		TriggerServerEvent("legacy_medicalertjobs")
		Wait(Config.doctors.timer)
		iscalled = false
	else
		VORPcore.NotifyRightTip(_U('cooldown'), 4000)
	end
end)


RegisterNetEvent('vorp:SelectedCharacter', function()
	local player = GetPlayerServerId(tonumber(PlayerId()))
	Wait(100)
	TriggerServerEvent("legacy_medic:sendPlayers", player)


	CreateThread(function()
		while true do
			Wait(1000 * 20)
			TriggerServerEvent('legacy_medic:CheckBleed')
			Wait(250)
			if IsBleeding == 1 and Config.AnimOnBleed then
				Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -25.00, 0, GetHashKey("weapon_bleeding"))
				if not IsEntityPlayingAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 3) then
					RequestAnimDict('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a')
					while not HasAnimDictLoaded('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 5.0, 1.0 , 4000, 31, 0)
				end
			end
		end
	end)
end)

if Config.devMode then
	local player = GetPlayerServerId(tonumber(PlayerId()))
	Wait(100)
	TriggerServerEvent("legacy_medic:sendPlayers", player)


	CreateThread(function()
		while true do
			Wait(1000)
			TriggerServerEvent('legacy_medic:CheckBleed')
			Wait(250)
			if IsBleeding == 1 and Config.AnimOnBleed then
				Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -25.00, 0, GetHashKey("weapon_bleeding"))
				if not IsEntityPlayingAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 3) then
					RequestAnimDict('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a')
					while not HasAnimDictLoaded('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a') do
						Citizen.Wait(100)
					end
					TaskPlayAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 5.0,
						1.0
						, 4000, 31, 0)
				end
			end
		end
	end)

	RegisterCommand("dmgtest", function()
		Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -10.00, 0, GetHashKey("weapon_pistol_mauser"))
	end)
end

MenuData = {}
TriggerEvent("menuapi:getData", function(call)
	MenuData = call
end)

function DamageHashCheck(DamageHash)
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



function MedicMenu() -- Base Police Menu Logic
	local Elements = {}
	MenuData.CloseAll()
	local ped = PlayerPedId()
	local closestPlayer, closestDistance = GetClosestPlayer()
	local closestPlayerPed = GetPlayerPed(closestPlayer)
	local closesthit, closestbone = GetPedLastDamageBone(closestPlayerPed)
	local hit, bone = GetPedLastDamageBone(PlayerPedId())
	if DamageHash == nil then DamageHash = 'None' end

	TriggerEvent("legacy_medic:checkpart", bone)
	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		TriggerEvent("legacy_medic:checkpartother", closestbone)
		Wait(1000)
		table.insert(Elements, {
			label = _U('ClosestInjury') .. damagebone,
			value = 'lastwound',
			desc = _U('ClosestInjuryDesc') ..
				damagebone
		})
	end

	Elements = {

		{
			label = _U('InjuredPart') .. damageboneself,
			value = 'lastwoundself',
			desc = _U('InjuredPartDesc') ..
				damageboneself
		},
		{
			label = _U('Wound') .. DamageHashCheck(DamageHash),
			value = 'wound',
			desc = _U('WoundDesc')
		},
	}

	MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
		{
			title    = _U('MedicMenu'),
			align    = 'top-left',
			elements = Elements,
		},
		function(data, menu)
			if (data.current.value == 'lastwound') then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					if healthcheck == false then
						healthcheck = true
						hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
						TriggerEvent("legacy_medic:checkpartother", closestbone)
					else
						healthcheck = false
					end
				else
				end
				MedicMenu()
			end
			if (data.current.value == 'lastwoundself') then
				if healthcheck == false then
					healthcheck = true
					hit, bone = GetPedLastDamageBone(PlayerPedId())
					TriggerEvent("legacy_medic:checkpart", bone)
				else
					healthcheck = false
				end
				MedicMenu()
			end
		end,
		function(data, menu)
			damagebone = _U('None')
			damageboneself = _U('None')
			menu.close()
		end)
end

function DoctorMenu() -- Base Police Menu Logic
	local DocElements = {}
	MenuData.CloseAll()
	local ped = PlayerPedId()
	local health = GetEntityHealth(ped)
	local pulse = health / 4 + math.random(20, 30)
	local closestPlayer, closestDistance = GetClosestPlayer()
	local closestPlayerPed = GetPlayerPed(closestPlayer)
	local patienthealth = GetEntityHealth(closestPlayerPed)
	local patientpulse = patienthealth / 4 + math.random(20, 30)

	local closesthit, closestbone = GetPedLastDamageBone(closestPlayerPed)
	local hit, bone = GetPedLastDamageBone(PlayerPedId())
	if DamageHash == nil then DamageHash = 'None' end

	TriggerEvent("legacy_medic:checkpart", bone)
	if closestPlayer ~= -1 and closestDistance <= 3.0 then
		TriggerEvent("legacy_medic:checkpartother", closestbone)
		Wait(1000)
		table.insert(DocElements, {
			label = _U('ClosestInjury') .. damagebone,
			value = 'lastwound',
			desc = _U('ClosestInjuryDesc') ..
				damagebone
		})
		table.insert(DocElements, {
			label = _U('ClosestWound') .. DamageHashCheck(DamageHash),
			value = 'wound',
			desc = _U('WoundDesc')
		})
		table.insert(DocElements,
			{
				label = _U('PatientPulse') .. patientpulse,
				value = 'patientpulse',
				desc = _U('PatientPulse') ..
					patientpulse
			}
		)
	end
	DocElements = {
		{ label = _U('Pulse') .. pulse, value = 'pulse', desc = _U('Pulse') },
		{
			label = _U('InjuredPart') .. damageboneself,
			value = 'lastwoundself',
			desc = _U('InjuredPartDesc') ..
				damageboneself
		},
		{
			label = _U('Wound') .. DamageHashCheck(DamageHash),
			value = 'wound',
			desc = _U('WoundDesc')
		},
	}

	MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
		{
			title    = _U('MedicMenu'),
			align    = 'top-left',
			elements = DocElements,
		},
		function(data, menu)
			if (data.current.value == 'lastwound') then
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					if healthcheck == false then
						healthcheck = true
						hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
						TriggerEvent("legacy_medic:checkpartother", closestbone)
					else
						healthcheck = false
					end
				else
				end
				DoctorMenu()
			end
			if (data.current.value == 'lastwoundself') then
				if healthcheck == false then
					healthcheck = true
					hit, bone = GetPedLastDamageBone(PlayerPedId())
					TriggerEvent("legacy_medic:checkpart", bone)
				else
					healthcheck = false
				end
				DoctorMenu()
			end
		end,
		function(data, menu)
			damagebone = _U('None')
			damageboneself = _U('None')
			menu.close()
		end)
end

function CabinetMenu() -- Base Police Menu Logic
	MenuData.CloseAll()

	local elements = {
		{ label = _U('Stitch'), value = 'takestim' },
		{ label = "Doctor Bag", value = 'takebag', desc = "Doctor Bag" },

	}


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

	MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
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
						TriggerServerEvent('legacy_medic:takeitem', "NeedleandThread", result)
					else
						print("its empty?") -- notify
					end
				end)
			end

			if (data.current.value == 'takebag') then
				TriggerServerEvent('legacy_medic:takeitem', "Doctor_Bag", 1)
			end
		end,

		function(data, menu)
			inmenu = false
			menu.close()
		end)
end

RegisterNetEvent("legacy_medic:checkpart")
AddEventHandler("legacy_medic:checkpart", function(bone)
	if bone == 6884 or bone == 43312 then
		damageboneself = _U('RightLeg')
	elseif bone == 65478 or bone == 55120 or bone == 45454 then
		damageboneself = _U('LeftLeg')
	elseif bone == 14411 or bone == 14410 then
		damageboneself = _U('Stomach')
	elseif bone == 14412 then
		damageboneself = _U('Stomach_Chest')
	elseif bone == 14414 then
		damageboneself = _U('Chest')
	elseif bone == 54187 or bone == 46065 then
		damageboneself = _U('RightArm')
	elseif bone == 37873 or bone == 53675 then
		damageboneself = _U('LeftArm')
	elseif bone == 0 then
		damageboneself = "None"
	end
end)

RegisterNetEvent("legacy_medic:checkpartother")
AddEventHandler("legacy_medic:checkpartother", function(bone)
	if bone == 6884 or bone == 43312 then
		damagebone = _U('RightLeg')
	elseif bone == 65478 or bone == 55120 or bone == 45454 then
		damagebone = _U('LeftLeg')
	elseif bone == 14411 or bone == 14410 then
		damagebone = _U('Stomach')
	elseif bone == 14412 then
		damagebone = _U('Stomach_Chest')
	elseif bone == 14414 then
		damagebone = _U('Chest')
	elseif bone == 54187 or bone == 46065 then
		damagebone = _U('RightArm')
	elseif bone == 37873 or bone == 53675 then
		damagebone = _U('LeftArm')
	elseif bone == 0 then
		damagebone = "None"
	end
end)

RegisterNetEvent("legacy_medic:revive")
AddEventHandler("legacy_medic:revive", function()
	TriggerEvent('vorp:resurrectPlayer')
end)

RegisterNetEvent("legacy_medic:npcrevive")
AddEventHandler("legacy_medic:npcrevive", function()
	if Config.doctors.toHospital then
		TriggerEvent('vorp_core:respawnPlayer')
	else
		TriggerEvent('vorp:resurrectPlayer')
	end
end)

function DrawText3D(x, y, z, text)
	local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
	local px, py, pz = table.unpack(GetGameplayCamCoord())
	local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
	local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())
	if onScreen then
		SetTextScale(0.30, 0.30)
		SetTextFontForCurrentCommand(1)
		SetTextColor(255, 255, 255, 215)
		SetTextCentre(1)
		DisplayText(str, _x, _y)
		local factor = (string.len(text)) / 225
		DrawSprite("feeds", "hud_menu_4a", _x, _y + 0.0125, 0.015 + factor, 0.03, 0.1, 35, 35, 35, 190, 0)
	end
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

function GetClosestPlayer()
	local players, closestDistance, closestPlayer = GetActivePlayers(), -1, -1
	local playerPed, playerId = PlayerPedId(), PlayerId()
	local coords, usePlayerPed = coords, false

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		usePlayerPed = true
		coords = GetEntityCoords(playerPed)
	end

	for i = 1, #players, 1 do
		local tgt = GetPlayerPed(players[i])

		if not usePlayerPed or (usePlayerPed and players[i] ~= playerId) then
			local targetCoords = GetEntityCoords(tgt)
			local distance = #(coords - targetCoords)

			if closestDistance == -1 or closestDistance > distance then
				closestPlayer = players[i]
				closestDistance = distance
			end
		end
	end
	return closestPlayer, closestDistance
end

function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(500)
	end
end

function CheckTable(table, element) --Job checking table
	for k, v in pairs(table) do
		if v == element then
			return true
		end
	end
	return false
end