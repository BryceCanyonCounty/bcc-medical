local HealthCheck = false

function MedicMenu()
    local health = GetEntityHealth(PlayerPedId())
    local pulse = health / 4 + math.random(20, 30)
    local hit, bone = GetPedLastDamageBone(PlayerPedId())
    if DamageHash == nil then DamageHash = 'None' end

    local MedicMenuPage = BCCMedicalCabinetMenu:RegisterPage('doctor:menu:page')

    MedicMenuPage:RegisterElement('header', {
        value = _U('PlayerMenu'),
        slot = "header",
        style = {}
    })

    MedicMenuPage:RegisterElement('button', {
        label = _U('Pulse') .. pulse,
        style = {}
    })

    MedicMenuPage:RegisterElement('button', {
        label = _U('InjuredPart') .. DamageBoneSelf,
        style = {},
    }, function()
        if Config.devMode then
            print("Injured part button clicked.")
        end
        if not HealthCheck then
            HealthCheck = true
            hit, bone = GetPedLastDamageBone(PlayerPedId())
            if Config.devMode then
                print("Checking part for player.")
            end
            CheckPartSelf(bone)  -- Directly call the function instead of triggering an event
        else
            HealthCheck = false
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
    if Config.devMode then
        print("Opening MedicMenu page.")
    end
    BCCMedicalCabinetMenu:Open({
        startupPage = MedicMenuPage
    })
end

function DoctorMenu()
	local health = GetEntityHealth(PlayerPedId())
	local pulse = health / 4 + math.random(20, 30)
    local closestPlayer, closestDistance = GetClosestPlayer()
    local closestPlayerPed = GetPlayerPed(closestPlayer)
    local patientHealth = GetEntityHealth(closestPlayerPed)
    local patientPulse = patientHealth / 4 + math.random(20, 30)

    local closestHit, closestBone = GetPedLastDamageBone(closestPlayerPed)
    local hit, bone = GetPedLastDamageBone(PlayerPedId())
    if DamageHash == nil then DamageHash = 'None' end

    local DoctorMenuPage = BCCMedicalCabinetMenu:RegisterPage('doctor:menu:page')

    DoctorMenuPage:RegisterElement('header', {
        value = _U('DoctorMenu'),
        slot = "header",
        style = {}
    })

    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        if Config.devMode then
            print("Found closest player within range. Checking part other.")
        end
        CheckPartOther(closestBone)
        Wait(1000)
        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestInjury') .. DamageBone,
            style = {},
        }, function()
            if Config.devMode then
                print("Closest injury button clicked.")
            end
            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                if not HealthCheck then
                    HealthCheck = true
                    hit, closestBone = GetPedLastDamageBone(closestPlayerPed)
                    if Config.devMode then
                        print("Checking part other for closest bone.")
                    end
                    CheckPartOther(closestBone) -- Directly call the function instead of triggering an event
                else
                    HealthCheck = false
                end
            end
            DoctorMenu() -- Refresh or re-open the DoctorMenu
        end)

        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestInjuryDesc') .. DamageBone,
            style = {},
        })


        DoctorMenuPage:RegisterElement('button', {
            label = _U('ClosestWound') .. DamageHashCheck(),
            style = {}
        })

        DoctorMenuPage:RegisterElement('button', {
            label = _U('WoundDesc') .. DamageHashCheck(),
            style = {}
        })

        DoctorMenuPage:RegisterElement('textdisplay', {
            label = _U('PatientPulse') .. patientPulse,
            style = {}
        })
    end

    DoctorMenuPage:RegisterElement('button', {
        label = _U('ClosestWound') .. DamageHashCheck(),
        style = {},
    }, function()
        if Config.devMode then
            print("Injured part button clicked.")
        end
        if closestPlayer ~= -1 and closestDistance <= 3.0 then
            if not HealthCheck then
                HealthCheck = true
                hit, closestBone = GetPedLastDamageBone(closestPlayerPed)
                if Config.devMode then
                    print("Checking part other for closest bone.")
                end
                CheckPartOther(closestBone) -- Directly call the function instead of triggering an event
            else
                HealthCheck = false
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
        if Config.devMode then
            print("Back button clicked. Refreshing menu.")
        end
        DoctorMenu() -- Navigate back or refresh the menu
    end)

    DoctorMenuPage:RegisterElement('bottomline', {
        slot = 'footer',
        style = {}
    })

    -- Open the initial doctor menu
    if Config.devMode then
        print("Opening DoctorMenu page.")
    end
    BCCMedicalCabinetMenu:Open({
        startupPage = DoctorMenuPage
    })
end

function CabinetMenu()
    BCCMedicalCabinetMenu:Close() -- Ensure no other menus are open
    if Config.devMode then
        print("Closed existing menu.")
    end

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
        if Config.devMode then
            print("Stitch button clicked.")
        end
        ShowInputForItem(cabinetChoiceMenuPage, "Stitch", "NeedleandThread")
    end)

    -- Register buttons for Bandage Items
    for _, item in ipairs(Config.BandageItems) do
        cabinetChoiceMenuPage:RegisterElement('button', {
            label = item:sub(1, 1):upper() .. item:sub(2),
            style = {}
        }, function()
            if Config.devMode then
                print(item .. " button clicked.")
            end
            ShowInputForItem(cabinetChoiceMenuPage, item, item)
        end)
    end

    -- Register buttons for Revive Items
    for _, item in ipairs(Config.ReviveItems) do
        cabinetChoiceMenuPage:RegisterElement('button', {
            label = item:sub(1, 1):upper() .. item:sub(2),
            style = {}
        }, function()
            if Config.devMode then
                print(item .. " button clicked.")
            end
            ShowInputForItem(cabinetChoiceMenuPage, item, item)
        end)
    end

    -- Button for Doctor Bag
    cabinetChoiceMenuPage:RegisterElement('button', {
        label = "Doctor Bag"
    }, function()
        if Config.devMode then
            print("Doctor Bag button clicked.")
        end
        TriggerServerEvent('bcc-medical:TakeItem', "Doctor_Bag", 1)
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
        if Config.devMode then
            print("Close button clicked. Closing menu.")
        end
        BCCMedicalCabinetMenu:Close()
    end)

    cabinetChoiceMenuPage:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    -- Open the cabinet choice menu
    if Config.devMode then
        print("Opening cabinet choice menu.")
    end
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
        if Config.devMode then
            print("Input received: " .. currentInputValue)
        end
    end)

    inputPage:RegisterElement('button', {
        label = "Submit",
        slot = "footer",
        style = {}
    }, function()
        local amount = tonumber(currentInputValue) -- Proper conversion to number
        if amount and amount > 0 then
            if Config.devMode then
                print("Amount entered for " .. itemLabel .. ": " .. amount)
            end
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
        if Config.devMode then
            print("Back button clicked. Returning to cabinet menu.")
        end
        CabinetMenu() -- Navigate back
    end)

    if Config.devMode then
        print("Opening input page for item: " .. itemLabel)
    end
    BCCMedicalCabinetMenu:Open({
        startupPage = inputPage
    })
end