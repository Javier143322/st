-- config.lua (CÓDIGO COMPLETO FINAL - Zonas, Drogas, Riesgo, Reputación, Heat, Alerta)

Config = {}

-- [[ Zonas y Multiplicadores de Precios y Dueños ]]
-- ownerJob: El nombre del job que será alertado de actividad en su zona. 'none' si no tiene dueño.
-- EJEMPLO: Asegúrate de que 'bloods', 'gang_a', 'gang_b' coincidan con los job.name reales de tu servidor.
Config.ZonasDeVenta = {
    -- ZONAS DE ALTO VALOR (Sin dueño por defecto)
    ['VINEYARD'] = { multiplier = 1.35, label = 'Vinewood Hills', ownerJob = 'none' },
    ['ROCKFORD'] = { multiplier = 1.25, label = 'Rockford Hills', ownerJob = 'none' },
    ['DOWNTOWN'] = { multiplier = 1.15, label = 'Downtown Los Santos', ownerJob = 'none' },
    
    -- ZONAS DE BAJO VALOR (Controladas por pandillas)
    ['RANCHO']   = { multiplier = 0.85, label = 'Rancho', ownerJob = 'bloods' }, -- ¡REVISA EL JOB NAME!
    ['DAVIS']    = { multiplier = 0.80, label = 'Davis', ownerJob = 'gang_a' },    -- ¡REVISA EL JOB NAME!
    ['GROVE']    = { multiplier = 0.70, label = 'Grove Street Area', ownerJob = 'gang_b' }, -- ¡REVISA EL JOB NAME!

    -- ZONAS NEUTRAS O POR DEFECTO
    ['VESPUCCI'] = { multiplier = 1.00, label = 'Vespucci Beach', ownerJob = 'none' },
    ['CHILAD']   = { multiplier = 1.00, label = 'Chiliad Mountain', ownerJob = 'none' },
    ['DELPERRO'] = { multiplier = 1.10, label = 'Del Perro', ownerJob = 'none' },
    ['DEFAULT'] = { multiplier = 0.90, label = 'Zona Desconocida/Normal', ownerJob = 'none' },
}

-- [[ Configuracion de Drogas ]]
Config.Drogas = {
    ['weed'] = {
        label = 'Marihuana',
        minPrice = 10,
        maxPrice = 25,
    },
    ['cocaine'] = {
        label = 'Cocaína',
        minPrice = 150,
        maxPrice = 250,
    },
    ['meth'] = {
        label = 'Metanfetamina',
        minPrice = 100,
        maxPrice = 180,
    }
}

-- [[ Configuracion de Riesgos BASE y Reputación ]]
Config.Riesgo = {
    rangoDeteccion = 3.0,  
    
    ProbabilidadPolisBase = 5,   -- 5% BASE de que un NPC sea policía encubierto
    ProbabilidadCorrerBase = 15, -- 15% BASE de que el NPC se asuste y corra
    
    TiempoAnimacion = 3000,      -- 3 segundos para la animación del trato
}

Config.Reputacion = {
    MaxReputacion = 1000,
    PuntosPorVentaExitosa = 5,
    MaxReduccionPorc = 4,           -- Máxima reducción de riesgo por reputación (4%)
    PuntosParaMaximaReduccion = 500
}

-- [[ CONFIGURACIÓN: HEAT LOCAL (Riesgo en el Área) ]]
Config.Heat = {
    HeatRadius = 50.0,             -- Radio (en metros) para buscar ventas recientes.
    SalesToTriggerHeat = 3,        -- Número de ventas en el radio para que el Heat empiece a sumar riesgo.
    MaxHeatRiskIncrease = 10,      -- Máximo porcentaje que el Heat local puede añadir al riesgo de policía (10%).
    HeatDurationSeconds = 300,     -- Cuánto tiempo (en segundos, 5 minutos) una venta cuenta para el Heat.
}

-- [[ NUEVA CONFIGURACIÓN: ALERTA DE INVASIÓN ]]
Config.AlertaInvasion = {
    HeatThreshold = 5,             -- Cuántas ventas recientes (activeSales) se necesitan para disparar la alerta.
    JobAlertColor = 'error',       -- Color de la notificación para la pandilla dueña.
    CoolDownTime = 120,            -- Tiempo de espera (en segundos) entre alertas para una misma zona.
}
