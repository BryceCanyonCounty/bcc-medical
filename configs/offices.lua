-- Doctors Offices
Offices = {
    valentine = {
        office = {
            prompt = 'Valentine Doctors Office',         -- Text Below Cabinet Prompt
            location = vector3(-288.72, 808.83, 119.39), -- Location of Doctors Office
            distance = 1.5,                              -- Distance Between Player and Supply Cabinet to Show Prompt
            hours = {
                active = false,                          -- Office uses Open and Closed Hours
                open = 7,                                -- Office Open Time / 24 Hour Clock
                close = 21                               -- Office Close Time / 24 Hour Clock
            }
        },
        blip = {
            show = true,             -- Show Blip On Map
            showClosed = true,       -- Show Blip On Map when Closed (if true, 'show' must be true)
            name = 'Doctors Office', -- Name of Blip on Map
            sprite = -695368421,     -- Medical Icon
            color = {
                open = 'WHITE',      -- Office Open - Default: White - Blip Colors Shown in Main Config
                closed = 'RED',      -- Office Closed - Deafault: Red - Blip Colors Shown in Main Config
            },
        },
        menu = {
            header = 'Medical',                      -- Header of Supply Cabinet Menu
            subHeader = 'Supply Cabinet',            -- Sub Header of Supply Cabinet Menu
        },
    },
    -----------------------------------------------------

    blackwater = {
        office = {
            prompt = 'Blackwater Doctors Office',
            location = vector3(-807.85, -1239.01, 43.56),
            distance = 1.5,
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Doctors Office',
            sprite = -695368421,
            color = {
                open = 'WHITE',
                closed = 'RED',
            },
        },
        menu = {
            header = 'Medical',
            subHeader = 'Supply Cabinet',
        },
    },
    -----------------------------------------------------

    strawberry = {
        office = {
            prompt = 'Strawberry Doctors Office',
            location = vector3(-1807.87, -430.77, 158.83),
            distance = 1.5,
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Doctors Office',
            sprite = -695368421,
            color = {
                open = 'WHITE',
                closed = 'RED',
            },
        },
        menu = {
            header = 'Medical',
            subHeader = 'Supply Cabinet',
        },
    },
    -----------------------------------------------------

    stdenis = {
        office = {
            prompt = 'St. Denis Doctors Office',
            location = vector3(2722.84, -1229.48, 50.37),
            distance = 1.5,
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Doctors Office',
            sprite = -695368421,
            color = {
                open = 'WHITE',
                closed = 'RED',
            },
        },
        menu = {
            header = 'Medical',
            subHeader = 'Supply Cabinet',
        },
    },
    -----------------------------------------------------

    rhodes = {
        office = {
            prompt = 'Rhodes Doctors Office',
            location = vector3(1372.43, -1305.73, 77.97),
            distance = 1.5,
            hours = {
                active = false,
                open = 7,
                close = 21
            }
        },
        blip = {
            show = true,
            showClosed = true,
            name = 'Doctors Office',
            sprite = -695368421,
            color = {
                open = 'WHITE',
                closed = 'RED',
            },
        },
        menu = {
            header = 'Medical',
            subHeader = 'Supply Cabinet',
        },
    },
}
