
local Color = require('utils.color_presets')
local Event = require('utils.event')
local Global = require('utils.global')
local safe_wrap_cmd = require('utils.utils').safe_wrap_cmd

local Public = {}

storage.follow2_enabled = false

local this = {
    targets = {
        ['north'] = nil,
        ['south'] = nil
    },
    inv_watchers = {
    },
    config = {},
}
Global.register(this, function(tbl)
    this = tbl
end)

---@param player LuaPlayer
local function get_screen_width(player)
    return player.display_resolution.width
end

---@param player LuaPlayer
local function get_screen_height(player)
    return player.display_resolution.height - 50
end

---@param player LuaPlayer
local function get_screen_width_half(player)
    return math.floor(get_screen_width(player) / 2)
end

---@param player LuaPlayer
local function get_screen_height_half(player)
    return math.floor(get_screen_height(player) / 2)
end


local function reset_gui(player)
    local controls_flow = player.gui.screen['follow2_controls']
    if controls_flow then
        controls_flow.destroy()
    end
    local frame = player.gui.screen['follow2_cameras']
    if frame then
        frame.destroy()
    end
    local elm = player.gui.screen['follow2_inventory_north']
    if elm then
        elm.destroy()
    end
    local elm = player.gui.screen['follow2_inventory_south']
    if elm then
        elm.destroy()
    end
end

---@param player LuaPlayer
---@param target_player LuaPlayer
local function create_follow2_player_gui(player, target_player, direction)
    local frame = player.gui.screen['follow2_cameras']

    local camera_name = 'north'
    if frame['follow2_camera_' .. camera_name] then
        camera_name = 'south'
    end

    local camera = frame.add({
        type = 'camera',
        name = 'follow2_camera_' .. camera_name,
        position = target_player.character.position,
        zoom = 0.3,
    })
    if direction == 'vertical' then
        camera.style.minimal_width = get_screen_width(player) - 500
        camera.style.minimal_height = get_screen_height_half(player)
        frame.location = { x = 250, y = 50 }
    else
        camera.style.minimal_width = get_screen_width_half(player)
        camera.style.minimal_height = get_screen_height(player)
        frame.location = { x = 1, y = 50 }
    end
    camera.style.padding = 0
    camera.style.margin = 0
    camera.entity = target_player.character
end

---@param player LuaPlayer
local function create_controls_gui(player)
    local controls_flow = player.gui.screen['follow2_controls']
    if controls_flow then
        controls_flow.destroy()
    end

    controls_flow = player.gui.screen.add({ type = 'flow', name = "follow2_controls", direction = 'horizontal' })
    controls_flow.location = { x = get_screen_width_half(player), y = 1 }


    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_vertical_layout',
        caption = '🁣',
        visible = false,
        tooltip = 'Change to vertical layout',
    })
    btn.style.width = 40
    btn.style.height = 40
    btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_horizontal_layout',
        caption = '🀱',
        tooltip = 'Change to horizontal layout',
    })
    btn.style.width = 40
    btn.style.height = 40
    btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_hide',
        caption = 'hide cameras',
        tooltip = 'Hide player cameras',
    })
    btn.style.width = 80
    btn.style.height = 40
    btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_show',
        caption = 'show cameras',
        tooltip = 'Show player cameras',
        visible = false,
    })
    btn.style.width = 80
    btn.style.height = 40
    btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_open_inventory',
        caption = 'inventory',
        tooltip = 'Open players inventory',
        auto_toggle = true,
    })
    btn.style.width = 70
    btn.style.height = 40
    btn.style.padding = 0

    -- local btn = controls_flow.add({
    --     type = 'button',
    --     name = 'follow2_show_fov',
    --     caption = 'FOV',
    --     tooltip = 'Show player field of view',
    -- })
    -- btn.style.width = 40
    -- btn.style.height = 40
    -- btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_hide_in_remove_view',
        caption = 'Remote hide',
        tooltip = 'Hide cameras in remote view',
        auto_toggle = true,
    })
    btn.style.width = 90
    btn.style.height = 40
    btn.style.padding = 0

    local btn = controls_flow.add({
        type = 'button',
        name = 'follow2_close',
        caption = '⨯',
        tooltip = 'Close follow',
    })
    btn.style.width = 40
    btn.style.height = 40
    btn.style.padding = 0
end

---@param player LuaPlayer
local function create_cameras_gui(player)
    local frame = player.gui.screen['follow2_cameras']
    if frame then
        frame.destroy()
    end

    local direction = this.config[player.name].layout
    frame = player.gui.screen.add({ type = 'frame', name = "follow2_cameras", direction = direction })
    frame.style.padding = 0
    frame.style.margin = 0
    frame.location = { x = 1, y = 50 }

    create_follow2_player_gui(player, this.targets.north, direction)
    create_follow2_player_gui(player, this.targets.south, direction)
end

local function do_follow2(cmd)
    local player = game.player
    if not player or not player.valid then
        return
    end

    if not storage.follow2_enabled then
        player.print('Command is disabled.', { color = Color.warning })
        return
    end

    reset_gui(player)

    if player.force.name ~= 'spectator' then
        player.print('You must be a spectator to use this command.', { color = Color.warning })
        return
    end

    local north_player = game.forces.north.connected_players[1]
    if north_player and north_player.valid and north_player.character then
        this.targets.north = north_player
    end
    local south_player = game.forces.south.connected_players[1]
    if south_player and south_player.valid and south_player.character then
        this.targets.south = south_player
    end

    -- enable for testing in single player
    -- this.targets.north = player
    -- this.targets.south = player

    if not this.targets.north or not this.targets.south then
        player.print('No players to follow. Wait for players to join teams', { color = Color.warning })
        return
    end

    create_controls_gui(player)
    if not this.config[player.name] then
        this.config[player.name] = {}
    end
    if not this.config[player.name].layout then
        this.config[player.name].layout = 'vertical'
    end
    create_cameras_gui(player)
end

commands.add_command('follow2', 'Follows a player', function(cmd)
    safe_wrap_cmd(cmd, do_follow2, cmd)
end)


local function on_player_respawned(event)
    local target_player = game.get_player(event.player_index)
    if not target_player or not target_player.valid or not target_player.character then
        return
    end

    local force_name = target_player.force.name
    if force_name ~= 'north' and force_name ~= 'south' then
        return
    end

    update_gui(event)
    for _, p in pairs(game.connected_players) do
        local frame = p.gui.screen['follow2_cameras']
        if frame and frame['follow2_camera_' .. force_name] then
            frame['follow2_camera_' .. force_name].entity = target_player.character
        end
    end
end

local function slot_btn_style(button)
    button.style.margin = -2
    button.style.padding = 0
    button.enabled = true
    button.ignored_by_interaction = true
end

local function redraw_inventory(gui_player, target_player, options)
    options = options or {}
    local force_name = target_player.force.name

    local inv_frame_name = 'follow2_inventory_' .. force_name
    local inventory_frame = gui_player.gui.screen[inv_frame_name]

    local recreate = inventory_frame and inventory_frame.valid and options.change_layout
    if recreate then
        inventory_frame.destroy()
        this.config[gui_player.name][force_name .. '_location'] = nil
    end

    if inventory_frame and inventory_frame.valid then
        if options.close then
            inventory_frame.destroy()
            return
        end
        inventory_frame.clear()
    else
        if options.close then
            return
        end
        if options.change_layout and not recreate then
            return
        end

        inventory_frame = gui_player.gui.screen.add({
            type = 'frame',
            name = inv_frame_name,
            caption = target_player.name,
            direction = this.config[gui_player.name].layout,
        })
        if options.change_layout or options.open then
            inventory_frame.bring_to_front()
        end

        local location = this.config[gui_player.name][force_name .. '_location']
        if location then
            inventory_frame.location = location
        else
            local y
            local x
            if this.config[gui_player.name].layout == 'vertical' then
                x = get_screen_width(gui_player) - 500/2
                y = 50
                if force_name == 'south' then
                    y = get_screen_height_half(gui_player) + 50
                end
            else -- horizontal
                x = 1
                if force_name == 'south' then
                    x = get_screen_width_half(gui_player) + 1
                end
                y = get_screen_height(gui_player) - 80
            end
            inventory_frame.location = { x = x, y = y }
            this.config[gui_player.name][force_name .. '_location'] = inventory_frame.location
        end
    end

    local target_character = target_player.character

    -- horisontal
    local column_count = 10
    if this.config[gui_player.name].layout == 'vertical' then
        column_count = 4
    end

    -- main inventory
    local main_table = inventory_frame.add({ type = 'table', column_count = column_count })
    main_table.style.cell_padding = 0

    main_table.style.margin = 0
    main_table.style.padding = 0

    local main_contents = target_character.get_main_inventory().get_contents()
    for _, item in pairs(main_contents) do
        local button = main_table.add({
            type = 'sprite-button',
            sprite = 'item/' .. item.name,
            number = item.count,
            name = item.name,
            style = 'slot_button',
        })
        slot_btn_style(button)
    end
    if #main_contents == 0 then
        main_table.add({
            type = 'label',
            caption = 'Main inventory empty',
        })
    end

    local button
    local invetory_bottom_flow = inventory_frame.add({ type = 'flow', direction = 'horizontal', index = 1 })

    -- armor inventoty
    local armor_hand_flow = invetory_bottom_flow.add({ type = 'flow', direction = 'vertical' })
    local armor_inv = target_character.get_inventory(defines.inventory.character_armor)
    local item = nil
    if armor_inv and armor_inv.valid then
        item = armor_inv[1]
    end
    if item and item.valid_for_read then
        button = armor_hand_flow.add({
            type = 'sprite-button',
            sprite = 'item/' .. item.name,
            number = item.count,
            name = 'armor_slot',
            style = 'slot_button',
        })
    else
        button = armor_hand_flow.add({
            type = 'sprite-button',
            sprite = 'utility/empty_armor_slot',
            name = 'armor_slot',
            style = 'slot_button',
        })
    end
    slot_btn_style(button)

    -- cursor/hand inventoty
    local item = target_player.cursor_stack
    if item and item.valid_for_read then
        button = armor_hand_flow.add({
            type = 'sprite-button',
            sprite = 'item/' .. item.name,
            number = item.count,
            name = 'cursor_slot',
            style = 'slot_button',
        })
    else
        button = armor_hand_flow.add({
            type = 'sprite-button',
            sprite = 'utility/hand_black',
            name = 'cursor_slot',
            style = 'slot_button',
        })
    end
    slot_btn_style(button)

    local guns_ammo_flow = invetory_bottom_flow.add({ type = 'flow', direction = 'vertical' })

    -- guns inventory
    local guns_inv = target_character.get_inventory(defines.inventory.character_guns)
    local guns_table = guns_ammo_flow.add({ type = 'table', column_count = #guns_inv })
    for i = 1, #guns_inv, 1 do
        local item = guns_inv[i]
        local button
        if item and item.valid_for_read then
            button = guns_table.add({
                type = 'sprite-button',
                sprite = 'item/' .. item.name,
                number = item.count,
                name = i,
                style = 'slot_button',
            })
        else
            button = guns_table.add({
                type = 'sprite-button',
                sprite = 'utility/empty_gun_slot',
                name = i,
                style = 'slot_button',
            })
        end
        slot_btn_style(button)
    end

    -- ammo inventory
    local ammo_inv = target_character.get_inventory(defines.inventory.character_ammo)
    local ammo_table = guns_ammo_flow.add({ type = 'table', column_count = #ammo_inv })
    for i = 1, #ammo_inv, 1 do
        local item = ammo_inv[i]
        local button
        if item and item.valid_for_read then
            button = ammo_table.add({
                type = 'sprite-button',
                sprite = 'item/' .. item.name,
                number = item.count,
                name = i,
                style = 'slot_button',
            })
        else
            button = ammo_table.add({
                type = 'sprite-button',
                sprite = 'utility/empty_ammo_slot',
                name = i,
                style = 'slot_button',
            })
        end
        slot_btn_style(button)
    end
end

local function open_inventory(gui_player, open)
    this.inv_watchers[gui_player.name] = open
    for _, target_player in pairs(this.targets) do
        redraw_inventory(gui_player, target_player, {['open'] = open, ['close'] = not open})
    end
end

local function redraw_inventory_layout(player)
    for _, target_player in pairs(this.targets) do
        redraw_inventory(player, target_player, {['change_layout'] = true})
    end
end

local function show_fov(player)
    local target_player = this.targets.north
    if target_player and target_player.valid and target_player.character then
        player.surface.create_entity({
            name = 'fov-indicator',
            position = target_player.position,
            force = player.force,
            target = target_player.character,
            speed = 0.05,
            max_distance = 30,
        })
    end
    local target_player = this.targets.south
    if target_player and target_player.valid and target_player.character then
        player.surface.create_entity({
            name = 'fov-indicator',
            position = target_player.position,
            force = player.force,
            target = target_player.character,
            speed = 0.05,
            max_distance = 30,
        })
    end
end

local function toggle_cameras(player, show)
    local frame = player.gui.screen['follow2_cameras']
    if frame and frame.valid then
        frame.visible = show
    end
    local controls_flow = player.gui.screen['follow2_controls']
    if controls_flow and controls_flow.valid then
        controls_flow['follow2_show'].visible = not show
        controls_flow['follow2_hide'].visible = show
    end
end

local function on_gui_click(event)
    local player = game.get_player(event.player_index)
    local element = event.element

    if not element.valid then
        return
    end

    local name = element.name
    if name == 'follow2_hide' then
        toggle_cameras(player, false)
        return
    end
    if name == 'follow2_show' then
        toggle_cameras(player, true)
        return
    end
    if name == 'follow2_vertical_layout' then
        this.config[player.name].layout = 'vertical'
        create_cameras_gui(player)
        redraw_inventory_layout(player)
        element.visible = false
        element.parent['follow2_horizontal_layout'].visible = true

        return
    end
    if name == 'follow2_horizontal_layout' then
        this.config[player.name].layout = 'horizontal'
        create_cameras_gui(player)
        redraw_inventory_layout(player)
        element.visible = false
        element.parent['follow2_vertical_layout'].visible = true

        return
    end
    if name == 'follow2_close' then
        reset_gui(player)
        return
    end
    if name == 'follow2_open_inventory' then
        open_inventory(player, element.toggled)
    end
    if name == 'follow2_show_fov' then
        show_fov(player)
    end
    if name == 'follow2_hide_in_remove_view' then
        this.config[player.name].hide_in_remote_view = element.toggled
    end

end

local function on_gui_location_changed(event)
    local player = game.get_player(event.player_index)
    local element = event.element

    if not element.valid then
        return
    end

    local name = element.name

    for force_name, _ in pairs(this.targets) do
        if name == 'follow2_inventory_' .. force_name then
            this.config[player.name][force_name .. '_location'] = element.location
            return
        end
    end
end

local function on_player_controller_changed(event)
    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if not this.config[player.name].hide_in_remote_view then
        return
    end

    local show = player.controller_type == defines.controllers.character
    toggle_cameras(player, show)
end

local function on_tick(event)
    for _, player in pairs(game.connected_players) do
        local frame = player.gui.screen['follow2_cameras']
        if frame and frame.valid and frame.visible then
            for _, camera in pairs(frame.children) do
                if camera and camera.valid and camera.type == 'camera' then
                    camera.zoom = player.zoom
                end
            end
        end
    end
end

local function update_gui(event)
    local target_player = game.get_player(event.player_index)
    if not target_player or not target_player.valid then
        return
    end

    if this.targets.north ~= target_player and this.targets.south ~= target_player then
        return
    end

    for player_name, wathing in pairs(this.inv_watchers) do
        if wathing then
            local player = game.get_player(player_name)
            if player and player.connected then
                redraw_inventory(player, target_player)
            end
        end
    end
end

Public.resetFollow2 = function ()
    this.targets.north = nil
    this.targets.south = nil
    this.inv_watchers = {}

    for _, player in pairs(game.players) do
        reset_gui(player)
    end
end


Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_location_changed, on_gui_location_changed)
Event.add(defines.events.on_player_controller_changed, on_player_controller_changed)
Event.on_nth_tick(5, on_tick)

Event.add(defines.events.on_player_main_inventory_changed, update_gui)
Event.add(defines.events.on_player_gun_inventory_changed, update_gui)
Event.add(defines.events.on_player_ammo_inventory_changed, update_gui)
Event.add(defines.events.on_player_armor_inventory_changed, update_gui)
Event.add(defines.events.on_player_trash_inventory_changed, update_gui)

return Public