fx_version 'cerulean'
game 'gta5'

author 'ChristianBDev'
description 'QBCore Truck Robbery'
version '1.0.0'

shared_scripts {
	'@qb-core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'shared/*.lua',
}

server_scripts {
	'server/*.lua',
}

client_scripts {
	'client/*.lua',
}


lua54 'yes'
