ESX = exports["es_extended"]:getSharedObject()
local gangInventories = {}
local registeredStashes = {}
local storageCheckInterval = 5000

local function InitGangInventory(gangName)
    if Config.Storage.UseOxInventory then return end
    
    if not gangInventories[gangName] then
        gangInventories[gangName] = {}
        MySQL.Async.fetchAll('SELECT storage_inventory FROM gangs WHERE name = @name', {
            ['@name'] = gangName
        }, function(result)
            if result[1] and result[1].storage_inventory then
                gangInventories[gangName] = json.decode(result[1].storage_inventory)
            end
        end)
    end
end

local function CreateOrUpdateStash(gangName, forceUpdate)
    if not Config.Storage.UseOxInventory then return end
    if not gangName or gangName == '' then return end
    local stashId = 'gang_' .. gangName:gsub("%s+", ""):lower()
    local label = 'Coffre ' .. gangName

    print('[GangBuilder] Tentative d\'enregistrement du stash:', stashId, 'pour le gang:', gangName)

    if registeredStashes[stashId] and not forceUpdate then 
        print('[GangBuilder] Le stash existe déjà:', stashId)
        return 
    end

    MySQL.Async.fetchAll('SELECT storage_pos, has_storage FROM gangs WHERE name = @name', {
        ['@name'] = gangName
    }, function(result)
        if not result[1] or not result[1].has_storage then 
            print('[GangBuilder] Le gang n\'a pas de stockage activé:', gangName)
            return 
        end

        local posRaw = result[1].storage_pos
        if not posRaw then 
            print('[GangBuilder] Pas de position de stockage pour:', gangName)
            return 
        end

        local success, pos = pcall(json.decode, posRaw)
        if not success or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
            print('[GangBuilder] [ERREUR] Position du coffre invalide pour: ' .. gangName)
            return
        end

        local success = pcall(function()
            exports.ox_inventory:RegisterStash(stashId, label, Config.Storage.DefaultSlots or 50, Config.Storage.DefaultWeight or 100000)
        end)
        
        if success then
            registeredStashes[stashId] = true
            print('[GangBuilder] Stash enregistré avec succès:', stashId, '(accessible à tous)')
        else
            print('[GangBuilder] [ERREUR] Échec de l\'enregistrement du stash:', stashId)
        end
    end)
end

local function CheckAndRepairStoragePositions()
    MySQL.Async.fetchAll('SELECT name, storage_pos, has_storage FROM gangs WHERE has_storage = 1', {}, function(gangs)
        for _, gang in ipairs(gangs) do
            if gang.storage_pos then
                local success, pos = pcall(json.decode, gang.storage_pos)
                if not success or type(pos) ~= "table" or not pos.x or not pos.y or not pos.z then
                    print('[GangBuilder] [ERREUR] Position invalide détectée pour: ' .. gang.name)
                    MySQL.Async.execute('UPDATE gangs SET storage_pos = NULL WHERE name = @name', {
                        ['@name'] = gang.name
                    })
                end
            end
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CheckAndRepairStoragePositions()
        Wait(1000)
        MySQL.Async.fetchAll('SELECT name FROM gangs WHERE has_storage = 1', {}, function(gangs)
            for _, gang in ipairs(gangs) do
                CreateOrUpdateStash(gang.name)
            end
        end)
    end
end)

ESX.RegisterServerCallback('gangbuilder:getGangInventory', function(source, cb, gangName)
    if Config.Storage.UseOxInventory then 
        cb({})
        return 
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].gang ~= gangName then
            cb({})
            return
        end
        InitGangInventory(gangName)
        cb(gangInventories[gangName])
    end)
end)

RegisterNetEvent('gangbuilder:depositItem')
AddEventHandler('gangbuilder:depositItem', function(gangName, itemName, amount)
    if Config.Storage.UseOxInventory then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].gang ~= gangName then return end
        
        amount = tonumber(amount)
        if not amount or amount <= 0 then return end

        local item = xPlayer.getInventoryItem(itemName)
        if not item or item.count < amount then return end

        InitGangInventory(gangName)
        if not gangInventories[gangName][itemName] then
            gangInventories[gangName][itemName] = {
                name = itemName,
                label = item.label,
                count = 0
            }
        end
        
        gangInventories[gangName][itemName].count = gangInventories[gangName][itemName].count + amount
        xPlayer.removeInventoryItem(itemName, amount)
        MySQL.Async.execute('UPDATE gangs SET storage_inventory = @inventory WHERE name = @name', {
            ['@inventory'] = json.encode(gangInventories[gangName]),
            ['@name'] = gangName
        })

        TriggerClientEvent('esx:showNotification', source, 'Vous avez déposé ~y~x' .. amount .. ' ' .. item.label)
    end)
end)

RegisterNetEvent('gangbuilder:withdrawItem')
AddEventHandler('gangbuilder:withdrawItem', function(gangName, itemName, amount)
    if Config.Storage.UseOxInventory then return end

    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].gang ~= gangName then return end
        
        amount = tonumber(amount)
        if not amount or amount <= 0 then return end

        InitGangInventory(gangName)
        
        if not gangInventories[gangName][itemName] or gangInventories[gangName][itemName].count < amount then
            TriggerClientEvent('esx:showNotification', source, '~r~Il n\'y a pas assez d\'items dans le coffre')
            return
        end

        local canCarry = xPlayer.canCarryItem(itemName, amount)
        if not canCarry then
            TriggerClientEvent('esx:showNotification', source, '~r~Vous ne pouvez pas porter autant d\'items')
            return
        end

        gangInventories[gangName][itemName].count = gangInventories[gangName][itemName].count - amount
        xPlayer.addInventoryItem(itemName, amount)
        if gangInventories[gangName][itemName].count <= 0 then
            gangInventories[gangName][itemName] = nil
        end
        MySQL.Async.execute('UPDATE gangs SET storage_inventory = @inventory WHERE name = @name', {
            ['@inventory'] = json.encode(gangInventories[gangName]),
            ['@name'] = gangName
        })

        TriggerClientEvent('esx:showNotification', source, 'Vous avez retiré ~y~x' .. amount .. ' ' .. ESX.GetItemLabel(itemName))
    end)
end)

RegisterNetEvent('gangbuilder:setGang')
AddEventHandler('gangbuilder:setGang', function(gang)
    if gang and Config.Storage.UseOxInventory then
        CreateOrUpdateStash(gang)
    end
end)

RegisterNetEvent('gangbuilder:refreshStashes')
AddEventHandler('gangbuilder:refreshStashes', function()
    registeredStashes = {}
    MySQL.Async.fetchAll('SELECT name FROM gangs WHERE has_storage = 1', {}, function(gangs)
        for _, gang in ipairs(gangs) do
            CreateOrUpdateStash(gang.name)
        end
    end)
end)

RegisterNetEvent('gangbuilder:updateStash')
AddEventHandler('gangbuilder:updateStash', function(gangName)
    if registeredStashes['gang_' .. gangName:gsub("%s+", ""):lower()] then
        registeredStashes['gang_' .. gangName:gsub("%s+", ""):lower()] = nil
    end
    CreateOrUpdateStash(gangName)
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                CreateOrUpdateStash(result[1].gang, true)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:playerJoinedGang')
AddEventHandler('gangbuilder:playerJoinedGang', function(gangName)
    if gangName then
        CreateOrUpdateStash(gangName, true)
    end
end)

ESX.RegisterServerCallback('gangbuilder:getPlayerGangGrade', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(0) end

    MySQL.Async.fetchAll('SELECT gang_grade, gang FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].gang then
            MySQL.Async.fetchAll('SELECT min_storage_grade FROM gangs WHERE name = @name', {
                ['@name'] = result[1].gang
            }, function(gangResult)
                if gangResult[1] then
                    minStorageGrade = gangResult[1].min_storage_grade
                    cb(result[1].gang_grade)
                else
                    cb(0)
                end
            end)
        else
            cb(0)
        end
    end)
end)

RegisterServerEvent('gangbuilder:gangUpdated')
AddEventHandler('gangbuilder:gangUpdated', function(gangName)
    if not gangName then return end
    
    MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
        ['@name'] = gangName
    }, function(result)
        if result[1] then
            if type(result[1].storage_pos) == 'string' then
                result[1].storage_pos = json.decode(result[1].storage_pos)
            end
            TriggerClientEvent('gangbuilder:onGangUpdate', -1, result[1])
        end
    end)
end)