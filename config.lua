Config = {}

Config.Garage = {
    UseOxTarget = true, 
    EntryMarker = {
        Type = 35,
        Size = {x = 1.5, y = 1.5, z = 1.0},
        Color = {r = 255, g = 0, b = 0, a = 100},
        DrawDistance = 20.0,
        Control = 38,
    },
    ExitMarker = {
        Type = 36,
        Size = {x = 3.0, y = 3.0, z = 1.0},
        Color = {r = 255, g = 0, b = 0, a = 100},
        DrawDistance = 20.0,
        Control = 38,
    },
}

Config.Storage = {
    UseOxInventory = true,
    DefaultWeight = 50000,
    DefaultSlots = 100,
    UseOxTarget = true,
    CheckInterval = 5000,
    Debug = false,
    EntryMarker = {
        Type = 2,
        DrawDistance = 15.0,
        Control = 38,
        Size = {x = 1.0, y = 1.0, z = 1.0},
        Color = {r = 255, g = 255, b = 255, a = 100}
    }
}

Config.Search = {
    UseOxInventory = true,
    SearchCommand = 'search'
}


Config.ValidateStorageConfig = function()
    if not Config.Storage then
        print('[GangBuilder] [ERREUR] Configuration du stockage manquante')
        return false
    end

    if not Config.Storage.UseOxInventory then
        print('[GangBuilder] [ATTENTION] ox_inventory n\'est pas activé dans la configuration')
    end

    if not Config.Storage.UseOxTarget then
        print('[GangBuilder] [ATTENTION] ox_target n\'est pas activé dans la configuration')
    end

    if not Config.Storage.DefaultWeight or Config.Storage.DefaultWeight <= 0 then
        print('[GangBuilder] [ERREUR] Poids par défaut invalide')
        Config.Storage.DefaultWeight = 50000
    end

    if not Config.Storage.DefaultSlots or Config.Storage.DefaultSlots <= 0 then
        print('[GangBuilder] [ERREUR] Nombre d\'emplacements par défaut invalide')
        Config.Storage.DefaultSlots = 100
    end

    return true
end