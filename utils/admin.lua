
local Color = require('utils.color_presets')
local Event = require('utils.event')
local Global = require('utils.global')
local safe_wrap_with_player_print = require('utils.utils').safe_wrap_with_player_print

local Public = {}

local admin_ids = {}

-- next demote event for this ids will not remove them from admin_ids
local ignore_demote_ids = {}

Global.register({
    admin_ids = admin_ids,
    ignore_demote_ids = ignore_demote_ids,
}, function(tbl)
    admin_ids = tbl.admin_ids
    ignore_demote_ids = tbl.ignore_demote_ids
end)

-- global
---@param player LuaPlayer
---@return boolean
function is_admin(player)
    return player.admin or admin_ids[player.index] == true
end


Event.add(defines.events.on_player_joined_game, function(event)
    local player = game.get_player(event.player_index)
    if player.admin then
        admin_ids[player.index] = true
    end
end)

Event.add(defines.events.on_player_promoted, function(event)
    admin_ids[event.player_index] = true
    ignore_demote_ids[event.player_index] = nil
end)

Event.add(defines.events.on_player_demoted, function(event)
    if ignore_demote_ids[event.player_index] then
        ignore_demote_ids[event.player_index] = nil
        return
    end
    admin_ids[event.player_index] = nil
end)

Event.add(defines.events.on_console_command, function(event)
    if not event.player_index then
        return
    end
    local player = game.get_player(event.player_index)

    if not player.admin then
        local commands = {
            ["ban"] = true,
            ["unban"] = true,
            ["kick"] = true,
            ["promote"] = true,
            ["demote"] = true,
            ["editor"] = true,
            ["sc"] = true,
            ["c"] = true,
        }
        if commands[event.command] then
            if admin_ids[player.index] then
                player.admin = true
                player.print("You are now a full admin. Run the command again to execute it.", { color = Color.red })
            end
            return
        end
    end

    if event.command == 'mode-admin' then
        if player.admin then
            player.print("You are already an admin", { color = Color.yellow })
            return
        end

        if admin_ids[player.index] then
            player.admin = true
            player.print("You are now a full admin", { color = Color.success })
            return
        end

        player.print("[ERROR] You're not admin!", { color = Color.fail })
    end
end)


commands.add_command(
    'mode-admin',
    "Swith admin from player mode to admin mode",
    function (cmd)
        --[[ 
            due to the fact that it is not possible to set player.admin = true here, 
            the real handler of this command is in on_console_command event above
        --]]
    end
)

function Public.swith_to_player_mode(player, notify)
    if player.admin then
        ignore_demote_ids[player.index] = true
        player.admin = false
        if notify then
            player.print("You are player now", { color = Color.warning })
        end
        return
    end

    if admin_ids[player.index] then
        if notify then
            player.print("You are already a player", { color = Color.yellow })
        end
        return
    end

    if notify then
        player.print("[ERROR] You're not admin!", { color = Color.fail })
    end
end

commands.add_command(
    'mode-player',
    "Swith admin from admin mode to player mode",
    function (cmd)
        local player = game.get_player(cmd.player_index)
        if not player then
            return
        end
        safe_wrap_with_player_print(player, Public.swith_to_player_mode, player, true)
    end
)

return Public

