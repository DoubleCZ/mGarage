Core = require 'framework'

local query = {
    ['esx'] = {
        queryStore1 = 'SELECT `owner`, `keys` FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1',
        queryStore2 =
        'UPDATE `owned_vehicles` SET `parking` = ?, `stored` = 1, `vehicle` = ?, type = ? WHERE `plate` = ? ',
        queryImpound =
        'UPDATE `owned_vehicles` SET `parking` = ?, `stored` = 0, `pound` = 1, `coords` = NULL, metadata = ? WHERE `plate` = ?',
        setImpound =
        'UPDATE `owned_vehicles` SET `parking` = ?, `stored` = 0, `pound` = 1, `coords` = NULL, `metadata` = ? WHERE TRIM(`plate`) = TRIM(?)',
    },
}


local Querys = query[Core.FrameWork]

lib.callback.register('mGarage:Interact', function(source, action, data, vehicle)
    local retval = nil
    local Player = Core:Player(source)

    local identifier = Player.identifier

    if action == 'get' then
        local vehicles = {}
        local PlyVehicles = Vehicles.GetAllPlayerVehicles(source, false, true)

        if PlyVehicles then
            lib.array.forEach(PlyVehicles, function(row)
                if (data.isShared or data.name == row.parking) then
                    row.isOwner = row.owner == identifier
                    if (data.garagetype == 'garage' and (not row.pound or row.pound == 0)) or data.garagetype == 'impound' then
                        if data.isShared or (type(data.carType) == 'table' and lib.table.contains(data.carType, row.type)) or data.carType == row.type then
                            table.insert(vehicles, row)
                        end
                    end
                end
            end)
        end

        retval = vehicles
    elseif action == 'spawn' then
        local coords = SpawnClearArea({ coords = data.garage.spawnpos, distance = 2.0, player = source })

        if not coords then
            Player.Notify({ title = data.name, description = locale('noSpawnPos'), type = 'error' })
            return false
        end

        Vehicles.SpawnVehicleId({ id = data.vehicleid, coords = coords, source = source, intocar = data.garage.intocar },
            function(vehicleData, Vehicle)
                if vehicleData and Vehicle then
                    Vehicles.ItemCarKeys(source, 'add', vehicleData.plate)
                    Vehicle.RetryVehicle()
                    retval = true
                else
                    retval = false
                end
            end)
    elseif action == 'saveCar' then
        local entity = NetworkGetEntityFromNetworkId(data.entity)
        local Vehicle = Vehicles.GetVehicle(entity)
        local VehicleType = GetVehicleType(entity)

        if type(data.carType) == 'table' then
            if not lib.table.contains(data.carType, VehicleType) then
                return false
            end
        elseif not data.carType == VehicleType then
            return false
        end

        if Vehicle then
            local metadata = Vehicle.GetMetadata()

            if metadata.customGarage then
                if Vehicles.Config.ItemKeys then
                    Vehicles.ItemCarKeys(source, 'delete', data.realplate)
                end

                return Vehicle.DeleteVehicle(false)
            end

            if type(Vehicle.keys) ~= 'table' then
                Vehicle.keys = json.decode(Vehicle.keys)
            end


            if data.job and (not data.job == Vehicle.job) then
                return false
            end

            if Vehicle.owner == identifier or Vehicle.keys and Vehicle.keys[identifier] then
                local left = LeftCar(entity, data.seats)

                if left then Citizen.Wait(1000) end

                Vehicles.ItemCarKeys(source, 'delete', data.realplate)

                Vehicle.StoreVehicle(data.name, data.props)

                return true
            else
                Player.Notify({
                    title = data.name,
                    description = locale('notYourVehicle'),
                    type = 'error',
                })
                return false
            end
        else
            data.plate = exports['mVehicle']:GetVehicleRealPlate(entity)

            local row = MySQL.single.await(Querys.queryStore1, { data.plate })

            if not row then
                Player.Notify({
                    title = data.name,
                    description = locale('notYourVehicle'),
                    type = 'error',
                })
                return false
            end

            if data.job then
                if not (data.job == row.job) then
                    return false
                end
            end

            if row and row.owner == identifier or row.keys and row.keys[identifier] then
                MySQL.update(Querys.queryStore2, { data.name, data.props, VehicleType, data.plate },
                    function(affectedRows)
                        if affectedRows then
                            if Vehicles.Config.ItemKeys then
                                Vehicles.ItemCarKeys(source, 'delete', data.plate)
                            end
                            DeleteEntity(entity)
                        end
                    end)
            else
                Player.Notify({
                    title = data.name,
                    description = locale('notYourVehicle'),
                    type = 'error',
                })
            end
        end
    elseif action == 'setimpound' then
        local composed = nil

        if data.hourEndPound and data.dateEndPound then
            local timestamphour = math.floor(data.hourEndPound / 1000)
            local hour = os.date('%H:%M', timestamphour)
            local timestamp = math.floor(data.dateEndPound / 1000)
            local date = os.date('%Y/%m/%d', timestamp)
            composed = ('%s %s'):format(date, hour)
        end
        local infoimpound = {
            reason = data.reason,
            price = data.price,
            impoundDate = os.date("%Y/%m/%d %H:%M:%S", os.time()),
            endPound = composed
        }

        local entity = NetworkGetEntityFromNetworkId(data.entity)
        local Vehicle = Vehicles.GetVehicle(entity)
        if Vehicle then
            Vehicle.ImpoundVehicle(data.garage, infoimpound.price, infoimpound.reason, infoimpound.impoundDate,
                infoimpound.endPound)
        else
            local plate = exports['mVehicle']:GetVehicleRealPlate(entity)
            local row = Vehicles.GetVehicleByPlate(plate, true)

            if row then
                local metadata = row.metadata
                if not metadata then
                    metadata = {}
                else
                    metadata = json.decode(metadata)
                end

                metadata.pound = infoimpound

                MySQL.update(Querys.queryImpound, { data.garage, json.encode(metadata), plate })

                DeleteEntity(entity)
            else
                DeleteEntity(entity)
            end
        end
    elseif action == 'impound' then
        local ImpVeh = Vehicles.GetVehicleByID(data.vehicleid)
        if ImpVeh then
            local metadata = json.decode(ImpVeh.metadata)
            local infoimpound = metadata.pound
            local PlayerMoney = Player.getMoney(data.paymentMethod)
            if infoimpound.endPound then
                local year, month, day, hour, min = infoimpound.endPound:match("(%d+)/(%d+)/(%d+) (%d+):(%d+)")

                if year and month and day and hour and min then
                    local endPoundDate = os.time({
                        year = year,
                        month = month,
                        day = day,
                        hour = hour,
                        min = min
                    })

                    local currentDate = os.time()
                    if currentDate < endPoundDate then
                        local timeDifference = endPoundDate - currentDate
                        local days = math.floor(timeDifference / (24 * 60 * 60))
                        local hours = math.floor((timeDifference % (24 * 60 * 60)) / (60 * 60))
                        local minutes = math.floor((timeDifference % (60 * 60)) / 60)

                        Player.Notify({
                            title = data.garage.name,
                            description = locale('ImpoundOption13', days, hours, minutes),
                            type = 'error',
                        })

                        return false
                    end
                end
            end


            if PlayerMoney.money >= infoimpound.price then
                ImpVeh.coords = SpawnClearArea({ coords = data.garage.spawnpos, distance = 2.0, player = source })

                if ImpVeh.coords and type(ImpVeh) == 'table' then
                    Player.RemoveMoney(data.paymentMethod, infoimpound.price)

                    Vehicles.CreateVehicle(ImpVeh, function(VehData, Vehicle)
                        if Vehicles.Config.ItemKeys then
                            Vehicles.ItemCarKeys(source, 'add', VehData.realplate)
                        end

                        Vehicle.RetryImpound(data.garage.defaultGarage)
                    end)


                    if data.garage.society then
                        Core:SetSotcietyMoney(data.garage.society, infoimpound.price)
                    end

                    Player.Notify({
                        title = data.garage.name,
                        description = locale('impound1', infoimpound.price),
                        type = 'success',
                    })
                    retval = true
                else
                    Player.Notify({
                        title = data.garage.name,
                        description = locale('noSpawnPos'),
                        type = 'warning',
                    })
                    retval = false
                end
            else
                Player.Notify({
                    title = data.garage.name,
                    description = locale('impound2'),
                    type = 'warning',
                })
                retval = false
            end
        end
    elseif action == 'changeimpound' then
        local ImpVeh = Vehicles.GetVehicleByPlate(data, true)
        if ImpVeh then
            local metadata = json.decode(ImpVeh.metadata)
            if metadata.pound then
                if metadata.pound.endPound then
                    metadata.pound.endPound = nil
                    MySQL.update('UPDATE owned_vehicles SET metadata = ? WHERE plate = ?',
                        { json.encode(metadata), data })
                    retval = true
                    Player.Notify({ title = 'Garage Unpound', description = locale('ImpoundOption11'), type = 'success', })
                else
                    Player.Notify({ title = 'Garage Unpound', description = locale('ImpoundOption8'), type = 'error' })
                    retval = false
                end
            else
                Player.Notify({ title = 'Garage Unpound', description = locale('ImpoundOption9'), type = 'error' })
                retval = false
            end
        else
            Player.Notify({
                title = 'Garage Unpound',
                description = locale('ImpoundOption10', data),
                type = 'error',
            })
            retval = false
        end
    elseif action == 'spawncustom' then
        local coords = SpawnClearArea({ coords = data.garage.spawnpos, distance = 2.0, player = source })

        if not coords then
            Player.Notify({ title = data.name, description = locale('noSpawnPos'), type = 'error' })
            return false
        end

        local plate = Vehicles.GeneratePlate()
        local platePrefix = data.garage.platePrefix

        if platePrefix and #platePrefix > 0 then
            if #platePrefix < 4 then
                platePrefix = string.format("%-4s", platePrefix)
            end
            plate = platePrefix:upper() .. string.sub(plate, 5)
        end

        Vehicles.CreateVehicle({
            vehicle  = { model = data.vehicle.model, plate = plate, fuelLevel = 100 },
            job      = (data.garage.job == false) and nil or data.garage.job,
            source   = source,
            intocar  = data.garage.intocar and source,
            owner    = identifier,
            keys     = { [identifier] = identifier },
            coords   = coords,
            metadata = { customGarage = data.garage.name },
        }, function(VehicleData, Vehicle)
            local keyPlate = data.vehicle.plate
            if data.vehicle.realplate then
                keyPlate = data.vehicle.realplate
            end
            Vehicles.ItemCarKeys(source, 'add', keyPlate)
        end)

        return true
    elseif action == 'saveCustomCar' then
        local entity = NetworkGetEntityFromNetworkId(data.entity)
        local Vehicle = Vehicles.GetVehicle(entity)
        if Vehicle then
            local metadata = Vehicle.GetMetadata('customGarage')
            local job = Player.GetJob()

            if metadata == data.name and Vehicle.owner == identifier or job.name == Vehicle.job then
                local left = LeftCar(entity, data.seats)

                if left then Citizen.Wait(2000) end

                Vehicle.DeleteVehicle(false)

                if Vehicles.Config.ItemKeys then
                    local keyPlate = data.vehicle.plate
                    if data.vehicle.realplate then
                        keyPlate = data.vehicle.realplate
                    end
                    Vehicles.ItemCarKeys(source, 'delete', keyPlate)
                end

                retval = true
            else
                retval = false
            end
        else
            retval = false
        end
    elseif action == 'spawnrent' then
        local coords = SpawnClearArea({ coords = data.garage.spawnpos, distance = 2.0, player = source })

        if not coords then
            Player.Notify({ title = data.name, description = locale('noSpawnPos'), type = 'error' })
            return false
        end

        local PlayerMoney = Player.getMoney(data.paymentMethod)

        if PlayerMoney.money >= tonumber(data.totalPrice) then
            local plate = Vehicles.GeneratePlate()


            if data.garage.platePrefix and #data.garage.platePrefix > 0 then
                if #data.garage.platePrefix < 4 then
                    data.garage.platePrefix = string.format("%-4s", data.garage.platePrefix)
                end
                plate = data.garage.platePrefix:upper() .. string.sub(plate, 5)
            end

            Player.RemoveMoney(data.paymentMethod, tonumber(data.totalPrice))

            Vehicles.CreateVehicle({
                vehicle   = { model = data.vehicle.model, plate = plate, fuelLevel = 100 },
                job       = (data.garage.job == false) and nil or data.garage.job,
                source    = source,
                intocar   = data.garage.intocar,
                owner     = identifier,
                coords    = coords,
                setOwner  = true,
                metadata  = { rent = true, rentName = data.garage.name },
                temporary = data.rentDate
            }, function(VehicleData, Vehicle)
                if Vehicles.Config.ItemKeys then
                    Vehicles.ItemCarKeys(source, 'add', VehicleData.plate)
                end
            end)
            retval = true
        else
            retval = false
        end
    elseif action == 'changeName' then
        local keyPlate = data.vehicle.plate
        if data.vehicle.realplate then
            keyPlate = data.vehicle.realplate
        end
        local Vehicle = Vehicles.GetVehicleByPlate(keyPlate)

        if Vehicle then
            Vehicle.setName(data.newName)
            retval = true
        else
            local keyPlate = data.vehicle.plate
            if data.vehicle.realplate then
                keyPlate = data.vehicle.realplate
            end
            local row = MySQL.single.await('SELECT `metadata` FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1', {
                keyPlate
            })
            if row then
                local metadata = json.decode(row.metadata)
                if not metadata then
                    metadata = {}
                end
                if metadata then
                    metadata.vehname = data.newName
                    local updatedMetadata = json.encode(metadata)
                    MySQL.update('UPDATE `owned_vehicles` SET `metadata` = ? WHERE `plate` = ?',
                        { updatedMetadata, keyPlate })
                    retval = true
                else
                    retval = false
                end
            else
                retval = false
            end
        end
    elseif action == 'cleanName' then
        local keyPlate = data.vehicle.plate
        if data.vehicle.realplate then
            keyPlate = data.vehicle.realplate
        end
        local Vehicle = Vehicles.GetVehicleByPlate(keyPlate)

        if Vehicle then
            vehicle.DeleteMetadata('vehname')
            retval = true
        else
            local row = Vehicles.GetVehicleByPlate(keyPlate, true)

            if row then
                local metadata = json.decode(row.metadata)

                if metadata then
                    metadata.vehname = nil
                    local updatedMetadata = json.encode(metadata)
                    MySQL.update('UPDATE `owned_vehicles` SET `metadata` = ? WHERE `plate` = ?',
                        { updatedMetadata, keyPlate })
                    retval = true
                else
                    retval = false
                end
            else
                retval = false
            end
        end
    end

    return retval
end)


-- Vehicle deleted? send to impound
AddEventHandler('entityRemoved', function(entity)
    if Config.ImpoundVehicledelete then
        local entityType = GetEntityType(entity)
        if entityType == 2 then
            if Vehicles.save() then return end

            local impound = GetDefaultImpound(GetVehicleType(entity))
            local plate = exports['mVehicle']:GetVehicleRealPlate(entity)
            local vehicle = Vehicles.GetVehicleByPlate(plate, true)

            if vehicle and vehicle.stored == 0 and not vehicle.pound then
                vehicle.metadata = json.decode(vehicle.metadata)

                if vehicle.metadata.RoutingBucket then return end

                vehicle.metadata.pound = {
                    price = Config.DefaultImpound.price,
                    reason = Config.DefaultImpound.note,
                    date = os.date("%Y/%m/%d %H:%M"),
                }

                MySQL.update(Querys.setImpound, { impound, json.encode(vehicle.metadata), plate })

                Vehicles.DeleteFromTable(entity)
            end
        end
    end
end)

function LeftCar(entity, seats)
    local players = 0
    local playerLeft = false
    local startTime = GetGameTimer()

    repeat
        for i = -1, seats do
            local ped = GetPedInVehicleSeat(entity, i)

            if ped and DoesEntityExist(ped) then
                TaskLeaveVehicle(ped, entity, 0)
                players = players + 1
                playerLeft = true
            end
        end

        Citizen.Wait(100)

        if GetGameTimer() - startTime > 10000 then
            break
        end
    until players >= seats or players == 0

    return playerLeft
end

function SpawnClearArea(data)
    local player = GetPlayerPed(data.player)
    local playerpos = GetEntityCoords(player)
    local selectedCoords = nil

    if #data.coords == 1 then
        local v = data.coords[1]
        return vec4(v.x, v.y, v.z, v.w)
    end

    for attempt = 1, #data.coords do
        for _, v in ipairs(data.coords) do
            local spawnPos = vector3(v.x, v.y, v.z)
            local distanceToPlayer = #(playerpos - spawnPos)

            if distanceToPlayer < (selectedCoords and #(playerpos - vector3(selectedCoords.x, selectedCoords.y, selectedCoords.z)) or math.huge) then
                local clearOfVehicles = true
                for _, vehicle in pairs(GetAllVehicles()) do
                    if #(spawnPos - GetEntityCoords(vehicle)) <= data.distance then
                        clearOfVehicles = false
                        break
                    end
                end

                if clearOfVehicles and distanceToPlayer > data.distance then
                    selectedCoords = vec4(v.x, v.y, v.z, v.w)
                end
            end
        end

        if selectedCoords then break end
    end

    return selectedCoords or false
end

local VehicleTypes = {
    ['car'] = { 'automobile', 'bicycle', 'bike', 'quadbike', 'trailer', 'amphibious_quadbike', 'amphibious_automobile' },
    ['boat'] = { 'submarine', 'submarinecar', 'boat' },
    ['air'] = { 'blimp', 'heli', 'plane' },
}

function GetDefaultImpound(type)
    for vehicleType, types in pairs(VehicleTypes) do
        for _, v in ipairs(types) do
            if v == type or type == vehicleType then
                return Config.DefaultImpound[vehicleType]
            end
        end
    end
end
