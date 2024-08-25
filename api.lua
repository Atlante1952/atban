local function write_to_file(path, content)
    local success, err = minetest.safe_file_write(path, content)
    if not success then
        minetest.log("error", "Failed to write to file " .. path .. ". Error: " .. (err or "unknown"))
    end
    return success
end

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        minetest.log("error", "Failed to open file " .. path)
        return nil
    end

    local content = file:read("*all")
    file:close()
    return content
end

local function append_to_file(path, content)
    local file = io.open(path, "a")
    if not file then
        minetest.log("error", "Failed to open file " .. path .. " for appending")
        return false
    end

    file:write(content)
    file:close()
    return true
end

local function get_file_path(filename)
    return minetest.get_worldpath() .. "/" .. filename
end

local function format_ban_info(entity, entity_type, banning_player, reason, time_in_minutes, current_time)
    return string.format("%s: %s\nBanned at: %s\nBanned by: %s\nReason: %s\nDuration: %d minutes\n\n",
                         entity_type, entity, current_time, banning_player, reason, time_in_minutes)
end

local function log_ban_action(entity, entity_type, banning_player, reason, time_in_minutes)
    minetest.log("action", string.format("%s %s has been banned by %s for reason: %s for %d minutes",
                                          entity_type, entity, banning_player, reason, time_in_minutes))
end

local function is_entity_banned(entity, entity_type, file_path)
    local content = read_file(file_path)
    if not content then
        return false
    end
    return content:find(entity_type .. ": " .. entity) ~= nil
end

local function replace_entity_ban(entity, entity_type, file_path, new_ban_info)
    local content = read_file(file_path)
    if not content then
        return false
    end
    local pattern = entity_type .. ": " .. entity .. "\nBanned at: .-\nBanned by: .-\nReason: .-\nDuration: .- minutes\n\n"
    local new_content = content:gsub(pattern, new_ban_info)
    return write_to_file(file_path, new_content)
end

local function replace_mute_info(entity, file_path, new_mute_info)
    local content = read_file(file_path)
    if not content then
        return false
    end
    local pattern = "Player: " .. entity .. "\nMuted by: .-\nReason: .-\nMuted at: .-\nDuration: .- minutes\n\n"
    local new_content = content:gsub(pattern, new_mute_info)
    return write_to_file(file_path, new_content)
end

local function ban_entity(entity, entity_type, reason, time_in_minutes, banning_player, file_path)
    local current_time = os.date("%Y-%m-%d %H:%M:%S")
    local ban_info = format_ban_info(entity, entity_type, banning_player, reason, time_in_minutes, current_time)

    if is_entity_banned(entity, entity_type, file_path) then
        if replace_entity_ban(entity, entity_type, file_path, ban_info) then
            log_ban_action(entity, entity_type, banning_player, reason, time_in_minutes)
            return true, entity_type .. " " .. entity .. " has been updated with a new ban."
        else
            return false, "Failed to update " .. entity_type:lower() .. " ban."
        end
    else
        if append_to_file(file_path, ban_info) then
            log_ban_action(entity, entity_type, banning_player, reason, time_in_minutes)
            return true, entity_type .. " " .. entity .. " has been banned."
        else
            return false, "Failed to ban " .. entity_type:lower() .. "."
        end
    end
end

function atban.ban_ip(ip, reason, time_in_minutes, banning_player)
    return ban_entity(ip, "IP", reason, time_in_minutes, banning_player, get_file_path("ban_ip.txt"))
end

function atban.is_ip_banned(ip)
    return is_entity_banned(ip, "IP", get_file_path("ban_ip.txt"))
end

function atban.ban_account(player_name, reason, time_in_minutes, banning_player)
    local success, message = ban_entity(player_name, "Account", reason, time_in_minutes, banning_player, get_file_path("ban_account.txt"))
    if success then
        local target_player = minetest.get_player_by_name(player_name)
        if target_player then
            minetest.kick_player(player_name, "Your account has been banned.\nReason: " .. reason .. "\nDuration: " .. time_in_minutes .. " minutes")
        end
    end
    return success, message
end

function atban.is_player_banned(player_name)
    return is_entity_banned(player_name, "Account", get_file_path("ban_account.txt"))
end

function atban.mute_player(player_name, reason, time_in_minutes, muter_name)
    local file_path = get_file_path("mute_account.txt")
    local current_time = os.date("%Y-%m-%d %H:%M:%S")
    local mute_info = string.format("Player: %s\nMuted by: %s\nReason: %s\nMuted at: %s\nDuration: %d minutes\n\n",
                                    player_name, muter_name, reason, current_time, time_in_minutes)
    if is_entity_banned(player_name, "Player", file_path) then
        if replace_mute_info(player_name, file_path, mute_info) then
            return true, "Player " .. player_name .. " has been updated with a new mute."
        else
            return false, "Failed to update player mute."
        end
    else
        if append_to_file(file_path, mute_info) then
            return true, "Player " .. player_name .. " has been muted successfully."
        else
            return false, "Failed to mute player."
        end
    end
end

function atban.get_mute_details(player_name)
    local file_path = get_file_path("mute_account.txt")
    local content = read_file(file_path)
    if not content then
        return nil
    end
    local pattern = "Player: " .. player_name .. "\nMuted by: (.-)\nReason: (.-)\nMuted at: (.-)\nDuration: (.-) minutes\n\n"
    local muter_name, reason, mute_start, duration = content:match(pattern)
    if mute_start then
        return {
            mute_start = mute_start,
            reason = reason,
            player_name = player_name,
            muter_name = muter_name,
            duration = tonumber(duration)
        }
    end
    return nil
end

local function parse_date_string(date_string)
    local year = tonumber(date_string:sub(1, 4))
    local month = tonumber(date_string:sub(6, 7))
    local day = tonumber(date_string:sub(9, 10))
    local hour = tonumber(date_string:sub(12, 13))
    local min = tonumber(date_string:sub(15, 16))
    local sec = tonumber(date_string:sub(18, 19))
    return {year = year, month = month, day = day, hour = hour, min = min, sec = sec}
end

function atban.calculate_unmute_time(mute_start, duration_minutes)
    local date_table = parse_date_string(mute_start)
    local mute_start_time = os.time(date_table)
    local unmute_time = mute_start_time + (duration_minutes * 60)
    return os.date("%Y-%m-%d %H:%M:%S", unmute_time)
end

function atban.calculate_unban_time(ban_start, duration_minutes)
    local date_table = parse_date_string(ban_start)
    local ban_start_time = os.time(date_table)
    local unban_time = ban_start_time + (duration_minutes * 60)
    return os.date("%Y-%m-%d %H:%M:%S", unban_time)
end

local function check_and_remove_expired_sanctions()
    local current_time = os.time()
    local ip_ban_file_path = get_file_path("ban_ip.txt")
    local ip_ban_content = read_file(ip_ban_file_path)
    if ip_ban_content then
        for ip, ban_start, duration in ip_ban_content:gmatch("IP: (.-)\nBanned at: (.-)\nDuration: (.-) minutes\n\n") do
            local ban_start_time = os.time(parse_date_string(ban_start))
            local unban_time = ban_start_time + (tonumber(duration) * 60)
            if current_time >= unban_time then
                local new_content = ip_ban_content:gsub("IP: " .. ip .. "\nBanned at: .-\nBanned by: .-\nReason: .-\nDuration: .- minutes\n\n", "")
                write_to_file(ip_ban_file_path, new_content)
                minetest.log("action", "IP " .. ip .. " has been unbanned.")
            end
        end
    end    local account_ban_file_path = get_file_path("ban_account.txt")
    local account_ban_content = read_file(account_ban_file_path)
    if account_ban_content then
        for account, ban_start, duration in account_ban_content:gmatch("Account: (.-)\nBanned at: (.-)\nDuration: (.-) minutes\n\n") do
            local ban_start_time = os.time(parse_date_string(ban_start))
            local unban_time = ban_start_time + (tonumber(duration) * 60)
            if current_time >= unban_time then
                local new_content = account_ban_content:gsub("Account: " .. account .. "\nBanned at: .-\nBanned by: .-\nReason: .-\nDuration: .- minutes\n\n", "")
                write_to_file(account_ban_file_path, new_content)
                minetest.log("action", "Account " .. account .. " has been unbanned.")
            end
        end
    end
    local mute_file_path = get_file_path("mute_account.txt")
    local mute_content = read_file(mute_file_path)
    if mute_content then
        for player, mute_start, duration in mute_content:gmatch("Player: (.-)\nMuted at: (.-)\nDuration: (.-) minutes\n\n") do
            local mute_start_time = os.time(parse_date_string(mute_start))
            local unmute_time = mute_start_time + (tonumber(duration) * 60)
            if current_time >= unmute_time then
                local new_content = mute_content:gsub("Player: " .. player .. "\nMuted by: .-\nReason: .-\nMuted at: .-\nDuration: .- minutes\n\n", "")
                write_to_file(mute_file_path, new_content)
                minetest.log("action", "Player " .. player .. " has been unmuted.")
            end
        end
    end
end

local last_check_time = 0

minetest.register_globalstep(function(dtime)
    last_check_time = last_check_time + dtime
    if last_check_time >= 60 then
        check_and_remove_expired_sanctions()
        last_check_time = 0
    end
end)
