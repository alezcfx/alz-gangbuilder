ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('gangbuilder:getGangData', function(source, cb, gangName)
    if not gangName then return cb(nil) end
    
    MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
        ['@name'] = gangName
    }, function(result)
        if result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('gangbuilder:getGangPermissions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    MySQL.Async.fetchAll('SELECT gang, gang_grade FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] and result[1].gang then
            MySQL.Async.fetchAll('SELECT * FROM gangs WHERE name = @name', {
                ['@name'] = result[1].gang
            }, function(gangResult)
                if gangResult[1] then
                    local permissions = {
                        gang_name = result[1].gang,
                        gang_grade = result[1].gang_grade,
                        has_f7_menu = gangResult[1].has_f7_menu == true or gangResult[1].has_f7_menu == 1 or gangResult[1].has_f7_menu == "1",
                        can_search = gangResult[1].can_search == true or gangResult[1].can_search == 1 or gangResult[1].can_search == "1",
                        can_handcuff = gangResult[1].can_handcuff == true or gangResult[1].can_handcuff == 1 or gangResult[1].can_handcuff == "1",
                        can_escort = gangResult[1].can_escort == true or gangResult[1].can_escort == 1 or gangResult[1].can_escort == "1",
                        can_put_in_vehicle = gangResult[1].can_put_in_vehicle == true or gangResult[1].can_put_in_vehicle == 1 or gangResult[1].can_put_in_vehicle == "1",
                        can_lockpick = gangResult[1].can_lockpick == true or gangResult[1].can_lockpick == 1 or gangResult[1].can_lockpick == "1"
                    }
                    
                    cb(permissions)
                else
                    cb(nil)
                end
            end)
        else
            cb(nil)
        end
    end)
end) 