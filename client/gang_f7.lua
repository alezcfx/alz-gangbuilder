ESX = exports["es_extended"]:getSharedObject()

local f9Menu = RageUI.CreateMenu("Actions Gang", "Menu d'actions")
local searchMenu = RageUI.CreateSubMenu(f9Menu, "Inventaire du joueur", "Items du joueur")
local isF9MenuOpen = false
local playerGang = nil
local gangGrade = 0
local minF7Grade = 0
local gangPermissions = nil
local isHandcuffed = false
local isDragged = false
local draggedBy = nil
local searchedPlayerId = nil
local searchedPlayerInventory = nil

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end
    
    CheckGangPermissions()
end)

RegisterNetEvent('gangbuilder:setGang')
AddEventHandler('gangbuilder:setGang', function(gang, grade)
    playerGang = gang
    gangGrade = grade
    CheckGangPermissions()
end)

function OpenF9Menu()
    if not playerGang or not gangPermissions or not gangPermissions.has_f7_menu then 
        ESX.ShowNotification('~r~Vous n\'avez pas accès au menu F7')
        return 
    end
    
    ESX.TriggerServerCallback('gangbuilder:getGangData', function(gangData)
        if not gangData then return end
        minF7Grade = gangData.min_f7_grade or 0
        
        if gangGrade < minF7Grade then
            ESX.ShowNotification('~r~Vous n\'avez pas le grade requis pour accéder au menu F7')
            return
        end
        
        if isF9MenuOpen then 
            isF9MenuOpen = false 
            RageUI.Visible(f9Menu, false)
            return
        else
            isF9MenuOpen = true 
            RageUI.Visible(f9Menu, true)

            CreateThread(function()
                while isF9MenuOpen do
                    RageUI.IsVisible(f9Menu, function()
                        if gangPermissions then
                            if gangPermissions.can_search then
                                RageUI.Button("Fouiller", "Fouiller la personne devant vous", {}, true, {
                                    onSelected = function()
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                            if Config.Search.UseOxInventory then
                                                exports.ox_inventory:openInventory('player', GetPlayerServerId(closestPlayer))
                                                RageUI.CloseAll()
                                            else
                                                searchedPlayerId = GetPlayerServerId(closestPlayer)
                                                TriggerServerEvent('gangbuilder:searchPlayerInventory', searchedPlayerId)
                                                RageUI.Visible(f9Menu, false)
                                                RageUI.Visible(searchMenu, true)
                                            end
                                        else
                                            ESX.ShowNotification('Aucun joueur à proximité')
                                        end
                                    end
                                })
                            end

                            if gangPermissions.can_handcuff then
                                RageUI.Button("Menotter", "Menotter/Démenotter la personne devant vous", {}, true, {
                                    onSelected = function()
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                            TriggerServerEvent('gangbuilder:handcuffPlayer', GetPlayerServerId(closestPlayer))
                                        else
                                            ESX.ShowNotification('Aucun joueur à proximité')
                                        end
                                    end
                                })
                            end

                            if gangPermissions.can_escort then
                                RageUI.Button("Escorter", "Escorter la personne devant vous", {}, true, {
                                    onSelected = function()
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                            local targetServerId = GetPlayerServerId(closestPlayer)
                                            TriggerServerEvent('gangbuilder:escortPlayer', targetServerId)
                                        else
                                            ESX.ShowNotification('Aucun joueur à proximité')
                                        end
                                    end
                                })
                            end

                            if gangPermissions.can_put_in_vehicle then
                                RageUI.Button("Mettre dans le véhicule", "Mettre la personne dans le véhicule", {}, true, {
                                    onSelected = function()
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                            TriggerServerEvent('gangbuilder:putInVehicle', GetPlayerServerId(closestPlayer))
                                        else
                                            ESX.ShowNotification('Aucun joueur à proximité')
                                        end
                                    end
                                })

                                RageUI.Button("Sortir du véhicule", "Sortir la personne du véhicule", {}, true, {
                                    onSelected = function()
                                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                            TriggerServerEvent('gangbuilder:removeFromVehicle', GetPlayerServerId(closestPlayer))
                                        else
                                            ESX.ShowNotification('Aucun joueur à proximité')
                                        end
                                    end
                                })
                            end

                            if gangPermissions.can_lockpick then
                                RageUI.Button("Crocheter", "Crocheter le véhicule devant vous", {}, true, {
                                    onSelected = function()
                                        local vehicle = ESX.Game.GetVehicleInDirection()
                                        if vehicle then
                                            local vehicleLockStatus = GetVehicleDoorLockStatus(vehicle)
                                            if vehicleLockStatus == 2 then
                                                TriggerServerEvent('gangbuilder:lockpickVehicle', VehToNet(vehicle))
                                            else
                                                ESX.ShowNotification('~r~Ce véhicule n\'est pas verrouillé')
                                            end
                                        else
                                            ESX.ShowNotification('~r~Aucun véhicule devant vous')
                                        end
                                    end
                                })
                            end
                        else
                            RageUI.Separator("↓ Menu non disponible ↓")
                        end
                    end)

                    RageUI.IsVisible(searchMenu, function()
                        if searchedPlayerInventory then
                            if #searchedPlayerInventory == 0 then
                                RageUI.Separator("~r~Inventaire vide")
                            else
                                for _, item in ipairs(searchedPlayerInventory) do
                                    RageUI.Button(item.label, ("Quantité: %s"):format(item.count), {RightLabel = "→"}, true, {
                                        onSelected = function()
                                            local quantity = exports['alz-gangbuilder']:ShowSync("Quantité à prendre", false, 200, "number")
                                            if quantity and tonumber(quantity) then
                                                quantity = tonumber(quantity)
                                                if quantity > 0 and quantity <= item.count then
                                                    TriggerServerEvent('gangbuilder:takeItem', searchedPlayerId, item.name, quantity)
                                                else
                                                    ESX.ShowNotification("Quantité invalide")
                                                end
                                            end
                                        end
                                    })
                                end
                            end
                        else
                            RageUI.Separator("~r~Chargement de l'inventaire...")
                        end
                    end)

                    if not RageUI.Visible(f9Menu) and not RageUI.Visible(searchMenu) then
                        isF9MenuOpen = false
                        searchedPlayerInventory = nil
                        searchedPlayerId = nil
                    end

                    Wait(0)
                end
            end)
        end
    end, playerGang)
end

function CheckGangPermissions()
    ESX.TriggerServerCallback('gangbuilder:getGangPermissions', function(permissions)
        if permissions then
            print('[GangBuilder] Permissions reçues pour le gang: ' .. tostring(permissions.gang_name))
            gangPermissions = permissions
            playerGang = permissions.gang_name
            gangGrade = permissions.gang_grade
            if playerGang then
                ESX.TriggerServerCallback('gangbuilder:getGangData', function(gangData)
                    if gangData then
                        minF7Grade = gangData.min_f7_grade or 0
                    else
                        print('[GangBuilder] Pas de données de gang trouvées')
                    end
                end, playerGang)
            end
        else
            playerGang = nil
            gangGrade = 0
            minF7Grade = 0
            gangPermissions = nil
        end
    end)
end

RegisterNetEvent('gangbuilder:escort')
AddEventHandler('gangbuilder:escort', function(escortingPlayerId)
    if not isHandcuffed then return end

    isDragged = not isDragged

    if isDragged then
        draggedBy = escortingPlayerId
    else
        draggedBy = nil
        DetachEntity(PlayerPedId(), true, false)
    end
end)

RegisterNetEvent('gangbuilder:handcuffAnim')
AddEventHandler('gangbuilder:handcuffAnim', function()
    local playerPed = PlayerPedId()
    isHandcuffed = not isHandcuffed
    
    if isHandcuffed then
        RequestAnimDict("mp_arresting")
        while not HasAnimDictLoaded("mp_arresting") do
            Wait(100)
        end
        
        SetEnableHandcuffs(playerPed, true)
        DisablePlayerFiring(PlayerId(), true)
        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
        TaskPlayAnim(playerPed, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
    else
        isDragged = false
        draggedBy = nil
        ClearPedSecondaryTask(playerPed)
        SetEnableHandcuffs(playerPed, false)
        DisablePlayerFiring(PlayerId(), false)
        DetachEntity(playerPed, true, false)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        
        if isHandcuffed and isDragged and draggedBy then
            local officerPed = GetPlayerPed(GetPlayerFromServerId(draggedBy))
            if DoesEntityExist(officerPed) and not IsEntityDead(officerPed) and officerPed ~= playerPed then
                if not IsEntityAttached(playerPed) then
                    AttachEntityToEntity(playerPed, officerPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                else
                    local attachedTo = GetEntityAttachedTo(playerPed)
                    if attachedTo ~= officerPed then
                        DetachEntity(playerPed, true, false)
                        AttachEntityToEntity(playerPed, officerPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    end
                end
            else
                isDragged = false
                draggedBy = nil
                DetachEntity(playerPed, true, false)
            end
        else
            if IsEntityAttached(playerPed) then
                DetachEntity(playerPed, true, false)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isHandcuffed then
            local playerPed = PlayerPedId()
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 75, true)
            if isDragged then
                DisableControlAction(0, 30, true)
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 36, true)
                DisableControlAction(0, 22, true)
            end
            
            if not IsEntityPlayingAnim(playerPed, "mp_arresting", "idle", 3) then
                TaskPlayAnim(playerPed, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
            end
        end
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    CheckGangPermissions()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    CheckGangPermissions()
end)

RegisterCommand('opengangmenu', function()
    if gangPermissions and gangPermissions.has_f7_menu then
        OpenF9Menu()
    end
end)

RegisterKeyMapping('opengangmenu', 'Ouvrir le menu gang', 'keyboard', 'F7')

RegisterNetEvent('gangbuilder:receivePlayerInventory')
AddEventHandler('gangbuilder:receivePlayerInventory', function(inventory)
    searchedPlayerInventory = inventory
end)

RegisterNetEvent('gangbuilder:putInVehicleAnim')
AddEventHandler('gangbuilder:putInVehicleAnim', function()
    local playerPed = PlayerPedId()
    
    if isHandcuffed then
        local vehicle = ESX.Game.GetClosestVehicle()
        if vehicle then
            local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
            local freeSeat = nil

            for i = 1, maxSeats do
                if IsVehicleSeatFree(vehicle, i - 1) then
                    freeSeat = i - 1
                    break
                end
            end

            if freeSeat ~= nil then
                TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
                isDragged = false
                if draggedBy then
                    DetachEntity(playerPed, true, false)
                    draggedBy = nil
                end
            else
                ESX.ShowNotification('~r~Aucune place disponible dans le véhicule')
            end
        else
            ESX.ShowNotification('~r~Aucun véhicule à proximité')
        end
    end
end)

RegisterNetEvent('gangbuilder:removeFromVehicleAnim')
AddEventHandler('gangbuilder:removeFromVehicleAnim', function()
    local playerPed = PlayerPedId()
    
    if isHandcuffed then
        if IsPedSittingInAnyVehicle(playerPed) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            TaskLeaveVehicle(playerPed, vehicle, 16)
        end
    end
end)

RegisterNetEvent('gangbuilder:lockpickAnim')
AddEventHandler('gangbuilder:lockpickAnim', function(vehicle)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicleNet = NetworkGetEntityFromNetworkId(vehicle)
    if not vehicleNet or not DoesEntityExist(vehicleNet) then return end
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Wait(10)
    end
    FreezeEntityPosition(playerPed, true)
    TaskPlayAnim(playerPed, "mini@repair", "fixing_a_player", 8.0, -8.0, -1, 49, 0, false, false, false)
    if Config.Search and Config.Search.UseOxLib then
        if lib.progressBar({
            duration = 3000,
            label = 'Crochetage en cours...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_player'
            },
        }) then
            SetVehicleDoorsLocked(vehicleNet, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicleNet, false)
            ESX.ShowNotification('~g~Véhicule déverrouillé')
            PlayVehicleDoorOpenSound(vehicleNet, 0)
        end
    else
        ESX.ShowNotification('Crochetage en cours...')
        Wait(3000)
        SetVehicleDoorsLocked(vehicleNet, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicleNet, false)
        ESX.ShowNotification('~g~Véhicule déverrouillé')
        PlayVehicleDoorOpenSound(vehicleNet, 0)
    end
    ClearPedTasks(playerPed)
    FreezeEntityPosition(playerPed, false)
end)

RegisterNetEvent('gangbuilder:updatePermissions')
AddEventHandler('gangbuilder:updatePermissions', function()
    CheckGangPermissions()
end) 