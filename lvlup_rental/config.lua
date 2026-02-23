Config = {}

Config.PlatePrefix = 'RENT' -- up to 8 chars (prefix + numbers)
Config.RefundPercent = 0.65 -- 65% refund

Config.Vehicles = {
    { label = 'Panto', model = 'panto', price = 50 },
    { label = 'Sultan', model = 'sultan', price = 150 },
}

Config.Locations = {
    {
        label = 'Vehicle Rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-38.02, -1115.61, 26.44), heading = 70.04,
        spawn = vec4(-45.13, -1114.76, 24.83, 2.29)
    },
    {
        label = 'Vehicle Rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-1031.24, -2734.88, 20.17), heading = 46.81,
        spawn = vec4(-1029.44, -2732.87, 19.46, 240.06),
        blip = { sprite = 810, color = 0, scale = 0.75 }
    },
}
