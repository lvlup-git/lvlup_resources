fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

dependencies {'ox_lib', 'meh-core'}