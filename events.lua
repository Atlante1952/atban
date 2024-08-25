minetest.register_on_prejoinplayer(function(name, ip)
    if atban.is_ip_banned(ip) then
        return "Your IP has been banned."
    end

    if atban.is_player_banned(name) then
        return "Your account has been banned."
    end

    return nil
end)

minetest.register_on_chat_message(function(name, message)
    local mute_details = atban.get_mute_details(name)
    if mute_details then
        local unmute_time = atban.calculate_unmute_time(mute_details.mute_start, mute_details.duration)
        minetest.chat_send_player(name, "Vous êtes muté pour la raison suivante : " .. mute_details.reason ..
                                        "\nDurée du mutisme : " .. mute_details.duration .. " minutes" ..
                                        "\nVous serez démuté le : " .. unmute_time)
        return true
    end
    return false
end)
