minetest.register_on_prejoinplayer(function(name, ip)
    local ban_details = atban.get_ban_details(name)
    if ban_details then
        return string.format(
            "\n\n--- Account Banned ---\n\n" ..
            "Your account : %s\n" ..
            "Ban Reason : %s\n" ..
            "Ban Duration : %s\n" ..
            "Start Date : %s\n\n" ..
            "If you believe this ban is a mistake, please contact the administrator.",
            ban_details.player_name,
            ban_details.reason,
            ban_details.duration,
            ban_details.ban_start
        )
    end

    if atban.is_ip_banned(ip) then
        return string.format(
            "\n\n--- IP Banned ---\n\n" ..
            "Your IP address has been banned.\n\n" ..
            "If you believe this ban is a mistake, please contact the administrator."
        )
    end

    atban.create_atban_files(name, ip)
    return true
end)

minetest.register_on_chat_message(function(name, message)
    local mute_details = atban.get_mute_details(name)
    if mute_details then
        minetest.chat_send_player(name, "Vous êtes muté pour la raison suivante : " .. mute_details.reason)
        return true
    end
    return false
end)
