-- fxmanifest.lua (VERSIÓN MEJORADA)
fx_version 'cerulean'
game 'gta5'

name 'esx_streetdealer'
author 'TuNombre'
description 'Sistema avanzado de venta de drogas con reputación, habilidades y mercado dinámico'
version '2.0.0'

-- DEPENDENCIAS
dependencies {
    'es_extended'
}

-- CONFIGURACIÓN COMPARTIDA
shared_scripts {
    '@es_extended/locale.lua',
    'config.lua'
}

-- SCRIPTS DEL CLIENTE
client_scripts {
    'client.lua'
}

-- SCRIPTS DEL SERVIDOR
server_scripts {
    'server.lua'
}

-- COMPATIBILIDAD
lua54 'yes'

-- METADATOS
description [[
Sistema de venta de drogas mejorado con:
✅ Sistema de reputación y habilidades
✅ Mercado negro dinámico
✅ Alertas a pandillas y médicos
✅ Optimización de rendimiento
✅ Detección inteligente de NPCs
✅ Heat system y riesgo dinámico
]]