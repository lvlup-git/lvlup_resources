fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'bridge/server/**.lua',
    'sv_sidejobs.lua'
}

client_scripts {
    'bridge/client/**.lua',
    'cl_sidejobs.lua'
}
