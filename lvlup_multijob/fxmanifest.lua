fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Multi Job'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'cl_multi.lua'
}

server_scripts {
    'sv_multi.lua'
}

lua54 'yes'
