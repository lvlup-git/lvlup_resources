return {
    debug = false,
    elevatorTime = 6000,
    elevators = {
        ['Pillbox Hospital'] = {
            {
                FloorName = 'Roof', FloorDesc = 'Heli-pad access',
                TargetCoords = vector3(338.28, -583.72, 74.33), TargetRadius = 0.2,
                TeleLocation = vector3(339.29, -584.15, 74.16), TeleHeading = 246.95,
                joblock = {'lspd', 'bcso', 'sasp', 'ems'}
            },
            {
                FloorName = 'Main Floor', FloorDesc = 'Main entrance, check-in, rooms',
                TargetCoords = vector3(331.96, -597.19, 43.62), TargetRadius = 0.2,
                TeleLocation = vector3(331.81, -595.47, 43.28), TeleHeading = 68.31
            },
            {
                FloorName = 'Bottom Floor', FloorDesc = 'Rear entrance, garage',
                TargetCoords = vector3(340.03, -586.36, 29.20), TargetRadius = 0.2,
                TeleLocation = vector3(342.34, -585.5, 28.8),   TeleHeading = 250.53
            }
        },
        ['Humane Labs'] = {
            {
                FloorName = 'Main Floor', FloorDesc = 'Scientific rooms',
                TargetCoords = vector3(3541.91, 3673.86, 28.23), TargetRadius = 2.0,
                TeleLocation = vector3(3540.64, 3675.52, 28.12), TeleHeading = 171.4
            },
            {
                FloorName = 'Bottom Floor', FloorDesc = 'Cooling rooms',
                TargetCoords = vector3(3541.91, 3673.86, 21.10), TargetRadius = 2.0,
                TeleLocation = vector3(3540.54, 3675.31, 20.99), TeleHeading = 169.99
            }
        }
    }
}