local Server = require('utils.server')
local Event = require('utils.event')
local Global = require('utils.global')

local color_data_set = 'color'
local set_data = Server.set_data
local get_data_color = Server.get_data_color
local math_round = math.round

local Public = {}

local player_colors = {}

Global.register({
    player_colors = player_colors,
}, function(t)
    this = t
end)

local function get_color_round(color)
    return {
        r = math_round(color.r, 3),
        g = math_round(color.g, 3),
        b = math_round(color.b, 3),
        a = math_round(color.a, 3)
    }
end

--- Tries to get data from the webpanel and applies the value to the player.
-- @param data_set player token
function Public.fetch(key)
    get_data_color(key)
end

Event.add(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if not player then
        return
    end

    if tournament1vs1_mode and player.online_time == 0 then
        -- save current player color for now but will be updated after fetch
        player_colors[player.name] = get_color_round(player.color)
        Public.fetch(player.name)
    end
end)

function Public.color_get_callback(player_name, color)
    local player = game.get_player(player_name)
    if not player then
        return
    end

    player_colors[player.name] = get_color_round(color)
    player.color = color
    player.chat_color = color
end

Event.on_nth_tick(
   3601, -- 3600 every minute
   function()
        for _, player in pairs(game.connected_players) do
            local color = get_color_round(player.color)
            local name = player.name
            local prev_color = player_colors[name]
            if prev_color
                and (  prev_color.r ~= color.r
                    or prev_color.g ~= color.g
                    or prev_color.b ~= color.b
                    or prev_color.a ~= color.a
                )
            then
                player_colors[name] = color
                set_data(color_data_set, name, color)
            end
        end
   end
)

return Public
