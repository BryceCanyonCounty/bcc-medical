local healthcheck = false
local createdped = 0
local damagebone = _U('None')
local damageboneself = _U('None')
local Playerjob
local inmenu = false
local iscalled = false
local DamageHash = nil
local globalBlip = nil
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local CreatedBlip = {}
local CreatedNPC = {}

-- Function to Setup Use Prompt
function SetupUsePrompt()
    local str = 'Use'
    UsePrompt = PromptRegisterBegin()
    PromptSetControlAction(UsePrompt, 0xC7B5340A)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(UsePrompt, str)
    PromptSetEnabled(UsePrompt, true)
    PromptSetVisible(UsePrompt, true)
    PromptSetStandardMode(UsePrompt, 1)
    PromptSetGroup(UsePrompt, PromptGroup)
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
    -- Create blips for doctor offices in Doctoroffices
    for k, v in pairs(Config.Doctoroffices) do
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.Pos.x, v.Pos.y, v.Pos.z)
        SetBlipSprite(blip, -695368421, 1)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, _U('Map_Blip'))
    end

    while true do
        Wait(1)
        local ped = PlayerPedId()
        local pedpos = GetEntityCoords(ped, true)
        local isDead = IsEntityDead(ped)

        -- Check distance to doctor offices for interaction in Doctoroffices
        for k, v in pairs(Config.Doctoroffices) do
            local distance = GetDistanceBetweenCoords(v.Pos.x, v.Pos.y, v.Pos.z, pedpos.x, pedpos.y, pedpos.z, false)
            if distance < 1.5 and not isDead and not inmenu then
                local item_name = CreateVarString(10, 'LITERAL_STRING', _U('Open_Cabinet'))
                PromptSetActiveGroupThisFrame(PromptGroup, item_name)
                if Citizen.InvokeNative(0xC92AC953F0A982AE, UsePrompt) then
                    TriggerServerEvent('legacy_medic:checkjob')
                    Wait(2000)
                    if CheckTable(Config.MedicJobs, Playerjob) then
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

function RevivePlayer(playerPed)
    local closestPlayerPed = GetPlayerPed(playerPed)
    if IsPedDeadOrDying(closestPlayerPed, 1) then
        local dic = "mech_revive@unapproved"
        local anim = "revive"
        loadAnimDict(dic)
        TaskPlayAnim(PlayerPedId(), dic, anim, 1.0, 8.0, 2000, 31, 0, true, true, false, false, true)
        Wait(2000)
        ClearPedTasksImmediately(PlayerPedId())
        TriggerServerEvent('legacy_medic:reviveclosestplayer', GetPlayerServerId(playerPed))
    else
        VORPcore.NotifyRightTip(_U('player_not_unconscious'), 4000)
    end
end

function SpawnNPC(coords)
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
AddEventHandler('legacy_medic:finddoc', function(coords)
    if IsEntityDead(PlayerPedId()) then
        VORPcore.NotifyRightTip(_U('calldoctor'), 4000)
        SpawnNPC(coords)
    else
        VORPcore.NotifyRightTip(_U('notdead'), 4000)
    end
end)

RegisterNetEvent('legacy_medic:getclosestplayerrevive', function()
    local closestPlayer, closestDistance = GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 1.5 then
        RevivePlayer(closestPlayer)
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
    if CheckTable(Config.MedicJobs, Playerjob) then
        DoctorMenu()
    else
        MedicMenu()
    end
end, false)

-- Register the /callDoctor command
RegisterCommand(Config.doctors.command, function()
    if not iscalled then
        iscalled = true
        TriggerServerEvent("legacy_medicalertjobs")  -- Notify the server
        Wait(Config.doctors.timer)
        iscalled = false
    else
        VORPcore.NotifyRightTip(_U('cooldown'), 4000)
    end
end, false) -- The 'false' parameter indicates that the command is not restricted

RegisterNetEvent('vorp:SelectedCharacter', function()
    local player = GetPlayerServerId(tonumber(PlayerId()))
    Wait(100)
    TriggerServerEvent("legacy_medic:sendPlayers", player)
    
    CreateThread(function()
        while true do
            Wait(1000 * 20) -- Wait for 20 seconds
            TriggerServerEvent('legacy_medic:CheckBleed')
            Wait(250)
			if IsBleeding == 1 and Config.AnimOnBleed then
                Citizen.InvokeNative(0x835F131E7DC8F97A, PlayerPedId(), -25.00, 0, GetHashKey("weapon_bleeding"))
                if not IsEntityPlayingAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 3) then
                    RequestAnimDict('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a')
                    while not HasAnimDictLoaded('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a') do
                        Citizen.Wait(100)
                    end
                    TaskPlayAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 5.0, 1.0, 4000, 31, 0, false, false, false)
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
					TaskPlayAnim(PlayerPedId(), "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 5.0, 1.0, 4000, 31, 0, false, false, false)
				end
			end
		end
	end)

    RegisterCommand("dmgtest", function(source, args)
        local cl = PlayerPedId()
        Citizen.InvokeNative(0x835F131E7DC8F97A, cl, -10.00, 0, GetHashKey("weapon_pistol_mauser"))
        -- Check if the player is playing an animation
        if not IsEntityPlayingAnim(cl, "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 3) then
            print("Requesting animation dictionary: amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a")
            RequestAnimDict('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a')

            -- Wait for the animation dictionary to load
            while not HasAnimDictLoaded('amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a') do
                print("Waiting for animation dictionary to load...")
                Citizen.Wait(100)
            end

            -- Play the animation
            print("Playing animation: idle_b from amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a")
            TaskPlayAnim(cl, "amb_wander@upperbody_idles@sick@both_arms@male_a@idle_a", "idle_b", 5.0, 1.0, 4000, 31, 0,
                false, false, false)
        else
            print("Player is already playing the animation.")
        end
    end, false)
end

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



function MedicMenu()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local pulse = health / 4 + math.random(20, 30)
    local hit, bone = GetPedLastDamageBone(PlayerPedId())
    if DamageHash == nil then DamageHash = 'None' end

    local MedicMenuPage = BCCMedicalCabinetMenu:RegisterPage('doctor:menu:page')

    MedicMenuPage:RegisterElement('header', {
        value = _U('MedicMenu'),
        slot = "header",
        style = {}
    })

    MedicMenuPage:RegisterElement('button', {
        label = _U('Pulse') .. pulse,
        style = {}
    })

    MedicMenuPage:RegisterElement('button', {
        label = _U('InjuredPart') .. damageboneself,
        style = {},
    }, function()
        print("Injured part button clicked.")
        if not healthcheck then
            healthcheck = true
            hit, bone = GetPedLastDamageBone(PlayerPedId())
            print("Checking part for player.")
            CheckPartSelf(bone)  -- Directly call the function instead of triggering an event
        else
            healthcheck = false
        end
        MedicMenu()  -- Refresh or re-open the MedicMenu
    end)

    MedicMenuPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    MedicMenuPage:RegisterElement('button', {
        label = "Back",
        slot = 'footer',
        style = {}
    })

    MedicMenuPage:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })

    -- Open the initial doctor menu
    print("Opening MedicMenu page.")
    BCCMedicalCabinetMenu:Open({
        startupPage = MedicMenuPage
    })
end

function DoctorMenu() -- Base Police Menu Logic
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

    local DoctorMenuPage = BCCMedicalCabinetMenu:RegisterPage('doctor:menu:page')

    DoctorMenuPage:RegisterElement('header', {
        value = _U('MedicMenu'),
        slot = "header",
        style = {}
    })

    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        print("Found closest player within range. Checking part other.")
        CheckPartOther(closestbone)
        Wait(1000)
        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestInjury') .. damagebone,
            style = {},
        }, function()
            print("Closest injury button clicked.")
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                if not healthcheck then
                    healthcheck = true
                    hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
                    print("Checking part other for closest bone.")
                    CheckPartOther(closestbone) -- Directly call the function instead of triggering an event
                else
                    healthcheck = false
                end
            end
            DoctorMenu() -- Refresh or re-open the DoctorMenu
        end)

        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestInjuryDesc') .. damagebone,
            style = {},
        })


        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestWound') .. DamageHashCheck(DamageHash),
            style = {}
        })

        DoctorMenuPage:RegisterElement('button', {
            label = _U('WoundDesc') .. DamageHashCheck(DamageHash),
            style = {}
        })

        DoctorMenuPage:RegisterElement('textdisplay', {
            label = _U('PatientPulse') .. patientpulse,
            style = {}
        })
    end

    DoctorMenuPage:RegisterElement('button', {
        label = _U('ClosestWound') .. DamageHashCheck(DamageHash),
        style = {},
    }, function()
        print("Injured part button clicked.")
        if closestPlayer ~= -1 and closestDistance <= 3.0 then
            if not healthcheck then
                healthcheck = true
                hit, closestbone = GetPedLastDamageBone(closestPlayerPed)
                print("Checking part other for closest bone.")
                CheckPartOther(closestbone) -- Directly call the function instead of triggering an event
            else
                healthcheck = false
            end
        end
        DoctorMenu() -- Refresh or re-open the DoctorMenu
    end)

    -- Add specific injury details
    DoctorMenuPage:RegisterElement('button', {
        label = _U('ClosestInjury') .. ": " .. (bone or _U('None')),
        style = {}
    })

    DoctorMenuPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    DoctorMenuPage:RegisterElement('button', {
        label = 'Back',
        slot = 'footer',
        style = {}
    }, function()
        print("Back button clicked. Refreshing menu.")
        DoctorMenu() -- Navigate back or refresh the menu
    end)

    DoctorMenuPage:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })

    -- Open the initial doctor menu
    print("Opening DoctorMenu page.")
    BCCMedicalCabinetMenu:Open({
        startupPage = DoctorMenuPage
    })
end

function CabinetMenu() -- Base Police Menu Logic
    BCCMedicalCabinetMenu:Close() -- Ensure no other menus are open
    print("Closed existing menu.")

    -- Initialize the cabinet choice menu page
    local cabinetChoiceMenuPage = BCCMedicalCabinetMenu:RegisterPage('cabinet_choice_page')

    cabinetChoiceMenuPage:RegisterElement('header', {
        value = _U('CabinetMenu'),
        slot = "header",
        style = {}
    })

    cabinetChoiceMenuPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    -- Button for initiating the stitch input
    cabinetChoiceMenuPage:RegisterElement('button', {
        label = _U('Stitch')
    }, function()
        print("Stitch button clicked.")
        ShowInputForItem(cabinetChoiceMenuPage, "Stitch", "NeedleandThread")
    end)

    -- Register buttons for Bandage Items
    for _, item in ipairs(Config.BandageItems) do
        cabinetChoiceMenuPage:RegisterElement('button', {
            label = item:sub(1, 1):upper() .. item:sub(2),
            style = {}
        }, function()
            print(item .. " button clicked.")
            ShowInputForItem(cabinetChoiceMenuPage, item, item)
        end)
    end

    -- Register buttons for Revive Items
    for _, item in ipairs(Config.ReviveItems) do
        cabinetChoiceMenuPage:RegisterElement('button', {
            label = item:sub(1, 1):upper() .. item:sub(2),
            style = {}
        }, function()
            print(item .. " button clicked.")
            ShowInputForItem(cabinetChoiceMenuPage, item, item)
        end)
    end

    -- Button for Doctor Bag
    cabinetChoiceMenuPage:RegisterElement('button', {
        label = "Doctor Bag"
    }, function()
        print("Doctor Bag button clicked.")
        TriggerServerEvent('legacy_medic:takeitem', "Doctor_Bag", 1)
    end)

    cabinetChoiceMenuPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    -- Register a back or close button on the menu
    cabinetChoiceMenuPage:RegisterElement('button', {
        label = "Close",
        slot = "footer",
        style = {}
    }, function()
        print("Close button clicked. Closing menu.")
        BCCMedicalCabinetMenu:Close()
    end)

    cabinetChoiceMenuPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    -- Open the cabinet choice menu
    print("Opening cabinet choice menu.")
    BCCMedicalCabinetMenu:Open({
        startupPage = cabinetChoiceMenuPage
    })
end

function ShowInputForItem(page, itemLabel, serverItemName)
    local inputPage = BCCMedicalCabinetMenu:RegisterPage('entry:quantity')

    local currentInputValue = nil -- To hold the input value as a string initially

    inputPage:RegisterElement('header', {
        value = itemLabel,
        slot = "header",
        style = {}
    })

    inputPage:RegisterElement('input', {
        label = "Enter Amount for " .. itemLabel,
        placeholder = "Enter amount...",
        style = {}
    }, function(data)
        currentInputValue = data.value -- Direct assignment as string
        print("Input received: " .. currentInputValue)
    end)

    inputPage:RegisterElement('button', {
        label = "Submit",
        slot = "footer",
        style = {}
    }, function()
        local amount = tonumber(currentInputValue) -- Proper conversion to number
        if amount and amount > 0 then
            print("Amount entered for " .. itemLabel .. ": " .. amount)
            TriggerServerEvent('legacy_medic:takeitem', serverItemName, amount)
            CabinetMenu()
        else
            print("Invalid input. Please enter a numeric value.")
        end
    end)

    inputPage:RegisterElement('button', {
        label = "Back",
        slot = "footer",
        style = {}
    }, function()
        print("Back button clicked. Returning to cabinet menu.")
        CabinetMenu() -- Navigate back
    end)

    print("Opening input page for item: " .. itemLabel)
    BCCMedicalCabinetMenu:Open({
        startupPage = inputPage
    })
end

-- Function to check part and set damageboneself based on the bone parameter
function CheckPartSelf(bone)
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
end

-- Function to check part and set damagebone based on the bone parameter
function CheckPartOther(bone)
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
end

RegisterNetEvent("legacy_medic:revive")
AddEventHandler("legacy_medic:revive", function()
    TriggerEvent('vorp:resurrectPlayer', source)
end)

RegisterNetEvent("legacy_medic:npcrevive")
AddEventHandler("legacy_medic:npcrevive", function()
	if Config.doctors.toHospital then
		TriggerEvent('vorp_core:respawnPlayer')
	else
		TriggerEvent('vorp:resurrectPlayer')
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

RegisterNetEvent('bcc-medical:notify')
AddEventHandler('bcc-medical:notify', function(data)
    --clientDebugPrint("Received notification: " .. data.message)

    -- Displaying the notification using VORP core method
    VORPcore.NotifyLeft(data.message, "", "scoretimer_textures", "scoretimer_generic_cross", 5000)

    -- Handling blip setup
    if data.x and data.y and data.z then
        if globalBlip then
            BccUtils.Blips:RemoveBlip(globalBlip.rawblip) -- Cleanup any existing blip
        end

        globalBlip = BccUtils.Blips:SetBlip(data.blipLabel, data.blipSprite, data.blipScale, data.x, data.y, data.z)
        SetTimeout(data.blipDuration, function()
            BccUtils.Blips:RemoveBlip(globalBlip.rawblip)
            globalBlip = nil -- Reset the global blip reference
        end)

        -- GPS route setup if required
        if data.useGpsRoute then
            StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
            AddPointToGpsMultiRoute(data.x, data.y, data.z)
            SetGpsMultiRouteRender(true)

            -- Set a timeout to clear the GPS route after a specified duration
            SetTimeout(data.gpsRouteDuration or data.blipDuration, function()
                ClearGpsMultiRoute() -- This will clear the GPS route
                SetGpsMultiRouteRender(false) -- Ensure it's no longer rendered on the map
                --clientDebugPrint("GPS route cleared.")
            end)
        end
    end
end)
