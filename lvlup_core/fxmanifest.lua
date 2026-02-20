fx_version 'cerulean'
game 'gta5'
lua54 'yes'

files {'metas/weapons/*.meta'}
shared_scripts {'@ox_lib/init.lua', 'shared/*.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua', 'server/*.lua'}
client_scripts {'@qbx_core/modules/playerdata.lua', 'client/*.lua'}

data_file 'WEAPONINFO_FILE_PATCH' 'metas/weapons/*.meta'

dependencies {'/onesync', 'ox_lib'}