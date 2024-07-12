fx_version 'cerulean'
game 'gta5'

author 'Luna & jaysixty'
description 'Truck Robbery'
version '1.0.0'

shared_scripts {
  '@qb-core/shared/locale.lua',
  'locales/en.lua',
  'locales/*.lua',
  'shared/config.lua',
}

server_scripts {
  'server/*.lua',
}

client_scripts {
  'client/*.lua',
  '@PolyZone/client.lua',
  '@PolyZone/BoxZone.lua',
  '@PolyZone/ComboZone.lua',
}


lua54 'yes'
