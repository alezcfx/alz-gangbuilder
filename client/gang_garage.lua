ESX = exports["es_extended"]:getSharedObject()

local garageMenu = RageUI.CreateMenu("Garage Gang", "Liste des véhicules")
local isGarageMenuOpen = false
local currentGang = nil
local spawnedVehicle = nil
local gangData = nil
local lastCheck = 0
local checkInterval = 5000
local entryZone = nil

function UpdateGangData()
    local currentTime = GetGameTimer()
    if currentTime - lastCheck > checkInterval then
        lastCheck = currentTime
        ESX.TriggerServerCallback('gangbuilder:getPlayerGang', function(gang)
            if gang then
                ESX.TriggerServerCallback('gangbuilder:getGangs', function(gangs)
                    for _, gangInfo in ipairs(gangs) do
                        if gangInfo.name == gang then
                            gangData = gangInfo
                            if type(gangInfo.garage_entry_pos) == 'string' then
                                gangData.garage_entry_pos = json.decode(gangInfo.garage_entry_pos)
                            end
                            
                            if type(gangInfo.garage_exit_pos) == 'string' then
                                gangData.garage_exit_pos = json.decode(gangInfo.garage_exit_pos)
                            end
                            
                            if type(gangInfo.garage_spawn_pos) == 'string' then
                                gangData.garage_spawn_pos = json.decode(gangInfo.garage_spawn_pos)
                            end
                            
                            if type(gangInfo.garage_vehicles) == 'string' then
                                gangData.garage_vehicles = json.decode(gangInfo.garage_vehicles)
                            elseif type(gangInfo.garage_vehicles) ~= 'table' then
                                gangData.garage_vehicles = {}
                            end
                            break
                        end
                    end
                end)
            end
        end)
    end
end

function OpenGarageMenu(vehicles, spawnPos)
    if not vehicles or type(vehicles) ~= 'table' then
        ESX.ShowNotification('~r~Erreur: Aucun véhicule disponible')
        return
    end

    if not spawnPos then
        ESX.ShowNotification('~r~Erreur: Position de spawn non définie')
        return
    end

    if isGarageMenuOpen then 
        isGarageMenuOpen = false 
        if garageMenu then
            RageUI.Visible(garageMenu, false)
        end
        return
    else
        isGarageMenuOpen = true 
        RageUI.Visible(garageMenu, true)

        CreateThread(function()
            while isGarageMenuOpen do
                RageUI.IsVisible(garageMenu, function()
                    if #vehicles > 0 then
                        for _, vehicle in ipairs(vehicles) do
                            local vehicleName = vehicle.model or "Véhicule inconnu"
                            RageUI.Button(vehicleName, "Sortir ce véhicule", {}, true, {
                                onSelected = function()
                                    SpawnGangVehicle(vehicle, spawnPos)
                                    if garageMenu then
                                        RageUI.Visible(garageMenu, false)
                                    end
                                    isGarageMenuOpen = false
                                end
                            })
                        end
                    else
                        RageUI.Separator("↓ Aucun véhicule disponible ↓")
                    end
                end)

                if not RageUI.Visible(garageMenu) then
                    isGarageMenuOpen = false
                end

                Wait(0)
            end
        end)
    end
end

function SpawnGangVehicle(vehicleData, coords)
    if not vehicleData or not coords then
        ESX.ShowNotification('~r~Erreur: Données de véhicule invalides')
        return
    end

    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
        spawnedVehicle = nil
    end

    ESX.Game.SpawnVehicle(vehicleData.model, vector3(coords.x, coords.y, coords.z -1), coords.w or 0.0, function(vehicle)
        if vehicle then
            spawnedVehicle = vehicle
            SetEntityHeading(vehicle, coords.w or 0.0)
            if vehicleData.color then
                SetVehicleCustomPrimaryColour(vehicle, vehicleData.color.r, vehicleData.color.g, vehicleData.color.b)
                SetVehicleCustomSecondaryColour(vehicle, vehicleData.color.r, vehicleData.color.g, vehicleData.color.b)
            end
            
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
            SetVehicleEngineOn(vehicle, true, true, false)
        else
            ESX.ShowNotification('~r~Erreur: Impossible de faire apparaître le véhicule')
        end
    end)
end

function CreateEntryZone(coords)
    if entryZone then return end
    
    entryZone = exports.ox_target:addSphereZone({
        coords = vector3(coords.x, coords.y, coords.z),
        radius = 5.0,
        options = {
            {
                name = 'gang_garage_entry',
                icon = 'fa-solid fa-car',
                label = 'Ouvrir le garage',
                distance = 5.0,
                onSelect = function()
                    if gangData and gangData.garage_vehicles and gangData.garage_spawn_pos then
                        OpenGarageMenu(gangData.garage_vehicles, gangData.garage_spawn_pos)
                    else
                        ESX.ShowNotification('~r~Erreur: Données du garage non disponibles')
                    end
                end
            }
        }
    })
    
    if entryZone then
        print('[GangBuilder] Zone ox_target créée avec succès, ID:', entryZone)
    else
        print('[GangBuilder] Erreur lors de la création de la zone ox_target')
    end
end

function RemoveEntryZone()
    if entryZone then
        exports.ox_target:removeZone(entryZone)
        entryZone = nil
    end
end

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        UpdateGangData()

        if gangData and gangData.has_garage then
            local entryPos = gangData.garage_entry_pos
            local exitPos = gangData.garage_exit_pos
            local spawnPos = gangData.garage_spawn_pos

            if entryPos then
                if Config.Garage.UseOxTarget then
                    CreateEntryZone(entryPos)
                else
                    local distanceToEntry = #(playerCoords - vector3(entryPos.x, entryPos.y, entryPos.z))
                    if distanceToEntry < Config.Garage.EntryMarker.DrawDistance then
                        wait = 0
                        DrawMarker(Config.Garage.EntryMarker.Type, 
                            entryPos.x, entryPos.y, entryPos.z, 
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            Config.Garage.EntryMarker.Size.x, Config.Garage.EntryMarker.Size.y, Config.Garage.EntryMarker.Size.z, 
                            Config.Garage.EntryMarker.Color.r, Config.Garage.EntryMarker.Color.g, Config.Garage.EntryMarker.Color.b, Config.Garage.EntryMarker.Color.a, 
                            false, true, 2, false, nil, nil, false)

                        if distanceToEntry < 2.0 then
                            ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le garage")
                            if IsControlJustReleased(0, Config.Garage.EntryMarker.Control) then
                                OpenGarageMenu(gangData.garage_vehicles, gangData.garage_spawn_pos)
                            end
                        end
                    end
                end
            end

            if exitPos and spawnedVehicle then
                local distanceToExit = #(playerCoords - vector3(exitPos.x, exitPos.y, exitPos.z))
                if distanceToExit < Config.Garage.ExitMarker.DrawDistance then
                    wait = 0
                    DrawMarker(Config.Garage.ExitMarker.Type, 
                        exitPos.x, exitPos.y, exitPos.z, 
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                        Config.Garage.ExitMarker.Size.x, Config.Garage.ExitMarker.Size.y, Config.Garage.ExitMarker.Size.z, 
                        Config.Garage.ExitMarker.Color.r, Config.Garage.ExitMarker.Color.g, Config.Garage.ExitMarker.Color.b, Config.Garage.ExitMarker.Color.a, 
                        false, true, 2, false, nil, nil, false)

                    if distanceToExit < 3.0 and IsPedInAnyVehicle(playerPed, false) then
                        ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger le véhicule")
                        if IsControlJustReleased(0, Config.Garage.ExitMarker.Control) then
                            DeleteEntity(spawnedVehicle)
                            spawnedVehicle = nil
                        end
                    end
                end
            end
        else
            RemoveEntryZone()
        end
        Wait(wait)
    end
end)

RegisterNetEvent('gangbuilder:setGang')
AddEventHandler('gangbuilder:setGang', function(gang)
    gangData = nil
    lastCheck = 0
    RemoveEntryZone()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    gangData = nil
    lastCheck = 0
end) 