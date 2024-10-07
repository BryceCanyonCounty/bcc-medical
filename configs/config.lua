Config = {}

Config.devMode = false -- Allows Reload of script for development
-----------------------------------------------------

Config.defaultlang = 'en_lang'
-----------------------------------------------------

Config.keys = {
    usePrompt = 0xC7B5340A -- Enter
}
-----------------------------------------------------

-- Bleed Config
Config.bleedChance = 75          -- Chance of bleed (lower - easier, higher - harder)

Config.StopBleedOnRevive = true  -- Stops Player Bleeding on Revive
Config.StopBleedOnRespawn = true -- Stops Player Bleeding on Respawn

Config.restartBleedTime = 60      -- Time in minutes to Restart Bleed After Temp Healing with Bandage Item

Config.AnimOnBleed = true        -- should Player animate on bleed
-----------------------------------------------------

Config.PropCrafting = true      -- Set to false to disable prop-based crafting with the Doctor Bag item (will remove from menu)
Config.doctorBag = 'Doctor_Bag' -- Item name in database for Doctor Bag
-----------------------------------------------------

-- Supply Cabinet Config
Config.cabinet = {
    bandageItems = true, -- Enable Bandage Items in Cabinet
    reviveItems = true,  -- Enable Revive Items in Cabinet
    stitches = true,     -- Enable Stitches in Cabinet
}
-----------------------------------------------------

-- Translate `label` for Cabinet Menu
Config.BandageItems = {
    { item = 'Bandage', label = 'Bandage' },
    { item = 'Rags',    label = 'Rag' }
}

Config.ReviveItems = {
    { item = 'DocMorphine',   label = 'Morphine' },
    { item = 'SmellingSalts', label = 'Smelling Salts' }
}

Config.Stitches = {
    { item = 'NeedleandThread', label = 'Needle and Thread' }
}
-----------------------------------------------------

Config.usewebhook = true
Config.Webhook = ''
Config.WebhookTitle = 'Medic'
-----------------------------------------------------

Config.Command = 'medic' -- Slash command to use in chat to open Medic Menu
-----------------------------------------------------

Config.gonegative = false -- Can you go negative paying for NPC revival
-----------------------------------------------------

Config.synsociety = false
-----------------------------------------------------

MedicJobs = { -- Jobs that count as Doctors
    'doctor',
    'police',
    'shaman'
}
-----------------------------------------------------

-- NPC Doctor Config
Config.doctors = {
    ped = 'u_m_m_rhddoctor_01', -- Model of NPC Doctor or replace with other ped model below
    --am_valentinedoctors_females_01
    --cs_sddoctor_01
    --cs_creoledoctor
    --u_m_m_rhddoctor_01
    --u_m_m_valdoctor_01

    command = 'sendhelp', -- Command to Call for NPC Doctor
    currency = 0,         -- Currency for Revive from NPC Doctor / 0 = cash, 1 = gold
    amount = 45,          -- Currency Amount for Revive from NPC Doctor
    timer = 1,            -- How many minutes between calls
    toHospital = true     -- if true, player will be respawned to nearby hospital else will be revived on spot
}
-----------------------------------------------------

Config.MedicAssistant = true
Config.AssistantReviveMoney = 35
Config.AssistantHealMoney = 20
Config.MedicAssistantBlips = false
Config.MedicAssistantNPC = true
Config.MedicAssistantLocations = {
    {
        coords = vector3(-283.51, 807.64, 119.39), -- Valentine
        NpcHeading = 140.9,
        NpcModel = 'am_valentinedoctors_females_01'
    },
    {
        coords = vector3(-1802.9, -432.84, 158.83), -- Strawberry
        NpcHeading = 33.47,
        NpcModel = 'CS_SDDoctor_01'
    },
    {
        coords = vector3(-789.54, -1307.17, 43.8), -- Blackwater
        NpcHeading = 307.05,
        NpcModel = 'CS_SDDoctor_01'
    },
    {
        coords = vector3(1370.34, -1312.62, 77.94), -- Rhodes
        NpcHeading = 138.55,
        NpcModel = 'u_m_m_rhddoctor_01'
    },
    {
        coords = vector3(2722.21, -1234.15, 50.37), -- Saint Denis
        NpcHeading = 4.84,
        NpcModel = 'CS_SDDoctor_01'
    },
    {
        coords = vector3(2919.72, 1354.12, 44.83), -- Annesburg
        NpcHeading = 252.48,
        NpcModel = 'CS_SDDoctor_01'
    }
}
-----------------------------------------------------

Config.BlipColors = {
    LIGHT_BLUE    = 'BLIP_MODIFIER_MP_COLOR_1',
    DARK_RED      = 'BLIP_MODIFIER_MP_COLOR_2',
    PURPLE        = 'BLIP_MODIFIER_MP_COLOR_3',
    ORANGE        = 'BLIP_MODIFIER_MP_COLOR_4',
    TEAL          = 'BLIP_MODIFIER_MP_COLOR_5',
    LIGHT_YELLOW  = 'BLIP_MODIFIER_MP_COLOR_6',
    PINK          = 'BLIP_MODIFIER_MP_COLOR_7',
    GREEN         = 'BLIP_MODIFIER_MP_COLOR_8',
    DARK_TEAL     = 'BLIP_MODIFIER_MP_COLOR_9',
    RED           = 'BLIP_MODIFIER_MP_COLOR_10',
    LIGHT_GREEN   = 'BLIP_MODIFIER_MP_COLOR_11',
    TEAL2         = 'BLIP_MODIFIER_MP_COLOR_12',
    BLUE          = 'BLIP_MODIFIER_MP_COLOR_13',
    DARK_PUPLE    = 'BLIP_MODIFIER_MP_COLOR_14',
    DARK_PINK     = 'BLIP_MODIFIER_MP_COLOR_15',
    DARK_DARK_RED = 'BLIP_MODIFIER_MP_COLOR_16',
    GRAY          = 'BLIP_MODIFIER_MP_COLOR_17',
    PINKISH       = 'BLIP_MODIFIER_MP_COLOR_18',
    YELLOW_GREEN  = 'BLIP_MODIFIER_MP_COLOR_19',
    DARK_GREEN    = 'BLIP_MODIFIER_MP_COLOR_20',
    BRIGHT_BLUE   = 'BLIP_MODIFIER_MP_COLOR_21',
    BRIGHT_PURPLE = 'BLIP_MODIFIER_MP_COLOR_22',
    YELLOW_ORANGE = 'BLIP_MODIFIER_MP_COLOR_23',
    BLUE2         = 'BLIP_MODIFIER_MP_COLOR_24',
    TEAL3         = 'BLIP_MODIFIER_MP_COLOR_25',
    TAN           = 'BLIP_MODIFIER_MP_COLOR_26',
    OFF_WHITE     = 'BLIP_MODIFIER_MP_COLOR_27',
    LIGHT_YELLOW2 = 'BLIP_MODIFIER_MP_COLOR_28',
    LIGHT_PINK    = 'BLIP_MODIFIER_MP_COLOR_29',
    LIGHT_RED     = 'BLIP_MODIFIER_MP_COLOR_30',
    LIGHT_YELLOW3 = 'BLIP_MODIFIER_MP_COLOR_31',
    WHITE         = 'BLIP_MODIFIER_MP_COLOR_32'
}
