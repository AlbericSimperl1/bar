-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = {
            top = 6,
            right = 6,
            bottom = 6,
            left = 00
        },
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = false,
        col = {
            active_border = "#ffffff2c",
            inactive_border = "#ffffff00",
        },
    },

    decoration = {
        dim_special = 0.3,
        rounding = 8,
        active_opacity = 0.92,
        inactive_opacity = 0.85,
        fullscreen_opacity = 0.94,
        blur = {
            size = 3,
            passes = 3,
            special = true,
        },
    },
})
