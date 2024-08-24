MySQL.ready(function()
    MySQL.Async.execute('CREATE TABLE `player_vip_status` (`identifier` varchar(50) NOT NULL,`is_vip` tinyint(1) NOT NULL DEFAULT 0,`vip_expiration` date DEFAULT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;')
    MySQL.Async.execute('CREATE TABLE `vip_codes` (`code` varchar(50) NOT NULL,`is_used` tinyint(1) NOT NULL DEFAULT 0,`days_to_add` int(11) DEFAULT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;')
    MySQL.Async.execute('CREATE TABLE `vip_cooldown` (`player_identifier` varchar(255) DEFAULT NULL,`command` varchar(50) DEFAULT NULL,`last_used` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;')
end)

RegisterCommand("givevip", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source > 0 and xPlayer.getGroup() == "user" then
        print("This command can only be used from the server console or by server admins.")
        return
    end

    local targetPlayerId = tonumber(args[1])
    local days = tonumber(args[2])

    if targetPlayerId and days then
        local identifiers = GetPlayerIdentifiers(targetPlayerId)
        local identifier = nil
        for _, id in pairs(identifiers) do
            if string.match(id, "discord:") then
                identifier = id
                break
            end
        end

        if identifier then
            local expirationDate = os.date("%Y-%m-%d", os.time() + (days * 86400))
            MySQL.Async.execute(
            'REPLACE INTO player_vip_status (identifier, is_vip, vip_expiration) VALUES (@identifier, TRUE, @expirationDate)',
                {
                    ['@identifier'] = identifier,
                    ['@expirationDate'] = expirationDate
                }, function(affectedRows)
                if affectedRows > 0 then
                    print("VIP status granted to identifier " .. identifier .. " for " .. days .. " days.")
                else
                    print("Failed to grant VIP status.")
                end
            end)
        else
            print("Unable to find a valid identifier for the given player ID.")
        end
    else
        print("Usage: givevip [playerId] [days]")
    end
end, true)

RegisterCommand("vipcodes", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source > 0 and xPlayer.getGroup() == "user" then
        print("This command can only be used from the server console or by server admins.")
        return
    end

    MySQL.Async.fetchAll('SELECT code, days_to_add FROM vip_codes ORDER BY days_to_add DESC', {}, function(results)
        if results and #results > 0 then
            local message = "VIP Codes:\n"

            for _, row in ipairs(results) do
                message = message .. "Code: " .. row.code .. " | Days to Add: " .. row.days_to_add .. "\n"
            end

            print(message)
        else
            print("No VIP codes found in the database.")
        end
    end)
end, true)

RegisterCommand("compvip", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source > 0 and xPlayer.getGroup() == "user" then
        print("This command can only be used from the server console or by server admins.")
        return
    end

    local daysToAdd = tonumber(args[1] or 0)

    if daysToAdd > 0 then
        local newExpiration = os.date('%Y-%m-%d', os.time() + (daysToAdd * 24 * 60 * 60))
        MySQL.Async.execute(
        'UPDATE player_vip_status SET vip_expiration = DATE_ADD(vip_expiration, INTERVAL @daysToAdd DAY) WHERE is_vip = TRUE AND vip_expiration >= CURDATE()',
            {
                ['@daysToAdd'] = daysToAdd
            }, function(rowsChanged)
            if rowsChanged > 0 then
                print('Active VIP players have been compensated with ' .. daysToAdd .. ' additional VIP days.')
            else
                print('No active VIP players found to compensate.')
            end
        end)
    else
        print('Invalid number of days to add.')
    end
end, false)

RegisterCommand("genvip", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if source > 0 and xPlayer.getGroup() == "user" then
        print("This command can only be used from the server console or by server admins.")
        return
    end

    local numberOfCodes = tonumber(args[1]) or 1
    local daysValid = tonumber(args[2]) or 30

    for i = 1, numberOfCodes do
        local code = tostring(math.random(100000, 999999))

        MySQL.Async.execute('INSERT INTO vip_codes (code, is_used, days_to_add) VALUES (@code, FALSE, @daysToAdd)', {
            ['@code'] = code,
            ['@daysToAdd'] = daysValid
        }, function(affectedRows)
            if affectedRows > 0 then
                print("VIP code generated: " .. code .. " | Days to add: " .. daysValid)
            else
                print("Failed to generate VIP code.")
            end
        end)
    end
end, true)

function checkVipExpirations()
    MySQL.Async.execute('UPDATE player_vip_status SET is_vip = FALSE WHERE vip_expiration <= CURDATE() AND is_vip = TRUE', {}, function(affectedRows)
        if affectedRows > 0 then
            print("Updated " .. affectedRows .. " VIP statuses to expired.")
        end
    end)
end

function VipFunctions(source)
    --print("has vip ", source)
    exports.ox_inventory:SetMaxWeight(source, 50000)
end

function DeVIPFunctions(source)
    --print("doesnt have vip ", source)
    exports.ox_inventory:SetMaxWeight(source, 24000)
end

lib.callback.register('vip:getDaysLeft', function(source)
    local data = IsVIP(source)
    Wait(150)
    if data.isVip then
        VipFunctions(source)
    else
        DeVIPFunctions(source)
    end
    return data
end)

lib.callback.register('vip:redeemcode', function(source, code)
    local data = {}
    local sourcePlayerId = source
    local identifiers = GetPlayerIdentifiers(sourcePlayerId)
    local identifier = nil

    for _, id in pairs(identifiers) do
        if string.match(id, "discord:") then
            identifier = id
            break
        end
    end

    if identifier then
        MySQL.Async.fetchAll('SELECT is_used, days_to_add FROM vip_codes WHERE code = @code', { ['@code'] = code },
            function(result)
                if #result == 0 or result[1].is_used then
                    data.response = "Code already used or invalid."
                    data.status = "inform"
                else
                    local daysToAdd = result[1].days_to_add

                    MySQL.Async.execute('DELETE FROM vip_codes WHERE code = @code', { ['@code'] = code },
                        function(rowsDeleted)
                            if rowsDeleted > 0 then
                                MySQL.Async.fetchAll('SELECT vip_expiration FROM player_vip_status WHERE identifier = @identifier',
                                    { ['@identifier'] = identifier }, function(vipResult)
                                        if #vipResult == 0 then
                                            MySQL.Async.execute('INSERT INTO player_vip_status (identifier, is_vip, vip_expiration) VALUES (@identifier, TRUE, DATE_ADD(CURDATE(), INTERVAL @daysToAdd DAY))',
                                                {
                                                    ['@identifier'] = identifier,
                                                    ['@daysToAdd'] = daysToAdd
                                                }, function(rowsInserted)
                                                    if rowsInserted > 0 then
                                                        data.response = "VIP status granted successfully."
                                                        data.status = "success"
                                                    else
                                                        data.response = "Failed to create VIP status."
                                                        data.status = "error"
                                                    end
                                                end)
                                        else
                                            local vipExpiration = vipResult[1].vip_expiration
                                            local currentDate = os.time(os.date("!*t")) * 1000
                                            local updateQuery = ''

                                            if vipExpiration < currentDate then
                                                updateQuery = 'UPDATE player_vip_status SET vip_expiration = DATE_ADD(CURDATE(), INTERVAL @daysToAdd DAY) WHERE identifier = @identifier'
                                            else
                                                updateQuery = 'UPDATE player_vip_status SET vip_expiration = DATE_ADD(vip_expiration, INTERVAL @daysToAdd DAY) WHERE identifier = @identifier'
                                            end

                                            MySQL.Async.execute(updateQuery,
                                                {
                                                    ['@identifier'] = identifier,
                                                    ['@daysToAdd'] = daysToAdd
                                                }, function(rowsChanged)
                                                    if rowsChanged > 0 then
                                                        data.response = "VIP status extended successfully."
                                                        data.status = "success"
                                                    else
                                                        data.response = "Failed to extend VIP status."
                                                        data.status = "error"
                                                    end
                                                end)
                                        end
                                    end)
                            else
                                data.response = "Failed to delete the code or it was already used."
                                data.status = "error"
                            end
                        end)
                end
            end)
    else
        data.response = "Unable to find a valid identifier."
        data.status = "error"
    end
    Citizen.Wait(150)
    print(data.response)
    return data
end)


function getLicenseIdentifier(playerServerId)
    local identifiers = GetPlayerIdentifiers(playerServerId)
    for _, v in pairs(identifiers) do
        if string.match(v, 'discord:') then
            return v
        end
    end
    return nil
end

function checkCooldown(playerIdentifier, command, cb)
    MySQL.Async.fetchScalar(
    'SELECT UNIX_TIMESTAMP(last_used) FROM vip_cooldown WHERE player_identifier = @playerIdentifier AND command = @command',
        {
            ['@playerIdentifier'] = playerIdentifier,
            ['@command'] = command
        }, function(lastUsedUnix)
        if lastUsedUnix then
            local currentTime = os.time()
            local timePassed = currentTime - lastUsedUnix
            local cooldown = 86400 -- 24 hours in seconds
            if timePassed < cooldown then
                local timeLeft = cooldown - timePassed
                local hours = math.floor(timeLeft / 3600)
                local minutes = math.floor((timeLeft % 3600) / 60)
                local seconds = timeLeft % 60
                cb(false, string.format("%02dh %02dm %02ds", hours, minutes, seconds))
            else
                cb(true)
            end
        else
            cb(true)
        end
    end)
end

function updateCooldown(playerIdentifier, command)
    MySQL.Async.execute(
    'INSERT INTO vip_cooldown (player_identifier, command, last_used) VALUES (@playerIdentifier, @command, NOW()) ON DUPLICATE KEY UPDATE last_used = NOW()',
        {
            ['@playerIdentifier'] = playerIdentifier,
            ['@command'] = command
        }, function(affectedRows)
        if affectedRows then
            print("Cooldown for " .. playerIdentifier .. " on command " .. command .. " has been updated.")
        else
            print("Failed to update cooldown for " .. playerIdentifier .. " on command " .. command .. ".")
        end
    end)
end

lib.callback.register('vip:getguns', function(source)
    local data = "error"
    local playerServerId = source
    local playerIdentifier = getLicenseIdentifier(playerServerId)
    if playerIdentifier then
        checkCooldown(playerIdentifier, 'guns', function(canUse, timeLeft)
            if canUse then
                local data = IsVIP(source)
                if data.isVip then
                    VipFunctions(source)
                    updateCooldown(playerIdentifier, 'guns')
                    exports.ox_inventory:AddItem(playerServerId, "weapon_pistol50", 3)
                    exports.ox_inventory:AddItem(playerServerId, "weapon_bullpuprifle", 3)
                    exports.ox_inventory:AddItem(playerServerId, "weapon_specialcarbine", 3)
                    exports.ox_inventory:AddItem(playerServerId, "weapon_carbinerifle", 3)
                    exports.ox_inventory:AddItem(playerServerId, "weapon_assaultrifle", 3)
                    exports.ox_inventory:AddItem(playerServerId, "weapon_tacticalrifle", 3)
                    exports.ox_inventory:AddItem(playerServerId, "case_prisma2", 3)
                    exports.ox_inventory:AddItem(playerServerId, "case_recoil", 5)
                    data = 'Have fun!'
                end
            else
                data = 'You must wait ' .. timeLeft .. ' to use the guns command again.'
            end
        end)
    else
        data = 'Could not retrieve your license identifier.'
    end
    Wait(150)
    return data
end)

lib.callback.register('vip:getmoney', function(source)
    local data = "error"
    local playerServerId = source
    local playerIdentifier = getLicenseIdentifier(playerServerId)
    if playerIdentifier then
        checkCooldown(playerIdentifier, 'money', function(canUse, timeLeft)
            if canUse then
                local data = IsVIP(source)
                if data.isVip then
                    VipFunctions(source)
                    updateCooldown(playerIdentifier, 'money')
                    exports.ox_inventory:AddItem(playerServerId, "money", 5000000)
                    data = 'Have fun!'
                end
            else
                data = 'You must wait ' .. timeLeft .. ' to use the money command again.'
            end
        end)
    else
        data = 'Could not retrieve your license identifier.'
    end
    Wait(150)
    return data
end)


function IsVIP(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local licenseIdentifier = nil

    for _, id in ipairs(identifiers) do
        if string.match(id, "discord:") then
            licenseIdentifier = id
            break
        end
    end

    local data = { isVip = false, daysLeft = 0 }

    if licenseIdentifier then
        local result = MySQL.Sync.fetchAll(
        'SELECT DATEDIFF(vip_expiration, CURDATE()) AS days_left FROM player_vip_status WHERE identifier = @identifier AND is_vip = TRUE AND vip_expiration >= CURDATE()',
            {
                ['@identifier'] = licenseIdentifier
            })

        if result and #result > 0 and result[1].days_left then
            local daysLeft = tonumber(result[1].days_left)
            if daysLeft > 0 then
                data.isVip = true
                data.daysLeft = daysLeft
            end
        end
    end

    return data
end

exports('IsVIP', IsVIP)


RegisterCommand("v", function(source, args, rawCommand)
    local playerId = source
    if IsVIP(playerId).isVip then
        local playerName = GetPlayerName(playerId)
        local steamId = GetPlayerIdentifiers(playerId)[1]
        local message = table.concat(args, " ")

        local players = GetPlayers()
        for _, id in ipairs(players) do
            if IsVIP(id) then
                TriggerClientEvent('chat:addMessage', id, {
                    template = '<div style="padding: 0.7vw; margin: 0.5vw; background-color: rgba(255, 215, 0, 0.8); color: white; border-radius: 8px; border-left: 6px solid rgba(255, 255, 255, 0.9); box-shadow: 0 0 10px rgba(255, 255, 255, 0.9);"><i class="fas fa-crown"></i> <b>{0}</b> {1}</div>',
                    args = { 'VIP:', '' .. playerId .. ' | ' .. playerName .. ': ' .. message }
                })
                
                --TriggerClientEvent('chatMessage', id, "[VIP] " .. playerId .. " | " .. playerName .. ": " .. message)
            end
        end
    else
        --TriggerClientEvent('chatMessage', playerId, "^1You are not a VIP and cannot use this chat.")
        TriggerClientEvent('chat:addMessage', playerId, {
            template = '<div style="padding: 0.7vw; margin: 0.5vw; background-color: rgba(255, 215, 0, 0.8); color: white; border-radius: 8px; border-left: 6px solid rgba(255, 255, 255, 0.9); box-shadow: 0 0 10px rgba(255, 255, 255, 0.9);"><i class="fas fa-crown"></i> <b>{0}</b> {1}</div>',
            args = { "^1VIP:", "^1You are not a VIP and cannot use this chat." }
        })
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 300,000 milliseconds = 5 minutes
        checkVipExpirations()
    end
end)

-- function getTimeLeft(playerIdentifier, command, cb)
--     MySQL.Async.fetchScalar('SELECT UNIX_TIMESTAMP(last_used) FROM vip_cooldown WHERE player_identifier = @playerIdentifier AND command = @command', {
--         ['@playerIdentifier'] = playerIdentifier,
--         ['@command'] = command
--     }, function(lastUsedUnix)
--         if lastUsedUnix then
--             local currentTime = os.time()
--             local timePassed = currentTime - lastUsedUnix
--             local cooldown = 86400 -- 24 hours in seconds
--             if timePassed < cooldown then
--                 local timeLeft = cooldown - timePassed
--                 local hours = math.floor(timeLeft / 3600)
--                 local minutes = math.floor((timeLeft % 3600) / 60)
--                 local seconds = timeLeft % 60
--                 cb(string.format("%02dh %02dm %02ds", hours, minutes, seconds))
--             else
--                 cb("No cooldown.") -- No cooldown is currently active
--             end
--         else
--             cb("No cooldown.") -- Command has not been used yet
--         end
--     end)
-- end
