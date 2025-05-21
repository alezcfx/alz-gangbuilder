ESX = exports["es_extended"]:getSharedObject()

local storageMenu = RageUI.CreateMenu("Coffre Gang", "Gestion du coffre")
local depositMenu = RageUI.CreateSubMenu(storageMenu, "Déposer", "Déposer des objets")
local withdrawMenu = RageUI.CreateSubMenu(storageMenu, "Retirer", "Retirer des objets")
local isStorageMenuOpen = false
local storageGangData = nil
local currentZoneName = nil
local zoneCreated = false
local cachedGangData = nil
local lastGangCheck = 0
local gangCheckInterval = 5000 
local playerGrade = 0
local minStorageGrade = 0

local function checkGradeAccess()
    if not cachedGangData then return false end
    ESX.TriggerServerCallback('gangbuilder:getPlayerGangGrade', function(grade)
        playerGrade = grade
    end)
    return playerGrade >= minStorageGrade
end

local function removeCurrentZone()
    if currentZoneName then
        exports.ox_target:removeZone(currentZoneName)
        currentZoneName = nil
    end
end

local function createZone(gang)
    if not Config.Storage.UseOxTarget then
        print('[GangBuilder] [INFO] ox_target n\'est pas activé dans la configuration')
        return
    end
    
    if not gang or not gang.name then
        print('[GangBuilder] [ERREUR] Données du gang invalides')
        return
    end

    if not gang.has_storage then
        print('[GangBuilder] [INFO] Le gang n\'a pas de stockage activé: ' .. gang.name)
        return
    end

    if not gang.storage_pos then
        print('[GangBuilder] [ERREUR] Position du coffre manquante pour: ' .. gang.name)
        return
    end

    if not gang.storage_pos.x or not gang.storage_pos.y or not gang.storage_pos.z then
        print('[GangBuilder] [ERREUR] Coordonnées du coffre invalides pour: ' .. gang.name)
        return
    end

    if currentZoneName then
        exports.ox_target:removeZone(currentZoneName)
        currentZoneName = nil
    end

    currentZoneName = 'gang_storage_' .. gang.name:gsub("%s+", ""):lower()
    
    local success = exports.ox_target:addBoxZone({
        name = currentZoneName,
        coords = vector3(gang.storage_pos.x, gang.storage_pos.y, gang.storage_pos.z),
        size = vector3(2.0, 2.0, 3.0),
        rotation = 0,
        debug = false,
        options = {
            {
                name = 'gang_storage_option',
                icon = 'fas fa-box',
                label = 'Ouvrir le coffre',
                distance = 2.0,
                onSelect = function()
                    if not checkGradeAccess() then
                        ESX.ShowNotification('~r~Vous n\'avez pas le grade requis pour accéder au coffre')
                        return
                    end
                    
                    if Config.Storage.UseOxInventory then
                        local stashId = 'gang_' .. gang.name:gsub("%s+", ""):lower()
                        exports.ox_inventory:openInventory('stash', stashId)
                    else
                        OpenStorageMenu()
                    end
                end
            }
        }
    })

    if success then
        print('[GangBuilder] [SUCCÈS] Zone créée pour: ' .. gang.name)
    else
        print('[GangBuilder] [ERREUR] Échec de création de la zone pour: ' .. gang.name)
    end
end

local function UpdateGangData()
    local currentTime = GetGameTimer()
    if currentTime - lastGangCheck > gangCheckInterval then
        lastGangCheck = currentTime
        ESX.TriggerServerCallback('gangbuilder:getPlayerGang', function(gang)
            if gang then
                ESX.TriggerServerCallback('gangbuilder:getGangs', function(gangs)
                    for _, gangInfo in ipairs(gangs) do
                        if gangInfo.name == gang then
                            if type(gangInfo.storage_pos) == 'string' then
                                gangInfo.storage_pos = json.decode(gangInfo.storage_pos)
                            end
                            
                            if not cachedGangData or cachedGangData.name ~= gangInfo.name then
                                removeCurrentZone()
                                createZone(gangInfo)
                            end
                            
                            cachedGangData = gangInfo
                            minStorageGrade = gangInfo.min_storage_grade or 0
                            break
                        end
                    end
                    
                    if not cachedGangData or cachedGangData.name ~= gang then
                        removeCurrentZone()
                        cachedGangData = nil
                        minStorageGrade = 0
                    end
                end)
            else
                removeCurrentZone()
                cachedGangData = nil
                minStorageGrade = 0
            end
        end)
    end
end

function OpenOxInventory(gangName)
    if not gangName then
        ESX.ShowNotification('~r~Erreur: Nom du gang invalide')
        return
    end
    
    local stashId = 'gang_' .. gangName
    ESX.ShowNotification('Ouverture du coffre: ' .. stashId)
    if not exports.ox_inventory then
        ESX.ShowNotification('~r~Erreur: ox_inventory n\'est pas disponible')
        return
    end
    exports.ox_inventory:openInventory('stash', stashId)
end

function OpenStorageMenu()
    if isStorageMenuOpen then 
        isStorageMenuOpen = false 
        RageUI.Visible(storageMenu, false)
        return
    else
        isStorageMenuOpen = true 
        RageUI.Visible(storageMenu, true)

        CreateThread(function()
            while isStorageMenuOpen do
                RageUI.IsVisible(storageMenu, function()
                    RageUI.Button("Déposer des objets", nil, {RightLabel = "→"}, true, {}, depositMenu)
                    RageUI.Button("Retirer des objets", nil, {RightLabel = "→"}, true, {}, withdrawMenu)
                end)

                RageUI.IsVisible(depositMenu, function()
                    local inventory = ESX.GetPlayerData().inventory
                    for _, item in ipairs(inventory) do
                        if item.count > 0 then
                            RageUI.Button(item.label, nil, {RightLabel = item.count}, true, {
                                onSelected = function()
                                    local amount = exports['alz-gangbuilder']:ShowSync("Quantité", false, 200, "number")
                                    amount = tonumber(amount)
                                    if amount and amount > 0 and amount <= item.count then
                                        TriggerServerEvent('gangbuilder:depositItem', storageGangData.name, item.name, amount)
                                    end
                                end
                            })
                        end
                    end
                end)

                RageUI.IsVisible(withdrawMenu, function()
                    ESX.TriggerServerCallback('gangbuilder:getGangInventory', function(items)
                        for _, item in pairs(items) do
                            if item.count > 0 then
                                RageUI.Button(item.label, nil, {RightLabel = item.count}, true, {
                                    onSelected = function()
                                        local amount = exports['alz-gangbuilder']:ShowSync("Quantité", false, 200, "number")
                                        amount = tonumber(amount)
                                        if amount and amount > 0 and amount <= item.count then
                                            TriggerServerEvent('gangbuilder:withdrawItem', storageGangData.name, item.name, amount)
                                        end
                                    end
                                })
                            end
                        end
                    end, storageGangData.name)
                end)

                if not RageUI.Visible(storageMenu) and not RageUI.Visible(depositMenu) and not RageUI.Visible(withdrawMenu) then
                    isStorageMenuOpen = false
                end

                Wait(0)
            end
        end)
    end
end

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        UpdateGangData()

        if cachedGangData and cachedGangData.has_storage and not Config.Storage.UseOxTarget and cachedGangData.storage_pos then
            local distance = #(playerCoords - vector3(cachedGangData.storage_pos.x, cachedGangData.storage_pos.y, cachedGangData.storage_pos.z))

            if distance < Config.Storage.EntryMarker.DrawDistance then
                wait = 0
                DrawMarker(Config.Storage.EntryMarker.Type, 
                    cachedGangData.storage_pos.x, cachedGangData.storage_pos.y, cachedGangData.storage_pos.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    Config.Storage.EntryMarker.Size.x, Config.Storage.EntryMarker.Size.y, Config.Storage.EntryMarker.Size.z, 
                    Config.Storage.EntryMarker.Color.r, Config.Storage.EntryMarker.Color.g, Config.Storage.EntryMarker.Color.b, Config.Storage.EntryMarker.Color.a, 
                    false, false, 2, false, nil, nil, false)

                if distance < 2.0 then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le coffre")
                    if IsControlJustReleased(0, Config.Storage.EntryMarker.Control) then
                        if Config.Storage.UseOxInventory then
                            local stashId = 'gang_' .. cachedGangData.name:gsub("%s+", ""):lower()
                            exports.ox_inventory:openInventory('stash', stashId)
                        else
                            OpenStorageMenu()
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    removeCurrentZone()
    cachedGangData = nil
    lastGangCheck = 0
end)

RegisterNetEvent('gangbuilder:gangUpdated')
AddEventHandler('gangbuilder:gangUpdated', function()
    removeCurrentZone()
    cachedGangData = nil
    lastGangCheck = 0
end)

RegisterNetEvent('gangbuilder:onGangUpdate')
AddEventHandler('gangbuilder:onGangUpdate', function(gangData)
    if not gangData then return end
    ESX.TriggerServerCallback('gangbuilder:getPlayerGang', function(playerGang)
        if playerGang == gangData.name then
            if type(gangData.storage_pos) == 'string' then
                gangData.storage_pos = json.decode(gangData.storage_pos)
            end
            
            removeCurrentZone()
            createZone(gangData)
            cachedGangData = gangData
            minStorageGrade = gangData.min_storage_grade or 0
        end
    end)
end) 