local Event = require('utils.event')
local Functions = require('maps.biter_battles_v2.functions')
local Tables = require('maps.biter_battles_v2.tables')
local Task = require('utils.task')
local TeamManager = require('maps.biter_battles_v2.team_manager')
local Token = require('utils.token')
local ternary = require('utils.utils').ternary
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

	storage.allow_teamstats = 'spectator'
	storage.bb_show_research_info = 'spec'
	storage.tournament1vs1_started = false
	storage.players_ready = {["north"] = false, ["south"] = false}

    local surface = game.get_surface(storage.bb_surface_name)
    fill_starter_chests(surface)
end

function Public.start_tournament1vs1_game()
    local f = game.forces['spectator']
    f.set_friend('north', false)
    f.set_friend('south', false)
    Functions.set_game_start_tick()
    if storage.freeze_players then
        storage.freeze_players = false
        TeamManager.unfreeze_players()
        game.print('>>> Players have been unfrozen!', { color = { r = 255, g = 77, b = 77 } })
    end
end

function Public.player_ready(player)
    game.print(player.name .. " is ready!", {0,250,0})
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

    storage.difficulty_votes_timeout = 0

    storage.tournament1vs1_started = true
    storage.tournament1vs1_countdown = 9
    for ticks = 60, 600, 60 do
        Task.set_timeout_in_ticks(ticks, countdown_captain_start_token)
    end
end


function Public.tournament1vs1_mode_init()
    if not tournament1vs1_mode then
        return
    end

    storage.bb_settings.map_reroll = false
    storage.feeding_timeout = 4 * 60 * 60

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

    if not player.admin then
        player.print('This command can only be used by admins')
        return
    end

    tournament1vs1_mode = not tournament1vs1_mode
    game.print('1vs1 tournament mode ha been ' .. ternary(tournament1vs1_mode, 'enabled', 'disabled') .. ' by ' .. player.name)

    Public.tournament1vs1_mode_init()
end

local function on_multiplayer_init()
    storage.tournament_mode = true
end

Event.add(defines.events.on_multiplayer_init, on_multiplayer_init)

commands.add_command(
    'tournament1vs1',
    'Switch game to 1vs1 tournament mode',
    function(cmd)
        Utils.safe_wrap_cmd(cmd, tournament1vs1_mode_toggle, cmd)
    end
)

return Public