Config = {
    devMode = false,-- Allows Reload of script for development

    defaultlang = 'en_lang',
    bleedChance = 85, -- Chance of bleed (lower - easier, higher - harder)
    StopBleedOnRevive = true, -- Stops Player Bleeding on Revive
    -- Used in case of temp bleed stop (Not yet Implemented)
    EnableBleedAfter = 0,

    BandageItems = { 
        'Bandage', 
        'Rags' 
    },
    ReviveItems = {
        'DocMorphine',
        'SmellingSalts'
    },

    Stitches = 'NeedleandThread', -- Can change to an equivalent item in your database or run the items.sql, icon in items folder, remember case sensitive
    usewebhook = true,
    Webhook = '',
    WebhookTitle = 'Bcc-Medic',

    Command = 'medic', -- Slash command to use in chat to open Medic Menu
    gonegative = true, -- Can you go negative paying for NPC revival
    synsociety = false,

    Doctoroffices = {
        val = {
            Pos = { x = -288.72, y = 808.83, z = 119.39 } -- location
        },
        bw = {
            Pos = { x = -785.76, y = -1302.8, z = 43.81 } -- location
        },
        straw = {
            Pos = { x = -1807.87, y = -430.77, z = 158.83 } -- location
        },
        stdenis = {
            Pos = { x = 2722.84, y = -1229.48, z = 50.37 } -- location
        },
        rhodes = {
            Pos = { x = 1372.43, y = -1305.73, z = 77.97 } -- location
        },
        annesburg = {
            Pos = { x = 2923.1, y = 1356.58, z = 44.83 } -- location
        },
    },
	keys = {
		sell = 0xCEFD9220,  -- [E] Open Shop Menu
		buy = 0x760A9C6F,   -- [G] Options
	},

    MedicJobs = { "doctor", "police", "shaman" },

    doctors = {
        ped = "u_m_m_rhddoctor_01", -- Model of NPC Doctor or choose other ped model below
        -- am_valentinedoctors_females_01
        -- cs_sddoctor_01
        -- cs_creoledoctor
        -- u_m_m_rhddoctor_01
        -- u_m_m_valdoctor_01

        command = "sendhelp", -- Command to Call for NPC Doctor
        amount = 45,            -- Payment for Revive from NPC Doctor
        timer = 60000 * 1       -- put how many minutes you'd like ie 60000 * 5 for 5 minutes
    },
    
    alertPermissions = {
        ["medicalEmergency"] = {
            allowedJobs = {
                doctor = { minGrade = 1, maxGrade = 5 },    -- Doctors of grade 1 to 5
            },
            blipSettings = {
                blipLabel = "Medical Emergency",
                blipSprite = 'blip_ambient_companion', -- Actual sprite name or hash
                blipScale = 1.0,
                blipColor = 1,
                blipDuration = 60000,    -- Time in milliseconds
                gpsRouteDuration = 30000 -- Time in milliseconds for GPS route
            }
        },
    }
}
