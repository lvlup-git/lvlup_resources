Config = {}

Config.PlatePrefix = 'RENT' -- up to 8 chars (prefix + numbers)
Config.RefundPercent = 0.65 -- 65% refund

Config.Vehicles = {
    { label = 'Panto', model = 'panto', price = 150 },
    { label = 'Sultan', model = 'sultan', price = 350 },
}

Config.Locations = {
    {
        label = 'Vehicle Rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-38.02, -1115.61, 26.44), heading = 70.04,
        spawn = vec4(-45.13, -1114.76, 24.83, 2.29),
        hideBlip = true
    },
    {
        label = 'Vehicle Rental', pedModel = 'a_m_m_business_01',
        coords = vec3(-832.9, -2351.19, 14.57), heading = 267.7,
        spawn = vec4(-829.26, -2354.96, 12.96, 330.53),
        blip = { sprite = 810, color = 0, scale = 0.75 }
    },
}