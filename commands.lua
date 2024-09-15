
minetest.register_chatcommand("atban_ip", {
    params = "<player_name> <reason> <time_in_minutes>",
    description = "Ban a player's IP",
    privs = {ban = true},
    func = function(player_name, param)
        local params = param:split(" ")
        if #params < 3 then
            return false, "Usage: /atban_ip <player_name> <reason> <time_in_minutes>"
        end
        local target_player_name = params[1]
        local reason = table.concat(params, " ", 2, #params - 1)
        local time_in_minutes = tonumber(params[#params])
        if not time_in_minutes then
            return false, "Time in minutes must be a number."
        end
        local target_player = minetest.get_player_by_name(target_player_name)
        if not target_player then
            return false, "Player not found."
        end
        local player_ip = minetest.get_player_ip(target_player_name)
        local success, message = atban.ban_ip(player_ip, reason, time_in_minutes, player_name)
        if success then
            return true, message
        else
            return false, message
        end
    end
})

minetest.register_chatcommand("atban_account", {
    params = "<player_name> <reason> <time_in_minutes>",
    description = "Ban a player's account",
    privs = {ban = true},
    func = function(player_name, param)
        local params = param:split(" ")
        if #params < 3 then
            return false, "Usage: /atban_account <player_name> <reason> <time_in_minutes>"
        end
        local target_player_name = params[1]
        local reason = table.concat(params, " ", 2, #params - 1)
        local time_in_minutes = tonumber(params[#params])
        if not time_in_minutes then
            return false, "Time in minutes must be a number."
        end
        local success, message = atban.ban_account(target_player_name, reason, time_in_minutes, player_name)
        if success then
            return true, message
        else
            return false, message
        end
    end
})

minetest.register_chatcommand("atmute", {
    params = "<player_name> <reason> <time_in_minutes>",
    description = "Mute a player",
    privs = {ban = true},
    func = function(player_name, param)
        local params = param:split(" ")
        if #params < 3 then
            return false, "Usage: /atmute <player_name> <reason> <time_in_minutes>"
        end
        local target_player_name = params[1]
        local reason = table.concat(params, " ", 2, #params - 1)
        local time_in_minutes = tonumber(params[#params])
        if not time_in_minutes then
            return false, "Time in minutes must be a number."
        end
        local success, message = atban.mute_player(target_player_name, reason, time_in_minutes, player_name)
        if success then
            return true, message
        else
            return false, message
        end
    end
})
