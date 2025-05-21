ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('gangbuilder:createGang')
AddEventHandler('gangbuilder:createGang', function(gangData)
    local source = source
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM gangs WHERE name = @name', {
        ['@name'] = gangData.name
    }, function(count)
        if count > 0 then
            MySQL.Async.execute([[
                UPDATE gangs 
                SET 
                    label = @label,
                    has_garage = @has_garage,
                    garage_entry_pos = @garage_entry_pos,
                    garage_exit_pos = @garage_exit_pos,
                    garage_spawn_pos = @garage_spawn_pos,
                    garage_vehicles = @garage_vehicles,
                    has_storage = @has_storage,
                    storage_pos = @storage_pos,
                    storage_inventory = @storage_inventory,
                    has_f7_menu = @has_f7_menu,
                    can_search = @can_search,
                    can_handcuff = @can_handcuff,
                    can_escort = @can_escort,
                    can_put_in_vehicle = @can_put_in_vehicle,
                    can_lockpick = @can_lockpick,
                    min_garage_grade = @min_garage_grade,
                    min_storage_grade = @min_storage_grade,
                    min_f7_grade = @min_f7_grade
                WHERE name = @name
            ]], {
                ['@name'] = gangData.name,
                ['@label'] = gangData.label,
                ['@has_garage'] = gangData.hasGarage,
                ['@garage_entry_pos'] = gangData.hasGarage and json.encode(gangData.garageEnterPos) or nil,
                ['@garage_exit_pos'] = gangData.hasGarage and json.encode(gangData.garageExitPos) or nil,
                ['@garage_spawn_pos'] = gangData.hasGarage and json.encode(gangData.garageSpawnPos) or nil,
                ['@garage_vehicles'] = gangData.hasGarage and json.encode(gangData.vehicles) or nil,
                ['@has_storage'] = gangData.hasCoffre,
                ['@storage_pos'] = gangData.hasCoffre and json.encode(gangData.coffrePos) or nil,
                ['@storage_inventory'] = gangData.hasCoffre and json.encode(gangData.coffreInventory) or nil,
                ['@has_f7_menu'] = gangData.hasF7Menu,
                ['@can_search'] = gangData.hasF7Menu and gangData.f7Options.fouiller or false,
                ['@can_handcuff'] = gangData.hasF7Menu and gangData.f7Options.menotter or false,
                ['@can_escort'] = gangData.hasF7Menu and gangData.f7Options.escorter or false,
                ['@can_put_in_vehicle'] = gangData.hasF7Menu and gangData.f7Options.vehicule or false,
                ['@can_lockpick'] = gangData.hasF7Menu and gangData.f7Options.crocheter or false,
                ['@min_garage_grade'] = gangData.minGarageGrade or 0,
                ['@min_storage_grade'] = gangData.minCoffreGrade or 0,
                ['@min_f7_grade'] = gangData.minF7Grade or 0
            }, function()
                MySQL.Async.execute('UPDATE jobs SET label = @label WHERE name = @name', {
                    ['@name'] = gangData.name,
                    ['@label'] = gangData.label
                })
                MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = @job_name', {
                    ['@job_name'] = gangData.name
                }, function()
                    for _, grade in ipairs(gangData.grades) do
                        MySQL.Async.execute('INSERT INTO job_grades (job_name, grade, name, label) VALUES (@job_name, @grade, @name, @label)', {
                            ['@job_name'] = gangData.name,
                            ['@grade'] = grade.number,
                            ['@name'] = string.lower(grade.label),
                            ['@label'] = grade.label
                        })
                    end
                    ESX.RefreshJobs()
                    TriggerClientEvent('esx:showNotification', source, 'Gang mis à jour avec succès !')
                end)
            end)
        else
            MySQL.Async.execute([[
                INSERT INTO gangs (
                    name, 
                    label, 
                    has_garage, 
                    garage_entry_pos, 
                    garage_exit_pos, 
                    garage_spawn_pos,
                    garage_vehicles,
                    has_storage,
                    storage_pos,
                    storage_inventory,
                    has_f7_menu,
                    can_search,
                    can_handcuff,
                    can_escort,
                    can_put_in_vehicle,
                    can_lockpick,
                    min_garage_grade,
                    min_storage_grade,
                    min_f7_grade
                ) VALUES (
                    @name, 
                    @label, 
                    @has_garage, 
                    @garage_entry_pos, 
                    @garage_exit_pos, 
                    @garage_spawn_pos,
                    @garage_vehicles,
                    @has_storage,
                    @storage_pos,
                    @storage_inventory,
                    @has_f7_menu,
                    @can_search,
                    @can_handcuff,
                    @can_escort,
                    @can_put_in_vehicle,
                    @can_lockpick,
                    @min_garage_grade,
                    @min_storage_grade,
                    @min_f7_grade
                )
            ]], {
                ['@name'] = gangData.name,
                ['@label'] = gangData.label,
                ['@has_garage'] = gangData.hasGarage,
                ['@garage_entry_pos'] = gangData.hasGarage and json.encode(gangData.garageEnterPos) or nil,
                ['@garage_exit_pos'] = gangData.hasGarage and json.encode(gangData.garageExitPos) or nil,
                ['@garage_spawn_pos'] = gangData.hasGarage and json.encode(gangData.garageSpawnPos) or nil,
                ['@garage_vehicles'] = gangData.hasGarage and json.encode(gangData.vehicles) or nil,
                ['@has_storage'] = gangData.hasCoffre,
                ['@storage_pos'] = gangData.hasCoffre and json.encode(gangData.coffrePos) or nil,
                ['@storage_inventory'] = gangData.hasCoffre and json.encode(gangData.coffreInventory) or nil,
                ['@has_f7_menu'] = gangData.hasF7Menu,
                ['@can_search'] = gangData.hasF7Menu and gangData.f7Options.fouiller or false,
                ['@can_handcuff'] = gangData.hasF7Menu and gangData.f7Options.menotter or false,
                ['@can_escort'] = gangData.hasF7Menu and gangData.f7Options.escorter or false,
                ['@can_put_in_vehicle'] = gangData.hasF7Menu and gangData.f7Options.vehicule or false,
                ['@can_lockpick'] = gangData.hasF7Menu and gangData.f7Options.crocheter or false,
                ['@min_garage_grade'] = gangData.minGarageGrade or 0,
                ['@min_storage_grade'] = gangData.minCoffreGrade or 0,
                ['@min_f7_grade'] = gangData.minF7Grade or 0
            }, function()
                MySQL.Async.execute('INSERT INTO jobs (name, label) VALUES (@name, @label)', {
                    ['@name'] = gangData.name,
                    ['@label'] = gangData.label
                }, function()
                    for _, grade in ipairs(gangData.grades) do
                        MySQL.Async.execute('INSERT INTO job_grades (job_name, grade, name, label) VALUES (@job_name, @grade, @name, @label)', {
                            ['@job_name'] = gangData.name,
                            ['@grade'] = grade.number,
                            ['@name'] = string.lower(grade.label),
                            ['@label'] = grade.label
                        })
                    end
                    ESX.RefreshJobs()
                    TriggerClientEvent('esx:showNotification', source, 'Gang créé avec succès !')
                end)
            end)
        end
    end)
end)

MySQL.ready(function()
    MySQL.Async.execute([[
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS gang VARCHAR(50) DEFAULT NULL,
        ADD COLUMN IF NOT EXISTS gang_grade INT DEFAULT 0
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS gangs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(50) NOT NULL UNIQUE,
            label VARCHAR(50) NOT NULL,
            has_garage BOOLEAN DEFAULT FALSE,
            garage_entry_pos TEXT,
            garage_exit_pos TEXT,
            garage_spawn_pos TEXT,
            garage_vehicles TEXT,
            has_storage BOOLEAN DEFAULT FALSE,
            storage_pos TEXT,
            storage_inventory TEXT,
            has_f7_menu BOOLEAN DEFAULT FALSE,
            can_search BOOLEAN DEFAULT FALSE,
            can_handcuff BOOLEAN DEFAULT FALSE,
            can_escort BOOLEAN DEFAULT FALSE,
            can_put_in_vehicle BOOLEAN DEFAULT FALSE,
            can_lockpick BOOLEAN DEFAULT FALSE,
            min_garage_grade INT DEFAULT 0,
            min_storage_grade INT DEFAULT 0,
            min_f7_grade INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.Async.execute([[
        ALTER TABLE gangs
        ADD COLUMN IF NOT EXISTS has_garage BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS garage_entry_pos TEXT,
        ADD COLUMN IF NOT EXISTS garage_exit_pos TEXT,
        ADD COLUMN IF NOT EXISTS garage_spawn_pos TEXT,
        ADD COLUMN IF NOT EXISTS garage_vehicles TEXT,
        ADD COLUMN IF NOT EXISTS has_storage BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS storage_pos TEXT,
        ADD COLUMN IF NOT EXISTS storage_inventory TEXT,
        ADD COLUMN IF NOT EXISTS has_f7_menu BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS can_search BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS can_handcuff BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS can_escort BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS can_put_in_vehicle BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS can_lockpick BOOLEAN DEFAULT FALSE,
        ADD COLUMN IF NOT EXISTS min_garage_grade INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS min_storage_grade INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS min_f7_grade INT DEFAULT 0
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS gang_admin (
            id INT AUTO_INCREMENT PRIMARY KEY,
            license VARCHAR(50) NOT NULL UNIQUE,
            added_by VARCHAR(50),
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])

    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM gangs WHERE name = @name', {
        ['@name'] = 'aucun'
    }, function(count)
        if count == 0 then
            MySQL.Async.execute([[
                INSERT INTO gangs (
                    name, 
                    label, 
                    has_garage,
                    has_storage,
                    has_f7_menu
                ) VALUES (
                    'aucun',
                    'Aucun Gang',
                    FALSE,
                    FALSE,
                    FALSE
                )
            ]], {}, function()
                print('^2Gang par défaut "aucun" créé avec succès^7')
                
                MySQL.Async.execute('INSERT INTO job_grades (job_name, grade, name, label) VALUES (@job_name, @grade, @name, @label)', {
                    ['@job_name'] = 'aucun',
                    ['@grade'] = 0,
                    ['@name'] = 'aucun',
                    ['@label'] = 'Aucun Grade'
                }, function()
                    print('^2Grade par défaut créé pour le gang "aucun"^7')
                    ESX.RefreshJobs()
                end)
            end)
        end
    end)
end)
ESX.RegisterServerCallback('gangbuilder:getGangs', function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM gangs', {}, function(gangs)
        for _, gang in ipairs(gangs) do
            if gang.garage_entry_pos then gang.garage_entry_pos = json.decode(gang.garage_entry_pos) end
            if gang.garage_exit_pos then gang.garage_exit_pos = json.decode(gang.garage_exit_pos) end
            if gang.garage_vehicles then gang.garage_vehicles = json.decode(gang.garage_vehicles) end
            if gang.storage_pos then gang.storage_pos = json.decode(gang.storage_pos) end
            if gang.storage_inventory then gang.storage_inventory = json.decode(gang.storage_inventory) end
        end
        cb(gangs)
    end)
end)

RegisterNetEvent('gangbuilder:deleteGang')
AddEventHandler('gangbuilder:deleteGang', function(gangName)
    local source = source
    MySQL.Async.execute('DELETE FROM gangs WHERE name = @name', {
        ['@name'] = gangName
    })
    MySQL.Async.execute('DELETE FROM jobs WHERE name = @name', {
        ['@name'] = gangName
    })
    MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = @job_name', {
        ['@job_name'] = gangName
    })
    ESX.RefreshJobs()
    TriggerClientEvent('esx:showNotification', source, 'Gang supprimé avec succès !')
end)

ESX.RegisterServerCallback('gangbuilder:getGangGrades', function(source, cb, gangName)
    MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @job_name ORDER BY grade', {
        ['@job_name'] = gangName
    }, function(grades)
        local formattedGrades = {}
        for _, grade in ipairs(grades) do
            table.insert(formattedGrades, {
                label = grade.label,
                number = grade.grade
            })
        end
        cb(formattedGrades)
    end)
end)

function IsGangAdmin(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local license = xPlayer.identifier
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM gang_admin WHERE license = @license', {
            ['@license'] = license
        }, function(count)
            cb(count > 0)
        end)
    else
        cb(false)
    end
end

RegisterCommand('addgangadmin', function(source, args)
    if source == 0 then
        local targetId = tonumber(args[1])
        if targetId then
            local xPlayer = ESX.GetPlayerFromId(targetId)
            if xPlayer then
                MySQL.Async.execute('INSERT INTO gang_admin (license, added_by) VALUES (@license, @added_by)', {
                    ['@license'] = xPlayer.identifier,
                    ['@added_by'] = 'console'
                }, function()
                    print('^2Gang Admin ajouté avec succès : ^7' .. xPlayer.getName())
                    xPlayer.showNotification('Vous êtes maintenant administrateur des gangs')
                end)
            else
                print('^1Joueur non trouvé^7')
            end
        else
            print('^1Usage : addgangadmin [ID]^7')
        end
    else
        IsGangAdmin(source, function(isAdmin)
            if isAdmin then
                local targetId = tonumber(args[1])
                if targetId then
                    local xPlayer = ESX.GetPlayerFromId(targetId)
                    local admin = ESX.GetPlayerFromId(source)
                    if xPlayer then
                        MySQL.Async.execute('INSERT INTO gang_admin (license, added_by) VALUES (@license, @added_by)', {
                            ['@license'] = xPlayer.identifier,
                            ['@added_by'] = admin.identifier
                        }, function()
                            admin.showNotification('Gang Admin ajouté : ' .. xPlayer.getName())
                            xPlayer.showNotification('Vous êtes maintenant administrateur des gangs')
                        end)
                    else
                        admin.showNotification('~r~Joueur non trouvé')
                    end
                else
                    admin.showNotification('~r~Usage : /addgangadmin [ID]')
                end
            else
                ESX.GetPlayerFromId(source).showNotification('~r~Vous n\'avez pas les permissions nécessaires')
            end
        end)
    end
end, false)

RegisterCommand('removegangadmin', function(source, args)
    if source == 0 then
        local targetId = tonumber(args[1])
        if targetId then
            local xPlayer = ESX.GetPlayerFromId(targetId)
            if xPlayer then
                MySQL.Async.execute('DELETE FROM gang_admin WHERE license = @license', {
                    ['@license'] = xPlayer.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        print('^2Gang Admin retiré avec succès : ^7' .. xPlayer.getName())
                        xPlayer.showNotification('Vous n\'êtes plus administrateur des gangs')
                    else
                        print('^1Cette personne n\'est pas admin gang^7')
                    end
                end)
            else
                print('^1Joueur non trouvé^7')
            end
        else
            print('^1Usage : removegangadmin [ID]^7')
        end
    else
        IsGangAdmin(source, function(isAdmin)
            if isAdmin then
                local targetId = tonumber(args[1])
                if targetId then
                    local xPlayer = ESX.GetPlayerFromId(targetId)
                    local admin = ESX.GetPlayerFromId(source)
                    if xPlayer then
                        if source == targetId then
                            admin.showNotification('~r~Vous ne pouvez pas vous retirer vous-même')
                            return
                        end
                        
                        MySQL.Async.execute('DELETE FROM gang_admin WHERE license = @license', {
                            ['@license'] = xPlayer.identifier
                        }, function(rowsChanged)
                            if rowsChanged > 0 then
                                admin.showNotification('Gang Admin retiré : ' .. xPlayer.getName())
                                xPlayer.showNotification('Vous n\'êtes plus administrateur des gangs')
                            else
                                admin.showNotification('~r~Cette personne n\'est pas admin gang')
                            end
                        end)
                    else
                        admin.showNotification('~r~Joueur non trouvé')
                    end
                else
                    admin.showNotification('~r~Usage : /removegangadmin [ID]')
                end
            else
                ESX.GetPlayerFromId(source).showNotification('~r~Vous n\'avez pas les permissions nécessaires')
            end
        end)
    end
end, false)

RegisterCommand('setgang', function(source, args)
    if source == 0 then
        local targetId = tonumber(args[1])
        local gangName = args[2]
        local grade = tonumber(args[3])
        
        if targetId and gangName and grade then
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            if targetPlayer then
                SetPlayerGang(targetPlayer, gangName, grade, function(success, message)
                    print(success and '^2' .. message .. '^7' or '^1' .. message .. '^7')
                end)
            else
                print('^1Joueur non trouvé^7')
            end
        else
            print('^1Usage : setgang [ID] [gang] [grade]^7')
        end
    else
        IsGangAdmin(source, function(isAdmin)
            if isAdmin then
                local targetId = tonumber(args[1])
                local gangName = args[2]
                local grade = tonumber(args[3])
                
                if targetId and gangName and grade then
                    local targetPlayer = ESX.GetPlayerFromId(targetId)
                    if targetPlayer then
                        SetPlayerGang(targetPlayer, gangName, grade, function(success, message)
                            local admin = ESX.GetPlayerFromId(source)
                            admin.showNotification(success and message or '~r~' .. message)
                        end)
                    else
                        ESX.GetPlayerFromId(source).showNotification('~r~Joueur non trouvé')
                    end
                else
                    ESX.GetPlayerFromId(source).showNotification('~r~Usage : /setgang [ID] [gang] [grade]')
                end
            else
                ESX.GetPlayerFromId(source).showNotification('~r~Vous n\'avez pas les permissions nécessaires')
            end
        end)
    end
end, false)

function SetPlayerGang(targetPlayer, gangName, grade, cb)
    if gangName == 'aucun' then
        MySQL.Async.execute('UPDATE users SET gang = NULL, gang_grade = 0 WHERE identifier = @identifier', {
            ['@identifier'] = targetPlayer.identifier
        }, function()
            targetPlayer.gang = { name = nil, grade = 0 }
            cb(true, ('Gang retiré pour %s'):format(targetPlayer.getName()))
            targetPlayer.showNotification('Vous n\'êtes plus dans un gang')
            TriggerClientEvent('gangbuilder:setGang', targetPlayer.source, nil, 0)
        end)
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
        ['@name'] = gangName
    }, function(gangs)
        if #gangs > 0 then
            MySQL.Async.execute('UPDATE users SET gang = @gang, gang_grade = @grade WHERE identifier = @identifier', {
                ['@gang'] = gangName,
                ['@grade'] = grade,
                ['@identifier'] = targetPlayer.identifier
            }, function()
                targetPlayer.gang = { name = gangName, grade = grade }
                cb(true, ('Gang %s défini pour %s'):format(gangName, targetPlayer.getName()))
                targetPlayer.showNotification(('Votre gang a été défini: %s'):format(gangName))
                TriggerClientEvent('gangbuilder:setGang', targetPlayer.source, gangName, grade)
                TriggerEvent('gangbuilder:playerJoinedGang', gangName)
            end)
        else
            cb(false, 'Ce gang n\'existe pas')
        end
    end)
end

ESX.RegisterServerCallback('gangbuilder:getGangPermissions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(gangs)
                    if #gangs > 0 then
                        local gang = gangs[1]
                        cb({
                            has_f7_menu = gang.has_f7_menu,
                            can_search = gang.can_search,
                            can_handcuff = gang.can_handcuff,
                            can_escort = gang.can_escort,
                            can_put_in_vehicle = gang.can_put_in_vehicle,
                            can_lockpick = gang.can_lockpick,
                            gang_grade = result[1].gang_grade
                        })
                    else
                        cb(nil)
                    end
                end)
            else
                cb(nil)
            end
        end)
    else
        cb(nil)
    end
end)

RegisterNetEvent('gangbuilder:searchPlayer')
AddEventHandler('gangbuilder:searchPlayer', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_search FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_search then
                        TriggerClientEvent('esx:showNotification', source, 'Vous fouillez ' .. tPlayer.getName())
                        TriggerClientEvent('esx:showNotification', target, 'Vous êtes fouillé par ' .. xPlayer.getName())
                    end
                end)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:handcuffPlayer')
AddEventHandler('gangbuilder:handcuffPlayer', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_handcuff FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_handcuff then
                        TriggerClientEvent('gangbuilder:handcuffAnim', target)
                    end
                end)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:escortPlayer')
AddEventHandler('gangbuilder:escortPlayer', function(target)
    local sourceId = source
    local xPlayer = ESX.GetPlayerFromId(sourceId)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_escort FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_escort then
                        if sourceId then
                            TriggerClientEvent('gangbuilder:escort', target, sourceId)
                        end
                    end
                end)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:putInVehicle')
AddEventHandler('gangbuilder:putInVehicle', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_put_in_vehicle FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_put_in_vehicle then
                        TriggerClientEvent('gangbuilder:putInVehicleAnim', target)
                    end
                end)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:lockpickVehicle')
AddEventHandler('gangbuilder:lockpickVehicle', function(vehicle)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_lockpick FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_lockpick then
                        TriggerClientEvent('gangbuilder:lockpickAnim', source, vehicle)
                    end
                end)
            end
        end)
    end
end)

RegisterNetEvent('gangbuilder:searchPlayerInventory')
AddEventHandler('gangbuilder:searchPlayerInventory', function(targetId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(targetId)
    
    if xPlayer and tPlayer then
        local inventory = {}
        local items = tPlayer.getInventory()
        
        for _, item in pairs(items) do
            if item.count > 0 then
                table.insert(inventory, {
                    name = item.name,
                    label = item.label,
                    count = item.count
                })
            end
        end
        
        TriggerClientEvent('gangbuilder:receivePlayerInventory', source, inventory)
    end
end)

RegisterNetEvent('gangbuilder:takeItem')
AddEventHandler('gangbuilder:takeItem', function(targetId, itemName, quantity)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(targetId)
    
    if xPlayer and tPlayer then
        local targetItem = tPlayer.getInventoryItem(itemName)
        
        if targetItem.count >= quantity then
            if xPlayer.canCarryItem(itemName, quantity) then
                tPlayer.removeInventoryItem(itemName, quantity)
                xPlayer.addInventoryItem(itemName, quantity)
                
                TriggerClientEvent('esx:showNotification', source, ('Vous avez pris ~g~%sx %s~s~'):format(quantity, targetItem.label))
                TriggerClientEvent('esx:showNotification', targetId, ('Quelqu\'un vous a pris ~r~%sx %s~s~'):format(quantity, targetItem.label))
                local inventory = {}
                local items = tPlayer.getInventory()
                for _, item in pairs(items) do
                    if item.count > 0 then
                        table.insert(inventory, {
                            name = item.name,
                            label = item.label,
                            count = item.count
                        })
                    end
                end
                TriggerClientEvent('gangbuilder:receivePlayerInventory', source, inventory)
            else
                TriggerClientEvent('esx:showNotification', source, '~r~Vous ne pouvez pas porter autant d\'objets')
            end
        else
            TriggerClientEvent('esx:showNotification', source, '~r~Le joueur n\'a pas assez d\'items')
        end
    end
end)

ESX.RegisterServerCallback('gangbuilder:getPlayerGang', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                cb(result[1].gang)
            else
                cb(nil)
            end
        end)
    else
        cb(nil)
    end
end)

RegisterNetEvent('gangbuilder:removeFromVehicle')
AddEventHandler('gangbuilder:removeFromVehicle', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(target)
    
    if xPlayer and tPlayer then
        MySQL.Async.fetchAll('SELECT gang FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] and result[1].gang then
                MySQL.Async.fetchAll('SELECT can_put_in_vehicle FROM gangs WHERE name = @name', {
                    ['@name'] = result[1].gang
                }, function(results)
                    if #results > 0 and results[1].can_put_in_vehicle then
                        TriggerClientEvent('gangbuilder:removeFromVehicleAnim', target)
                    end
                end)
            end
        end)
    end
end) 
