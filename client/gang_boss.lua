ESX = exports["es_extended"]:getSharedObject()

local bossMenu = RageUI.CreateMenu("Menu Patron", "Actions de patron")
local recruitMenu = RageUI.CreateSubMenu(bossMenu, "Menu Patron", "Recruter un joueur")
local memberMenu = RageUI.CreateSubMenu(bossMenu, "Menu Patron", "Gestion du membre")
local gradeMenu = RageUI.CreateSubMenu(memberMenu, "Menu Patron", "Modifier le grade")

local isBossMenuOpen = false
local bossMenuCoords = nil
local playerGang = nil
local playerGangGrade = 0
local gangMembers = {}
local availablePlayers = {}
local selectedMember = nil
local gradeList = {}
local currentGradeIndex = 1
local hasBossAccess = false
local lastAccessCheck = 0
local accessCheckCooldown = 5000
local bossMenuTargets = {}

function CreateBossMenuTarget()
    if not Config.BossMenu.UseOxTarget or not exports.ox_target then return end
    if bossMenuTargets[1] then
        exports.ox_target:removeZone(bossMenuTargets[1])
        bossMenuTargets = {}
    end
    local targetId = exports.ox_target:addSphereZone({
        coords = bossMenuCoords,
        radius = Config.BossMenu.OxTarget.Distance or 5.0,
        debug = false,
        options = {
            {
                name = 'gang_boss_menu',
                icon = Config.BossMenu.OxTarget.Icon or 'fa-solid fa-briefcase',
                label = Config.BossMenu.OxTarget.Label or 'Menu Patron',
                onSelect = function()
                    OpenBossMenu()
                end
            }
        }
    })
    
    if targetId then
        table.insert(bossMenuTargets, targetId)
    end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.TriggerServerCallback('gangbuilder:getPlayerGang', function(gang, grade)
        if gang then
            playerGang = gang
            playerGangGrade = grade
            ESX.TriggerServerCallback('gangbuilder:checkBossAccess', function(hasAccess, gangData)
                hasBossAccess = hasAccess
                
                if gangData and gangData.boss_menu_pos then
                    local bossPos = type(gangData.boss_menu_pos) == 'string' and json.decode(gangData.boss_menu_pos) or gangData.boss_menu_pos
                    
                    if bossPos.x and bossPos.y and bossPos.z then
                        bossMenuCoords = vector3(bossPos.x, bossPos.y, bossPos.z)
                        if Config.BossMenu and Config.BossMenu.UseOxTarget then
                            CreateBossMenuTarget()
                        end
                    end
                end
            end)
        end
    end)
end)

function CheckBossAccess(forceCheck)
    local currentTime = GetGameTimer()
    
    if forceCheck or (currentTime - lastAccessCheck > accessCheckCooldown) then
        lastAccessCheck = currentTime
        
        ESX.TriggerServerCallback('gangbuilder:checkBossAccess', function(hasAccess)
            hasBossAccess = hasAccess
        end)
    end
    
    return hasBossAccess
end

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        if Config.BossMenu and Config.BossMenu.UseOxTarget then
            Wait(1000)
        elseif bossMenuCoords then
            local menuCoords = type(bossMenuCoords) == 'vector3' and bossMenuCoords or 
                               (type(bossMenuCoords) == 'table' and vector3(bossMenuCoords.x, bossMenuCoords.y, bossMenuCoords.z) or nil)
            
            if menuCoords then
                local distance = #(coords - menuCoords)
                if distance < 10.0 then
                    sleep = 0
                    
                    if distance < 3.0 then
                        if CheckBossAccess(false) then
                            DrawMarker(22, menuCoords.x, menuCoords.y, menuCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                                0.5, 0.5, 0.5, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                            
                            if distance < 1.5 then
                                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder au menu patron")
                                if IsControlJustReleased(0, 38) then
                                    ESX.TriggerServerCallback('gangbuilder:checkBossAccess', function(hasAccess)
                                        if hasAccess then
                                            OpenBossMenu()
                                        else
                                            ESX.ShowNotification("~r~Vous n'avez pas accès au menu patron")
                                        end
                                    end)
                                end
                            end
                        end
                    else
                        DrawMarker(22, menuCoords.x, menuCoords.y, menuCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                            0.5, 0.5, 0.5, 255, 0, 0, 100, false, true, 2, false, nil, nil, false)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('gangbuilder:setGangBoss')
AddEventHandler('gangbuilder:setGangBoss', function(gang, grade, bossPos)
    if bossMenuTargets[1] and exports.ox_target then
        exports.ox_target:removeZone(bossMenuTargets[1])
        bossMenuTargets = {}
    end
    
    playerGang = gang
    playerGangGrade = grade
    
    if bossPos then
        if type(bossPos) == 'string' then
            bossPos = json.decode(bossPos)
        end
        
        if bossPos.x and bossPos.y and bossPos.z then
            bossMenuCoords = vector3(bossPos.x, bossPos.y, bossPos.z)
            if Config.BossMenu and Config.BossMenu.UseOxTarget then
                CreateBossMenuTarget()
            end
        end
    end
    
    CheckBossAccess(true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and bossMenuTargets[1] and exports.ox_target then
        exports.ox_target:removeZone(bossMenuTargets[1])
    end
end)

function OpenBossMenu()
    if isBossMenuOpen then
        isBossMenuOpen = false
        RageUI.Visible(bossMenu, false)
        return
    end
    
    ESX.TriggerServerCallback('gangbuilder:checkBossAccess', function(hasAccess, gangData, members)
        if not hasAccess then
            ESX.ShowNotification("~r~Vous n'avez pas accès au menu patron")
            return
        end
        
        ESX.TriggerServerCallback('gangbuilder:getGangGrades', function(grades)
            if not grades or #grades == 0 then
                ESX.ShowNotification("~r~Erreur lors de la récupération des grades du gang")
                return
            end
            
            gradeList = {}
            for _, grade in ipairs(grades) do
                table.insert(gradeList, grade)
            end
            
            table.sort(gradeList, function(a, b)
                return a.number < b.number
            end)
            
            gangMembers = members or {}
            isBossMenuOpen = true
            RageUI.Visible(bossMenu, true)
            
            RefreshAvailablePlayers()
            
            CreateThread(function()
                while isBossMenuOpen do
                    RageUI.IsVisible(bossMenu, function()
                        RageUI.Separator("↓ Gestion des membres ↓")
                        
                        RageUI.Button("Recruter un joueur", "Recruter un nouveau membre dans le gang", {}, true, {}, recruitMenu)
                        
                        RageUI.Separator("↓ Membres du gang ↓")
                        
                        if #gangMembers == 0 then
                            RageUI.Button("Aucun membre", "Aucun membre dans ce gang", {}, false, {})
                        else
                            for _, member in ipairs(gangMembers) do
                                RageUI.Button(member.name .. " - " .. member.grade_label, "Gérer ce membre", {}, true, {
                                    onSelected = function()
                                        selectedMember = member
                                        currentGradeIndex = 1
                                        
                                        for i, grade in ipairs(gradeList) do
                                            if grade.number == member.grade then
                                                currentGradeIndex = i
                                                break
                                            end
                                        end
                                    end
                                }, memberMenu)
                            end
                        end
                    end)

                    RageUI.IsVisible(recruitMenu, function()
                        if #availablePlayers == 0 then
                            RageUI.Button("Aucun joueur à proximité", nil, {}, false, {})
                        else
                            for _, player in ipairs(availablePlayers) do
                                RageUI.Button(player.name, "Recruter ce joueur", {}, true, {
                                    onSelected = function()
                                        TriggerServerEvent('gangbuilder:recruitPlayer', player.id, playerGang)
                                        RageUI.GoBack()
                                        Wait(500)
                                        ESX.TriggerServerCallback('gangbuilder:getGangMembers', function(members)
                                            gangMembers = members or {}
                                        end, playerGang)
                                    end
                                })
                            end
                        end
                    end)

                    RageUI.IsVisible(memberMenu, function()
                        if selectedMember then
                            RageUI.Button("Modifier le grade", "Changer le grade du membre", {}, true, {}, gradeMenu)
                            
                            RageUI.Button("Virer du gang", "Virer le membre du gang", {Color = {BackgroundColor = {200, 0, 0, 50}}}, true, {
                                onSelected = function()
                                    local confirm = exports['alz-gangbuilder']:ShowSync("Tapez 'CONFIRMER' pour virer " .. selectedMember.name, false, 200, "text")
                                    if confirm == "CONFIRMER" then
                                        TriggerServerEvent('gangbuilder:firePlayer', selectedMember.identifier)
                                        ESX.ShowNotification(selectedMember.name .. " a été viré du gang")
                                        RageUI.GoBack()
                                        Wait(500)
                                        ESX.TriggerServerCallback('gangbuilder:getGangMembers', function(members)
                                            gangMembers = members or {}
                                        end, playerGang)
                                    else
                                        ESX.ShowNotification("~r~Action annulée")
                                    end
                                end
                            })
                        end
                    end)

                    RageUI.IsVisible(gradeMenu, function()
                        if selectedMember then
                            for i, grade in ipairs(gradeList) do
                                if grade.number < playerGangGrade then
                                    RageUI.Button(grade.label .. " (Grade " .. grade.number .. ")", "Définir ce grade", {
                                        RightBadge = grade.number == selectedMember.grade and RageUI.BadgeStyle.Tick or nil
                                    }, true, {
                                        onSelected = function()
                                            TriggerServerEvent('gangbuilder:changePlayerGrade', selectedMember.identifier, playerGang, grade.number)
                                            ESX.ShowNotification("Grade modifié pour " .. selectedMember.name)
                                            RageUI.GoBack()
                                            Wait(500)
                                            ESX.TriggerServerCallback('gangbuilder:getGangMembers', function(members)
                                                gangMembers = members or {}
                                            end, playerGang)
                                        end
                                    })
                                end
                            end
                        end
                    end)
                    
                    if not RageUI.Visible(bossMenu) and 
                       not RageUI.Visible(recruitMenu) and 
                       not RageUI.Visible(memberMenu) and 
                       not RageUI.Visible(gradeMenu) then
                        isBossMenuOpen = false
                    end
                    
                    Wait(0)
                end
            end)
        end, playerGang)
    end)
end

function RefreshAvailablePlayers()
    availablePlayers = {}
    local players = ESX.Game.GetPlayersInArea(GetEntityCoords(PlayerPedId()), 10.0)
    
    for i = 1, #players, 1 do
        local serverPlayerId = GetPlayerServerId(players[i])
        local player = {
            id = serverPlayerId,
            name = GetPlayerName(players[i])
        }
        table.insert(availablePlayers, player)
    end
end 