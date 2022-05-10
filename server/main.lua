ESX = nil

local function getPlayerLicense(source)
    for k,v in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(v, 'license:') then
            return string.sub(v, 9)
        end
    end
    return false
end

if not Config.StandAlone then
    if Config.ExtendedMode then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    else
        ESX = exports['es_extended']:getSharedObject()
    end

    if not ESX then
        SetTimeout(3000, print('[^3WARNING^7] Unable to start cui_character - your version of ESX is not compatible '))
    end

    local charSkins = {}

    if not Config.EnableESXIdentityIntegration then
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

        if ESX.GetConfig().Multichar and xPlayer == nil then
            charSkins[source] = data
            return
        else
            charSkins[source] = nil
        end

        MySQL.ready(function()
            MySQL.Async.execute('UPDATE users SET skin = @data WHERE identifier = @identifier', {
                ['@data'] = json.encode(data),
                ['@identifier'] = xPlayer.identifier
            })
        end)
    end)

    RegisterServerEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(source, xPlayer, isNew, skin)
        local data = charSkins[source]
        if isNew and ESX.GetConfig().Multichar and data then
            MySQL.ready(function()
                MySQL.Async.execute('UPDATE users SET skin = @data WHERE identifier = @identifier', {
                    ['@data'] = json.encode(data),
                    ['@identifier'] = xPlayer.identifier
                })
            end)
        end
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
        -- start of copied identity functions
        function checkAlphanumeric(str)
            return (string.match(str, "%W"))
        end

        function checkForNumbers(str)
            return (string.match(str,"%d"))
        end

        function checkDate(str)
            if string.match(str, '(%d%d)/(%d%d)/(%d%d%d%d)') ~= nil then
                local m, d, y = string.match(str, '(%d+)/(%d+)/(%d+)')
                m = tonumber(m)
                d = tonumber(d)
                y = tonumber(y)
                if ((d <= 0) or (d > 31)) or ((m <= 0) or (m > 12)) or ((y <= Config.LowestYear) or (y > Config.HighestYear)) then
                    return false
                elseif m == 4 or m == 6 or m == 9 or m == 11 then
                    if d > 30 then
                        return false
                    else
                        return true
                    end
                elseif m == 2 then
                    if y%400 == 0 or (y%100 ~= 0 and y%4 == 0) then
                        if d > 29 then
                            return false
                        else
                            return true
                        end
                    else
                        if d > 28 then
                            return false
                        else
                            return true
                        end
                    end
                else
                    if d > 31 then
                        return false
                    else
                        return true
                    end
                end
            else
                return false
            end
        end

        function checkNameFormat(name)
            if not checkAlphanumeric(name) then
                if not checkForNumbers(name) then
                    local stringLength = string.len(name)
                    if stringLength > 0 and stringLength < Config.MaxNameLength then
                        return true
                    else
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        end

        function checkDOBFormat(dob)
            local date = tostring(dob)
            if checkDate(date) then
                return true
            else
                return false
            end
        end

        function checkSexFormat(sex)
            if sex == "m" or sex == "M" or sex == "f" or sex == "F" then
                return true
            else
                return false
            end
        end

        function checkHeightFormat(height)
            local numHeight = tonumber(height)
            if numHeight < Config.MinHeight and numHeight > Config.MaxHeight then
                return false
            else
                return true
            end
        end

        function formatName(name)
            local loweredName = convertToLowerCase(name)
            local formattedName = convertFirstLetterToUpper(loweredName)
            return formattedName
        end
        
        function convertToLowerCase(str)
            return string.lower(str)
        end
        
        function convertFirstLetterToUpper(str)
            return str:gsub("^%l", string.upper)
        end

        function saveIdentityToDatabase(identifier, identity)
            MySQL.Sync.execute('UPDATE users SET firstname = @firstname, lastname = @lastname, dateofbirth = @dateofbirth, sex = @sex, height = @height WHERE identifier = @identifier', {
                ['@identifier']  = identifier,
                ['@firstname'] = identity.firstName,
                ['@lastname'] = identity.lastName,
                ['@dateofbirth'] = identity.dateOfBirth,
                ['@sex'] = identity.sex,
                ['@height'] = identity.height
            })
        end
        -- end of copied identity functions

        ESX.RegisterServerCallback('cui_character:updateIdentity', function(source, cb, data)
            local xPlayer = ESX.GetPlayerFromId(source)
            
            if xPlayer then
                if checkNameFormat(data.firstname) and checkNameFormat(data.lastname) and checkSexFormat(data.sex) and checkDOBFormat(data.dateofbirth) and checkHeightFormat(data.height) then
                    local currentIdentity = {
                        firstName = formatName(data.firstname),
                        lastName = formatName(data.lastname),
                        dateOfBirth = data.dateofbirth,
                        sex = data.sex,
                        height = data.height
                    }
    
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
            else
                if ESX.GetConfig().Multichar and checkNameFormat(data.firstname) and checkNameFormat(data.lastname) and checkSexFormat(data.sex) and checkDOBFormat(data.dateofbirth) and checkHeightFormat(data.height) then
                    cb(true)
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


    if not Config.UseLocalClothingJSON then
        ESX.RegisterServerCallback('cui_character_workaround:getClothingComponent', function(source, cb, typeId, isMale)
            local url = Config.DefaultClothingUrlBase

            if isMale then
                url = url..Config.DefaultClothing.components.male[typeId]
            else
                url = url..Config.DefaultClothing.components.female[typeId]
            end

            PerformHttpRequest(url, function (errorCode, resultData, resultHeaders)
                cb(resultData)
            end)
        end)

        ESX.RegisterServerCallback('cui_character_workaround:getClothingProp', function(source, cb, typeId, isMale)
            local url = Config.DefaultClothingUrlBase

            if isMale then
                url = url..Config.DefaultClothing.props.male[typeId]
            else
                url = url..Config.DefaultClothing.props.female[typeId]
            end

            PerformHttpRequest(url, function (errorCode, resultData, resultHeaders)
                cb(resultData)
            end)
        end)
    end

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