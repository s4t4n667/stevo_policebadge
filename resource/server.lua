lib.locale()

ESX = exports["es_extended"]:getSharedObject()

local config = lib.require('config')


lib.callback.register("stevo_policebadge:retrieveInfo", function(source)
    local badge_data = {}

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return badge_data end  -- Ensure player exists

    badge_data.name = xPlayer.getName()
    badge_data.rank = xPlayer.getJob().gradeName or "Unknown"

    local id = xPlayer.getIdentifier()
    local result = MySQL.single.await('SELECT `image` FROM `stevo_badge_photos` WHERE `identifier` = ? LIMIT 1', { id })
    
    badge_data.photo = result and result.image or nil
    
    return badge_data
end)


lib.callback.register("stevo_policebadge:setBadgePhoto", function(source, photo)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = xPlayer.getIdentifier()

    local image = MySQL.single.await('SELECT `image` FROM `stevo_badge_photos` WHERE `identifier` = ? LIMIT 1', {
        identifier
    })

    if not image then 
        id = MySQL.insert.await('INSERT INTO `stevo_badge_photos` (identifier, image) VALUES (?, ?)', {
            identifier, photo
        })
    else 
        id = MySQL.update.await('UPDATE `stevo_badge_photos` SET image = ? WHERE identifier = ?', {
            photo, identifier
        })
    end
    return id
end)

RegisterNetEvent('stevo_policebadge:showbadge')
AddEventHandler('stevo_policebadge:showbadge', function(data, ply)
    for i, player in pairs(ply) do
        TriggerClientEvent('stevo_policebadge:displaybadge', player, data)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    local tableExists, result = pcall(MySQL.scalar.await, 'SELECT 1 FROM stevo_badge_photos')

    if not tableExists then
        MySQL.query([[CREATE TABLE IF NOT EXISTS `stevo_badge_photos` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `identifier` VARCHAR(50) NOT NULL,
        `image` longtext NOT NULL,
        PRIMARY KEY (`id`)
        )]])

        lib.print.info('[Stevo Scripts] Deployed database table for stevo_badge_photos')
    end

    ESX.RegisterUsableItem(config.badge_item_name, function(source)
        TriggerClientEvent('stevo_policebadge:use', source)
    end)
end)

