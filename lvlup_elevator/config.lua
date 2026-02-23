return {
    debug = false,
    elevatorTime = 6000, -- Time in milliseconds for elevator animation
    jobCacheDuration = 5000, -- How long to cache player job data (ms)

    elevators = {
        ['Humane Labs'] = {
            {
                name = 'Main Floor',
                description = 'Scientific rooms',

                interaction = {
                    coords = vector3(3541.91, 3673.86, 28.23),
                    radius = 2.0
                },

                destination = {
                    coords = vector3(3540.64, 3675.52, 28.12),
                    heading = 171.4
                }
            },
            {
                name = 'Bottom Floor',
                description = 'Cooling rooms',

                interaction = {
                    coords = vector3(3541.91, 3673.86, 21.10),
                    radius = 2.0
                },

                destination = {
                    coords = vector3(3540.54, 3675.31, 20.99),
                    heading = 169.99
                }
            }
        }
    }
}
