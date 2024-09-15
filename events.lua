
local last_check_time = 0

minetest.register_globalstep(function(dtime)
    last_check_time = last_check_time + dtime
    if last_check_time >= 60 then
        atban.check_and_remove_expired_sanctions()
        last_check_time = 0
    end
end)

minetest.register_on_prejoinplayer(function(name, ip)
    atban.check_and_remove_expired_sanctions()
    return nil
end)

minetest.register_on_chat_message(function(name, message)
    atban.check_and_remove_expired_sanctions()
    return false
end)

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
        minetest.chat_send_player(name, "You are muted for the following reason: " .. mute_details.reason ..
                                        "\nDuration of the mute: " .. mute_details.duration .. " minutes" ..
                                        "\nYou will be unmuted on: " .. unmute_time)
        return true
    end
    return false
end)
