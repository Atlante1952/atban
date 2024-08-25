atban = {}

local function create_directory(path)
    if not minetest.mkdir(path) then
        if minetest.get_dir_list(path) then
            minetest.log("info", "The directory " .. path .. " already exists.")
        else
            minetest.log("error", "Failed to create the directory " .. path .. ".")
            return false
        end
    else
        minetest.log("info", "The directory " .. path .. " has been created.")
    end
    return true
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function write_to_file(path, content)
    local success, err = minetest.safe_file_write(path, content)
    if not success then
        minetest.log("error", "Failed to write to file " .. path .. ". Error: " .. (err or "unknown"))
    end
    return success
end

local function get_file_path(player_name, subdir)
    local base_dir = minetest.get_worldpath() .. "/atban"
    if subdir then
        base_dir = base_dir .. "/" .. subdir
    end
    return base_dir .. "/" .. player_name .. ".txt"
end

function atban.create_atban_files(name, ip)
    local atban_dir = minetest.get_worldpath() .. "/atban"
    local player_file = get_file_path(name)

    if not create_directory(atban_dir) then
        return
    end

    if file_exists(player_file) then
        minetest.log("info", "The file " .. name .. ".txt already exists.")
    else
        local content = "IP: " .. ip .. "\n"
        if write_to_file(player_file, content) then
            minetest.log("info", "The file " .. name .. ".txt has been created with IP " .. ip .. ".")
        end
    end
end

function atban.clear_ban_file(player_name)
    local file_path = get_file_path(player_name)
    if not write_to_file(file_path, "") then
        return false, "Failed to clear file."
    end
    return true
end

function atban.write_ban_info(player_name, reason, banning_player)
    local file_path = get_file_path(player_name)
    local file = io.open(file_path, "a")
    if not file then
        return false
    end

    local current_time = os.date("[%Y-%m-%d] - %H:%M:%S")
    local ban_info = string.format("Account banned at: %s\nDuration: Permanent\nBanned by: %s\nReason: %s\n\n",
                                   current_time, banning_player, reason)

    file:write(ban_info)
    file:close()
    return true
end

function atban.mute_player(player_name, reason, muter_name)
    local mute_dir = minetest.get_worldpath() .. "/atban/mute"
    local file_path = get_file_path(player_name, "mute")

    if not create_directory(mute_dir) then
        return false, "Failed to create mute directory."
    end

    local file = io.open(file_path, "w")
    if not file then
        return false, "Error while writing mute file."
    end

    file:write("Player: " .. player_name .. "\n")
    file:write("Muted by: " .. muter_name .. "\n")
    file:write("Reason: " .. reason .. "\n")
    file:write("Muted at: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    file:close()

    return true, "Player " .. player_name .. " has been muted successfully."
end

function atban.ban_account(player_name, reason, banning_player)
    local success, err = atban.clear_ban_file(player_name)
    if not success then
        return false, err
    end

    success, err = atban.write_ban_info(player_name, reason, banning_player)
    if not success then
        return false, err
    end

    local target_player = minetest.get_player_by_name(player_name)
    if target_player then
        minetest.kick_player(player_name, "Your account has been permanently banned.\nReason: " .. reason)
    end
    return true, "Player " .. player_name .. " has been permanently banned."
end

function atban.is_player_banned(player_name)
    local file_path = get_file_path(player_name)
    local file = io.open(file_path, "r")
    if not file then
        return false
    end

    local content = file:read("*all")
    file:close()

    return content:find("Account banned at:") ~= nil
end

function atban.get_ban_details(player_name)
    local file_path = get_file_path(player_name)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if content:find("Account banned at:") then
        local reason = content:match("Reason: (.-)\n")
        local duration = content:match("Duration: (.-)\n")
        local banner_name = content:match("Banned by: (.-)\n")
        local ban_start = content:match("Account banned at: (.-)\n")
        return {
            ban_start = ban_start,
            reason = reason,
            duration = duration,
            player_name = player_name,
            banner_name = banner_name
        }
    end
    return nil
end

function atban.get_mute_details(player_name)
    local file_path = get_file_path(player_name, "mute")
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    if content:find("Muted at:") then
        local reason = content:match("Reason: (.-)\n")
        local muter_name = content:match("Muted by: (.-)\n")
        local mute_start = content:match("Muted at: (.-)\n")
        return {
            mute_start = mute_start,
            reason = reason,
            player_name = player_name,
            muter_name = muter_name
        }
    end
    return nil
end

function atban.ban_ip(ip, reason, banning_player)
    local banned_ips_file = minetest.get_worldpath() .. "/banned_ips.txt"
    local file = io.open(banned_ips_file, "a")
    if not file then
        minetest.log("error", "Failed to open banned IPs file for writing.")
        return false, "Failed to open banned IPs file."
    end

    local current_time = os.date("[%Y-%m-%d] - %H:%M:%S")
    local ban_info = string.format("IP: %s\nBanned at: %s\nBanned by: %s\nReason: %s\n\n",
                                   ip, current_time, banning_player, reason)

    file:write(ban_info)
    file:close()

    minetest.log("action", string.format("IP %s has been banned by %s for reason: %s", ip, banning_player, reason))
    return true, "IP " .. ip .. " has been banned."
end

function atban.is_ip_banned(ip)
    local banned_ips_file = minetest.get_worldpath() .. "/banned_ips.txt"
    local file = io.open(banned_ips_file, "r")
    if not file then
        return false
    end

    local content = file:read("*all")
    file:close()

    return content:find("IP: " .. ip) ~= nil
end

function atban.get_player_ip_from_file(player_name)
    local file_path = get_file_path(player_name)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end

    local content = file:read("*all")
    file:close()

    local ip = content:match("IP: (.-)\n")
    return ip
end
