lvlup_config_target = {}

lvlup_config_target.Zones = {
    boosting = {
        radius = 1.0,
        coords = {
            vec3(720.74, -964.90, 25.06)
        },
        actions = {
            {
                type = 'event',
                name = 'boosting',
                icon = 'fa-solid fa-laptop',
                label = 'Use Computer',
                event = 'rahe-boosting:client:openTablet'
            }
        }
    },

    sanitizehands = {
        modelHashes = { 1155201954 },
        actions = {
            {
                type = 'emote',
                name = 'sanitizehands',
                icon = 'fa-solid fa-hand-sparkles',
                label = 'Sanitize Hands',
                emote = 'cleanhands',
                cancelEarly = true,
                progress = {
                    style = 'circle',
                    duration = 4000,
                    label = 'Sanitizing hands...',
                    canCancel = true,
                    disable = {car = true, combat = true}
                }
            }
        }
    }
}
