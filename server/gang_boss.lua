ESX = exports["es_extended"]:getSharedObject()

-- Callback pour vérifier si le joueur peut accéder au menu patron
ESX.RegisterServerCallback('gangbuilder:checkBossAccess', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    -- Récupérer le gang du joueur depuis la base de données
    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or not result[1].gang then
            cb(false)
            return
        end

        local playerGang = result[1].gang
        local playerGrade = result[1].gang_grade
        
        -- Vérifier si le joueur appartient à un gang
        MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
            ['@name'] = playerGang
        }, function(gangs)
            if #gangs == 0 then
                cb(false)
                return
            end
            
            local gangData = gangs[1]
            
            -- Obtenir le grade maximum pour ce gang
            MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @job_name ORDER BY grade DESC', {
                ['@job_name'] = playerGang
            }, function(grades)
                if #grades == 0 then
                    cb(false)
                    return
                end
                
                local formattedGrades = {}
                for _, grade in ipairs(grades) do
                    table.insert(formattedGrades, {
                        label = grade.label,
                        number = grade.grade
                    })
                end
                
                -- Trier les grades par numéro (décroissant)
                table.sort(formattedGrades, function(a, b) 
                    return a.number > b.number 
                end)
                
                local maxGrade = formattedGrades[1].number
                
                -- Le joueur doit avoir le grade maximum pour accéder au menu patron
                local hasBossAccess = (playerGrade == maxGrade)
                
                if hasBossAccess then
                    -- Récupérer la liste des membres du gang
                    MySQL.Async.fetchAll([[
                        SELECT u.identifier, u.firstname, u.lastname, g.label AS gang_label, 
                               u.gang_grade, u.gang
                        FROM users u
                        JOIN gangs g ON g.name = u.gang
                        WHERE u.gang = @gang
                    ]], {
                        ['@gang'] = playerGang
                    }, function(members)
                        -- Récupérer les noms des grades pour chaque membre
                        for i = 1, #members do
                            local firstname = members[i].firstname or ''
                            local lastname = members[i].lastname or ''
                            members[i].name = firstname .. ' ' .. lastname
                            
                            -- Trouver le grade correspondant
                            for _, grade in ipairs(formattedGrades) do
                                if grade.number == members[i].gang_grade then
                                    members[i].grade_label = grade.label
                                    break
                                end
                            end
                            
                            if not members[i].grade_label then
                                members[i].grade_label = "Grade " .. members[i].gang_grade
                            end
                        end
                        
                        cb(true, gangData, members)
                    end)
                else
                    cb(false)
                end
            end)
        end)
    end)
end)

-- Callback pour récupérer la liste des membres du gang
ESX.RegisterServerCallback('gangbuilder:getGangMembers', function(source, cb, gangName)
    MySQL.Async.fetchAll([[
        SELECT u.identifier, u.firstname, u.lastname, j.label AS gang_label, 
               jg.grade, jg.label AS grade_label, u.gang, u.gang_grade
        FROM users u
        JOIN jobs j ON j.name = u.gang
        JOIN job_grades jg ON jg.job_name = j.name AND jg.grade = u.gang_grade
        WHERE u.gang = @gang
    ]], {
        ['@gang'] = gangName
    }, function(members)
        for i = 1, #members do
            local firstname = members[i].firstname
            local lastname = members[i].lastname
            members[i].name = firstname .. ' ' .. lastname
        end
        
        cb(members)
    end)
end)

-- Événement pour recruter un joueur
RegisterNetEvent('gangbuilder:recruitPlayer')
AddEventHandler('gangbuilder:recruitPlayer', function(targetId, gangName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer or not tPlayer then
        TriggerClientEvent('esx:showNotification', source, "~r~Joueur introuvable")
        return
    end
    
    -- Vérifier que le recruteur appartient bien au gang
    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].gang ~= gangName then
            TriggerClientEvent('esx:showNotification', source, "~r~Vous n'appartenez pas à ce gang")
            return
        end
        
        local playerGrade = result[1].gang_grade
        
        -- Vérifier que le recruteur a le grade max
        MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @job_name ORDER BY grade', {
            ['@job_name'] = gangName
        }, function(gradeResults)
            if #gradeResults == 0 then
                TriggerClientEvent('esx:showNotification', source, "~r~Impossible de récupérer les grades du gang")
                return
            end
            
            local grades = {}
            for _, grade in ipairs(gradeResults) do
                table.insert(grades, {
                    label = grade.label,
                    number = grade.grade
                })
            end
            
            -- Trier les grades pour trouver le max
            table.sort(grades, function(a, b) 
                return a.number > b.number 
            end)
            
            local maxGrade = grades[1].number
            
            if playerGrade ~= maxGrade then
                TriggerClientEvent('esx:showNotification', source, "~r~Vous n'avez pas les permissions nécessaires")
                return
            end
            
            -- Trouver le grade minimum pour le nouveau membre
            table.sort(grades, function(a, b) 
                return a.number < b.number 
            end)
            
            local minGrade = grades[1].number
            
            -- Mettre à jour la base de données
            MySQL.Async.execute('UPDATE users SET gang = @gang, gang_grade = @grade WHERE identifier = @identifier', {
                ['@gang'] = gangName,
                ['@grade'] = minGrade,
                ['@identifier'] = tPlayer.identifier
            }, function()
                TriggerClientEvent('esx:showNotification', source, "~g~" .. tPlayer.getName() .. " a été recruté dans votre gang")
                TriggerClientEvent('esx:showNotification', targetId, "~g~Vous avez été recruté dans le gang " .. gangName)
                
                -- Mettre à jour les permissions et positions pour le nouveau membre
                MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
                    ['@name'] = gangName
                }, function(gangs)
                    if #gangs > 0 then
                        local gangData = gangs[1]
                        local bossMenuPos = gangData.boss_menu_pos
                        
                        if bossMenuPos then
                            TriggerClientEvent('gangbuilder:setGangBoss', targetId, gangName, minGrade, bossMenuPos)
                        end
                    end
                end)
            end)
        end)
    end)
end)

-- Événement pour changer le grade d'un joueur
RegisterNetEvent('gangbuilder:changePlayerGrade')
AddEventHandler('gangbuilder:changePlayerGrade', function(targetIdentifier, gangName, newGrade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    -- Vérifier que le promoteur appartient au gang et a le grade max
    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].gang ~= gangName then
            TriggerClientEvent('esx:showNotification', source, "~r~Vous n'appartenez pas à ce gang")
            return
        end
        
        local playerGrade = result[1].gang_grade
        
        MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @job_name ORDER BY grade', {
            ['@job_name'] = gangName
        }, function(gradeResults)
            if #gradeResults == 0 then
                TriggerClientEvent('esx:showNotification', source, "~r~Impossible de récupérer les grades du gang")
                return
            end
            
            local grades = {}
            for _, grade in ipairs(gradeResults) do
                table.insert(grades, {
                    label = grade.label,
                    number = grade.grade
                })
            end
            
            -- Trier les grades pour trouver le max
            table.sort(grades, function(a, b) 
                return a.number > b.number 
            end)
            
            local maxGrade = grades[1].number
            
            if playerGrade ~= maxGrade then
                TriggerClientEvent('esx:showNotification', source, "~r~Vous n'avez pas les permissions nécessaires")
                return
            end
            
            -- Vérifier que le nouveau grade est inférieur au grade du joueur actuel
            if newGrade >= playerGrade then
                TriggerClientEvent('esx:showNotification', source, "~r~Vous ne pouvez pas promouvoir à un grade égal ou supérieur au vôtre")
                return
            end
            
            -- Mettre à jour la base de données
            MySQL.Async.execute('UPDATE users SET gang_grade = @grade WHERE identifier = @identifier AND gang = @gang', {
                ['@grade'] = newGrade,
                ['@identifier'] = targetIdentifier,
                ['@gang'] = gangName
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    -- Si le joueur est en ligne, mettre à jour ses données
                    local tPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
                    if tPlayer then
                        TriggerClientEvent('esx:showNotification', tPlayer.source, "~g~Votre grade dans le gang a été modifié")
                    end
                    
                    TriggerClientEvent('esx:showNotification', source, "~g~Grade du membre modifié avec succès")
                else
                    TriggerClientEvent('esx:showNotification', source, "~r~Aucun membre trouvé avec cet identifiant")
                end
            end)
        end)
    end)
end)

-- Événement pour virer un joueur du gang
RegisterNetEvent('gangbuilder:firePlayer')
AddEventHandler('gangbuilder:firePlayer', function(targetIdentifier)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    -- Vérifier que le licencieur appartient au gang et a le grade max
    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if not result[1] or not result[1].gang then
            TriggerClientEvent('esx:showNotification', source, "~r~Vous n'appartenez pas à un gang")
            return
        end
        
        local gangName = result[1].gang
        local playerGrade = result[1].gang_grade
        
        MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @job_name ORDER BY grade', {
            ['@job_name'] = gangName
        }, function(gradeResults)
            if #gradeResults == 0 then
                TriggerClientEvent('esx:showNotification', source, "~r~Impossible de récupérer les grades du gang")
                return
            end
            
            local grades = {}
            for _, grade in ipairs(gradeResults) do
                table.insert(grades, {
                    label = grade.label,
                    number = grade.grade
                })
            end
            
            -- Trier les grades pour trouver le max
            table.sort(grades, function(a, b) 
                return a.number > b.number 
            end)
            
            local maxGrade = grades[1].number
            
            if playerGrade ~= maxGrade then
                TriggerClientEvent('esx:showNotification', source, "~r~Vous n'avez pas les permissions nécessaires")
                return
            end
            
            -- Mettre à jour la base de données
            MySQL.Async.execute('UPDATE users SET gang = "aucun", gang_grade = 0 WHERE identifier = @identifier AND gang = @gang', {
                ['@identifier'] = targetIdentifier,
                ['@gang'] = gangName
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    -- Si le joueur est en ligne, mettre à jour ses données
                    local tPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
                    if tPlayer then
                        TriggerClientEvent('esx:showNotification', tPlayer.source, "~r~Vous avez été viré de votre gang")
                    end
                    
                    TriggerClientEvent('esx:showNotification', source, "~g~Le membre a été viré avec succès")
                else
                    TriggerClientEvent('esx:showNotification', source, "~r~Aucun membre trouvé avec cet identifiant")
                end
            end)
        end)
    end)
end)

-- Mettre à jour les informations du joueur quand il se connecte
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].gang then
            local playerGang = result[1].gang
            local playerGrade = result[1].gang_grade
            
            MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
                ['@name'] = playerGang
            }, function(gangs)
                if #gangs > 0 then
                    local gangData = gangs[1]
                    local bossMenuPos = gangData.boss_menu_pos
                    
                    if bossMenuPos then
                        TriggerClientEvent('gangbuilder:setGangBoss', playerId, playerGang, playerGrade, bossMenuPos)
                    end
                end
            end)
        end
    end)
end)

-- Callback pour récupérer les grades d'un gang (utilisé par le client)
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