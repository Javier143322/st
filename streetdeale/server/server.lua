-- server/server.lua (VERSIÓN MEJORADA Y OPTIMIZADA)
local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- [SISTEMA DE DATOS MEJORADO]
local PlayerData = {
    Reputation = {},
    Skills = {},
    SalesHistory = {}
}

local HeatSystem = {
    LocalTracker = {},
    GlobalSales = 0,
    MarketPrices = {},
    LastPriceUpdate = 0
}

local AlertSystem = {
    ZoneCooldowns = {},
    MedicCooldown = 0,
    LastCleanup = os.time()
}

-- [INICIALIZACIÓN DEL SISTEMA]
Citizen.CreateThread(function()
    InitializeMarketPrices()
    StartCleanupThread()
    print('[STREETDEALER] Servidor mejorado inicializado')
end)

function InitializeMarketPrices()
    for drugName, config in pairs(Config.Drogas) do
        local basePrice = (config.minPrice + config.maxPrice) / 2
        HeatSystem.MarketPrices[drugName] = {
            base = basePrice,
            current = basePrice,
            demand = 1.0,
            lastUpdate = os.time()
        }
    end
end

function StartCleanupThread()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Cada 1 minuto
            CleanupOldData()
            UpdateMarketPrices()
        end
    end)
end

-- [SISTEMA DE REPUTACIÓN Y HABILIDADES MEJORADO]
function GetPlayerReputation(source)
    return PlayerData.Reputation[source] or 0
end

function AddReputation(source, amount)
    local currentRep = GetPlayerReputation(source)
    local newRep = math.min(currentRep + amount, 1000)
    PlayerData.Reputation[source] = newRep
    
    -- Verificar desbloqueo de habilidades
    CheckSkillUnlocks(source, newRep)
    
    TriggerClientEvent('esx:showNotification', source, 
        '📈 +' .. amount .. ' Reputación Criminal. Total: ' .. newRep)
end

function GetPlayerSkill(source, skillName)
    local skills = PlayerData.Skills[source] or {}
    return skills[skillName] or 0
end

function AddSkillPoints(source, skillName, points)
    if not PlayerData.Skills[source] then
        PlayerData.Skills[source] = {}
    end
    
    local currentLevel = PlayerData.Skills[source][skillName] or 0
    local maxLevel = Config.Habilidades[skillName].maxLevel
    local newLevel = math.min(currentLevel + points, maxLevel)
    
    PlayerData.Skills[source][skillName] = newLevel
    
    if newLevel > currentLevel then
        TriggerClientEvent('esx:showNotification', source, 
            '🎯 ' .. Config.Habilidades[skillName].label .. ' subió al nivel ' .. newLevel)
    end
end

function CheckSkillUnlocks(source, reputation)
    if reputation >= 100 and GetPlayerSkill(source, 'persuasion') == 0 then
        AddSkillPoints(source, 'persuasion', 1)
    end
    if reputation >= 250 and GetPlayerSkill(source, 'stealth') == 0 then
        AddSkillPoints(source, 'stealth', 1)
    end
    if reputation >= 500 and GetPlayerSkill(source, 'networking') == 0 then
        AddSkillPoints(source, 'networking', 1)
    end
end

-- [SISTEMA DE HEAT Y MERCADO OPTIMIZADO]
function CalculateAreaHeat(coords)
    local activeSales = 0
    local currentTime = os.time()
    
    -- Limpieza y conteo optimizado
    for i = #HeatSystem.LocalTracker, 1, -1 do
        local sale = HeatSystem.LocalTracker[i]
        if currentTime - sale.timestamp >= 300 then -- 5 minutos
            table.remove(HeatSystem.LocalTracker, i)
            HeatSystem.GlobalSales = math.max(0, HeatSystem.GlobalSales - 1)
        else
            local distance = #(coords - sale.coords)
            if distance <= 50.0 then
                activeSales = activeSales + 1
            end
        end
    end

    -- Calcular heat local
    local heatIncrease = 0
    if activeSales >= 3 then
        local extraSales = math.min(activeSales - 3, 10)
        heatIncrease = (extraSales * 10) / 10 -- Máximo 10% de aumento
    end

    return heatIncrease, activeSales, HeatSystem.GlobalSales
end

function UpdateMarketPrices()
    local currentTime = os.time()
    if currentTime - HeatSystem.LastPriceUpdate < Config.MercadoNegro.updateInterval then
        return
    end
    
    HeatSystem.LastPriceUpdate = currentTime
    
    for drugName, priceData in pairs(HeatSystem.MarketPrices) do
        -- Fluctuación basada en oferta/demanda
        local fluctuation = (math.random() * 2 - 1) * Config.MercadoNegro.priceFluctuation
        local demandEffect = (priceData.demand - 1.0) * Config.MercadoNegro.demandEffect
        
        local newPrice = priceData.base * (1 + fluctuation + demandEffect)
        local minPrice = Config.Drogas[drugName].minPrice
        local maxPrice = Config.Drogas[drugName].maxPrice
        
        HeatSystem.MarketPrices[drugName].current = math.max(minPrice, math.min(maxPrice, newPrice))
        
        -- Ajustar demanda basada en ventas recientes
        if HeatSystem.GlobalSales > 15 then
            priceData.demand = math.min(2.0, priceData.demand + 0.1)
        elseif HeatSystem.GlobalSales < 5 then
            priceData.demand = math.max(0.5, priceData.demand - 0.1)
        end
    end
end

function CleanupOldData()
    local currentTime = os.time()
    local removedCount = 0
    
    -- Limpiar LocalTracker
    for i = #HeatSystem.LocalTracker, 1, -1 do
        if currentTime - HeatSystem.LocalTracker[i].timestamp >= 300 then
            table.remove(HeatSystem.LocalTracker, i)
            removedCount = removedCount + 1
        end
    end
    
    HeatSystem.GlobalSales = math.max(0, HeatSystem.GlobalSales - removedCount)
    
    -- Limpiar cooldowns viejos
    for zoneName, cooldown in pairs(AlertSystem.ZoneCooldowns) do
        if currentTime > cooldown then
            AlertSystem.ZoneCooldowns[zoneName] = nil
        end
    end
    
    if removedCount > 0 and Config.Debug then
        print('[HEAT SYSTEM] Limpiadas ' .. removedCount .. ' ventas antiguas')
    end
end

-- [SISTEMA DE ALERTAS MEJORADO]
function SendJobAlert(message, jobName, alertType)
    local players = ESX.GetPlayers()
    for i = 1, #players do
        local xPlayer = ESX.GetPlayerFromId(players[i])
        if xPlayer and xPlayer.job.name == jobName then
            TriggerClientEvent('esx:showNotification', players[i], message, alertType)
            
            -- Log para administradores
            if Config.Debug then
                print('[ALERTA] Enviada a ' .. jobName .. ': ' .. message)
            end
        end
    end
end

function SendInvasionAlert(zoneLabel, ownerJob)
    local currentTime = os.time()
    if AlertSystem.ZoneCooldowns[zoneLabel] and AlertSystem.ZoneCooldowns[zoneLabel] > currentTime then
        return 
    end
    
    AlertSystem.ZoneCooldowns[zoneLabel] = currentTime + Config.AlertaInvasion.CoolDownTime
    
    local message = '🚨 Alta actividad de drogas en ' .. zoneLabel .. ' - ¡Revisa tu territorio!'
    SendJobAlert(message, ownerJob, Config.AlertaInvasion.JobAlertColor)
    
    if Config.Debug then
        print('[INVASIÓN] Alerta enviada para ' .. zoneLabel .. ' - Job: ' .. ownerJob)
    end
end

function SendMedicAlert(globalSales)
    local currentTime = os.time()
    if AlertSystem.MedicCooldown > currentTime then
        return
    end

    if globalSales >= Config.AlertaMedicos.GlobalSaleThreshold then
        AlertSystem.MedicCooldown = currentTime + Config.AlertaMedicos.CoolDownTime
        
        local message = '🏥 Alerta de salud pública: ' .. globalSales .. ' ventas de drogas activas en la ciudad'
        SendJobAlert(message, Config.AlertaMedicos.MedicJobName, Config.AlertaMedicos.AlertColor)
        
        if Config.Debug then
            print('[ALERTA MÉDICOS] Activada con ' .. globalSales .. ' ventas globales')
        end
    end
end

-- [CALLBACKS Y EVENTOS PRINCIPALES]
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

RegisterNetEvent('streetdealer:server:procesarVenta', function(drugName, npcNetId, zoneName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or not drugName then
        print('[ERROR] Venta inválida - Source: ' .. tostring(source) .. ' Drug: ' .. tostring(drugName))
        return
    end

    local drugConfig = Config.Drogas[drugName]
    if not drugConfig then
        TriggerClientEvent('esx:showNotification', source, '❌ Droga no válida')
        return
    end

    -- Verificar inventario
    local item = xPlayer.getInventoryItem(drugName)
    if not item or item.count < 1 then
        TriggerClientEvent('esx:showNotification', source, '❌ No tienes ' .. drugConfig.label .. ' suficiente.')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcNetId, 0)
        return
    end

    -- Obtener coordenadas del NPC
    local npcEntity = NetworkGetEntityFromNetworkId(npcNetId)
    if not DoesEntityExist(npcEntity) then
        TriggerClientEvent('esx:showNotification', source, '❌ Cliente no disponible')
        return
    end

    local npcCoords = GetEntityCoords(npcEntity)

    -- CÁLCULO DE RIESGO CON HABILIDADES
    local playerRep = GetPlayerReputation(source)
    local reduction = math.min(
        (playerRep / 500) * 4, -- Máximo 4% de reducción
        4
    )
    
    -- Aplicar habilidades
    local persuasionLevel = GetPlayerSkill(source, 'persuasion')
    local stealthLevel = GetPlayerSkill(source, 'stealth')
    
    local persuasionBonus = Config.Habilidades.persuasion.effect(persuasionLevel)
    local stealthBonus = Config.Habilidades.stealth.effect(stealthLevel)
    
    local heatIncrease, activeSales, globalActiveSales = CalculateAreaHeat(npcCoords)
    local finalPoliceChance = math.max(1, Config.Riesgo.ProbabilidadPolisBase - reduction + heatIncrease - (stealthLevel * 3))
    local probCorrerAjustada = math.max(3, Config.Riesgo.ProbabilidadCorrerBase - reduction * 2)

    -- DETERMINAR RESULTADO
    local isCop = (math.random(1, 100) <= finalPoliceChance)
    local isScared = (math.random(1, 100) <= probCorrerAjustada)

    -- CÁLCULO DE PRECIO CON HABILIDADES Y MERCADO
    local zoneConfig = Config.ZonasDeVenta[zoneName] or Config.ZonasDeVenta['DEFAULT']
    local marketPrice = HeatSystem.MarketPrices[drugName].current
    local basePrice = math.random(drugConfig.minPrice, drugConfig.maxPrice)
    local finalPrice = math.floor(basePrice * zoneConfig.multiplier * persuasionBonus)

    -- EJECUCIÓN DEL RESULTADO
    if isCop then
        -- Policía encubierto
        TriggerClientEvent('esx:showNotification', source, 
            '👮 ¡Era un policía! Riesgo: ' .. math.floor(finalPoliceChance) .. '%', 'error')
        
        -- Crear alerta policial
        TriggerEvent('esx_policejob:message', source, 'Venta de drogas en ' .. zoneConfig.label, npcCoords, true)
        
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcNetId, 2)
        
    elseif isScared then
        -- NPC asustado
        TriggerClientEvent('esx:showNotification', source, 
            '🏃 El cliente se asustó. Riesgo: ' .. math.floor(probCorrerAjustada) .. '%', 'warning')
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcNetId, 1)
        
    else
        -- VENTA EXITOSA
        xPlayer.removeInventoryItem(drugName, 1)
        xPlayer.addMoney(finalPrice)
        
        -- Sistema de reputación y habilidades
        AddReputation(source, Config.Reputacion.PuntosPorVentaExitosa)
        AddSkillPoints(source, 'persuasion', 0.1) -- Puntos decimales para progresión gradual
        AddSkillPoints(source, 'stealth', 0.05)

        -- REGISTRAR EN SISTEMA DE HEAT
        table.insert(HeatSystem.LocalTracker, { 
            coords = npcCoords, 
            timestamp = os.time(),
            drugType = drugName,
            zone = zoneName
        })
        HeatSystem.GlobalSales = HeatSystem.GlobalSales + 1

        -- ACTUALIZAR DEMANDA DEL MERCADO
        HeatSystem.MarketPrices[drugName].demand = math.min(2.0, 
            HeatSystem.MarketPrices[drugName].demand + 0.05)

        -- VERIFICAR ALERTAS
        if activeSales >= Config.AlertaInvasion.HeatThreshold and zoneConfig.ownerJob ~= 'none' then
            SendInvasionAlert(zoneConfig.label, zoneConfig.ownerJob)
        end
        
        SendMedicAlert(globalActiveSales + 1)

        -- NOTIFICACIÓN DE ÉXITO
        local heatMsg = activeSales > 0 and " (🔥 Zona Caliente)" or ""
        local skillMsg = persuasionLevel > 0 and " (+" .. math.floor((persuasionBonus - 1) * 100) .. "% Habilidad)" or ""
        
        TriggerClientEvent('esx:showNotification', source, 
            '💵 Vendiste ' .. drugConfig.label .. ' por $' .. finalPrice .. heatMsg .. skillMsg)
        TriggerClientEvent('streetdealer:client:resetNPC', source, npcNetId, 0)
        
        -- Registrar en historial
        if not PlayerData.SalesHistory[source] then
            PlayerData.SalesHistory[source] = {}
        end
        table.insert(PlayerData.SalesHistory[source], {
            drug = drugName,
            price = finalPrice,
            zone = zoneName,
            timestamp = os.time()
        })
    end
end)

-- [COMANDOS DE ADMINISTRACIÓN]
RegisterCommand('dealerstats', function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, 'streetdealer.admin') then
        print('=== STREETDEALER STATS ===')
        print('Ventas globales activas: ' .. HeatSystem.GlobalSales)
        print('Jugadores con reputación: ' .. GetTableLength(PlayerData.Reputation))
        print('Precios de mercado:')
        for drugName, priceData in pairs(HeatSystem.MarketPrices) do
            print('  ' .. drugName .. ': $' .. math.floor(priceData.current) .. ' (Demanda: ' .. string.format('%.2f', priceData.demand) .. ')')
        end
        print('========================')
    end
end)

-- [EVENTOS DE CONEXIÓN]
AddEventHandler('esx:playerLoaded', function(source)
    PlayerData.Reputation[source] = 0
    PlayerData.Skills[source] = {}
    
    -- Enviar datos iniciales al cliente
    local initialData = {
        reputation = 0,
        skills = {}
    }
    TriggerClientEvent('streetdealer:client:updatePlayerData', source, initialData)
end)

AddEventHandler('playerDropped', function(source)
    PlayerData.Reputation[source] = nil
    PlayerData.Skills[source] = nil
    PlayerData.SalesHistory[source] = nil
end)

-- [FUNCIONES AUXILIARES]
function GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

print('[STREETDEALER] Servidor mejorado completamente cargado')