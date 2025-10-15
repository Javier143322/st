-- config.lua (COMPLETO Y ACTUALIZADO con Reputación y Heat Local)

Config = {}

-- [[ Zonas y Multiplicadores de Precios ]]
-- Multiplicadores: 1.0 = Precio base (sin cambio), > 1.0 = Más caro, < 1.0 = Más barato

Config.ZonasDeVenta = {
    -- ZONAS DE ALTO VALOR
    ['VINEYARD'] = { multiplier = 1.35, label = 'Vinewood Hills' },
    ['ROCKFORD'] = { multiplier = 1.25, label = 'Rockford Hills' },
    ['DOWNTOWN'] = { multiplier = 1.15, label = 'Downtown Los Santos' },
    ['DELPERRO'] = { multiplier = 1.10, label = 'Del Perro' },

    -- ZONAS DE VALOR MEDIO
    ['VESPUCCI'] = { multiplier = 1.00, label = 'Vespucci Beach' },
    ['CHILAD']   = { multiplier = 1.00, label = 'Chiliad Mountain' },

    -- ZONAS DE BAJO VALOR
    ['RANCHO']   = { multiplier = 0.85, label = 'Rancho' },
    ['DAVIS']    = { multiplier = 0.80, label = 'Davis' },
    ['GROVE']    { multiplier = 0.70, label = 'Grove Street Area' },

    -- Valor por defecto
    ['DEFAULT'] = { multiplier = 0.90, label = 'Zona Desconocida/Normal' },
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
    
    -- Probabilidades BASE (para reputación 0)
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

-- [[ NUEVA CONFIGURACIÓN: HEAT LOCAL (Riesgo en el Área) ]]
Config.Heat = {
    HeatRadius = 50.0,             -- Radio (en metros) para buscar ventas recientes.
    SalesToTriggerHeat = 3,        -- Número de ventas en el radio para que el Heat empiece a sumar riesgo.
    MaxHeatRiskIncrease = 10,      -- Máximo porcentaje que el Heat local puede añadir al riesgo de policía (10%).
    HeatDurationSeconds = 300,     -- Cuánto tiempo (en segundos, 5 minutos) una venta cuenta para el Heat.
}

