ESX = exports["es_extended"]:getSharedObject()

local open = false
local mainMenu = RageUI.CreateMenu("Gangs", "Menu de gestion des gangs")
local createGangMenu = RageUI.CreateSubMenu(mainMenu, "Gangs", "Créer un gang")
local vehicleMenu = RageUI.CreateSubMenu(createGangMenu, "Gangs", "Gestion des véhicules")
local gradeMenu = RageUI.CreateSubMenu(createGangMenu, "Gangs", "Gestion des grades")
local manageGangMenu = RageUI.CreateSubMenu(mainMenu, "Gangs", "Gérer le gang")
local gangs = {}
local gangName = ""
local gangLabel = ""
local hasGarage = false
local hasCoffre = false
local garageVehicles = {}
local garageExitPos = nil
local garageEnterPos = nil
local garageSpawnPos = nil
local coffrePos = nil
local gangGrades = {}
local selectedGang = nil
local hasF7Menu = false
local f7Options = {
    fouiller = false,
    menotter = false,
    escorter = false,
    vehicule = false,
    crocheter = false
}
local bossMenuPos = nil

local minGarageGrade = 0
local minCoffreGrade = 0
local minF7Grade = 0

local currentR, currentG, currentB = 0, 0, 0
local editingVehicleIndex = nil
local BadgeStyle = {
    RedCross = function()
        return {
            BadgeTexture = "mp_alerttriangle",
            BadgeColour = { R = 255, G = 0, B = 0, A = 255 }
        }
    end,
    GreenCross = function()
        return {
            BadgeTexture = "mp_alerttriangle",
            BadgeColour = { R = 0, G = 255, B = 0, A = 255 }
        }
    end
}

function ResetAllValues()
    gangName = ""
    gangLabel = ""
    hasGarage = false
    hasCoffre = false
    garageVehicles = {}
    garageExitPos = nil
    garageEnterPos = nil
    garageSpawnPos = nil
    coffrePos = nil
    gangGrades = {}
    hasF7Menu = false
    f7Options = {
        fouiller = false,
        menotter = false,
        escorter = false,
        vehicule = false,
        crocheter = false
    }
    garageSpawnPos = nil
    bossMenuPos = nil
    minGarageGrade = 0
    minCoffreGrade = 0
    minF7Grade = 0
end

function IsEverythingValid()
    if gangName == "" or gangLabel == "" then return false end
    if #gangGrades == 0 then return false end
    if hasGarage then
        if not garageExitPos or not garageEnterPos or not garageSpawnPos then return false end
        if #garageVehicles == 0 then return false end
    end
    if hasCoffre and not coffrePos then return false end
    
    return true
end

local function RefreshGangs()
    ESX.TriggerServerCallback('gangbuilder:getGangs', function(gangList)
        gangs = gangList
    end)
end

local function LoadGangData(gang)
    gangName = gang.name
    gangLabel = gang.label
    hasGarage = gang.has_garage
    hasCoffre = gang.has_storage
    if type(gang.garage_vehicles) == 'string' then
        local vehicles = json.decode(gang.garage_vehicles) or {}
        garageVehicles = {}
        for _, vehicle in ipairs(vehicles) do
            if type(vehicle) == 'string' then
                table.insert(garageVehicles, {
                    model = vehicle,
                    color = {r = 0, g = 0, b = 0}
                })
            else
                table.insert(garageVehicles, vehicle)
            end
        end
    else
        garageVehicles = gang.garage_vehicles or {}
    end
    garageExitPos = type(gang.garage_exit_pos) == 'string' and json.decode(gang.garage_exit_pos) or gang.garage_exit_pos
    garageEnterPos = type(gang.garage_entry_pos) == 'string' and json.decode(gang.garage_entry_pos) or gang.garage_entry_pos
    garageSpawnPos = type(gang.garage_spawn_pos) == 'string' and json.decode(gang.garage_spawn_pos) or gang.garage_spawn_pos
    coffrePos = type(gang.storage_pos) == 'string' and json.decode(gang.storage_pos) or gang.storage_pos
    bossMenuPos = type(gang.boss_menu_pos) == 'string' and json.decode(gang.boss_menu_pos) or gang.boss_menu_pos
    
    hasF7Menu = gang.has_f7_menu
    f7Options = {
        fouiller = gang.can_search,
        menotter = gang.can_handcuff,
        escorter = gang.can_escort,
        vehicule = gang.can_put_in_vehicle,
        crocheter = gang.can_lockpick
    }


    minGarageGrade = gang.min_garage_grade or 0
    minCoffreGrade = gang.min_storage_grade or 0
    minF7Grade = gang.min_f7_grade or 0

    if #gangGrades == 0 then
        ESX.TriggerServerCallback('gangbuilder:getGangGrades', function(grades)
            gangGrades = grades or {}
        end, gang.name)
    end
end

mainMenu.Closed = function()
    open = false
end

function OpenGangMenu()
    if RageUI.Visible(mainMenu) then 
        if mainMenu then
            RageUI.Visible(mainMenu, false)
        end
        if manageGangMenu then
            RageUI.Visible(manageGangMenu, false)
        end
        if createGangMenu then
            RageUI.Visible(createGangMenu, false)
        end
        if gradeMenu then
            RageUI.Visible(gradeMenu, false)
        end
        if vehicleMenu then
            RageUI.Visible(vehicleMenu, false)
        end
        open = false
    else
        open = true 
        RefreshGangs()
        RageUI.Visible(mainMenu, true)

        CreateThread(function()
            while open do
                RageUI.IsVisible(mainMenu, function()
                    RageUI.Separator("↓ Gangs existants ↓")
                    
                    if #gangs == 0 then
                        RageUI.Separator("Aucun gang créé")
                    else
                        for _, gang in ipairs(gangs) do
                            RageUI.Button(gang.label, "Gang: " .. gang.name, {}, true, {
                                onSelected = function()
                                    selectedGang = gang
                                end
                            }, manageGangMenu)
                        end
                    end

                    RageUI.Separator("↓ Création d'un gang ↓")
                    RageUI.Button("Créer un gang", "Créer un nouveau gang", {}, true, {
                        onSelected = function()
                            ResetAllValues()
                        end
                    }, createGangMenu)
                end)

                RageUI.IsVisible(manageGangMenu, function()
                    if selectedGang then
                        RageUI.Button("Modifier le gang", "Modifier les paramètres du gang", {}, true, {
                            onSelected = function()
                                LoadGangData(selectedGang)
                            end
                        }, createGangMenu)

                        RageUI.Button("Supprimer le gang", "Supprimer définitivement le gang", {RightBadge = RageUI.BadgeStyle.Alert}, true, {
                            onSelected = function()
                                local confirm = exports['alz-gangbuilder']:ShowSync("Tapez 'CONFIRMER' pour supprimer le gang", false, 200, "text")
                                if confirm == "CONFIRMER" then
                                    TriggerServerEvent('gangbuilder:deleteGang', selectedGang.name)
                                    RefreshGangs()
                                    selectedGang = nil
                                else
                                    ESX.ShowNotification("Suppression annulée")
                                end
                            end
                        })
                    end
                end)

                RageUI.IsVisible(createGangMenu, function()
                    RageUI.Separator("Création d'un gang")
                    RageUI.Button(gangName ~= "" and "Nom du gang : " .. gangName or "Nom du gang", "Entrez le nom de votre gang", {RightLabel = gangName ~= "" and "✅" or "❌"}, true, {
                        onSelected = function()
                            local input = exports['alz-gangbuilder']:ShowSync("Entrez le nom du gang", false, 200, "text")
                            if input then
                                gangName = input
                            end
                        end
                    })
                    RageUI.Button(gangLabel ~= "" and "Label du gang : " .. gangLabel or "Label du gang", "Entrez le label de votre gang", {RightLabel = gangLabel ~= "" and "✅" or "❌"}, true, {
                        onSelected = function()
                            local input = exports['alz-gangbuilder']:ShowSync("Entrez le label du gang", false, 200, "text")
                            if input then
                                gangLabel = input
                            end
                        end
                    })
                    RageUI.Button("Grades du gang", "Gérer les grades du gang", {RightLabel = #gangGrades > 0 and "✅" or "❌"}, true, {}, gradeMenu)
                    RageUI.Separator("↓ Garage ↓")
                    RageUI.Checkbox("Garage", "Activer le garage pour ce gang", hasGarage, {}, {
                        onChecked = function()
                            if #gangGrades > 0 then
                                hasGarage = true
                                local items = {}
                                for _, grade in ipairs(gangGrades) do
                                    table.insert(items, grade.label)
                                end
                                local selectedIndex = 1
                                RageUI.List("Grade minimum", items, selectedIndex, "Sélectionnez le grade minimum pour accéder au garage", {}, true, {
                                    onListChange = function(Index, Item)
                                        selectedIndex = Index
                                        minGarageGrade = gangGrades[Index].number
                                    end
                                })
                            else
                                ESX.ShowNotification("~r~Vous devez d'abord créer des grades")
                                hasGarage = false
                            end
                        end,
                        onUnChecked = function()
                            hasGarage = false
                            garageExitPos = nil
                            garageEnterPos = nil
                            garageVehicles = {}
                            minGarageGrade = 0
                        end
                    }, #gangGrades > 0)

                    if hasGarage then
                        local gradesList = {}
                        for _, grade in ipairs(gangGrades) do
                            table.insert(gradesList, grade.label)
                        end
                        
                        RageUI.List("Grade minimum garage", gradesList, minGarageGrade + 1, "Sélectionnez le grade minimum pour accéder au garage", {}, true, {
                            onListChange = function(Index, Item)
                                minGarageGrade = gangGrades[Index].number
                            end
                        })
                        RageUI.Button("Position pour rentrer", "Définir la position de rentrer du garage", {RightLabel = garageExitPos and "✅" or "❌"}, true, {
                            onSelected = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                garageExitPos = coords
                                ESX.ShowNotification("Position de rentrer enregistrée")
                            end
                        })

                        RageUI.Button("Position pour sortir", "Définir la position sortie du garage", {RightLabel = garageEnterPos and "✅" or "❌"}, true, {
                            onSelected = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                garageEnterPos = coords
                                ESX.ShowNotification("Position sortie enregistrée")
                            end
                        })

                        RageUI.Button("Position spawn véhicule", "Définir la position où les véhicules apparaîtront", {RightLabel = garageSpawnPos and "✅" or "❌"}, true, {
                            onSelected = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                local heading = GetEntityHeading(ped)
                                garageSpawnPos = {
                                    x = coords.x,
                                    y = coords.y,
                                    z = coords.z,
                                    w = heading
                                }
                                ESX.ShowNotification("Position de spawn enregistrée")
                            end
                        })

                        RageUI.Button("Choisir véhicule", "Gérer les véhicules du garage", {RightLabel = #garageVehicles > 0 and "✅" or "❌"}, true, {}, vehicleMenu)
                    end

                    RageUI.Separator("↓ Coffre ↓")
                    RageUI.Checkbox("Coffre", "Activer le coffre pour ce gang", hasCoffre, {}, {
                        onChecked = function()
                            if #gangGrades > 0 then
                                hasCoffre = true
                            else
                                ESX.ShowNotification("~r~Vous devez d'abord créer des grades")
                                hasCoffre = false
                            end
                        end,
                        onUnChecked = function()
                            hasCoffre = false
                            coffrePos = nil
                            minCoffreGrade = 0
                        end
                    }, #gangGrades > 0)

                    if hasCoffre then
                        local gradesList = {}
                        for _, grade in ipairs(gangGrades) do
                            table.insert(gradesList, grade.label)
                        end
                        
                        RageUI.List("Grade minimum coffre", gradesList, minCoffreGrade + 1, "Sélectionnez le grade minimum pour accéder au coffre", {}, true, {
                            onListChange = function(Index, Item)
                                minCoffreGrade = gangGrades[Index].number
                            end
                        })
                        RageUI.Button("Position du coffre", "Définir la position du coffre", {RightLabel = coffrePos and "✅" or "❌"}, true, {
                            onSelected = function()
                                local ped = PlayerPedId()
                                local coords = GetEntityCoords(ped)
                                coffrePos = coords
                                ESX.ShowNotification("Position du coffre enregistrée")
                            end
                        })
                    end

                    RageUI.Separator("↓ Menu F7 ↓")
                    RageUI.Checkbox("Menu F7", "Activer le menu F7 pour ce gang", hasF7Menu, {}, {
                        onChecked = function()
                            if #gangGrades > 0 then
                                hasF7Menu = true
                            else
                                ESX.ShowNotification("~r~Vous devez d'abord créer des grades")
                                hasF7Menu = false
                            end
                        end,
                        onUnChecked = function()
                            hasF7Menu = false
                            f7Options.fouiller = false
                            f7Options.menotter = false
                            f7Options.escorter = false
                            f7Options.vehicule = false
                            f7Options.crocheter = false
                            minF7Grade = 0
                        end
                    }, #gangGrades > 0)

                    if hasF7Menu then
                        local gradesList = {}
                        for _, grade in ipairs(gangGrades) do
                            table.insert(gradesList, grade.label)
                        end
                        
                        RageUI.List("Grade minimum F7", gradesList, minF7Grade + 1, "Sélectionnez le grade minimum pour accéder au menu F7", {}, true, {
                            onListChange = function(Index, Item)
                                minF7Grade = gangGrades[Index].number
                            end
                        })
                        RageUI.Checkbox("Fouiller", "Autoriser l'action Fouiller", f7Options.fouiller, {}, {
                            onChecked = function()
                                f7Options.fouiller = true
                            end,
                            onUnChecked = function()
                                f7Options.fouiller = false
                            end
                        })

                        RageUI.Checkbox("Menotter", "Autoriser l'action Menotter", f7Options.menotter, {}, {
                            onChecked = function()
                                f7Options.menotter = true
                            end,
                            onUnChecked = function()
                                f7Options.menotter = false
                            end
                        })

                        RageUI.Checkbox("Escorter", "Autoriser l'action Escorter", f7Options.escorter, {}, {
                            onChecked = function()
                                f7Options.escorter = true
                            end,
                            onUnChecked = function()
                                f7Options.escorter = false
                            end
                        })

                        RageUI.Checkbox("Mettre dans le véhicule", "Autoriser l'action Mettre dans le véhicule", f7Options.vehicule, {}, {
                            onChecked = function()
                                f7Options.vehicule = true
                            end,
                            onUnChecked = function()
                                f7Options.vehicule = false
                            end
                        })

                        RageUI.Checkbox("Crocheter le véhicule", "Autoriser l'action Crocheter le véhicule", f7Options.crocheter, {}, {
                            onChecked = function()
                                f7Options.crocheter = true
                            end,
                            onUnChecked = function()
                                f7Options.crocheter = false
                            end
                        })
                    end

                    RageUI.Separator("↓ Menu Patron ↓")
                    RageUI.Button("Position du menu patron", "Définir la position du menu patron", {RightLabel = bossMenuPos and "✅" or "❌"}, true, {
                        onSelected = function()
                            local ped = PlayerPedId()
                            local coords = GetEntityCoords(ped)
                            bossMenuPos = coords
                            ESX.ShowNotification("Position du menu patron enregistrée")
                        end
                    })

                    RageUI.Separator("↓ Confirmation ↓")
                    RageUI.Button("Valider le gang", "Créer le gang avec les paramètres définis", {RightLabel = IsEverythingValid() and "✅" or "❌"}, IsEverythingValid(), {
                        onSelected = function()
                            local gangData = {
                                name = gangName,
                                label = gangLabel,
                                grades = gangGrades,
                                hasGarage = hasGarage,
                                hasCoffre = hasCoffre,
                                hasF7Menu = hasF7Menu,
                                f7Options = f7Options,
                                minGarageGrade = minGarageGrade,
                                minCoffreGrade = minCoffreGrade,
                                minF7Grade = minF7Grade,
                                bossMenuPos = bossMenuPos
                            }
                            if hasGarage then
                                gangData.garageEnterPos = garageEnterPos
                                gangData.garageExitPos = garageExitPos
                                gangData.garageSpawnPos = garageSpawnPos
                                gangData.vehicles = garageVehicles
                            end
                            if hasCoffre then
                                gangData.coffrePos = coffrePos
                            end
                            TriggerServerEvent('gangbuilder:createGang', gangData)
                            ResetAllValues()
                            RefreshGangs()
                            RageUI.GoBack()
                            TriggerServerEvent('gangbuilder:gangUpdated', gangData.name)
                        end
                    })
                    RageUI.Button("Supprimer tout", "Réinitialiser tous les champs", {RightBadge = RageUI.BadgeStyle.Alert}, true, {
                        onSelected = function()
                            ResetAllValues()
                            ESX.ShowNotification("Toutes les valeurs ont été réinitialisées")
                        end
                    })
                end)

                RageUI.IsVisible(gradeMenu, function()
                    RageUI.Separator("↓ Grades du gang ↓")
                    RageUI.Button("Ajouter un grade", "Ajouter un nouveau grade", {}, true, {
                        onSelected = function()
                            local label = exports['alz-gangbuilder']:ShowSync("Entrez le label du grade", false, 200, "text")
                            if label then
                                local number = exports['alz-gangbuilder']:ShowSync("Entrez le numéro du grade", false, 200, "number")
                                if number then
                                    number = tonumber(number)
                                    if number then
                                        table.insert(gangGrades, {
                                            label = label,
                                            number = number
                                        })
                                    end
                                end
                            end
                        end
                    })
                    for i, grade in ipairs(gangGrades) do
                        RageUI.Button(grade.label .. " (Grade " .. grade.number .. ")", "Supprimer ce grade", {}, true, {
                            onSelected = function()
                                table.remove(gangGrades, i)
                            end
                        })
                    end
                    RageUI.Button("Retour", "Retourner au menu précédent", {}, true, {
                        onSelected = function()
                            RageUI.GoBack()
                        end
                    })
                end)

                RageUI.IsVisible(vehicleMenu, function()
                    RageUI.Separator("↓ Véhicules du garage ↓")
                    RageUI.Button("Ajouter un véhicule", "Ajouter un nouveau véhicule au garage", {}, true, {
                        onSelected = function()
                            local input = exports['alz-gangbuilder']:ShowSync("Entrez le nom du véhicule", false, 200, "text")
                            if input then
                                table.insert(garageVehicles, {
                                    model = input,
                                    color = {r = 0, g = 0, b = 0}
                                })
                            end
                        end
                    })
                    for i, vehicle in ipairs(garageVehicles) do
                        if type(vehicle) == 'string' then
                            garageVehicles[i] = {
                                model = vehicle,
                                color = {r = 0, g = 0, b = 0}
                            }
                            vehicle = garageVehicles[i]
                        elseif type(vehicle) == 'table' and not vehicle.color then
                            vehicle.color = {r = 0, g = 0, b = 0}
                        end
                        
                        RageUI.Button(vehicle.model, "Gérer ce véhicule", {
                            RightLabel = "→→→",
                            Color = {
                                BackgroundColor = {vehicle.color.r, vehicle.color.g, vehicle.color.b, 50}
                            }
                        }, true, {
                            onSelected = function()
                                editingVehicleIndex = i
                                currentR = vehicle.color.r
                                currentG = vehicle.color.g
                                currentB = vehicle.color.b
                            end
                        })
                        if editingVehicleIndex == i then
                            RageUI.Separator("↓ Couleur du véhicule ↓")

                            local colorValues = {}
                            for i = 0, 255 do
                                table.insert(colorValues, i)
                            end

                            RageUI.List("Rouge", colorValues, currentR + 1, "Appuyez sur ENTRÉE pour saisir une valeur manuellement", {}, true, {
                                onListChange = function(Index, Item)
                                    currentR = Index - 1
                                    vehicle.color.r = currentR
                                end,
                                onSelected = function()
                                    local input = exports['alz-gangbuilder']:ShowSync("Entrez une valeur entre 0 et 255", false, 200, "number")
                                    if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 255 then
                                        currentR = tonumber(input)
                                        vehicle.color.r = currentR
                                    else
                                        ESX.ShowNotification("~r~Valeur invalide. Veuillez entrer un nombre entre 0 et 255.")
                                    end
                                end
                            })

                            RageUI.List("Vert", colorValues, currentG + 1, "Appuyez sur ENTRÉE pour saisir une valeur manuellement", {}, true, {
                                onListChange = function(Index, Item)
                                    currentG = Index - 1
                                    vehicle.color.g = currentG
                                end,
                                onSelected = function()
                                    local input = exports['alz-gangbuilder']:ShowSync("Entrez une valeur entre 0 et 255", false, 200, "number")
                                    if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 255 then
                                        currentG = tonumber(input)
                                        vehicle.color.g = currentG
                                    else
                                        ESX.ShowNotification("~r~Valeur invalide. Veuillez entrer un nombre entre 0 et 255.")
                                    end
                                end
                            })

                            RageUI.List("Bleu", colorValues, currentB + 1, "Appuyez sur ENTRÉE pour saisir une valeur manuellement", {}, true, {
                                onListChange = function(Index, Item)
                                    currentB = Index - 1
                                    vehicle.color.b = currentB
                                end,
                                onSelected = function()
                                    local input = exports['alz-gangbuilder']:ShowSync("Entrez une valeur entre 0 et 255", false, 200, "number")
                                    if input and tonumber(input) and tonumber(input) >= 0 and tonumber(input) <= 255 then
                                        currentB = tonumber(input)
                                        vehicle.color.b = currentB
                                    else
                                        ESX.ShowNotification("~r~Valeur invalide. Veuillez entrer un nombre entre 0 et 255.")
                                    end
                                end
                            })

                            RageUI.Separator("↓ Actions ↓")

                            RageUI.Button("Supprimer ce véhicule", "Supprimer ce véhicule du garage", {
                                Color = { BackgroundColor = { 150, 0, 0, 50 } }
                            }, true, {
                                onSelected = function()
                                    table.remove(garageVehicles, i)
                                    editingVehicleIndex = nil
                                end
                            })

                            RageUI.Button("Fermer l'éditeur de couleur", "Retourner à la liste des véhicules", {}, true, {
                                onSelected = function()
                                    editingVehicleIndex = nil
                                end
                            })
                        end
                    end
                    if editingVehicleIndex == nil then
                        RageUI.Button("Retour", "Retourner au menu précédent", {}, true, {
                            onSelected = function()
                                RageUI.GoBack()
                            end
                        })
                    end
                end)

                if not RageUI.Visible(mainMenu) and 
                   not RageUI.Visible(manageGangMenu) and 
                   not RageUI.Visible(createGangMenu) and 
                   not RageUI.Visible(gradeMenu) and 
                   not RageUI.Visible(vehicleMenu) then
                    open = false
                end

                Wait(0)
            end
        end)
    end
end

RegisterCommand("gangmenu", function()
    if not open then
        OpenGangMenu()
    else
        RageUI.CloseAll()
        open = false
    end
end)

RegisterKeyMapping("gangmenu", "Ouvrir le menu des gangs", "keyboard", "F9")
RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function()
    if open then
        open = false
        RageUI.CloseAll()
    end
end)

RegisterNetEvent('esx:showInventory')
AddEventHandler('esx:showInventory', function()
    if open then
        open = false
        RageUI.CloseAll()
    end
end)

TriggerEvent('chat:addSuggestion', '/setgang', 'Assigne un gang et un grade à un joueur', {
    { name = 'ID', help = 'ID du joueur' },
    { name = 'gang', help = 'Nom du gang (ex: ballas, vagos...)' },
    { name = 'grade', help = 'Grade numérique dans le gang (ex: 0, 1, 2)' }
})