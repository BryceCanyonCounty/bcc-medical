local RefreshMenu = false

function OpenPlayerMenu()
    local playerPed = PlayerPedId()
    local health = GetEntityHealth(playerPed)
    local pulse = math.floor((health * 0.1) + (math.random(15, 20)))
    local bool, bone = GetPedLastDamageBone(playerPed)

    -- Check if the player is bleeding
    local bleeding = 'No'
    local isBleeding = PlayerBleedCheck()
    if isBleeding then
        bleeding = 'Yes'
    end

    local PlayerMenu = MedicalMenu:RegisterPage('player:menu:page')

    PlayerMenu:RegisterElement('header', {
        value = _U('PlayerMenu'),
        slot = 'header',
        style = {
            ['color'] = '#999'
        }
    })

    PlayerMenu:RegisterElement('subheader', {
        value = _U('myStats'),
        slot = 'header',
        style = {
            ['font-size'] = '0.94vw',
            ['color'] = '#CC9900'
        }
    })

    PlayerMenu:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    -- Display my pulse
    PlayerMenu:RegisterElement('button', {
        label = _U('Pulse') .. tostring(pulse),
        style = {
            ['color'] = '#E0E0E0'
        }
    })

    local damageBone = nil
    damageBone = CheckPart(bone)
    while not damageBone do
        Wait(5)
    end

    local damageLabel = _U('lastInjury')
    if bleeding == 'Yes' then
        damageLabel = _U('Injury')
    end

    -- Display the injured part and wound type
    PlayerMenu:RegisterElement('button', {
        label = damageLabel .. damageBone,
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    local woundLabel = _U('lastWound')
    if bleeding == 'Yes' then
        woundLabel = _U('Wound')
    end

    PlayerMenu:RegisterElement('button', {
        label = woundLabel .. DamageHashCheck(nil),
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    PlayerMenu:RegisterElement('button', {
        label = _U('bleeding') .. bleeding,
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    PlayerMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Refresh menu stats
    PlayerMenu:RegisterElement('button', {
        label = 'Refresh',
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        if not RefreshMenu then
            RefreshMenu = true
            OpenPlayerMenu()
            if Config.devMode then
                print('Refresh button clicked. Refreshing menu.')
            end
        else
            RefreshMenu = false
        end
    end)

    PlayerMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Open the initial player menu
    if Config.devMode then
        print('Opening PlayerMenu page.')
    end
    MedicalMenu:Open({
        startupPage = PlayerMenu
    })
end

function OpenDoctorMenu()
    local closestPlayer, closestDistance = GetClosestPlayer()
    local closestPlayerPed = GetPlayerPed(closestPlayer)
    local health = GetEntityHealth(closestPlayerPed)
    local pulse = math.floor((health * 0.1) + (math.random(15, 20)))
    local bool, bone = GetPedLastDamageBone(closestPlayerPed)

    -- Check if the patient is bleeding
    local bleeding = 'No'
    local isBleeding = PatientBleedCheck(GetPlayerServerId(closestPlayer))
    if isBleeding then
        bleeding = 'Yes'
    end

    local DoctorMenu = MedicalMenu:RegisterPage('doctor:menu:page')

    DoctorMenu:RegisterElement('header', {
        value = _U('DoctorMenu'),
        slot = 'header',
        style = {
            ['color'] = '#999'
        }
    })

    DoctorMenu:RegisterElement('subheader', {
        value = _U('patientStats'),
        slot = 'header',
        style = {
            ['font-size'] = '0.9vw',
            ['color'] = '#CC9900'
        }
    })

    DoctorMenu:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    -- Display patient pulse
    DoctorMenu:RegisterElement('button', {
        label = _U('Pulse') .. tostring(pulse),
        style = {
            ['color'] = '#E0E0E0'
        }
    })

    local damageBone = nil
    damageBone = CheckPart(bone)
    while not damageBone do
        Wait(5)
    end

    local damageLabel = _U('lastInjury')
    if bleeding == 'Yes' then
        damageLabel = _U('Injury')
    end

    -- Display patients injured part and wound type
    DoctorMenu:RegisterElement('button', {
        label = damageLabel .. damageBone,
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    local damageHash = Entity(closestPlayerPed).state.damageHash
    local damageType = nil
    damageType = DamageHashCheck(damageHash)
    while not damageType do
        Wait(5)
    end

    local woundLabel = _U('lastWound')
    if bleeding == 'Yes' then
        woundLabel = _U('Wound')
    end

    DoctorMenu:RegisterElement('button', {
        label = woundLabel .. damageType,
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    DoctorMenu:RegisterElement('button', {
        label = _U('bleeding') .. bleeding,
        style = {
            ['color'] = '#E0E0E0'
        },
    })

    DoctorMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Refresh menu stats
    DoctorMenu:RegisterElement('button', {
        label = 'Refresh',
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        if not RefreshMenu then
            RefreshMenu = true
            OpenDoctorMenu()
            if Config.devMode then
                print('Refresh button clicked. Refreshing menu.')
            end
        else
            RefreshMenu = false
        end
    end)

    DoctorMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Open the initial doctor menu
    if Config.devMode then
        print('Opening DoctorMenu page.')
    end
    MedicalMenu:Open({
        startupPage = DoctorMenu
    })
end

function OpenCabinetMenu(menuCfg)
    if Config.devMode then
        print('Closed existing menu.')
    end

    -- Initialize the cabinet choice menu page
    local CabinetMenu = MedicalMenu:RegisterPage('cabinet_choice_page')

    CabinetMenu:RegisterElement('header', {
        value = menuCfg.header,
        slot = 'header',
        style = {
            ['color'] = '#999'
        }
    })

    CabinetMenu:RegisterElement('subheader', {
        value = menuCfg.subHeader,
        slot = 'header',
        style = {
            ['font-size'] = '0.9vw',
            ['color'] = '#CC9900'
        }
    })

    CabinetMenu:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    -- Button for initiating the stitch input
    if Config.cabinet.stitches then
        for _, itemCfg in pairs(Config.Stitches) do
            CabinetMenu:RegisterElement('button', {
                label = itemCfg.label:sub(1, 1):upper() .. itemCfg.label:sub(2),
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                if Config.devMode then
                    print(itemCfg.label .. ' button clicked.')
                end
                ShowInputForItem(menuCfg, itemCfg.label, itemCfg.item)
            end)
        end
    end

    -- Register buttons for Bandage Items
    if Config.cabinet.bandageItems then
        for _, itemCfg in pairs(Config.BandageItems) do
            CabinetMenu:RegisterElement('button', {
                label = itemCfg.label:sub(1, 1):upper() .. itemCfg.label:sub(2),
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                if Config.devMode then
                    print(itemCfg.label .. ' button clicked.')
                end
                ShowInputForItem(menuCfg, itemCfg.label, itemCfg.item)
            end)
        end
    end

    -- Register buttons for Revive Items
    if Config.cabinet.reviveItems then
        for _, itemCfg in pairs(Config.ReviveItems) do
            CabinetMenu:RegisterElement('button', {
                label = itemCfg.label:sub(1, 1):upper() .. itemCfg.label:sub(2),
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                if Config.devMode then
                    print(itemCfg.label .. ' button clicked.')
                end
                ShowInputForItem(menuCfg, itemCfg.label, itemCfg.item)
            end)
        end
    end

    -- Button for Doctor Bag
    if Config.PropCrafting then
        CabinetMenu:RegisterElement('button', {
            label = _U('doctorBag'),
            style = {
                ['color'] = '#E0E0E0'
            }
        }, function()
            if Config.devMode then
                print('Doctor Bag button clicked.')
            end
            TriggerServerEvent('bcc-medical:TakeItem', _U('doctorBag'), Config.doctorBag, 1)
        end)
    end

    CabinetMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Register close button on the menu
    CabinetMenu:RegisterElement('button', {
        label = _U('close'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        if Config.devMode then
            print('Close button clicked. Closing menu.')
        end
        MedicalMenu:Close()
    end)

    CabinetMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Open the cabinet choice menu
    if Config.devMode then
        print('Opening cabinet choice menu.')
    end
    MedicalMenu:Open({
        startupPage = CabinetMenu
    })
end

function ShowInputForItem(menuCfg, itemLabel, serverItemName)
    local currentInputValue = nil -- To hold the input value as a string initially

    local inputPage = MedicalMenu:RegisterPage('entry:quantity')

    inputPage:RegisterElement('header', {
        value = menuCfg.header,
        slot = 'header',
        style = {
            ['color'] = '#999'
        }
    })

    inputPage:RegisterElement('subheader', {
        value = itemLabel,
        slot = 'header',
        style = {
            ['font-size'] = '0.9vw',
            ['color'] = '#CC9900'
        }
    })

    inputPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    inputPage:RegisterElement('input', {
        label = _U('quantity'),
        placeholder = _U('placeholder'),
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function(data)
        currentInputValue = data.value -- Direct assignment as string
        if Config.devMode then
            print('Input received: ' .. currentInputValue)
        end
    end)

    inputPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    inputPage:RegisterElement('button', {
        label = _U('submit'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        local amount = tonumber(currentInputValue) -- Proper conversion to number
        if amount and amount > 0 then
            if Config.devMode then
                print('Amount entered for ' .. itemLabel .. ': ' .. amount)
            end
            TriggerServerEvent('bcc-medical:TakeItem', itemLabel, serverItemName, amount)
            OpenCabinetMenu(menuCfg)
        else
            print('Invalid input. Please enter a numeric value.')
        end
    end)

    inputPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        if Config.devMode then
            print('Back button clicked. Returning to cabinet menu.')
        end
        OpenCabinetMenu(menuCfg) -- Navigate back
    end)

    inputPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    if Config.devMode then
        print('Opening input page for item: ' .. itemLabel)
    end
    MedicalMenu:Open({
        startupPage = inputPage
    })
end