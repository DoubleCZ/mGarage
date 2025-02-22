Config                = {}

Config.Debug          = false

-- To edit/create garages
Config.AdminGroup     = 'admin'

-- Start defaultGarages.lua
Config.DefaultGarages = true

Config.ClearTimeBlip  = 1000 * 120 -- 2 mins

Config.TargetDistance = 10.0


Config.BlipDefault          = {
    sprite = 50,
    color = 1,
    size = 0.7,
    stackBlips = true,
    impound = 'Odtahovka', 
    garage = 'Garaz',
    custom = 'Garage',
    rent = 'Pronajmi si auto',
}

Config.PedAnims             = {
    anims = true,
    list = { "WORLD_HUMAN_AA_SMOKE", "WORLD_HUMAN_AA_COFFEE", "WORLD_HUMAN_CLIPBOARD" }
}

-- ox Target Based job and grade min grade
Config.TargetImpound        = {
    -- job     -- min grade
    ['police'] = 0,
    ['gruppe6'] = 0,
    ['gov'] = 0,

}
----------------------------------------------------------------------
-- on Vehicles delete or /dv
Config.ImpoundVehicledelete = true

-- Default impounds names
Config.DefaultImpound       = {
    car = 'Odtahovka',
    air = 'Air Odtahovka',
    boat = 'Boat Odtahovka',
    price = 250,
    note = 'Vaše vozidlo bylo odbaveno.'
}



Config.Notify = function(data)
    lib.notify({
        title = data.title,
        description = data.description,
        position = data.position or 'bottom-right',
        type = data.type or 'warning',
        icon = data.icon or 'car',
        duration = data.duration or 3500,
        showDuration = true,
    })
end


Config.Textui = {
    Showtext = function(text, ...)
        lib.showTextUI(text, ...)
    end,

    HideText = function()
        lib.hideTextUI()
    end
}
