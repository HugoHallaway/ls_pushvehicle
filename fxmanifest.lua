fx_version 'cerulean'
games {'gta5'}

author 'ERROR'
version '1.0.0'

lua54 'yes'

ox_lib 'locale'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/config.lua',
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'server/main.lua'
}

files {
	'locales/*.json',
}