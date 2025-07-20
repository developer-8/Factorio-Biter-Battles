local Color = require('utils.color_presets')
local Event = require('utils.event')
local Functions = require('maps.biter_battles_v2.functions')
local Server = require('utils.server')
local Tables = require('maps.biter_battles_v2.tables')
local Task = require('utils.task')
local TeamManager = require('maps.biter_battles_v2.team_manager')
local ternary = require('utils.utils').ternary
local Token = require('utils.token')
local Utils = require('utils.utils')



local Public = {}

local starter_pack = {
    ["raw-fish"]=100,
    ["electric-mining-drill"]=40,
    ["stone-furnace"]=50,
    ["burner-mining-drill"]=20,
    ["small-electric-pole"]=200,
    ["transport-belt"]=400,
    ["copper-cable"]=200,
    ["assembling-machine-1"]=20,
    ["offshore-pump"]=1,
    ["steam-engine"]=10,
    ["boiler"]=5,
    ["burner-inserter"]=5,
    ["pipe"]=20,
    ["pipe-to-ground"]=2,
    ["lab"]=5,
    ["coal"]=600,
    ["inserter"]=50,
    ["pistol"]=1,
    ["firearm-magazine"]=10,
    ["grenade"]=10
}

local function fill_starter_chests(surface)
	local _posX = 0
	local _posY = 41

	if storage.packchest2N then storage.packchest2N.destroy() end
	if storage.packchest2S then storage.packchest2S.destroy() end
	storage.packchest2N = surface.create_entity({name = "steel-chest", position = {x=_posX, y=-_posY}, force = "north"})
	storage.packchest2S = surface.create_entity({name = "steel-chest", position = {x=_posX, y=_posY-1}, force = "south"})
	for _item,_qty in pairs(starter_pack) do
		storage.packchest2N.insert({name=_item, count=_qty})
		storage.packchest2S.insert({name=_item, count=_qty})
	end
end

function Public.setup_new_game()
    if not tournament1vs1_mode then
        return
    end

    if not storage.freeze_players then
        storage.freeze_players = true
        TeamManager.freeze_players()
        game.print('>>> Players have been frozen!', { color = { r = 111, g = 111, b = 255 } })
    end

    storage.tournament1vs1_chart_tags = {}
    storage.difficulty_vote_value = 1
    storage.difficulty_vote_index = 5

	storage.allow_teamstats = 'spectator'
	storage.bb_show_research_info = 'spec'
	storage.tournament1vs1_started = false
	storage.players_ready = {["north"] = false, ["south"] = false}

    local surface = game.get_surface(storage.bb_surface_name)
    fill_starter_chests(surface)
end

function Public.start_tournament1vs1_game()
    Functions.set_game_start_tick()
    if storage.freeze_players then
        storage.freeze_players = false
        TeamManager.unfreeze_players()
        game.print('>>> Players have been unfrozen!', { color = { r = 255, g = 77, b = 77 } })
    end

    Server.to_server_game_start('')
end

function Public.player_ready(player)
    game.print(player.name .. " is ready!", {0,250,0})
    log(player.name .. " is ready!")

    storage.players_ready[player.force.name] = true
    if storage.training_mode then
        Public.prepare_start_tournament1vs1_game()
        return
    end
    if storage.players_ready[Tables.enemy_team_of[player.force.name]] then
        Public.prepare_start_tournament1vs1_game()
    end
end


local countdown_captain_start_token = Token.register(function()
    if storage.tournament1vs1_countdown <= 0 then
        Public.start_tournament1vs1_game()
    end
    for _, player in pairs(game.connected_players) do
        if player.gui.center.bb_captain_countdown then
            player.gui.center.bb_captain_countdown.destroy()
        end
        if storage.tournament1vs1_countdown > 0 then
            local _sprite = 'file/png/' .. storage.tournament1vs1_countdown .. '.png'
            player.gui.center.add({ name = 'bb_captain_countdown', type = 'sprite', sprite = _sprite })
        end
    end
    if storage.tournament1vs1_countdown > 0 then
        Sounds.notify_all('utility/build_blueprint_large')
        storage.tournament1vs1_countdown = storage.tournament1vs1_countdown - 1
    end
end)

function Public.prepare_start_tournament1vs1_game()
    if storage.tournament1vs1_started then
        return
    end

    -- make spectator enemy to not share cursors with players
    -- do it just before game starts so map reveal shared with players 
    local f = game.forces['spectator']
    f.set_friend('north', false)
    f.set_friend('south', false)

    storage.difficulty_votes_timeout = 0

    storage.tournament1vs1_started = true
    storage.tournament1vs1_countdown = 9
    for ticks = 60, 600, 60 do
        Task.set_timeout_in_ticks(ticks, countdown_captain_start_token)
    end


    local text_x = -20
    local text_y = -3
    local scale = 4
    local north_name = ''
    for _, player in pairs(game.forces.north.players) do
        if north_name ~= '' then
            north_name = north_name .. " & "
        end
        north_name = north_name .. player.name
    end
    rendering.draw_text({
        text = north_name,
        surface = game.surfaces[storage.bb_surface_name],
        target = {text_x, text_y},
        color = { r = 120, g = 120, b = 255 },
        scale = scale,
        font = "infinite",
        forces = {"spectator"},
        alignment = 'center',
        vertical_alignment = 'middle',
    })
    rendering.draw_text({
        text = "vs",
        surface = game.surfaces[storage.bb_surface_name],
        target = {text_x, 0},
        color = Color.light_grey,
        scale = scale,
        font = "infinite",
        forces = {"spectator"},
        alignment = 'center',
        vertical_alignment = 'middle',
    })
    local south_name = ''
    for _, player in pairs(game.forces.south.players) do
        if south_name ~= '' then
            south_name = south_name .. " & "
        end
        south_name = south_name .. player.name
    end
    rendering.draw_text({
        text = south_name,
        surface = game.surfaces[storage.bb_surface_name],
        target = {text_x, -text_y},
        color = { r = 255, g = 65, b = 65 },
        scale = scale,
        font = "infinite",
        forces = {"spectator"},
        alignment = 'center',
        vertical_alignment = 'middle',
    })
end


function Public.tournament1vs1_mode_init()
    if not tournament1vs1_mode then
        return
    end

    storage.bb_settings.map_reroll = false
    storage.feeding_timeout = 4 * 60 * 60
    storage.boundary_offset = 200
    storage.MAX_STRIKE_DISTANCE = 400

    Public.setup_new_game()
end

---@param cmd CustomCommandData
local function tournament1vs1_mode_toggle(cmd)
    ---@type number?
    local index = cmd.player_index
    if not index then
        return
    end

    ---@type LuaPlayer?
    local player = game.get_player(index)
    if not player or not player.valid then
        return
    end

    if not is_admin(player) then
        player.print('This command can only be used by admins')
        return
    end

    tournament1vs1_mode = not tournament1vs1_mode
    game.print('1vs1 tournament mode ha been ' .. ternary(tournament1vs1_mode, 'enabled', 'disabled') .. ' by ' .. player.name)

    Public.tournament1vs1_mode_init()
end

Event.add(defines.events.on_multiplayer_init, function()
    storage.tournament_mode = true
end)


-- add player tag on map view
Event.add(defines.events.on_player_changed_position, function(event)
    if not tournament1vs1_mode then
        return
    end

    local player = game.get_player(event.player_index)
    local force_name = player.force.name
    if force_name ~= 'north' and force_name ~= 'south' then
        return;
    end

    if not player.character or not player.character.valid then
        return
    end

    local player_tag = storage.tournament1vs1_chart_tags[player.name]
    if player_tag then
        player_tag.destroy()
    end

    storage.tournament1vs1_chart_tags[player.name] = game.forces.spectator.add_chart_tag(
        player.physical_surface,
        {
            position = player.character.position,
            text = player.name, -- '⬤ ' ..  player.name,
            icon = {
                type = 'virtual',
                name = 'signal-dot'
            }
        }
    )
end)

-- remove player chart tag if player changes force
Event.add(defines.events.on_player_changed_force, function(event)
    if not tournament1vs1_mode then
        return
    end

    local force_name = event.force.name
    if force_name ~= 'north' and force_name ~= 'south' then
        return;
    end

    local player = game.get_player(event.player_index)
    local player_tag = storage.tournament1vs1_chart_tags[player.name]
    if player_tag then
        player_tag.destroy()
    end
end)

-- commands.add_command(
--     'tournament1vs1',
--     'Switch game to 1vs1 tournament mode',
--     function(cmd)
--         Utils.safe_wrap_cmd(cmd, tournament1vs1_mode_toggle, cmd)
--     end
-- )

return Public