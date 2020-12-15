if not Config.EnableESXIdentityIntegration then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

    RegisterNetEvent('esx:onPlayerJoined')
    AddEventHandler('esx:onPlayerJoined', function()
        if not ESX.Players[source] then
            local identifier

            for k,v in ipairs(GetPlayerIdentifiers(source)) do
                if string.match(v, 'license:') then
                    identifier = string.sub(v, 9)
                    break 
                end
            end

            if identifier then
                MySQL.Async.fetchScalar('SELECT 1 FROM users WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                }, function(result)
                    if not result then
                        -- first login stuff
                    else
                        -- subsequent login stuff
                    end
                end)
            end
        end
    end)
end

RegisterServerEvent('cui_character:save')
AddEventHandler('cui_character:save', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.execute('UPDATE users SET skin = @data WHERE identifier = @identifier', {
        ['@data'] = json.encode(data),
        ['@identifier'] = xPlayer.identifier
    })
end)

ESX.RegisterServerCallback('cui_character:getPlayerSkin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(users)
        local user = users[1]
        local skin = nil

        if user.skin ~= nil then
            skin = json.decode(user.skin)
        end

        cb(skin, jobSkin)
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