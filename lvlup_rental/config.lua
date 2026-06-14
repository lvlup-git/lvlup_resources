Config = {}

Config.PlatePrefix = 'RENT' -- up to 8 chars (prefix + numbers eg. RENT1234)
Config.RefundPercent = 0.65 -- 65% refund

Config.ClearRentalsOnRestart = true -- Clears vehicle rentals on server start

Config.Vehicles = {
    { label = 'Faggio', model = 'faggio', price = 25 },
    { label = 'Panto', model = 'panto', price = 75 },
    { label = 'Sultan', model = 'sultan', price = 100 },
    { label = 'Bison', model = 'bison', price = 200 }
}

Config.Locations = {
    {
        label = 'Vehicle rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-1037.47, -1350.84, 5.55), heading = 350.29,
        spawn = vec4(-1036.9, -1348.8, 4.84, 73.11)
    },
    {
        label = 'Vehicle rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-1031.24, -2734.88, 20.17), heading = 46.81,
        spawn = vec4(-1029.44, -2732.87, 19.46, 240.06),
        blip = { sprite = 810, color = 0, scale = 0.75 }
    },
}
