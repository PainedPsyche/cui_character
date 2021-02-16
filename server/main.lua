local function getPlayerLicense(source)
    for k,v in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(v, 'license:') then
            return string.sub(v, 9)
        end
    end
    return false
end

if not Config.StandAlone then  
    if not Config.EnableESXIdentityIntegration then
        ESX = nil
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

        RegisterNetEvent('esx:onPlayerJoined')
        AddEventHandler('esx:onPlayerJoined', function()
            if not ESX.Players[source] then
                local identifier = getPlayerLicense(source)

                if identifier then
                    MySQL.ready(function()
                        MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
                            ['@identifier'] = identifier
                        }, function(result)
                            if not result then
                                -- first login stuff
                            else
                                -- subsequent login stuff
                            end
                        end)
                    end)
                end
            end
        end)
    end

    RegisterServerEvent('cui_character:save')
    AddEventHandler('cui_character:save', function(data)
        local xPlayer = ESX.GetPlayerFromId(source)
        MySQL.ready(function()
            MySQL.Async.execute('UPDATE users SET skin = @data WHERE identifier = @identifier', {
                ['@data'] = json.encode(data),
                ['@identifier'] = xPlayer.identifier
            })
        end)
    end)

    RegisterServerEvent('esx_skin:save')
    AddEventHandler('esx_skin:save', function(data)
        TriggerEvent('cui_character:save', data)
    end)

    ESX.RegisterServerCallback('esx_skin:getPlayerSkin', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        MySQL.ready(function()
            MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier
            }, function(users)
                local user = users[1]
                local skin = nil

                local jobSkin = {
                    skin_male   = xPlayer.job.skin_male,
                    skin_female = xPlayer.job.skin_female
                }

                if user.skin ~= nil then
                    skin = json.decode(user.skin)
                end

                cb(skin, jobSkin)
            end)
        end)
    end)

    if Config.EnableESXIdentityIntegration then
        ESX.RegisterServerCallback('cui_character:updateIdentity', function(source, cb, data)
            local xPlayer = ESX.GetPlayerFromId(source)
            
            if xPlayer then
                if checkNameFormat(data.firstname) and checkNameFormat(data.lastname) and checkSexFormat(data.sex) and checkDOBFormat(data.dateofbirth) and checkHeightFormat(data.height) then
                    local playerIdentity = {}
                    playerIdentity[xPlayer.identifier] = {
                        firstName = formatName(data.firstname),
                        lastName = formatName(data.lastname),
                        dateOfBirth = data.dateofbirth,
                        sex = data.sex,
                        height = data.height
                    }

                    local currentIdentity = playerIdentity[xPlayer.identifier]

                    xPlayer.setName(('%s %s'):format(currentIdentity.firstName, currentIdentity.lastName))
                    xPlayer.set('firstName', currentIdentity.firstName)
                    xPlayer.set('lastName', currentIdentity.lastName)
                    xPlayer.set('dateofbirth', currentIdentity.dateOfBirth)
                    xPlayer.set('sex', currentIdentity.sex)
                    xPlayer.set('height', currentIdentity.height)

                    saveIdentityToDatabase(xPlayer.identifier, currentIdentity)
                    cb(true)
                else
                    cb(false)
                end
            end
        end)

        ESX.RegisterServerCallback('cui_character:getIdentity', function(source, cb)
            local xPlayer = ESX.GetPlayerFromId(source)
            MySQL.ready(function()
                MySQL.Async.fetchAll('SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                }, function(users)
                    local user = users[1]
                    local identity = {}

                    if user ~= nil then
                        for k, v in pairs(user) do
                            identity[k] = v
                        end
                    end

                    cb(identity)
                end)
            end)
        end)
    end

    ESX.RegisterCommand('character', 'admin', function(xPlayer, args, showError)
        xPlayer.triggerEvent('cui_character:open', { 'identity', 'features', 'style', 'apparel' })
        end, true, {help = 'Open full character editor.', validate = true, arguments = {}
    })

    ESX.RegisterCommand('identity', 'admin', function(xPlayer, args, showError)
        xPlayer.triggerEvent('cui_character:open', { 'identity' })
        end, true, {help = 'Open character identity editor.', validate = true, arguments = {}
    })

    ESX.RegisterCommand('features', 'admin', function(xPlayer, args, showError)
        xPlayer.triggerEvent('cui_character:open', { 'features' })
        end, true, {help = 'Open character physical features editor.', validate = true, arguments = {}
    })

    ESX.RegisterCommand('style', 'admin', function(xPlayer, args, showError)
        xPlayer.triggerEvent('cui_character:open', { 'style' })
        end, true, {help = 'Open character style editor.', validate = true, arguments = {}
    })

    ESX.RegisterCommand('apparel', 'admin', function(xPlayer, args, showError)
        xPlayer.triggerEvent('cui_character:open', { 'apparel' })
        end, true, {help = 'Open character apparel editor.', validate = true, arguments = {}
    })

-- Standalone Deployment
else
    -- Create the database table if it does not exist
    MySQL.ready(function()
        MySQL.Async.execute('CREATE TABLE IF NOT EXISTS `player_skins` (`id` int(11) NOT NULL auto_increment, `identifier` varchar(128) NOT NULL, `skin` LONGTEXT NULL DEFAULT NULL, PRIMARY KEY  (`id`), UNIQUE(`identifier`))',{}, 
        function() end)
    end)

    RegisterServerEvent('cui_character:save')
    AddEventHandler('cui_character:save', function(data)
        local _source = source
        local license = getPlayerLicense(_source)

        if license then
            MySQL.ready(function()
                MySQL.Async.execute('INSERT INTO `player_skins` (`identifier`, `skin`) VALUES (@identifier, @skin) ON DUPLICATE KEY UPDATE `skin` = @skin', {
                    ['@skin'] = json.encode(data),
                    ['@identifier'] = license
                })
            end)
        end
    end)

    RegisterServerEvent('cui_character:requestPlayerData')
    AddEventHandler('cui_character:requestPlayerData', function()
        local _source = source
        local license = getPlayerLicense(_source)

        if license then
            MySQL.ready(function()
                MySQL.Async.fetchAll('SELECT skin FROM player_skins WHERE identifier = @identifier', {
                    ['@identifier'] = license
                }, function(users)
                    local playerData = { skin = nil, newPlayer = true}
                    if users and users[1] ~= nil and users[1].skin ~= nil then
                        playerData.skin = json.decode(users[1].skin)
                        playerData.newPlayer = false
                    end
                    TriggerClientEvent('cui_character:recievePlayerData', _source, playerData)
                end)
            end)
        end
    end)

    RegisterCommand("character", function(source, args, rawCommand)
        if (source > 0) then
            TriggerClientEvent('cui_character:open', source, { 'features', 'style', 'apparel' })
        end
    end, true)

    RegisterCommand("features", function(source, args, rawCommand)
        if (source > 0) then
            TriggerClientEvent('cui_character:open', source, { 'features' })
        end
    end, true)

    RegisterCommand("style", function(source, args, rawCommand)
        if (source > 0) then
            TriggerClientEvent('cui_character:open', source, { 'style' })
        end
    end, true)

    RegisterCommand("apparel", function(source, args, rawCommand)
        if (source > 0) then
            TriggerClientEvent('cui_character:open', source, { 'apparel' })
        end
    end, true)

end