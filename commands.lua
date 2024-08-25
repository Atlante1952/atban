
minetest.register_chatcommand("atban_account", {
    description = "Ban a player's account permanently",
    privs = {ban = true},
    params = "<player_name> <reason_of_account_ban>",
    func = function(name, param)
        local player_name, reason = param:match("^([^%s]+)%s(.+)$")

        if not player_name or not reason then
            return false, "Usage: /atban_account <player_name> <reason_of_account_ban>"
        end

        local success, message = atban.ban_account(player_name, reason, name)
        return success, message
    end,
})

minetest.register_chatcommand("atban_ip", {
    params = "<player_name> <reason>",
    description = "Ban a player's IP permanently for the specified reason.",
    privs = {ban = true},
    func = function(name, param)
        local player_name, reason = string.match(param, "^(%S+)%s(.+)$")
        if not player_name or not reason then
            return false, "Invalid parameters. Usage: /atban_ip <player_name> <reason>"
        end

        local ip = atban.get_player_ip_from_file(player_name)
        if not ip then
            return false, "Failed to retrieve IP for player " .. player_name
        end

        local success, msg = atban.ban_ip(ip, reason, name)
        return success, msg
    end
})

minetest.register_chatcommand("mute", {
    description = "Mute a player with a reason",
    privs = {ban = true},
    params = "<player_name> <reason>",
    func = function(name, param)
        local player_name, reason = param:match("^([^%s]+)%s(.+)$")

        if not player_name or not reason then
            return false, "Usage: /mute <player_name> <reason>"
        end

        local success, message = atban.mute_player(player_name, reason, name)
        return success, message
    end,
})
