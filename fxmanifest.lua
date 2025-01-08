fx_version 'cerulean'
game 'gta5'

author 'Kakarot'
description 'Allows players to rob specific trucks for money and items'
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
