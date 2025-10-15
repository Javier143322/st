-- server/server.lua (CÓDIGO COMPLETO FINAL - Reputación, Heat, Alerta de Invasión y Estados NPC)

local ESX = nil

TriggerEvent('esx:getExtendedServer', function(obj) ESX = obj end)

-- [GLOBALES DEL SERVIDOR]
local PlayerReputation = {} 
local LocalHeatTracker = {}
local ZoneAlertCooldown = {} -- { ['NombreZona'] = timestamp_expiracion, ... }

-- Eventos de conexión/desconexión para inicializar la reputación
AddEventHandler('esx:playerLoaded', function(source)
    PlayerReputation[source] = 0 -- Inicializar reputación
end)

AddEventHandler('playerDropped', function(source)
    PlayerReputation[source] = nil -- Eliminar reputación al desconectar
end)


-- [[ GESTIÓN DE LA REPUTACIÓN ]]

local function GetPlayerReputation(source)
    return PlayerReputation[source] or 0
end

local function AddReputation(source, amount)
    local currentRep = GetPlayerReputation(source)
    local newRep = currentRep + amount

    if newRep > Config.Reputacion.MaxReputacion then
        newRep = Config.Reputacion.MaxReputacion
    end

    PlayerReputation[source] = newRep
    
    TriggerClientEvent('esx:showNotification', source, 'Has ganado ' .. amount .. ' puntos de Reputación Criminal. Total: ' .. newRep)
end


-- [[ GESTIÓN DEL HEAT LOCAL ]]

local function CalculateAreaHeat(coords)
    local activeSales = 0
    local currentTime = os.time()

    for i = #LocalHeatTracker, 1, -1 do
        local sale = LocalHeatTracker[i]
        
        if currentTime - sale.timestamp < Config.Heat.HeatDurationSeconds then
            local distance = #(coords - sale.coords)
            if distance <= Config.Heat.HeatRadius then
                activeSales = activeSales + 1
            end
        else
            table.remove(LocalHeatTracker, i)
        end
    end

    if activeSales >= Config.Heat.SalesToTriggerHeat then
        local extraSales = activeSales - Config.Heat.SalesToTriggerHeat
        local maxIncrease = Config.Heat.MaxHeatRiskIncrease
        local increasePerSale = maxIncrease / 10

        local finalIncrease = extraSales * increasePerSale
        if finalIncrease > maxIncrease then
            finalIncrease = maxIncrease
        end

        return finalIncrease, activeSales 
    end

    return 0, 0
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(120000) 
        local currentTime = os.time()
        for i = #LocalHeatTracker, 1, -1 do
            if currentTime - LocalHeatTracker[i].timestamp >= Config.Heat.HeatDurationSeconds then
                table.remove(LocalHeatTracker, i)
            end
        end
    end
end)


-- [[ LÓGICA DE ALERTA DE INVASIÓN (NUEVA FUNCIÓN) ]]

local function SendInvasionAlert(zoneLabel, ownerJob)
    local currentTime = os.time()

    -- 1. Verificar Cooldown
    if ZoneAlertCooldown[zoneLabel] and ZoneAlertCooldown[zoneLabel] > currentTime then
        return 
    end
    
    -- 2. Establecer el Cooldown
    ZoneAlertCooldown[zoneLabel] = currentTime + Config.AlertaInvasion.CoolDownTime

    -- 3. Enviar notificación a todos los jugadores con el trabajo 'ownerJob'
    local message = 'Se ha detectado una alta actividad de venta de drogas en ' .. zoneLabel .. '. ¡Revisa tu territorio!'
    
    for id, player in pairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(id)
        
        if xPlayer and xPlayer.job.name == ownerJob then
            TriggerClientEvent('esx:showNotification', id, message, Config.AlertaInvasion.JobAlertColor) 
        end
    end
end


-- [[ LÓGICA PRINCIPAL DEL SERVIDOR: PROCESAR VENTA ]]

ESX.RegisterServerCallback('streetdealer:server:getDrogasJugador', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerDrogas = {}
    for drugName, config in pairs(Config.Drogas) do
        local item = xPlayer.getInventoryItem(drugName)
        if item and item.count > 0 then
            playerDrogas[drugName] = item.count
        end
    end
    cb(playerDrogas)
end)

RegisterNetEvent('streetdealer:server:procesarVenta', function(drugName, npcId, zoneName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local drugConfig = Config.Drogas[drugName]
    local amount = 1 

    if not drugConfig then return end

    local item = xPlayer.getInventoryItem(drugName)
    if not item or item.count < amount then
        TriggerClientEvent('esx:showNotification', source, 'No tienes ' .. drugConfig.label .. ' suficiente.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId, 0) -- Estado 0
        return
    end

    local npcCoords = GetEntityCoords(npcId) 

    -- CÁLCULO DE RIESGO
    local playerRep = GetPlayerReputation(source)
    local reduction = (playerRep / Config.Reputacion.PuntosParaMaximaReduccion) * Config.Reputacion.MaxReduccionPorc
    if reduction > Config.Reputacion.MaxReduccionPorc then reduction = Config.Reputacion.MaxReduccionPorc end
    
    local heatIncrease, activeSales = CalculateAreaHeat(npcCoords)
    
    local finalPoliceChance = math.max(1, Config.Riesgo.ProbabilidadPolisBase - reduction + heatIncrease)
    local probCorrerAjustada = math.max(3, Config.Riesgo.ProbabilidadCorrerBase - reduction * 2) 
    
    local isCop = (math.random(1, 100) <= finalPoliceChance)
    local isScared = (math.random(1, 100) <= probCorrerAjustada)

    -- CÁLCULO DE PRECIO
    local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
    local priceMultiplier = zoneConfig.multiplier
    local finalPrice = math.floor(math.random(drugConfig.minPrice, drugConfig.maxPrice) * priceMultiplier) 

    -- EJECUCIÓN DEL RESULTADO
    if isCop then
        TriggerClientEvent('esx:showNotification', source, '¡El comprador era un policía encubierto! ¡CORRE! (Riesgo: ' .. math.floor(finalPoliceChance) .. '%)', 'error')
        TriggerEvent('esx_policejob:server:createGangsterAlert', npcCoords)
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId, 2) -- Estado 2: Policía (Ataca/Persigue)
        
    elseif isScared then
        TriggerClientEvent('esx:showNotification', source, 'El NPC se asustó y salió corriendo. Venta fallida. (Riesgo: ' .. math.floor(probCorrerAjustada) .. '%)', 'warning')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId, 1) -- Estado 1: Asustado (Huye)
        
    else
        -- Éxito
        local sellPrice = finalPrice 

        xPlayer.removeInventoryItem(drugName, amount)
        xPlayer.addMoney(sellPrice)
        AddReputation(source, Config.Reputacion.PuntosPorVentaExitosa)
        
        -- AGREGAR VENTA A HEAT Y VERIFICAR ALERTA DE INVASIÓN
        table.insert(LocalHeatTracker, { coords = npcCoords, timestamp = os.time() })
        
        if activeSales >= Config.AlertaInvasion.HeatThreshold and zoneConfig.ownerJob ~= 'none' then
            SendInvasionAlert(zoneConfig.label, zoneConfig.ownerJob)
        end
        
        local heatMsg = ""
        if activeSales > 0 then
            heatMsg = " (Área Caliente: " .. activeSales .. " ventas cercanas)"
        end
        
        TriggerClientEvent('esx:showNotification', source, 'Venta exitosa en ' .. zoneConfig.label .. '. Ganaste $' .. sellPrice .. '.' .. heatMsg)
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcId, 0) -- Estado 0: Vuelve a vagabundear
    end
end)
