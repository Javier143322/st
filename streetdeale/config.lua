-- config.lua (CÓDIGO COMPLETO FINAL con FILTRO DE MODELOS NPC)

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
    ['RANCHO']   = { multiplier = 0.85, label = 'Rancho', ownerJob = 'bloods' }, 
    ['DAVIS']    = { multiplier = 0.80, label = 'Davis', ownerJob = 'gang_a' },    
    ['GROVE']    = { multiplier = 0.70, label = 'Grove Street Area', ownerJob = 'gang_b' },  

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
    
    ProbabilidadPolisBase = 5,   
    ProbabilidadCorrerBase = 15, 
    
    TiempoAnimacion = 3000,      
}

Config.Reputacion = {
    MaxReputacion = 1000,
    PuntosPorVentaExitosa = 5,
    MaxReduccionPorc = 4,           
    PuntosParaMaximaReduccion = 500
}

-- [[ CONFIGURACIÓN: HEAT LOCAL (Riesgo en el Área) ]]
Config.Heat = {
    HeatRadius = 50.0,             
    SalesToTriggerHeat = 3,        
    MaxHeatRiskIncrease = 10,      
    HeatDurationSeconds = 300,     
}

-- [[ CONFIGURACIÓN: ALERTA DE INVASIÓN ]]
Config.AlertaInvasion = {
    HeatThreshold = 5,             
    JobAlertColor = 'error',       
    CoolDownTime = 120,            
}

-- [[ NUEVA CONFIGURACIÓN: FILTRO DE MODELOS DE NPC ]]

Config.ModelosNPC = {
    -- Si 'Whitelist' es TRUE, solo los modelos listados pueden comprar.
    -- Si 'Whitelist' es FALSE, CUALQUIER modelo PUEDE comprar EXCEPTO los listados.
    Whitelist = true, 
    
    -- Lista de modelos de NPC permitidos (ejemplos de civiles genéricos y algo rudos)
    AllowedModels = {
        -- Civiles Comunes (M y F)
        'a_m_m_hillbilly_01', 'a_f_m_beach_01', 'a_m_m_bevhills_02',
        -- Gente de barrios bajos o trabajadores
        'g_m_y_famfor_01', 'g_m_y_famdnf_01', 'a_m_m_tramp_01',
        -- Más genéricos
        'csb_car3guy1', 'csb_chef', 's_m_m_autoshop_01',
        -- Puedes añadir más nombres de modelos aquí
    },

    -- Modelos a EXCLUIR SI Whitelist es FALSE (Ejemplo de Policía/Militar/Gente de Negocios)
    -- Si Whitelist es TRUE, esta lista se ignora.
    ExcludedModels = {
        's_m_y_cop_01', 's_m_y_hwaycop_01', 's_f_y_hooker_01', 'a_m_m_business_01',
    }
}
