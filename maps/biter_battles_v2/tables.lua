local GUI_VARIANTS = require('utils.utils').GUI_VARIANTS

local Public = {}

-- List of forces that will be affected by ammo modifier
Public.ammo_modified_forces_list = { 'north', 'south', 'spectator' }

-- Ammo modifiers via set_ammo_damage_modifier
-- [ammo_category] = value
-- ammo_modifier_dmg = base_damage * base_ammo_modifiers
-- damage = base_damage + ammo_modifier_dmg
Public.base_ammo_modifiers = {
    ['bullet'] = 0.16,
    ['shotgun-shell'] = 1,
    ['flamethrower'] = -0.6,
    ['landmine'] = -0.9,
}

-- turret attack modifier via set_turret_attack_modifier
Public.base_turret_attack_modifiers = {
    ['flamethrower-turret'] = -0.8,
    ['laser-turret'] = 0.0,
}

Public.upgrade_modifiers = {
    ['flamethrower'] = 0.02,
    ['flamethrower-turret'] = 0.02,
    ['laser-turret'] = 0.3,
    ['shotgun-shell'] = 0.6,
    ['grenade'] = 0.48,
    ['landmine'] = 0.04,
}

Public.food_values = {
    ["firearm-magazine"] = {value = 0.00055, name = "yellow ammo", color = "255, 50, 50"},
    ["piercing-rounds-magazine"] = {value = 0.0024, name = "red ammo", color = "105, 105, 105"},
    ["stone-wall"] = {value = 0.0013, name = "wall", color = "50, 255, 50"},
    ["gate"] = {value = 0.0115, name = "gates", color = "100, 200, 255"},
    ["gun-turret"] = {value = 0.0105, name = "gun turret", color = "150, 25, 255"},
    ["defender-capsule"] = {value = 0.0500, name = "capsule bot", color = "210, 210, 60"},
    ["flamethrower-ammo"] = {value = 0.0800, name = "flamer ammo", color = "255, 255, 255"},
}

Public.gui_foods = {}
Public.food_value_table_version = {}
Public.food_long_and_short = {}
Public.food_long_to_short = {}
for k, v in pairs(Public.food_values) do
    Public.gui_foods[k] = math.floor(v.value * 10000) .. ' Mutagen strength'
    table.insert(Public.food_value_table_version, v.value)
    table.insert(Public.food_long_and_short, {short_name = v.name, long_name = k})
    Public.food_long_to_short[k] = {short_name = v.name, indexScience = #Public.food_value_table_version}
end
Public.gui_foods['raw-fish'] =
    'Send a fish to spy for 45 seconds.\nLeft Mouse Button: Send one fish.\nRMB: Sends 5 fish.\nShift+LMB: Send all fish.\nShift+RMB: Send half of all fish.'

Public.force_translation = {
    ['south_biters'] = 'south',
    ['north_biters'] = 'north',
}

Public.enemy_team_of = {
    ['north'] = 'south',
    ['south'] = 'north',
}

-- This array contains parameters for spawn area ore patches.
-- These are non-standard units and they do not map to values used in factorio
-- map generation. They are only used internally by scenario logic.
Public.spawn_ore = {
    -- Value "size" is a parameter used as coefficient for simplex noise
    -- function that is applied to shape of an ore patch. You can think of it
    -- as size of a patch on average. Recomended range is from 1 up to 50.

    -- Value "density" controls the amount of resource in a single tile.
    -- The center of an ore patch contains specified amount and is decreased
    -- proportionally to distance from center of the patch.

    -- Value "big_patches" and "small_patches" represents a number of an ore
    -- patches of given type. The "density" is applied with the same rule
    -- regardless of the patch size.
    ['iron-ore'] = {
        size = 23,
        density = 3500,
        big_patches = 2,
        small_patches = 1,
    },
    ['copper-ore'] = {
        size = 21,
        density = 3000,
        big_patches = 1,
        small_patches = 2,
    },
    ['coal'] = {
        size = 22,
        density = 2500,
        big_patches = 1,
        small_patches = 1,
    },
    ['stone'] = {
        size = 20,
        density = 2000,
        big_patches = 1,
        small_patches = 0,
    },
}

Public.difficulties = {
    [1] = {
        name = "I'm Too Young to Die",
        short_name = 'ITYTD',
        str = '20%',
        value = 0.2,
        color = {
            [GUI_VARIANTS.Dark] = { r = 0.00, g = 1.00, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.00, g = 0.50, b = 0.00 },
        },
    },
    [2] = {
        name = 'Have a Nice Day',
        short_name = 'HaND',
        str = '35%',
        value = 0.35,
        color = {
            [GUI_VARIANTS.Dark] = { r = 0.33, g = 1.00, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.13, g = 0.40, b = 0.00 },
        },
    },
    [3] = {
        name = 'Piece of Cake',
        short_name = 'PoC',
        str = '50%',
        value = 0.5,
        color = {
            [GUI_VARIANTS.Dark] = { r = 0.67, g = 1.00, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.17, g = 0.30, b = 0.00 },
        },
    },
    [4] = {
        name = 'Easy',
        short_name = 'Easy',
        str = '75%',
        value = 0.75,
        color = {
            [GUI_VARIANTS.Dark] = { r = 1.00, g = 1.00, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.30, g = 0.30, b = 0.00 },
        },
    },
    [5] = {
        name = 'Normal',
        short_name = 'Normal',
        str = '100%',
        value = 1,
        color = {
            [GUI_VARIANTS.Dark] = { r = 1.00, g = 0.67, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.30, g = 0.17, b = 0.00 },
        },
    },
    [6] = {
        name = 'Hard',
        short_name = 'Hard',
        str = '200%',
        value = 2,
        color = {
            [GUI_VARIANTS.Dark] = { r = 1.00, g = 0.33, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.40, g = 0.13, b = 0.00 },
        },
    },
    [7] = {
        name = 'Fun and Fast',
        short_name = 'FnF',
        str = '500%',
        value = 5,
        color = {
            [GUI_VARIANTS.Dark] = { r = 1.00, g = 0.00, b = 0.00 },
            [GUI_VARIANTS.Light] = { r = 0.40, g = 0.00, b = 0.00 },
        },
    },
}

Public.difficulty_lowered_names_to_index = {
    ["i'm too young to die"] = 1,
    ['itytd'] = 1,
    ['have a nice day'] = 2,
    ['hand'] = 2,
    ['piece of cake'] = 3,
    ['poc'] = 3,
    ['easy'] = 4,
    ['normal'] = 5,
    ['hard'] = 6,
    ['fun and fast'] = 7,
    ['fnf'] = 7,
}

Public.forces_list = { 'all teams', 'north', 'south' }
Public.science_list = {
    'all science',
    'very high tier (space, utility, production)',
    'high tier (space, utility, production, chemical)',
    'mid+ tier (space, utility, production, chemical, military)',
    'space',
    'utility',
    'production',
    'chemical',
    'military',
    'logistic',
    'automation',
}
Public.evofilter_list =
    { 'all evo jump', 'no 0 evo jump', '10+ only', '5+ only', '4+ only', '3+ only', '2+ only', '1+ only' }

return Public
